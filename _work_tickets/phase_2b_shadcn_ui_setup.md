# Phase 2b: shadcn/ui セットアップ・統合 (推定工数: 3-4日)

## 概要

Phase 2 (Tailwind CSS v4導入) 完了後、Phase 3のUI開発開始前にshadcn/ui コンポーネントライブラリを導入・設定する作業チケット。Zod統合、Tailwind CSS v4との連携、TypeScript最適化を含む包括的なセットアップを実施。

**技術スタック**: Next.js 15 + TypeScript + Tailwind CSS v4 + Zod + React Hook Form  
**前提条件**: Phase 2 (Tailwind CSS v4導入) 完了  
**実施タイミング**: Phase 2完了後、Phase 3 (個人TODO機能UI開発) 開始前  
**優先度**: MUST (Phase 3以降のUI開発でshadcn/uiコンポーネントを活用するため必須)

## Phase A: 事前準備・設計 (0.5日)

### A.1 現状確認・設計方針決定

- [ ] 現在のプロジェクト構造確認
  ```bash
  ls -la src/
  cat tsconfig.json | grep -A 10 '"paths"'
  ```
- [ ] Tailwind CSS v4設定の確認
  ```bash
  cat src/app/globals.css
  ```
- [ ] shadcn/ui設計方針決定
  - [ ] スタイル: "new-york" vs "default" (new-york推奨)
  - [ ] RSC (React Server Components): true
  - [ ] TypeScript: true
  - [ ] Tailwind prefix: なし (デフォルト)
  - [ ] CSS Variables: true (Tailwind v4@theme連携)

### A.2 依存関係・互換性確認

- [ ] 必要依存パッケージの確認
  ```bash
  # 確認すべきパッケージ
  echo "Radix UI, class-variance-authority, clsx, tailwind-merge"
  ```
- [ ] バージョン互換性確認
  - [ ] Next.js 15との互換性
  - [ ] Tailwind CSS v4との互換性
  - [ ] TypeScript最新版との互換性

## Phase B: shadcn/ui 初期セットアップ (1日)

### B.1 shadcn/ui CLI導入・初期化

- [ ] shadcn/ui CLI での初期化
  ```bash
  pnpm dlx shadcn@latest init
  ```
- [ ] 設定内容確認
  ```json
  {
    "$schema": "https://ui.shadcn.com/schema.json",
    "style": "new-york",
    "rsc": true,
    "tsx": true,
    "tailwind": {
      "config": "tailwind.config.ts",
      "css": "src/app/globals.css",
      "baseColor": "slate",
      "cssVariables": true,
      "prefix": ""
    },
    "aliases": {
      "components": "@/components",
      "utils": "@/lib/utils",
      "ui": "@/components/ui",
      "lib": "@/lib",
      "hooks": "@/hooks"
    }
  }
  ```

### B.2 パスエイリアス・ディレクトリ構造整備

- [ ] tsconfig.json パスエイリアス確認・追加
  ```json
  {
    "compilerOptions": {
      "paths": {
        "@/*": ["./src/*"],
        "@/components/*": ["./src/components/*"],
        "@/lib/*": ["./src/lib/*"],
        "@/hooks/*": ["./src/hooks/*"],
        "@/ui/*": ["./src/components/ui/*"]
      }
    }
  }
  ```
- [ ] 必要ディレクトリ作成
  ```bash
  mkdir -p src/components/ui
  mkdir -p src/lib
  mkdir -p src/hooks
  ```

### B.3 ユーティリティ関数・統合設定

- [ ] cn() ユーティリティ関数作成 (`src/lib/utils.ts`)

  ```typescript
  import { type ClassValue, clsx } from "clsx";
  import { twMerge } from "tailwind-merge";

  export function cn(...inputs: ClassValue[]) {
    return twMerge(clsx(inputs));
  }
  ```

- [ ] Tailwind CSS v4 との統合確認
  - [ ] CSS Variables と shadcn/ui テーマ変数の連携
  - [ ] @theme ディレクティブとの互換性確認

## Phase C: 基本コンポーネント導入・検証 (1.5日)

### C.1 基本UIコンポーネント導入

- [ ] フォーム関連コンポーネント (Phase 3で使用予定)

  ```bash
  pnpm dlx shadcn@latest add button
  pnpm dlx shadcn@latest add input
  pnpm dlx shadcn@latest add label
  pnpm dlx shadcn@latest add textarea
  pnpm dlx shadcn@latest add select
  pnpm dlx shadcn@latest add checkbox
  pnpm dlx shadcn@latest add radio-group
  ```

- [ ] レイアウト・表示コンポーネント

  ```bash
  pnpm dlx shadcn@latest add card
  pnpm dlx shadcn@latest add badge
  pnpm dlx shadcn@latest add separator
  pnpm dlx shadcn@latest add skeleton
  ```

