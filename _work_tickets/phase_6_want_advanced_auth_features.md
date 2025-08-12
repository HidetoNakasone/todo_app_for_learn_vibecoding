# Phase 6 (WANT): NextAuth.js v5 高度機能・ベストプラクティス実装

## 概要

Phase 1-5の基本機能実装完了後に検討する、NextAuth.js v5の高度機能とベストプラクティス実装。プロダクショングレード認証システムへの最終仕上げ作業。

**前提条件**: Phase 1-5 完了  
**実施タイミング**: 基本機能完成後の品質向上期間  
**優先度**: WANT (基本機能は Phase 1 で完了済み)  
**推定工数**: 7-10日

---

## 6.1 高度なCallbacks・認証ロジック (2-3日)

### 6.1.1 システム全体権限管理 (Team権限と統合したRBAC)

- [ ] グローバルユーザーロール管理システム

  ```typescript
  // schema.prisma 拡張 - Team機能と統合
  model User {
    globalRole     GlobalUserRole @default(USER)
    // 既存フィールド (teams, teamMemberships等) ...
  }

  enum GlobalUserRole {
    USER        // 一般ユーザー (個人機能のみ)
    MODERATOR   // 運営：複数チーム監視可能
    ADMIN       // 管理者：全チーム・全ユーザー管理可能
  }

  // Team内権限は既存のTeamRole (OWNER/ADMIN/MEMBER) を継続使用
  ```

- [ ] NextAuth.js Callbacks拡張 (SSO専用 + Team統合)

  ```typescript
  // auth.ts
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.globalRole = user.globalRole
        token.teamMemberships = await getUserTeamMemberships(user.id)
        token.permissions = await getUserGlobalPermissions(user.id)
      }
      return token
    },
    async session({ session, token }) {
      session.user.globalRole = token.globalRole as GlobalUserRole
      session.user.teamMemberships = token.teamMemberships as TeamMembership[]
      session.user.permissions = token.permissions as GlobalPermission[]
      return session
    },
    async signIn({ user, account, profile }) {
      // SSO検証ロジック (OAuth専用)
      if (account?.provider === "google") {
        return profile?.email_verified === true
      }
      if (account?.provider === "github") {
        // GitHubは常にverified
        return true
      }
      return false // 他のプロバイダーは拒否
    }
  }
  ```

- [ ] グローバル権限ベースルート保護 (middleware.ts拡張)

  ```typescript
  export default auth((req) => {
    const { auth: session } = req;
    const globalRole = session?.user?.globalRole;

    // システム管理専用ルート (/admin)
    if (req.nextUrl.pathname.startsWith("/admin")) {
      if (globalRole !== "ADMIN") {
        return NextResponse.redirect(new URL("/unauthorized", req.url));
      }
    }

    // 運営機能ルート (/moderation) - 複数チーム監視
    if (req.nextUrl.pathname.startsWith("/moderation")) {
      if (!["ADMIN", "MODERATOR"].includes(globalRole || "")) {
        return NextResponse.redirect(new URL("/unauthorized", req.url));
      }
    }

    // チーム機能は既存のTeam権限チェックで処理 (/teams/[id])
    // → Server Componentレベルで個別にTeamRole確認
  });
  ```

### 6.1.2 SSO専用プロファイルマッピング

