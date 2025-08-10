# NextAuth.js v5 データベーススキーマ完全ガイド

## 記録者・作成日
- **記録者**: Claude Code
- **作成日**: 2025-08-10
- **プロジェクト**: TODO App (Next.js 15 + NextAuth.js v5 + Prisma + PostgreSQL)

## 概要

NextAuth.js v5 を使用した認証システムで必要なデータベーステーブルの詳細解説。
実際のデータと合わせて各テーブルの役割と構成を説明する。

## NextAuth.js v5 必須テーブル (4テーブル)

### 1. **users テーブル** - ユーザー基本情報

```prisma
model User {
  id            String    @id @default(cuid())
  name          String?
  email         String?   @unique
  emailVerified DateTime?
  image         String?
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
  
  // NextAuth.js relations
  accounts Account[]
  sessions Session[]
}
```

**役割**: 
- アプリケーションのユーザー基本情報を管理
- OAuth プロバイダー（GitHub、Google等）から取得した情報を統合保存

**各カラムの詳細**:

| カラム名 | 型 | 説明 | 例 |
|---|---|---|---|
| `id` | String | ユーザーの一意識別子。cuid() で自動生成される | `"cme5bdkaz0002ps2367l29fsp"` |
| `name` | String? | ユーザーの表示名。OAuth プロバイダーから取得 | `"HEP!"` |
| `email` | String? | メールアドレス。unique制約付き | `"user@example.com"` |
| `emailVerified` | DateTime? | メール認証完了日時。OAuth では通常 null | `null` |
| `image` | String? | プロフィール画像のURL。OAuth プロバイダーから取得 | `"https://avatars.githubusercontent.com/u/..."` |
| `createdAt` | DateTime | レコード作成日時。自動設定 | `"2025-08-10T06:40:02.315Z"` |
| `updatedAt` | DateTime | レコード更新日時。自動更新 | `"2025-08-10T06:40:02.315Z"` |

**実際のデータ例**:
```json
{
  "id": "cme5bdkaz0002ps2367l29fsp",
  "name": "HEP!",
  "email": null,
  "emailVerified": null,
  "image": "https://avatars.githubusercontent.com/u/41560892?v=4",
  "createdAt": "2025-08-10T06:40:02.315Z",
  "updatedAt": "2025-08-10T06:40:02.315Z"
}
```

**重要なポイント**:
- **idカラム**: `cuid()` は衝突しにくい一意IDを生成する関数（Collision-resistant Unique Identifier）
- **emailカラム**: GitHub OAuth ではメールアドレスが提供されない場合があるため nullable
- **imageカラム**: OAuth プロバイダーのプロフィール画像 URL を保存
- **?マーク**: Prisma で nullable（null 値を許可）を表す記法

### 2. **accounts テーブル** - OAuth 認証情報

```prisma
model Account {
  userId            String
  type              String
  provider          String
  providerAccountId String
  refresh_token     String?
  access_token      String?
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String?
  session_state     String?
  
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  @@id([provider, providerAccountId])
}
```

**役割**:
- OAuth プロバイダー（GitHub、Google等）別の認証情報とトークンを管理
- API アクセス用のトークンを永続化して、後からプロバイダーのAPI を呼び出し可能にする

**各カラムの詳細**:

| カラム名 | 型 | 説明 | 例 |
|---|---|---|---|
| `userId` | String | 関連する users テーブルのユーザーID | `"cme5bdkaz0002ps2367l29fsp"` |
| `type` | String | OAuth の種類。oauth または oidc | `"oauth"`, `"oidc"` |
| `provider` | String | OAuth プロバイダー名 | `"github"`, `"google"` |
| `providerAccountId` | String | プロバイダー側のユーザーID | `"41560892"` (GitHub のユーザーID) |
| `refresh_token` | String? | 長期間有効なトークン。access_token更新用 | `"ghr_xxxxxxxxxxxxx..."` |
| `access_token` | String? | API アクセス用の短期トークン | `"ghu_xxxxxxxxxxxxx..."` |
| `expires_at` | Int? | access_token の有効期限（UNIXタイムスタンプ） | `1754836802` |
| `token_type` | String? | トークンの種類。通常は bearer | `"bearer"` |
| `scope` | String? | 許可された権限のスコープ | `"userinfo.email userinfo.profile"` |
| `id_token` | String? | OpenID Connect の ID トークン（JWT） | `"eyJhbGciOiJSUzI1NiIs..."` |
| `session_state` | String? | OAuth セッション状態（通常は null） | `null` |