- [ ] ナビゲーション・フィードバックコンポーネント
  ```bash
  pnpm dlx shadcn@latest add dropdown-menu
  pnpm dlx shadcn@latest add toast
  pnpm dlx shadcn@latest add alert
  pnpm dlx shadcn@latest add dialog
  ```

### C.2 React Hook Form + Zod統合パターン実装

- [ ] React Hook Form依存関係追加

  ```bash
  bun add react-hook-form @hookform/resolvers zod
  ```

- [ ] Form統合コンポーネント追加

  ```bash
  pnpm dlx shadcn@latest add form
  ```

- [ ] 統合フォームパターン実装例 (`src/components/example-form.tsx`)

  ```typescript
  "use client";

  import { zodResolver } from "@hookform/resolvers/zod";
  import { useForm } from "react-hook-form";
  import { z } from "zod";
  import { Button } from "@/components/ui/button";
  import {
    Form,
    FormControl,
    FormField,
    FormItem,
    FormLabel,
    FormMessage,
  } from "@/components/ui/form";
  import { Input } from "@/components/ui/input";

  const formSchema = z.object({
    name: z.string().min(1, "名前は必須です").max(50, "名前は50文字以内です"),
    email: z.string().email("有効なメールアドレスを入力してください"),
  });

  export function ExampleForm() {
    const form = useForm<z.infer<typeof formSchema>>({
      resolver: zodResolver(formSchema),
      defaultValues: {
        name: "",
        email: "",
      },
    });

    function onSubmit(values: z.infer<typeof formSchema>) {
      console.log(values);
    }

    return (
      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
          <FormField
            control={form.control}
            name="name"
            render={({ field }) => (
              <FormItem>
                <FormLabel>名前</FormLabel>
                <FormControl>
                  <Input placeholder="名前を入力" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="email"
            render={({ field }) => (
              <FormItem>
                <FormLabel>メールアドレス</FormLabel>
                <FormControl>
                  <Input placeholder="email@example.com" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <Button type="submit">送信</Button>
        </form>
      </Form>
    );
  }
  ```

### C.3 テーマ・スタイリング統合

- [ ] Tailwind CSS v4 @theme との統合最適化

  ```css
  /* src/app/globals.css に追加 */
  @import "tailwindcss";

  @theme {
    /* shadcn/ui + カスタムテーマ統合 */
    --color-background: 0 0% 100%;
    --color-foreground: 222.2 84% 4.9%;
    --color-card: 0 0% 100%;
    --color-card-foreground: 222.2 84% 4.9%;
    --color-popover: 0 0% 100%;
    --color-popover-foreground: 222.2 84% 4.9%;
    --color-primary: 221.2 83.2% 53.3%;
    --color-primary-foreground: 210 40% 98%;
    --color-secondary: 210 40% 96%;
    --color-secondary-foreground: 222.2 84% 4.9%;
    --color-muted: 210 40% 96%;
    --color-muted-foreground: 215.4 16.3% 46.9%;
    --color-accent: 210 40% 96%;
    --color-accent-foreground: 222.2 84% 4.9%;
    --color-destructive: 0 84.2% 60.2%;
    --color-destructive-foreground: 210 40% 98%;
    --color-border: 214.3 31.8% 91.4%;
    --color-input: 214.3 31.8% 91.4%;
    --color-ring: 221.2 83.2% 53.3%;
  }

  .dark {
    --color-background: 222.2 84% 4.9%;
    --color-foreground: 210 40% 98%;
    /* ダークモード色定義... */
  }
  ```

- [ ] ダークモード対応確認 (Next.js 15 + next-themes)
  ```bash
  bun add next-themes
  ```

## Phase D: 認証UIとの統合・実装例 (1日)

### D.1 NextAuth.js v5 UI統合

- [ ] サインイン・サインアウトボタンコンポーネント実装

  ```typescript
  // src/components/auth-button.tsx
  "use client";

  import { signIn, signOut, useSession } from "next-auth/react";
  import { Button } from "@/components/ui/button";
  import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
  import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
  } from "@/components/ui/dropdown-menu";

  export function AuthButton() {
    const { data: session, status } = useSession();

    if (status === "loading") {
      return <Button variant="outline" disabled>Loading...</Button>;
    }

    if (!session?.user) {
      return (
        <div className="flex gap-2">
          <Button
            onClick={() => signIn("github")}
            variant="outline"
            className="flex items-center gap-2"
          >
            GitHub でサインイン
          </Button>
          <Button
            onClick={() => signIn("google")}
            variant="default"
            className="flex items-center gap-2"
          >
            Google でサインイン
          </Button>
        </div>
      );
    }

    return (
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" className="relative h-8 w-8 rounded-full">
            <Avatar className="h-8 w-8">
              <AvatarImage src={session.user.image ?? ""} alt={session.user.name ?? ""} />
              <AvatarFallback>{session.user.name?.[0]}</AvatarFallback>
            </Avatar>
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent className="w-56" align="end" forceMount>
          <DropdownMenuItem className="flex-col items-start">
            <div className="font-medium">{session.user.name}</div>
            <div className="text-xs text-muted-foreground">{session.user.email}</div>
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuItem onClick={() => signOut()}>
            サインアウト
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    );
  }
  ```

