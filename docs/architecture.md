# TODO アプリ アーキテクチャ設計書

## システム全体アーキテクチャ

```mermaid
graph TB
    subgraph "Ubuntu Server"
        subgraph "Docker Container (Next.js App)"
            subgraph "Frontend Layer"
                F1[React Components]
                F2[shadcn/ui]
                F3[TypeScript]
                F4[Tailwind CSS]
            end

            subgraph "Backend Layer"
                B1[Next.js API Routes]
                B2[Prisma ORM]
                B3[Zod Validation]
            end

            PORT1[Port: 3000]
        end

        subgraph "Docker Container (PostgreSQL)"
            subgraph "Database"
                DB1[PostgreSQL DB]
                DB2[Tasks Table]
                DB3[Categories Table]
                DB4[Indexes]
            end

            VOL[Volume: /var/lib/postgresql]
            PORT2[Port: 5432]
        end
    end

    USER[User Browser] --> F1
    F1 --> B1
    B1 --> B2
    B2 -.->|TCP Connection| DB1
    DB1 --> DB2
    DB1 --> DB3
    DB1 --> DB4

    style F1 fill:#e1f5fe
    style B1 fill:#f3e5f5
    style DB1 fill:#e8f5e8
    style USER fill:#fff3e0
```

## シーケンス図

### タスク作成フロー

```mermaid
sequenceDiagram
    participant U as User
    participant F as Frontend
    participant A as API Routes
    participant P as Prisma ORM
    participant D as PostgreSQL DB

    U->>F: タスク作成フォーム入力
    F->>F: Zod バリデーション
    alt バリデーション成功
        F->>A: POST /api/tasks
        A->>A: リクエストバリデーション
        A->>P: task.create()
        P->>D: INSERT INTO tasks
        D-->>P: タスクID返却
        P-->>A: 作成されたタスク
        A-->>F: 201 Created + タスクデータ
        F-->>U: 成功メッセージ表示
        F->>F: タスク一覧を更新
    else バリデーションエラー
        F-->>U: エラーメッセージ表示
    end
```

### タスク状態変更フロー

```mermaid
sequenceDiagram
    participant U as User
    participant F as Frontend
    participant A as API Routes
    participant P as Prisma ORM
    participant D as PostgreSQL DB

    U->>F: 状態変更ボタンクリック
    F->>A: PUT /api/tasks/[id]
    Note over F,A: { status: "in_progress" }

    A->>A: 状態遷移バリデーション
    alt 有効な状態遷移
        A->>P: task.update()
        P->>D: UPDATE tasks SET status=?
        D-->>P: 更新完了
        P-->>A: 更新されたタスク
        A-->>F: 200 OK + タスクデータ
        F->>F: UI状態更新
        F-->>U: 視覚的フィードバック
    else 無効な状態遷移
        A-->>F: 400 Bad Request
        F-->>U: エラーメッセージ表示
    end
```

### タスク一覧取得・フィルタリングフロー

```mermaid
sequenceDiagram
    participant U as User
    participant F as Frontend
    participant A as API Routes
    participant P as Prisma ORM
    participant D as PostgreSQL DB

    U->>F: ページアクセス
    F->>A: GET /api/tasks
    A->>P: task.findMany()
    P->>D: SELECT * FROM tasks
    D-->>P: タスクリスト
    P-->>A: タスクデータ配列
    A-->>F: 200 OK + タスク一覧
    F-->>U: タスク一覧表示

    U->>F: フィルタ条件変更
    Note over U,F: 状態: "in_progress"
    F->>A: GET /api/tasks?status=in_progress
    A->>P: task.findMany({where: {status}})
    P->>D: SELECT * FROM tasks WHERE status=?
    D-->>P: フィルタされたタスク
    P-->>A: フィルタ結果
    A-->>F: 200 OK + フィルタ済み一覧
    F-->>U: フィルタされたタスク表示
```

### エラーハンドリングフロー