- [ ] OAuth専用プロファイル処理 (Google + GitHub)

  ```typescript
  providers: [
    GitHub({
      async profile(profile) {
        return {
          id: profile.id.toString(),
          name: profile.name || profile.login,
          email: profile.email,
          image: profile.avatar_url,
          globalRole: determineGlobalRoleFromEmail(profile.email), // 管理者ドメイン判定
          githubUsername: profile.login,
          githubId: profile.id,
          provider: "github",
        };
      },
    }),
    Google({
      async profile(profile) {
        return {
          id: profile.sub,
          name: profile.name,
          email: profile.email,
          image: profile.picture,
          globalRole: determineGlobalRoleFromEmail(profile.email), // 管理者ドメイン判定
          googleId: profile.sub,
          provider: "google",
        };
      },
    }),
  ];

  // 管理者ドメイン判定関数
  function determineGlobalRoleFromEmail(email: string): GlobalUserRole {
    const adminDomains = process.env.ADMIN_DOMAINS?.split(",") || [];
    const moderatorDomains = process.env.MODERATOR_DOMAINS?.split(",") || [];

    const domain = email.split("@")[1];

    if (adminDomains.includes(domain)) return "ADMIN";
    if (moderatorDomains.includes(domain)) return "MODERATOR";
    return "USER";
  }
  ```

- [ ] OAuth専用アカウントリンク制御
  ```typescript
  callbacks: {
    async signIn({ user, account, profile }) {
      // OAuth専用のアカウントリンク制御
      if (account?.provider === "google" || account?.provider === "github") {
        const existingUser = await getUserByEmail(profile?.email)

        if (existingUser) {
          // 既存ユーザーに新しいOAuthアカウントをリンク
          const hasThisProvider = await checkProviderLinked(existingUser.id, account.provider)
          if (!hasThisProvider) {
            await linkOAuthAccount(existingUser.id, account)
          }
        }
        return true
      }

      return false // OAuth以外は全て拒否
    }
  }
  ```

---

## 6.2 セキュリティ強化・DAL実装 (2-3日)

### 6.2.1 Data Access Layer (DAL) - グローバル権限 + Team権限統合

- [ ] 集中認証検証システム (SSO + Team統合)

  ```typescript
  // lib/dal.ts
  import { auth } from "@/auth";
  import { cache } from "react";

  export const verifySession = cache(async () => {
    const session = await auth();

    if (!session?.user?.id) {
      throw new Error("User not authenticated");
    }

    return {
      isAuth: true,
      userId: session.user.id,
      globalRole: session.user.globalRole,
      teamMemberships: session.user.teamMemberships,
    };
  });

  export const requireGlobalRole = cache(
    async (requiredRole: GlobalUserRole) => {
      const { globalRole } = await verifySession();

      if (!hasGlobalRole(globalRole, requiredRole)) {
        throw new Error(`Access denied. Required global role: ${requiredRole}`);
      }

      return true;
    },
  );

  export const requireTeamRole = cache(
    async (teamId: string, requiredRole: TeamRole) => {
      const { userId, globalRole, teamMemberships } = await verifySession();

      // ADMINは全チームアクセス可能
      if (globalRole === "ADMIN") return true;

      const membership = teamMemberships?.find((tm) => tm.teamId === teamId);
      if (!membership) {
        throw new Error(`Access denied. Not a member of team ${teamId}`);
      }

      if (!hasTeamRole(membership.role, requiredRole)) {
        throw new Error(`Access denied. Required team role: ${requiredRole}`);
      }

      return true;
    },
  );

  export const requireTeamMembership = cache(async (teamId: string) => {
    const { globalRole, teamMemberships } = await verifySession();

    // ADMIN/MODERATORは全チームアクセス可能
    if (["ADMIN", "MODERATOR"].includes(globalRole)) return true;

    const isMember = teamMemberships?.some((tm) => tm.teamId === teamId);
    if (!isMember) {
      throw new Error(`Access denied. Not a member of team ${teamId}`);
    }

    return true;
  });
  ```