**実際のデータ例**:
```json
// GitHub OAuth の例
{
  "userId": "cme5bdkaz0002ps2367l29fsp",
  "provider": "github",
  "type": "oauth",
  "providerAccountId": "41560892",
  "access_token": "ghu_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "refresh_token": "ghr_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "expires_at": 1754836802,
  "token_type": "bearer",
  "scope": ""
}

// Google OAuth の例
{
  "userId": "cme5bqyyg0003ps23tf3hvrk7",
  "provider": "google",
  "type": "oidc",
  "providerAccountId": "100810084834844405154",
  "access_token": "ya29.a0AS3H6NwyG00R6plLjkK7...",
  "refresh_token": null,
  "expires_at": 1754812226,
  "token_type": "bearer",
  "scope": "userinfo.email userinfo.profile openid",
  "id_token": "eyJhbGciOiJSUzI1NiIs..."
}
```

**重要なポイント**:
- **複合主キー**: `@@id([provider, providerAccountId])` により、同じプロバイダーの同じユーザーは1レコードのみ
- **refresh_tokenの有無**:
  - GitHub: 常に提供される → 長期間のAPI アクセス可能
  - Google: `offline_access` スコープ指定時のみ提供 → 現在は null のため期限切れ後は再ログイン必須
- **expires_at**: UNIXタイムスタンプ形式。例: `1754836802` = 2025年10月10日頃
- **type の違い**: `"oauth"` (GitHub) vs `"oidc"` (Google) は OAuth の実装方式の違い

### 3. **sessions テーブル** - ログインセッション管理

```prisma
model Session {
  sessionToken String   @unique
  userId       String
  expires      DateTime
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt
  
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
}
```

**役割**:
- ユーザーのログイン状態を管理
- ブラウザの Cookie と紐づくセッショントークンを保存して、ユーザーがログイン状態を維持できるようにする

**各カラムの詳細**:

| カラム名 | 型 | 説明 | 例 |
|---|---|---|---|
| `sessionToken` | String | ユニークなセッション識別子。Cookie に保存される | `"c7a2949d-1804-4347-9304-563b312c9cb8"` |
| `userId` | String | このセッションの所有者である users テーブルのユーザーID | `"cme5bqyyg0003ps23tf3hvrk7"` |
| `expires` | DateTime | セッションの有効期限。これを過ぎると自動的に無効 | `"2025-09-09T06:50:27.835Z"` |
| `createdAt` | DateTime | セッション作成日時。ログイン時に自動設定 | `"2025-08-10T06:50:27.835Z"` |
| `updatedAt` | DateTime | セッション更新日時。自動更新 | `"2025-08-10T06:50:27.835Z"` |

**実際のデータ例**:
```json
{
  "sessionToken": "c7a2949d-1804-4347-9304-563b312c9cb8",
  "userId": "cme5bqyyg0003ps23tf3hvrk7",
  "expires": "2025-09-09T06:50:27.835Z",
  "createdAt": "2025-08-10T06:50:27.835Z",
  "updatedAt": "2025-08-10T06:50:27.835Z"
}
```

**重要なポイント**:
- **sessionToken カラム**: UUID 形式の一意識別子。ブラウザの Cookie に保存され、リクエスト毎にこの値でユーザーを識別
- **expires カラム**: 通常30日間のセッション有効期限。期限切れ後は再ログイン必須
- **自動削除機能**: NextAuth.js が期限切れセッションを自動的にクリーンアップ
- **@unique 制約**: sessionToken カラムには重複値を許可しない

### 4. **verificationtokens テーブル** - 確認トークン

```prisma
model VerificationToken {
  identifier String
  token      String
  expires    DateTime
  
  @@id([identifier, token])
}
```

**役割**:
- メール認証、パスワードリセット用の一時的なトークン管理
- Magic Link 認証（メールリンクでログイン）の実装に使用
- 一時的な確認作業で使用されるトークンを安全に保存

**各カラムの詳細**:

| カラム名 | 型 | 説明 | 例 |
|---|---|---|---|
| `identifier` | String | トークンの識別子。通常はメールアドレス | `"user@example.com"` |
| `token` | String | ランダム生成された確認用トークン | `"abc123def456ghi789"` |
| `expires` | DateTime | トークンの有効期限。通常は数時間〜1日程度 | `"2025-08-11T06:50:27.835Z"` |

**現在の状況**: 
このプロジェクトでは OAuth 認証のみを使用しているため、現在このテーブルは空の状態です。

**使用される場面の例**:
- **メール確認**: Email + Password 認証時の新規ユーザーメール確認
- **パスワードリセット**: 「パスワードを忘れた」機能でのリセットトークン管理
- **Magic Link**: メールに送られたリンクをクリックするだけでログインできる機能
- **招待機能**: チーム招待時の確認トークン管理