```mermaid
sequenceDiagram
    participant U as User
    participant F as Frontend
    participant A as API Routes
    participant P as Prisma ORM
    participant D as PostgreSQL DB

    U->>F: タスク操作実行
    F->>A: API リクエスト
    A->>P: Prisma操作
    P->>D: データベースクエリ

    alt データベースエラー
        D-->>P: 接続エラー
        P-->>A: PrismaClientError
        A->>A: エラーログ記録
        A-->>F: 500 Internal Server Error
        F->>F: エラー状態設定
        F-->>U: "サーバーエラーが発生しました"
    else バリデーションエラー
        A->>A: Zodバリデーション失敗
        A-->>F: 400 Bad Request + 詳細
        F-->>U: 具体的なエラーメッセージ
    else リソース未発見
        P-->>A: レコードが見つからない
        A-->>F: 404 Not Found
        F-->>U: "タスクが見つかりません"
    end
```

## フロントエンド アーキテクチャ

### ディレクトリ構造

#### 現在の構造 (Next.js 15 App Router) - Phase 1 完了時点

```
src/
├── app/                       # Next.js App Router
│   ├── globals.css           # グローバルスタイル
│   ├── layout.tsx            # ルートレイアウト
│   ├── page.tsx              # ホームページ
│   ├── favicon.ico           # ファビコン
│   ├── auth/                 # 認証関連ページ
│   │   └── error/
│   │       └── page.tsx      # OAuth認証エラー処理ページ
│   ├── api/                  # API Routes
│   │   └── auth/
│   │       └── [...nextauth]/
│   │           └── route.ts  # NextAuth.js v5 API endpoints
│   └── _components/          # 再利用可能なコンポーネント (プライベート)
│       └── AuthButton.tsx    # 認証ボタンコンポーネント (Server Component)
├── generated/prisma/         # 生成されたPrismaクライアント (カスタムパス)
│   ├── index.js             # メインPrismaクライアント
│   ├── client.js            # クライアントモジュール
│   ├── edge.js              # Edge Runtime対応
│   ├── wasm.js              # WebAssembly サポート
│   └── runtime/             # Prisma ランタイムファイル群
└── auth.ts                   # NextAuth.js v5 設定ファイル
```

#### Phase 1 完了項目 (認証機能)

現在実装済みの基本認証機能：

- **NextAuth.js v5**: GitHub/Google OAuth認証システム
- **Session Management**: PostgreSQL + Prisma Adapter によるデータベースセッション
- **Route Protection**: 認証状態に応じたページアクセス制御
- **Error Handling**: OAuth認証エラー専用ページ（`/auth/error`）
- **Development Environment**: Docker + HTTPS対応の開発環境

#### 将来実装予定の構造 (Phase 2-6)

```
src/app/
├── _lib/                    # ユーティリティライブラリ (Phase 2)
│   ├── utils.ts            # 汎用ユーティリティ関数
│   ├── validations.ts      # Zod バリデーションスキーマ
│   ├── db.ts              # Prisma クライアントインスタンス
│   └── types.ts           # TypeScript 型定義
├── _hooks/                 # カスタムReactフック (Phase 3)
│   ├── useTasks.ts        # タスク操作フック
│   └── useCategories.ts   # カテゴリ操作フック
├── tasks/                  # タスク管理ページ (Phase 3)
│   ├── page.tsx           # タスク一覧ページ
│   ├── [id]/
│   │   └── page.tsx       # タスク詳細・編集ページ
│   └── new/
│       └── page.tsx       # 新規タスク作成ページ
├── categories/             # カテゴリ管理ページ (Phase 4)
│   ├── page.tsx           # カテゴリ一覧ページ
│   └── [id]/
│       └── page.tsx       # カテゴリ詳細ページ
├── api/
│   ├── tasks/             # タスクAPI Routes (Phase 3)
│   │   ├── route.ts       # GET(一覧), POST(作成)
│   │   └── [id]/
│   │       └── route.ts   # GET(詳細), PUT(更新), DELETE(削除)
│   └── categories/        # カテゴリAPI Routes (Phase 4)
│       ├── route.ts       # GET(一覧), POST(作成)
│       └── [id]/
│           └── route.ts   # GET(詳細), PUT(更新), DELETE(削除)
└── _components/
    ├── ui/                # shadcn/ui コンポーネント (Phase 2)
    │   ├── button.tsx     # ボタンコンポーネント
    │   ├── card.tsx       # カードコンポーネント
    │   ├── form.tsx       # フォームコンポーネント
    │   └── ...           # その他UIコンポーネント
    ├── TaskCard.tsx       # タスク表示カード (Phase 3)
    ├── TaskForm.tsx       # タスク入力フォーム (Phase 3)
    ├── TaskList.tsx       # タスク一覧表示 (Phase 3)
    └── CategorySelector.tsx # カテゴリ選択 (Phase 4)
```