- [ ] Team統合リソース別アクセス制御

  ```typescript
  // lib/team-auth-utils.ts
  export async function canAccessTask(
    taskId: string,
    action: "read" | "write" | "delete",
  ) {
    const { userId, globalRole, teamMemberships } = await verifySession();

    if (globalRole === "ADMIN") return true;

    const task = await getTask(taskId);
    if (!task) return false;

    // 個人タスクの場合
    if (!task.teamId) {
      return task.userId === userId;
    }

    // チームタスクの場合
    const membership = teamMemberships?.find((tm) => tm.teamId === task.teamId);
    if (!membership) return false;

    switch (action) {
      case "read":
        return true; // チームメンバーは全て閲覧可能
      case "write":
        return membership.role !== "MEMBER" || task.assigneeId === userId;
      case "delete":
        return (
          ["OWNER", "ADMIN"].includes(membership.role) || task.userId === userId
        );
      default:
        return false;
    }
  }

  export async function canAccessTeam(
    teamId: string,
    action: "read" | "write" | "delete",
  ) {
    const { globalRole, teamMemberships } = await verifySession();

    if (globalRole === "ADMIN") return true;
    if (globalRole === "MODERATOR" && action === "read") return true;

    const membership = teamMemberships?.find((tm) => tm.teamId === teamId);
    if (!membership) return false;

    switch (action) {
      case "read":
        return true; // メンバーは閲覧可能
      case "write":
        return ["OWNER", "ADMIN"].includes(membership.role);
      case "delete":
        return membership.role === "OWNER";
      default:
        return false;
    }
  }
  ```

### 6.2.2 OAuth Token Rotation (Google/GitHub専用)

- [ ] OAuthトークンローテーション実装

  ```typescript
  callbacks: {
    async jwt({ token, account, user }) {
      // 初回OAuth サインイン
      if (account && user) {
        return {
          ...token,
          accessToken: account.access_token,
          refreshToken: account.refresh_token,
          accessTokenExpires: account.expires_at! * 1000,
          provider: account.provider, // google or github
        }
      }

      // アクセストークンが有効
      if (Date.now() < (token.accessTokenExpires as number)) {
        return token
      }

      // プロバイダー別リフレッシュトークンで更新
      if (token.provider === "google") {
        return await refreshGoogleToken(token)
      }

      // GitHubはリフレッシュトークンなし：再認証が必要
      if (token.provider === "github") {
        return { ...token, error: "RefreshAccessTokenError" }
      }

      return token
    },
    async session({ session, token }) {
      // トークンエラー時は再ログインを促す
      if (token.error === "RefreshAccessTokenError") {
        session.error = "RefreshAccessTokenError"
      }

      session.user.globalRole = token.globalRole
      session.user.teamMemberships = token.teamMemberships
      return session
    }
  }
  ```

- [ ] セッション無効化機能

  ```typescript
  // API route: /api/auth/revoke-session
  export async function POST(request: Request) {
    const session = await auth();
    if (!session?.user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    // データベースからセッション削除
    await revokeUserSessions(session.user.id);

    return NextResponse.json({ success: true });
  }
  ```

### 6.2.3 監査ログ・セキュリティモニタリング

- [ ] 認証イベントロギング

  ```typescript
  // lib/audit-log.ts
  export async function logAuthEvent(
    event: "signin" | "signout" | "signup" | "password_change",
    userId: string,
    metadata: Record<string, any> = {},
  ) {
    await createAuditLog({
      userId,
      event,
      timestamp: new Date(),
      ipAddress: metadata.ip,
      userAgent: metadata.userAgent,
      metadata,
    });
  }
  ```

- [ ] セキュリティ違反検知

  ```typescript
  // lib/security-monitor.ts
  export async function detectSuspiciousActivity(userId: string) {
    const recentLogins = await getRecentLogins(userId, 24); // 24時間以内

    // 異常な場所からのログイン
    const locations = recentLogins.map((login) => login.location);
    if (hasUnusualLocation(locations)) {
      await sendSecurityAlert(userId, "unusual_location");
    }

    // 短時間での複数失敗試行
    const failedAttempts = recentLogins.filter((login) => !login.success);
    if (failedAttempts.length > 5) {
      await temporarilyLockAccount(userId);
    }
  }
  ```

---

## 6.3 エラーハンドリング・UX改善 (1-2日)

### 6.3.1 カスタムエラーページ