**重要なポイント**:
- **複合主キー**: `@@id([identifier, token])` により、同じ identifier（メールアドレス）でも複数の token を持てる
- **一時的な性質**: expires カラムにより自動的に無効化される
- **セキュリティ**: token は推測困難なランダム文字列で生成される

## データベース設計のベストプラクティス

### 1. **リレーション設計**
```prisma
// User と Account: 1対多
User -> Account[] // 1ユーザーが複数の OAuth プロバイダーを使用可能

// User と Session: 1対多  
User -> Session[] // 1ユーザーが複数デバイスでログイン可能

// onDelete: Cascade
// ユーザー削除時、関連する accounts/sessions も自動削除
```

### 2. **インデックス戦略**
```prisma
// 自動的に作成される重要なインデックス
User.email         @unique  // ログイン時の高速検索
Session.sessionToken @unique // セッション検証の高速化
Account.[provider, providerAccountId] @@id // OAuth 連携の一意性
```

### 3. **セキュリティ考慮事項**

**トークン管理**:
- `access_token` と `refresh_token` は機密情報
- データベースレベルでの暗号化推奨
- 定期的なトークンローテーション

**セッション管理**:
- セッショントークンはランダム生成 (UUID)
- HTTPS 必須、Cookie の `httpOnly`, `secure` フラグ
- セッション有効期限の適切な設定

## NextAuth.js v5 設定との対応関係

### 1. **プロバイダー設定 → accounts テーブル**
```javascript
// auth.ts
providers: [
  GitHub({
    clientId: process.env.AUTH_GITHUB_ID,
    clientSecret: process.env.AUTH_GITHUB_SECRET,
  }),
  Google({
    clientId: process.env.AUTH_GOOGLE_ID,
    clientSecret: process.env.AUTH_GOOGLE_SECRET,
  }),
]

// → accounts.provider: "github" | "google"
// → accounts.type: "oauth" | "oidc"
```

### 2. **アダプター設定 → データベース操作**
```javascript
// auth.ts
adapter: PrismaAdapter(prisma),

// → 自動的に users, accounts, sessions, verificationtokens を操作
// → Prisma クライアント経由でデータベース読み書き
```

### 3. **コールバック設定 → ユーザー情報カスタマイズ**
```javascript
callbacks: {
  session: ({ session, token }) => ({
    ...session,
    user: { ...session.user, id: token.sub }
  }),
}

// → User テーブルの情報をセッションに含める
```

## 実装時の注意点

### 1. **マイグレーション実行順序**
```bash
# 1. スキーマ更新
bun prisma db push

# 2. クライアント再生成  
bun prisma generate

# 3. 開発サーバー再起動
bun run dev
```

### 2. **環境変数の必須設定**
```bash
# .env.local
AUTH_SECRET="your-secret-key"
AUTH_GITHUB_ID="your-github-client-id"
AUTH_GITHUB_SECRET="your-github-secret"
AUTH_GOOGLE_ID="your-google-client-id"  
AUTH_GOOGLE_SECRET="your-google-secret"
```

### 3. **Prisma スキーマのポイント**
```prisma
// カスタム出力先指定
generator client {
  provider = "prisma-client-js"
  output   = "../src/generated/prisma"
}

// テーブル名マッピング
@@map("users")      // User model → users table
@@map("accounts")   // Account model → accounts table
@@map("sessions")   // Session model → sessions table
```

## トラブルシューティング

### よくあるエラーと解決法

1. **SessionTokenError**
   - 原因: セッショントークンの不整合
   - 解決: `sessions` テーブルの該当レコード削除

2. **PrismaClientValidationError**  
   - 原因: スキーマとクライアントの不一致
   - 解決: `bun prisma generate` でクライアント再生成

3. **OAuth エラー (Google)**
   - 原因: `refresh_token` 未取得
   - 解決: `access_type: "offline"` をプロバイダー設定に追加

## まとめ

NextAuth.js v5 のデータベーススキーマは以下の4つの核となるテーブルで構成される：

1. **users**: ユーザー基本情報の統合管理
2. **accounts**: OAuth プロバイダー別認証情報とトークン管理  
3. **sessions**: ログインセッションの状態管理
4. **verificationtokens**: 一時的な確認トークン管理

これらのテーブルにより、複数 OAuth プロバイダーでの認証、セッション管理、API アクセストークンの永続化が実現できる。アプリケーション固有のテーブル（tasks, categories等）は、users テーブルとリレーションを張ることで、ユーザー別のデータ管理が可能になる。