#### オプション: ルートグループによる論理的整理

将来の拡張を見据えた構造：

```
src/app/
├── (dashboard)/              # メイン機能グループ (URLに影響なし)
│   ├── layout.tsx           # ダッシュボード共通レイアウト
│   ├── tasks/
│   └── categories/
├── (auth)/                  # 認証機能グループ (将来拡張)
│   ├── layout.tsx           # 認証ページ共通レイアウト
│   ├── login/
│   └── signup/
└── api/                     # API Routes (グループ化しない)
```

#### メタデータ最適化

各ページファイルに SEO 対応の metadata を追加：

```typescript
// app/tasks/page.tsx
import { Metadata } from "next";

export const metadata: Metadata = {
  title: "タスク一覧 | TODO App",
  description: "あなたのタスクを効率的に管理",
};
```

### レイヤー構成

#### 1. プレゼンテーション層 (Components)

- **責務**: UI の表示とユーザーインタラクション
- **技術**: React, shadcn/ui, Tailwind CSS
- **特徴**:
  - Server Components と Client Components の適切な使い分け
  - アクセシビリティの考慮
  - レスポンシブデザイン

#### 2. ビジネスロジック層 (Hooks & Utils)

- **責務**: アプリケーションロジックとデータ変換
- **技術**: Custom Hooks, TypeScript
- **特徴**:
  - 状態管理
  - API 呼び出し
  - データバリデーション

#### 3. データアクセス層 (API Routes)

- **責務**: データベースとの通信
- **技術**: Next.js API Routes, Prisma ORM
- **特徴**:
  - RESTful API 設計
  - エラーハンドリング
  - レスポンス型定義

## バックエンド アーキテクチャ

### API 設計

#### エンドポイント一覧

```typescript
// Tasks API
GET    /api/tasks              # タスク一覧取得
POST   /api/tasks              # タスク作成
GET    /api/tasks/[id]         # 特定タスク取得
PUT    /api/tasks/[id]         # タスク更新
DELETE /api/tasks/[id]         # タスク削除

// Categories API
GET    /api/categories         # カテゴリ一覧取得
POST   /api/categories         # カテゴリ作成
GET    /api/categories/[id]    # 特定カテゴリ取得
PUT    /api/categories/[id]    # カテゴリ更新
DELETE /api/categories/[id]    # カテゴリ削除
```

#### API レスポンス形式

```typescript
// 成功レスポンス
interface ApiResponse<T> {
  success: true;
  data: T;
}

// エラーレスポンス
interface ApiError {
  success: false;
  error: {
    message: string;
    code: string;
    details?: any;
  };
}
```

## セキュリティ設計

### 入力値検証

- **Zod スキーマ**: フロントエンド・バックエンド共通のバリデーション
- **サニタイゼーション**: XSS 攻撃の防止
- **型安全性**: TypeScript による静的型チェック

### データベースセキュリティ

- **Prisma ORM**: SQL インジェクション攻撃の防止
- **パラメータ化クエリ**: 安全なデータベースアクセス
- **接続暗号化**: SSL/TLS 接続の使用

## パフォーマンス最適化

### フロントエンド最適化

- **Server Components**: サーバーサイドレンダリングの活用
- **動的インポート**: コード分割による初期読み込み時間の短縮
- **画像最適化**: Next.js Image コンポーネントの使用
- **キャッシュ戦略**: SWR または React Query の使用

### バックエンド最適化

- **データベースインデックス**: クエリパフォーマンスの向上
- **接続プール**: データベース接続の効率化
- **レスポンスキャッシュ**: 頻繁にアクセスされるデータのキャッシュ

## 運用・監視

### ロギング

- **アプリケーションログ**: エラーとアクセスログ
- **データベースログ**: クエリパフォーマンスの監視
- **コンテナログ**: Docker コンテナの状態監視

### ヘルスチェック

- **アプリケーション**: `/api/health` エンドポイント
- **データベース**: 接続確認とレスポンス時間測定
- **コンテナ**: Docker Compose health check

### バージョン管理, 設定ファイルの管理方法

- **アプリケーションコード**: Git リポジトリでの管理
- **設定ファイル**: 環境変数と Dockerfile の管理