- [ ] 包括的エラー処理

  ```typescript
  // app/auth/error/page.tsx
  "use client"

  import { useSearchParams } from "next/navigation"
  import { Alert, AlertDescription } from "@/components/ui/alert"
  import { Button } from "@/components/ui/button"

  const authErrors = {
    Configuration: "認証設定に問題があります。管理者にお問い合わせください。",
    AccessDenied: "アクセスが拒否されました。適切な権限がありません。",
    OAuthSignin: "OAuth認証でエラーが発生しました。もう一度お試しください。",
    OAuthCallback: "認証プロバイダーからの応答でエラーが発生しました。",
    OAuthCreateAccount: "アカウント作成でエラーが発生しました。",
    EmailCreateAccount: "このアプリはOAuth認証（Google/GitHub）のみ対応しています。",
    Callback: "認証コールバック処理でエラーが発生しました。",
    OAuthAccountNotLinked: "同じメールアドレスで既にアカウントが存在します。正しいプロバイダーでサインインしてください。",
    Default: "認証エラーが発生しました。OAuth（Google/GitHub）でサインインしてください。"
  }

  export default function AuthError() {
    const searchParams = useSearchParams()
    const error = searchParams?.get("error")

    const errorMessage = authErrors[error as keyof typeof authErrors] || authErrors.Default

    return (
      <div className="container max-w-md mx-auto mt-8">
        <Alert variant="destructive">
          <AlertDescription>{errorMessage}</AlertDescription>
        </Alert>

        <div className="mt-6 space-y-2">
          <Button onClick={() => window.location.href = "/auth/signin"} className="w-full">
            サインインページに戻る
          </Button>
          <Button variant="outline" onClick={() => window.location.href = "/"} className="w-full">
            ホームページに戻る
          </Button>
        </div>
      </div>
    )
  }
  ```

### 6.3.2 認証状態の最適化

- [ ] セッション期限切れハンドリング

  ```typescript
  // hooks/useAuthStatus.ts
  "use client";

  import { useSession } from "next-auth/react";
  import { useRouter } from "next/navigation";
  import { useToast } from "@/components/ui/use-toast";

  export function useAuthStatus() {
    const { data: session, status } = useSession();
    const router = useRouter();
    const { toast } = useToast();

    useEffect(() => {
      if (status === "unauthenticated") {
        toast({
          title: "セッションが期限切れです",
          description: "もう一度サインインしてください。",
          variant: "destructive",
        });
        router.push("/auth/signin");
      }
    }, [status]);

    return { session, status, isAuthenticated: status === "authenticated" };
  }
  ```

- [ ] 楽観的UI更新

  ```typescript
  // components/optimistic-auth.tsx
  "use client"

  import { useOptimistic, useTransition } from "react"
  import { signOut } from "next-auth/react"

  export function OptimisticSignOut() {
    const [isPending, startTransition] = useTransition()
    const [optimisticState, addOptimistic] = useOptimistic(
      { isSignedOut: false },
      (state) => ({ isSignedOut: true })
    )

    const handleSignOut = () => {
      startTransition(() => {
        addOptimistic(null)
        signOut()
      })
    }

    if (optimisticState.isSignedOut) {
      return <div>サインアウト中...</div>
    }

    return (
      <Button onClick={handleSignOut} disabled={isPending}>
        {isPending ? "サインアウト中..." : "サインアウト"}
      </Button>
    )
  }
  ```

---

## 6.4 テスト戦略・E2E自動化 (2日)

### 6.4.1 認証フローE2Eテスト

