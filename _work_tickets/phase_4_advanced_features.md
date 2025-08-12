# Phase 4: 高度機能 (Week 5)

## 4.1 カテゴリ管理機能

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

### モダン状態管理統合 (TanStack Query + Zustand)

**前提条件**: Phase 2c (Modern State Management Setup) 完了

- [ ] Categories Query/Mutation フック (`src/queries/categories-queries.ts`)
  - [ ] `useCategories()` - 自動キャッシング・背景同期付きカテゴリ一覧
  - [ ] `useCreateCategory()` - 楽観的更新付きカテゴリ作成
  - [ ] `useUpdateCategory(id)` - 楽観的更新付きカテゴリ更新
  - [ ] `useDeleteCategory()` - 楽観的更新付きカテゴリ削除

- [ ] カテゴリ関連クライアント状態拡張 (`src/stores/`)
  - [ ] `useUIStore()` - カテゴリモーダル状態管理
  - [ ] `useFilterStore()` - カテゴリフィルター状態拡張
  - [ ] `useFormStore()` - カテゴリフォームドラフト機能

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

- [ ] 検索用モダン状態管理統合
  - [ ] **TanStack Query**: `useTasks({ search: query })` で検索結果キャッシング
  - [ ] **Zustand拡張**: `useFilterStore()` に検索状態追加
    - [ ] `searchQuery: string`
    - [ ] `setSearchQuery: (query: string) => void`
    - [ ] `searchHistory: string[]` (localStorage連携)
  - [ ] **Debounced Query**: 検索入力の最適化

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
  - [ ] **フィルター状態連携**: `useFilterStore()` でエクスポート条件指定
  - [ ] **TanStack Mutation**: `useExportTasks()` で楽観的UI更新
  - [ ] ダウンロード実行
  - [ ] **UI状態管理**: `useUIStore()` でモーダル・ローディング状態

### インポート機能

- [ ] Import API実装 (`src/app/api/tasks/import/route.ts`)
  - [ ] ファイル形式検証 (JSON/CSV)
  - [ ] データバリデーション
  - [ ] 重複データ処理 (skip/overwrite)
  - [ ] カテゴリの自動作成・マッピング
  - [ ] インポート結果レポート

- [ ] ImportModal コンポーネント (`src/app/_components/ImportModal.tsx`)
  - [ ] ファイルアップロード (drag & drop対応)
  - [ ] **Form状態管理**: `useFormStore()` でアップロード状態管理
  - [ ] プレビュー機能 (インポート前確認)
  - [ ] **TanStack Mutation**: `useImportTasks()` で楽観的更新
  - [ ] 重複処理オプション
  - [ ] インポート実行・結果表示
  - [ ] **キャッシュ無効化**: インポート後の自動データ更新

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

### モダンフロントエンド最適化 (TanStack Query + Zustand)

- [ ] **TanStack Query最適化**
  - [ ] **Selective re-rendering**: `select` オプションでデータ変換
  - [ ] **Background updates**: `staleTime`, `cacheTime` 最適化
  - [ ] **Query invalidation**: 効率的なキャッシュ無効化

- [ ] **Zustand最適化**
  - [ ] **Shallow equality**: 不要な再レンダリング防止
  - [ ] **Store slicing**: 大きなストアの分割
  - [ ] **Selective subscriptions**: 必要な状態のみ購読

- [ ] ローディング・エラー状態の統一化
  - [ ] **TanStack Query states**: `isLoading`, `isFetching`, `isError`
  - [ ] **UI Store integration**: グローバルローディング状態
  - [ ] Skeleton UI 実装 (shadcn/ui Skeleton)

### Next.js App Router 最適化 (WANT)

- [ ] Server/Client Components の適切な分離
  - [ ] データ取得は Server Component
  - [ ] インタラクションは Client Component
  - [ ] "use client" の最小化

- [ ] **TanStack Query + Next.js 統合キャッシング**
  - [ ] **Server Component**: 初期データプリフェッチ
  - [ ] **TanStack Query**: クライアントサイドキャッシング
  - [ ] **Hybrid approach**: SSR初期データ + CSRリアルタイム更新
  - [ ] `revalidatePath()` との協調動作

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

### 高度機能エラーハンドリング

- [ ] 検索機能エラー処理
  - [ ] 検索結果なし時の適切なメッセージ表示
  - [ ] 検索クエリ不正時のバリデーションエラー
  - [ ] 検索タイムアウト時のフォールバック

- [ ] エクスポート・インポートエラー処理
  - [ ] ファイルサイズ制限エラー (10MB上限)
  - [ ] 不正ファイル形式エラーとサポート形式表示
  - [ ] インポートデータバリデーションエラー詳細
  - [ ] 部分インポート失敗時の成功・失敗レポート
  - [ ] ネットワークエラー時のファイル破損防止

- [ ] カテゴリ機能エラー処理
  - [ ] 同名カテゴリ作成エラーと代替案提示
  - [ ] 使用中カテゴリ削除時の警告と移行オプション
  - [ ] 色選択競合時の自動調整機能

### 性能テスト

- [ ] 大量データでのパフォーマンス確認
- [ ] 検索機能のレスポンス時間測定

### パフォーマンス詳細テスト

- [ ] 検索パフォーマンステスト
  - [ ] 1000タスク規模での部分一致検索 (500ms以内)
  - [ ] リアルタイム検索の debounce 効果測定
  - [ ] 日本語・英語・特殊文字での検索性能確認

- [ ] エクスポート・インポート性能
  - [ ] 1000タスクのJSONエクスポート (10秒以内)
  - [ ] 1000タスクのCSVエクスポート (10秒以内)
  - [ ] 大量データインポート時のバリデーション性能
- [ ] カテゴリ管理性能
  - [ ] 50カテゴリでのフィルタリング性能
  - [ ] カテゴリ一覧表示性能 (タスク数計算含む)

### アクセシビリティテスト追加 (Phase 4機能)

- [ ] 検索機能のアクセシビリティ
  - [ ] 検索結果のライブリージョン通知
  - [ ] 検索フィールドのaria-describedby設定
  - [ ] 検索結果ナビゲーションのキーボード操作
  - [ ] 検索候補選択の矢印キー操作

- [ ] カテゴリ管理のアクセシビリティ
  - [ ] 色選択UIのキーボード・スクリーンリーダー対応
  - [ ] カテゴリバッジの色情報テキスト併記
  - [ ] カテゴリ削除時の確認ダイアログアクセシビリティ

- [ ] エクスポート・インポートのアクセシビリティ
  - [ ] ファイルドラッグ&ドロップの代替手段
  - [ ] 進行状況の視覚・音声両対応
  - [ ] エラー・成功メッセージのスクリーンリーダー通知

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
