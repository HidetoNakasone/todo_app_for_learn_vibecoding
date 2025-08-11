# Phase 3: 高度機能 (Week 5)

## 3.1 カテゴリ管理機能

### データベース拡張

- [ ] Category モデル追加 (schema.prisma)
  - [ ] 基本フィールド定義
    - [ ] id: String @id @default(cuid())
    - [ ] name: String (必須, 最大50文字)
    - [ ] color: String (必須, hex color #RRGGBB)
    - [ ] createdAt: DateTime @default(now())
    - [ ] updatedAt: DateTime @updatedAt
    - [ ] userId: String (外部キー to User)
  - [ ] リレーション定義
    - [ ] user: User @relation (userId参照)
    - [ ] tasks: Task[] (逆参照)

- [ ] Task モデルにカテゴリ関連フィールド追加
  - [ ] categoryId: String? (任意, 外部キー to Category)
  - [ ] category: Category? @relation (categoryId参照)

- [ ] User モデルにCategory リレーション追加
  - [ ] categories: Category[]

### マイグレーション・データ準備

- [ ] マイグレーション実行
  - [ ] `bun prisma migrate dev --name "add-category-model"`
  - [ ] PostgreSQL MCP でテーブル構造確認

- [ ] Prisma Client 再生成
  - [ ] `bun prisma generate` 実行

- [ ] カテゴリシードデータ追加
  - [ ] デフォルトカテゴリ (Work, Personal, Shopping, Health等)
  - [ ] 異なる色設定のサンプルデータ
  - [ ] 既存タスクにカテゴリ割り当て

### バリデーション・型定義

- [ ] Category関連型定義 (`src/app/_lib/types.ts`)
  - [ ] Category interface
  - [ ] CategoryCreateInput interface
  - [ ] CategoryUpdateInput interface

- [ ] Category バリデーション (`src/app/_lib/validations.ts`)
  - [ ] categoryCreateSchema
    - [ ] name: z.string().min(1).max(50)
    - [ ] color: z.string().regex(/^#[0-9A-Fa-f]{6}$/)
  - [ ] categoryUpdateSchema (partial)

- [ ] Task バリデーション拡張
  - [ ] taskCreateSchema に categoryId: z.string().cuid().optional() 追加
  - [ ] taskUpdateSchema 更新

### Categories API Routes

- [ ] GET /api/categories (カテゴリ一覧)
  - [ ] 認証チェック実装
  - [ ] ユーザー別カテゴリ取得
  - [ ] タスク数集計 (`_count.tasks`)
  - [ ] 作成日順ソート

- [ ] POST /api/categories (カテゴリ作成)
  - [ ] 認証チェック実装
  - [ ] リクエストバリデーション
  - [ ] 同名カテゴリ重複チェック (同ユーザー内)
  - [ ] Prisma でカテゴリ作成

- [ ] PUT /api/categories/[id] (カテゴリ更新)
  - [ ] 認証・オーナーシップチェック
  - [ ] リクエストバリデーション
  - [ ] 同名チェック (更新対象を除く)
  - [ ] Prisma でカテゴリ更新

- [ ] DELETE /api/categories/[id] (カテゴリ削除)
  - [ ] 認証・オーナーシップチェック
  - [ ] 関連タスクの確認・警告
  - [ ] カテゴリ削除 (tasksのcategoryIdはnullに設定)

### カテゴリUI実装

- [ ] CategoryBadge コンポーネント (`src/app/_components/CategoryBadge.tsx`)
  - [ ] カテゴリ名・色表示
  - [ ] サイズバリエーション (small, medium, large)
  - [ ] クリック可能オプション (フィルター用)

- [ ] CategoryForm コンポーネント (`src/app/_components/CategoryForm.tsx`)
  - [ ] 新規作成・編集フォーム
  - [ ] 色選択UI (カラーピッカーまたはプリセット)
  - [ ] リアルタイムプレビュー

- [ ] CategoryList コンポーネント (`src/app/_components/CategoryList.tsx`)
  - [ ] カテゴリ一覧表示
  - [ ] 編集・削除ボタン
  - [ ] 関連タスク数表示
  - [ ] 削除確認ダイアログ

- [ ] Categories 管理ページ (`src/app/categories/page.tsx`)
  - [ ] CategoryList コンポーネント使用
  - [ ] 新規作成ボタン・フォーム
  - [ ] モーダル or 別ページでの編集

### Task UI にカテゴリ機能統合

- [ ] TaskForm コンポーネント拡張
  - [ ] カテゴリ選択フィールド追加
  - [ ] カテゴリ未選択オプション

- [ ] TaskCard コンポーネント拡張
  - [ ] CategoryBadge 表示

- [ ] TaskList フィルター拡張
  - [ ] カテゴリ別フィルター追加
  - [ ] カテゴリ未設定タスクフィルター

### カスタムフック拡張

- [ ] Categories用フック (`src/app/_hooks/`)
  - [ ] useCategories() - カテゴリ一覧
  - [ ] useCreateCategory() - カテゴリ作成
  - [ ] useUpdateCategory(id) - カテゴリ更新
  - [ ] useDeleteCategory(id) - カテゴリ削除

## 3.2 検索機能

### バックエンド検索機能

- [ ] GET /api/tasks 検索機能追加
  - [ ] ?search=keyword パラメーター追加
  - [ ] タスク名での部分一致検索
  - [ ] 説明文での部分一致検索
  - [ ] OR条件での複合検索
  - [ ] 検索結果のハイライト情報

### 検索UI実装

- [ ] SearchBar コンポーネント (`src/app/_components/SearchBar.tsx`)
  - [ ] 検索入力フィールド
  - [ ] リアルタイム検索 (debounce処理)
  - [ ] searchParams との連携 (URL同期)
  - [ ] 検索履歴機能 (localStorage) (WANT)
  - [ ] 検索クリアボタン

- [ ] SearchResults コンポーネント (`src/app/_components/SearchResults.tsx`)
  - [ ] 検索結果表示
  - [ ] ヒット件数表示
  - [ ] 検索キーワードハイライト
  - [ ] 検索結果なしの場合の表示
  - [ ] Streaming対応 (Suspense + Server Component) (WANT)

### 検索機能の Next.js 最適化 (WANT)

- [ ] Server Component での検索処理
  - [ ] searchParams を Server Component で受け取り
  - [ ] 検索結果の段階的表示 (Suspense)
  - [ ] 検索キーワードでの静的最適化考慮

### 検索機能統合

- [ ] TaskList コンポーネント拡張
  - [ ] SearchBar 統合
  - [ ] 検索状態管理
  - [ ] 検索とフィルターの組み合わせ
  - [ ] URL パラメーター連携

- [ ] 検索用カスタムフック
  - [ ] useTaskSearch() - 検索状態管理
  - [ ] useSearchHistory() - 検索履歴管理

## 3.3 データエクスポート・インポート

### エクスポート機能

- [ ] Export API実装 (`src/app/api/tasks/export/route.ts`)
  - [ ] JSON エクスポート
    - [ ] ユーザーのタスク・カテゴリ一括取得
    - [ ] メタデータ付加 (exportDate, version等)
    - [ ] ファイル形式: .json
  - [ ] CSV エクスポート
    - [ ] タスクデータのCSV変換
    - [ ] カテゴリ名の展開
    - [ ] 日付フォーマット統一
    - [ ] ファイル形式: .csv

- [ ] ExportModal コンポーネント (`src/app/_components/ExportModal.tsx`)
  - [ ] エクスポート形式選択 (JSON/CSV)
  - [ ] フィルター条件指定 (全て/完了済み/未完了等)
  - [ ] ダウンロード実行
  - [ ] 進行状況表示

### インポート機能

- [ ] Import API実装 (`src/app/api/tasks/import/route.ts`)
  - [ ] ファイル形式検証 (JSON/CSV)
  - [ ] データバリデーション
  - [ ] 重複データ処理 (skip/overwrite)
  - [ ] カテゴリの自動作成・マッピング
  - [ ] インポート結果レポート

- [ ] ImportModal コンポーネント (`src/app/_components/ImportModal.tsx`)
  - [ ] ファイルアップロード (drag & drop対応)
  - [ ] プレビュー機能 (インポート前確認)
  - [ ] 重複処理オプション
  - [ ] インポート実行・結果表示

### データ管理ページ

- [ ] Data Management ページ (`src/app/data/page.tsx`)
  - [ ] エクスポート・インポート機能統合
  - [ ] データ統計表示 (総タスク数、カテゴリ数等)
  - [ ] データクリア機能 (確認付き)

## 3.4 認証プロバイダー追加 (必要に応じて)

### 追加OAuth プロバイダー検討

- [ ] Discord OAuth 追加 (オプション)
  - [ ] Discord Developer Portal設定
  - [ ] auth.config.ts にDiscordプロバイダー追加
  - [ ] 動作確認

- [ ] Twitter/X OAuth 追加 (オプション)
  - [ ] Twitter Developer Portal設定
  - [ ] auth.config.ts にTwitterプロバイダー追加
  - [ ] 動作確認

### プロバイダー管理UI

- [ ] Account Settings ページ (`src/app/account/page.tsx`)
  - [ ] 連携済みプロバイダー表示
  - [ ] アカウント連携・解除機能
  - [ ] プロフィール情報管理

## 3.5 パフォーマンス最適化

### データベース最適化

- [ ] インデックス追加確認
  - [ ] tasks.userId インデックス
  - [ ] tasks.categoryId インデックス
  - [ ] tasks.status インデックス
  - [ ] tasks.dueDate インデックス
  - [ ] categories.userId インデックス

- [ ] クエリ最適化
  - [ ] N+1問題の解決 (include/select最適化)
  - [ ] 不要なデータ取得の削減
  - [ ] ページネーション準備

### フロントエンド最適化

- [ ] Client Component最適化
  - [ ] React.memo() 適用
  - [ ] useMemo, useCallback 最適化
  - [ ] 不要な re-render 防止

- [ ] ローディング・エラー状態改善
  - [ ] Skeleton UI 実装
  - [ ] Error Boundary 実装 (error.tsx)
  - [ ] Loading状態の統一 (loading.tsx)

### Next.js App Router 最適化 (WANT)

- [ ] Server/Client Components の適切な分離
  - [ ] データ取得は Server Component
  - [ ] インタラクションは Client Component
  - [ ] "use client" の最小化

- [ ] 基本的なキャッシング活用
  - [ ] `revalidatePath()` での適切なキャッシュ無効化
  - [ ] Static vs Dynamic の適切な分離

## 3.6 テスト・品質保証

### API テスト拡張

- [ ] Categories API テスト
  - [ ] CRUD操作テスト
  - [ ] バリデーションテスト
  - [ ] 権限チェックテスト

- [ ] 検索機能テスト
  - [ ] 部分一致検索テスト
  - [ ] 特殊文字・日本語検索テスト

### E2E テスト拡張

- [ ] カテゴリ管理フローテスト
- [ ] 検索機能テスト
- [ ] エクスポート・インポートテスト

### 性能テスト

- [ ] 大量データでのパフォーマンス確認
- [ ] 検索機能のレスポンス時間測定

## 3.7 Phase 3 完了チェック

### 機能動作確認

- [ ] カテゴリCRUD・タスクとの連携が正常動作
- [ ] 検索機能が正常動作 (日本語・英語対応)
- [ ] エクスポート・インポート機能が正常動作
- [ ] パフォーマンス要件を満たす (1秒以内レスポンス)

### コード品質確認

- [ ] ESLint エラーなし (`bun run lint`)
- [ ] TypeScript エラーなし (`bunx tsc --noEmit`)
- [ ] テストカバレッジ基準を満たす

---

**Phase 3 完了条件**: カテゴリ管理、検索、データ管理機能が追加され、個人TODO機能として完成した状態になること。