- [ ] Playwright認証テスト

  ```typescript
  // tests/auth.spec.ts
  import { test, expect } from "@playwright/test";

  test.describe("Authentication", () => {
    test("GitHub OAuth login flow", async ({ page }) => {
      await page.goto("/auth/signin");

      await page.click("text=GitHub でサインイン");

      // GitHub認証ページでの操作 (テスト環境)
      await page.fill('input[name="login"]', process.env.TEST_GITHUB_USERNAME!);
      await page.fill(
        'input[name="password"]',
        process.env.TEST_GITHUB_PASSWORD!,
      );
      await page.click('input[type="submit"]');

      // リダイレクト後の確認
      await expect(page).toHaveURL("/dashboard");
      await expect(page.locator('[data-testid="user-name"]')).toBeVisible();
    });

    test("unauthorized access protection", async ({ page }) => {
      await page.goto("/admin");
      await expect(page).toHaveURL("/auth/signin");
    });

    test("role-based access control", async ({ page, context }) => {
      // Adminユーザーでログイン
      await loginAsAdmin(page);
      await page.goto("/admin");
      await expect(page.locator("text=管理画面")).toBeVisible();

      // 一般ユーザーでログイン
      await context.clearCookies();
      await loginAsUser(page);
      await page.goto("/admin");
      await expect(page).toHaveURL("/unauthorized");
    });
  });
  ```

### 6.4.2 セキュリティテスト

- [ ] セッションセキュリティテスト

  ```typescript
  // tests/security.spec.ts
  test("session expiration handling", async ({ page, context }) => {
    await loginAsUser(page);

    // セッション手動削除
    await context.clearCookies();

    await page.goto("/dashboard");
    await expect(page).toHaveURL("/auth/signin");
    await expect(page.locator("text=セッションが期限切れです")).toBeVisible();
  });

  test("CSRF protection", async ({ request }) => {
    // CSRF トークンなしでのPOST リクエスト
    const response = await request.post("/api/auth/signin", {
      data: { email: "test@example.com" },
    });

    expect(response.status()).toBe(403);
  });
  ```

### 6.4.3 OAuth負荷テスト・パフォーマンステスト

- [ ] OAuth認証負荷テスト

  ```javascript
  // k6/oauth-load-test.js
  import { check } from "k6";
  import http from "k6/http";

  export let options = {
    vus: 50, // 50 virtual users (OAuth認証は外部依存のため控えめ)
    duration: "30s",
  };

  export default function () {
    // OAuth認証フロー負荷テスト
    let response = http.get("/api/auth/signin");

    check(response, {
      "signin page loads": (r) => r.status === 200,
      "response time < 2s": (r) => r.timings.duration < 2000, // OAuth考慮で2秒
    });

    // セッション確認API負荷テスト
    let sessionResponse = http.get("/api/auth/session", {
      headers: { Cookie: "next-auth.session-token=test-token" },
    });

    check(sessionResponse, {
      "session check < 500ms": (r) => r.timings.duration < 500,
    });
  }
  ```

- [ ] Team権限チェック性能テスト

  ```javascript
  // k6/team-auth-load-test.js
  export default function () {
    // 大量チーム権限チェック負荷テスト
    let teamResponse = http.get("/api/teams/test-team-id", {
      headers: { Authorization: `Bearer ${__ENV.TEST_TOKEN}` },
    });

    check(teamResponse, {
      "team access check < 300ms": (r) => r.timings.duration < 300,
      "correct team permissions": (r) => r.status === 200 || r.status === 403,
    });
  }
  ```

### 6.4.4 高度認証機能アクセシビリティテスト

- [ ] 認証フローのアクセシビリティ
  - [ ] OAuth認証ボタンのスクリーンリーダー対応
  - [ ] 認証エラーページの適切なaria-live設定
  - [ ] グローバルロール・チーム権限の音声案内対応
  - [ ] 権限不足時のエラーメッセージ明確化

- [ ] 管理機能のアクセシビリティ
  - [ ] 管理者ダッシュボードのキーボードナビゲーション
  - [ ] セキュリティイベントログの表形式適切対応
  - [ ] 権限変更UIのスクリーンリーダー対応

- [ ] Team権限UIのアクセシビリティ
  - [ ] グローバルロール表示の視覚・音声両対応
  - [ ] チーム権限vs全体権限の明確な区別表示
  - [ ] 複合権限状態の分かりやすい説明