- [ ] レイアウトコンポーネント実装

  ```typescript
  // src/components/app-layout.tsx
  import { auth } from "@/auth";
  import { AuthButton } from "@/components/auth-button";
  import { ThemeProvider } from "@/components/theme-provider";
  import { Toaster } from "@/components/ui/toaster";

  interface AppLayoutProps {
    children: React.ReactNode;
  }

  export async function AppLayout({ children }: AppLayoutProps) {
    const session = await auth();

    return (
      <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
        <div className="min-h-screen bg-background">
          <header className="border-b">
            <div className="container flex h-16 items-center justify-between py-4">
              <h1 className="text-xl font-semibold">TODO App</h1>
              <AuthButton />
            </div>
          </header>
          <main className="container py-6">{children}</main>
        </div>
        <Toaster />
      </ThemeProvider>
    );
  }
  ```

### D.2 追加コンポーネント導入

- [ ] 認証UIで使用するコンポーネント追加

  ```bash
  pnpm dlx shadcn@latest add avatar
  pnpm dlx shadcn@latest add dropdown-menu
  ```

- [ ] テーマ切り替えコンポーネント (next-themes統合)
  ```bash
  pnpm dlx shadcn@latest add switch
  ```

## Phase E: 品質保証・ドキュメント整備 (0.5日)

### E.1 動作確認・テスト

- [ ] コンポーネント表示確認
  - [ ] ライトモード・ダークモード表示確認
  - [ ] レスポンシブ表示確認
  - [ ] インタラクション動作確認

- [ ] TypeScript型チェック

  ```bash
  bunx tsc --noEmit
  ```

- [ ] ESLint品質チェック

  ```bash
  bun run lint
  ```

- [ ] Prettier整形確認
  ```bash
  bun run lint:fix
  ```

### E.2 ドキュメント・スタイルガイド作成

- [ ] shadcn/ui使用ガイド作成 (`docs/shadcn-ui-guide.md`)
  - [ ] プロジェクト固有の使用方法
  - [ ] Zod + React Hook Form 統合パターン
  - [ ] Tailwind CSS v4 との連携方法
  - [ ] カスタムコンポーネント作成指針

- [ ] コンポーネントカタログページ作成 (開発用)

  ```typescript
  // src/app/dev/components/page.tsx
  import { ExampleForm } from "@/components/example-form";
  import { AuthButton } from "@/components/auth-button";
  import { Button } from "@/components/ui/button";
  import { Card } from "@/components/ui/card";

  export default function ComponentsPage() {
    return (
      <div className="space-y-8">
        <h1>Component Catalog</h1>
        <Card className="p-6">
          <h2>Form Example</h2>
          <ExampleForm />
        </Card>
        <Card className="p-6">
          <h2>Auth Button</h2>
          <AuthButton />
        </Card>
      </div>
    );
  }
  ```

## 完了判定基準

### 導入成功の条件

- [ ] shadcn/ui が正常にセットアップされている
- [ ] Zod + React Hook Form統合が動作する
- [ ] Tailwind CSS v4 @theme と shadcn/ui テーマが連携している
- [ ] 基本コンポーネントが正常表示・動作する
- [ ] NextAuth.js v5 との統合UIが実装されている
- [ ] TypeScript型エラーがない
- [ ] ダークモード対応が完了している

### Phase 3 開発準備完了の条件

- [ ] TaskCard, TaskForm, TaskList で使用するコンポーネントが揃っている
- [ ] Zod統合フォームパターンが確立されている
- [ ] レスポンシブ・アクセシビリティ対応パターンが確立されている

## 推定工数・スケジュール

| Phase    | 作業内容                     | 推定工数 | 担当者 |
| -------- | ---------------------------- | -------- | ------ |
| Phase A  | 事前準備・設計               | 0.5日    | hep    |
| Phase B  | shadcn/ui初期セットアップ    | 1日      | hep    |
| Phase C  | 基本コンポーネント導入・検証 | 1.5日    | hep    |
| Phase D  | 認証UI統合・実装例           | 1日      | hep    |
| Phase E  | 品質保証・ドキュメント整備   | 0.5日    | hep    |
| **合計** | **全プロセス**               | **4日**  | -      |

## 次フェーズ連携

- **Phase 3 (個人TODO機能)**: shadcn/ui + Zod統合パターンでUI開発
- **TaskCard**: Card, Badge, Button, DropdownMenuを活用
- **TaskForm**: Form, Input, Textarea, Select, Buttonを活用
- **TaskList**: Card, Skeleton, Alert, Separatorを活用

---

**Phase 2b 優先度**: MUST  
**実装価値**: HIGH（UI開発効率・品質・一貫性の大幅向上）  
**完了条件**: Phase 3でのshadcn/ui + Zod統合UI開発が可能な状態