---

## 6.5 運用・監視機能 (1日)

### 6.5.1 認証メトリクス・ダッシュボード

- [ ] 認証統計収集

  ```typescript
  // lib/auth-metrics.ts
  export async function collectAuthMetrics() {
    const metrics = {
      totalUsers: await getUserCount(),
      activeUsers: await getActiveUserCount(30), // 30日以内
      signInSuccess: await getSignInCount("success", 24),
      signInFailures: await getSignInCount("failure", 24),
      popularProviders: await getProviderStats(),
      averageSessionDuration: await getAverageSessionDuration(),
    };

    return metrics;
  }
  ```

- [ ] 管理者ダッシュボード

  ```typescript
  // app/admin/auth-dashboard/page.tsx
  export default async function AuthDashboard() {
    const metrics = await collectAuthMetrics()
    const recentUsers = await getRecentUsers(10)
    const securityEvents = await getSecurityEvents(50)

    return (
      <div className="space-y-6">
        <MetricsCards metrics={metrics} />
        <UserActivityChart data={metrics} />
        <RecentUsersTable users={recentUsers} />
        <SecurityEventsLog events={securityEvents} />
      </div>
    )
  }
  ```

### 6.5.2 アラート・通知システム

- [ ] セキュリティアラート

  ```typescript
  // lib/alerts.ts
  export async function sendSecurityAlert(
    type: "suspicious_login" | "multiple_failures" | "unusual_location",
    userId: string,
    details: any,
  ) {
    const user = await getUserById(userId);
    const alert = {
      type,
      userId,
      userEmail: user.email,
      timestamp: new Date(),
      details,
      severity: getSeverityLevel(type),
    };

    // 管理者通知
    await notifyAdmins(alert);

    // ユーザー通知 (必要に応じて)
    if (type === "unusual_location") {
      await sendUserNotification(user.email, "セキュリティ通知", alert);
    }
  }
  ```

---

## 完了判定基準

### 実装完了条件

- [ ] グローバル権限 + Team権限統合システムが正常動作する
- [ ] Data Access Layer による集中認証が機能する (SSO + Team統合)
- [ ] OAuth Token Rotation (Google/GitHub) が実装されている
- [ ] SSO専用エラーハンドリングが完了している
- [ ] OAuth認証E2Eテストが全て通過する
- [ ] Team統合セキュリティテストが通過する
- [ ] 認証メトリクス収集が動作する
- [ ] 管理者ダッシュボードが表示される
- [ ] アクセシビリティ要件 (WCAG 2.1 AA) を満たす

### 品質確認

- [ ] TypeScript型エラーなし
- [ ] ESLint警告なし
- [ ] セキュリティ脆弱性スキャン通過
- [ ] パフォーマンステスト基準達成
- [ ] アクセシビリティ要件満足

---

## 推定工数・優先度

| セクション | 作業内容               | 推定工数   | 優先度 |
| ---------- | ---------------------- | ---------- | ------ |
| 6.1        | Callbacks・RBAC        | 2-3日      | HIGH   |
| 6.2        | セキュリティ強化・DAL  | 2-3日      | HIGH   |
| 6.3        | エラーハンドリング・UX | 1-2日      | MEDIUM |
| 6.4        | テスト戦略・E2E        | 2日        | MEDIUM |
| 6.5        | 運用・監視機能         | 1日        | LOW    |
| **合計**   | **全実装**             | **7-10日** | -      |

---

**Phase 6 位置づけ**: プロダクショングレード認証システムへの最終仕上げ (SSO + Team統合)  
**実施判断**: Phase 1-5完了後、企業利用・大規模チーム運用時に実施検討  
**技術価値**: グローバル権限 + Team権限の統合、OAuth専用セキュリティ強化、運用監視  
**長期価値**: セキュリティ・保守性・運用効率の大幅向上、企業グレード対応
