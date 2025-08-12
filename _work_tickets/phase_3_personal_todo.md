# Phase 3: 個人TODO機能 (Week 3-4)

## 3.1 データベース基盤構築

### Prisma スキーマ拡張

- [ ] Task モデル追加 (schema.prisma)
  - [ ] 基本フィールド定義
    - [ ] id: String @id @default(cuid())
    - [ ] name: String (必須, 最大100文字)
    - [ ] description: String? (任意, 最大500文字)
    - [ ] createdAt: DateTime @default(now())
    - [ ] updatedAt: DateTime @updatedAt
    - [ ] userId: String (外部キー to User)
  - [ ] ステータス・優先度フィールド
    - [ ] status: TaskStatus @default(TODO)
    - [ ] priority: TaskPriority @default(MEDIUM)
    - [ ] dueDate: DateTime? (任意)
  - [ ] リレーション定義
    - [ ] user: User @relation (userId参照)

- [ ] TaskStatus enum 定義
  - [ ] TODO
  - [ ] IN_PROGRESS
  - [ ] COMPLETED

- [ ] TaskPriority enum 定義
  - [ ] HIGH
  - [ ] MEDIUM
  - [ ] LOW

- [ ] User モデルに Task リレーション追加
  - [ ] tasks: Task[]

### データベースマイグレーション

- [ ] マイグレーション実行
  - [ ] `bun prisma migrate dev --name "add-task-model"`
  - [ ] マイグレーションファイル確認
  - [ ] PostgreSQL MCP でテーブル構造確認

- [ ] Prisma Client 再生成
  - [ ] `bun prisma generate` 実行
  - [ ] TypeScript型定義確認

### 開発用データ準備

- [ ] シードデータ作成 (prisma/seed.ts)
  - [ ] サンプルタスク作成関数
  - [ ] 各ステータスのサンプルデータ (各5個程度)
  - [ ] 各優先度のサンプルデータ
  - [ ] 期限あり・なしのデータ

- [ ] シードデータ投入
  - [ ] `bun prisma db seed` 実行
  - [ ] Prisma Studio でデータ確認

## 3.2 バリデーション・型定義基盤

### TypeScript 型定義

- [ ] Task関連型定義 (`src/app/_lib/types.ts`)
  - [ ] TaskStatus、TaskPriority type
  - [ ] Task interface (Prisma型ベース)
  - [ ] TaskCreateInput interface
  - [ ] TaskUpdateInput interface
  - [ ] TaskFilters interface

### Zod バリデーションスキーマ

- [ ] Task バリデーション (`src/app/_lib/validations.ts`)
  - [ ] taskCreateSchema
    - [ ] name: z.string().min(1).max(100)
    - [ ] description: z.string().max(500).optional()
    - [ ] priority: z.enum(["HIGH", "MEDIUM", "LOW"])
    - [ ] status: z.enum(["TODO", "IN_PROGRESS", "COMPLETED"])
    - [ ] dueDate: z.date().optional()
  - [ ] taskUpdateSchema (partial)
  - [ ] taskQuerySchema (フィルター用)

## 3.3 API実装 (バックエンド)

### Tasks API Routes

- [ ] GET /api/tasks (タスク一覧)
  - [ ] 認証チェック実装
  - [ ] ユーザー別データ取得
  - [ ] クエリパラメーター処理 (status, priority filter)
  - [ ] ソート機能 (createdAt, dueDate, priority)
  - [ ] エラーハンドリング
  - [ ] レスポンス形式統一

- [ ] POST /api/tasks (タスク作成)
  - [ ] 認証チェック実装
  - [ ] リクエストボディバリデーション
  - [ ] Prisma でタスク作成
  - [ ] 作成後のレスポンス返却
  - [ ] エラーハンドリング

- [ ] GET /api/tasks/[id] (特定タスク取得)
  - [ ] 認証チェック実装
  - [ ] タスク存在確認
  - [ ] オーナーシップ確認 (自分のタスクのみ)
  - [ ] エラーハンドリング (404, 403)

- [ ] PUT /api/tasks/[id] (タスク更新)
  - [ ] 認証チェック実装
  - [ ] タスク存在・オーナーシップ確認
  - [ ] リクエストボディバリデーション (partial)
  - [ ] Prisma でタスク更新
  - [ ] 更新後のレスポンス返却
  - [ ] エラーハンドリング

- [ ] DELETE /api/tasks/[id] (タスク削除)
  - [ ] 認証チェック実装
  - [ ] タスク存在・オーナーシップ確認
  - [ ] Prisma でタスク削除
  - [ ] 削除成功レスポンス
  - [ ] エラーハンドリング

### API 共通機能

- [ ] 認証ヘルパー関数 (`src/app/_lib/auth.ts`)
  - [ ] getCurrentUser(): Promise<User | null>
  - [ ] requireAuth(): Promise<User> (認証必須)

- [ ] エラーレスポンスヘルパー (`src/app/_lib/api-utils.ts`)
  - [ ] createErrorResponse(message, status)
  - [ ] handlePrismaError(error)
  - [ ] handleValidationError(zodError)

### 詳細エラーハンドリング実装

- [ ] 認証エラー処理
  - [ ] セッション期限切れ自動ログアウト機能
  - [ ] 権限不足時の403エラーと明確なメッセージ
  - [ ] OAuth認証失敗時の間接的エラー表示

- [ ] バリデーションエラー処理
  - [ ] リアルタイムバリデーション (フォーム入力時)
  - [ ] Zodスキーマベースの統一エラーメッセージ
  - [ ] フィールドレベルエラー表示と改善方法提示

- [ ] システムエラー処理
  - [ ] データベース接続エラー処理とログ記録
  - [ ] API統一エラーレスポンス形式
  - [ ] Error Boundary実装とフォールバックUI

- [ ] ネットワークエラー処理
  - [ ] オフライン状態検知と表示
  - [ ] 自動リトライ機能 (指数バックオフ)
  - [ ] 再接続時のデータ同期機能

### Server Actions 実装 (推奨)

- [ ] Task操作 Server Actions (`src/app/_lib/actions/task-actions.ts`)
  - [ ] createTaskAction(formData: FormData)
  - [ ] updateTaskAction(id: string, formData: FormData)
  - [ ] deleteTaskAction(id: string)
  - [ ] toggleTaskStatusAction(id: string, status: TaskStatus)
  - [ ] `revalidatePath("/tasks")` でキャッシュ無効化

- [ ] Server Actions バリデーション
  - [ ] formData からの型安全なデータ抽出
  - [ ] Zodスキーマでのサーバーサイドバリデーション
  - [ ] エラーハンドリング（try-catch + redirect）

## 3.4 Modern Frontend Components (TanStack Query + Zustand + shadcn/ui)

### 基本UI コンポーネント (shadcn/ui + Tailwind CSS v4 ベース)

- [ ] TaskCard コンポーネント (`src/app/_components/TaskCard.tsx`)
  - [ ] shadcn/ui Card, Badge, Button, DropdownMenu使用
  - [ ] **TanStack Query Integration**: `useUpdateTask()`, `useDeleteTask()`
  - [ ] **Optimistic Updates**: 即座のUI更新 + rollback
  - [ ] タスク情報表示 (name, description, status, priority, dueDate)
  - [ ] ステータスバッジ表示 (Badge + OKLCH色空間)
  - [ ] **Zustand Integration**: `openModal('editTask', taskId)`, `openModal('deleteTask', taskId)`
  - [ ] 編集・削除ボタン (DropdownMenu + Button)
  - [ ] ステータス変更機能 (楽観的更新パターン)

- [ ] TaskForm コンポーネント (`src/app/_components/TaskForm.tsx`)
  - [ ] shadcn/ui Form, Input, Textarea, Select, Button使用
  - [ ] **TanStack Query Integration**: `useCreateTask()`, `useUpdateTask(id)`
  - [ ] **Form State Management**: `useFormStore()` for draft functionality
  - [ ] Zod + React Hook Form + shadcn/ui Form統合パターン
  - [ ] 新規作成・編集フォーム (zodResolver使用)
  - [ ] フィールドバリデーション (FormField, FormMessage)
  - [ ] **Mutation Integration**: 楽観的更新 + エラーハンドリング
  - [ ] **Auto-save Draft**: `setTaskFormDraft()` with debouncing
  - [ ] **Toast Notifications**: Success/Error feedback

- [ ] TaskList コンポーネント (`src/app/_components/TaskList.tsx`)
  - [ ] shadcn/ui Card, Separator, Alert, Skeleton使用
  - [ ] **TanStack Query Integration**: `useTasks(filters)` with real-time updates
  - [ ] **Filter State Integration**: `useFilterStore()` for filter/sort state
  - [ ] タスク一覧表示 (TaskCardコンポーネント活用)
  - [ ] **Dynamic Filtering**: Real-time filter/sort with automatic re-fetch
  - [ ] **Loading States**: `isLoading`, `isFetching`, `isRefetching` handling
  - [ ] **Error Boundaries**: Query error handling with retry options
  - [ ] **Empty State**: Alert + イラスト with filtered results message
  - [ ] **Skeleton Loading**: Progressive loading with realistic placeholders

### ページ実装

- [ ] Tasks 一覧ページ (`src/app/tasks/page.tsx`)
  - [ ] Server Component でのデータ取得（Prisma直接呼び出し）
  - [ ] `searchParams` での フィルター・ソート対応
  - [ ] TaskList コンポーネント使用
  - [ ] 新規作成ボタン
  - [ ] loading.tsx, error.tsx 実装
  - [ ] ページネーション（将来拡張用）

- [ ] Tasks ローディング・エラー UI
  - [ ] `src/app/tasks/loading.tsx` (shadcn/ui Skeleton使用)
  - [ ] `src/app/tasks/error.tsx` (shadcn/ui Alert + Button使用)
  - [ ] Suspense境界での段階的表示 (WANT)

- [ ] **モーダルベースのフォーム** (専用ページの代替)
  - [ ] **タスク作成モーダル**: `useUIStore()` + `modals.createTask`
  - [ ] **タスク編集モーダル**: `useUIStore()` + `modals.editTask`
  - [ ] **削除確認モーダル**: `useUIStore()` + `modals.deleteTask`
  - [ ] **TaskForm統合**: モーダルラッパー + フォーム状態
  - [ ] **楽観的更新**: 即座のUI フィードバック

- [ ] Task 詳細ページ (`src/app/tasks/[id]/page.tsx`) - オプション
  - [ ] **サーバーコンポーネント**: 初期データ取得
  - [ ] **TanStack Query ハイドレーション**: `useTask(id)` + プリフェッチデータ
  - [ ] **リアルタイム更新**: バックグラウンド同期
  - [ ] **アクションボタン**: 編集・削除のモーダル統合
  - [ ] **パンくずリスト**: `useRouter()` でのナビゲーション

### モダン状態管理統合 (TanStack Query + Zustand)

**前提条件**: Phase 2c (Modern State Management Setup) 完了

- [ ] タスク Query/Mutation フック (`src/queries/tasks-queries.ts` - Phase 2c で作成済み)
  - [ ] `useTasks(filters)` - 自動キャッシング・背景同期付きタスク一覧
  - [ ] `useTask(id)` - 個別タスク取得・リアルタイム更新
  - [ ] `useCreateTask()` - 楽観的更新付きタスク作成
  - [ ] `useUpdateTask(id)` - 楽観的更新付きタスク編集
  - [ ] `useDeleteTask()` - 楽観的更新付きタスク削除

- [ ] クライアント状態管理 (`src/stores/` - Phase 2c で作成済み)
  - [ ] `useUIStore()` - モーダル状態、テーマ、サイドバー
  - [ ] `useFilterStore()` - フィルター、ソート、検索状態
  - [ ] `useFormStore()` - 一時的なフォームデータ、ドラフト機能

- [ ] 統合パターン実装
  - [ ] サーバー状態 (TanStack Query) + クライアント状態 (Zustand) 連携
  - [ ] URL同期フィルター (`useRouter` + `useFilterStore`)
  - [ ] 楽観的更新エラーハンドリング
  - [ ] バックグラウンド同期 + Toast通知

## 3.5 フィルタリング・ソート機能

### バックエンド拡張

- [ ] GET /api/tasks クエリパラメーター拡張
  - [ ] ?status=TODO|IN_PROGRESS|COMPLETED
  - [ ] ?priority=HIGH|MEDIUM|LOW
  - [ ] ?sortBy=createdAt|dueDate|priority|name
  - [ ] ?sortOrder=asc|desc
  - [ ] 複数条件の組み合わせ対応

### モダンフィルターUI と状態統合

- [ ] FilterBar コンポーネント (`src/app/_components/FilterBar.tsx`)
  - [ ] shadcn/ui Tabs, Checkbox, Select, Button使用
  - [ ] **Zustand統合**: `useFilterStore()` でフィルター状態管理
  - [ ] ステータスフィルター (Tabs + `setTaskFilter('status', value)`)
  - [ ] 優先度フィルター (Checkbox + `setTaskFilter('priority', value)`)
  - [ ] ソート選択 (Select + `setTaskFilter('sortBy', value)`)
  - [ ] フィルター初期化 (`resetTaskFilters()`)

- [ ] TaskList コンポーネント TanStack Query 統合
  - [ ] **サーバー状態**: `useTasks(filterStore.getTaskFiltersAsParams())`
  - [ ] **クライアント状態**: `useFilterStore()` でUI状態管理
  - [ ] **URL同期**: `useSearchParams()` + `useFilterStore()`
  - [ ] **ローディング状態**: `isLoading`, `isFetching` 表示
  - [ ] **エラー境界**: Query エラーハンドリング

## 3.6 テスト実装

### API テスト

- [ ] Tasks API エンドポイント テスト
  - [ ] 認証が必要なエンドポイントの認証チェック
  - [ ] 正常系: CRUD操作の動作確認
  - [ ] 異常系: バリデーションエラー、権限エラー
  - [ ] エッジケース: 存在しないID、他ユーザーのタスクアクセス

### フロントエンド テスト

- [ ] コンポーネント単体テスト
  - [ ] TaskCard 表示・操作テスト
  - [ ] TaskForm バリデーション・送信テスト
  - [ ] TaskList フィルター・ソートテスト

### 統合テスト

- [ ] E2E テスト シナリオ
  - [ ] ログイン → タスク作成 → 一覧確認
  - [ ] タスク編集・削除フロー
  - [ ] フィルター・ソート操作

## 3.7 Phase 3 完了チェック

### 機能動作確認

- [ ] タスクCRUD操作が正常動作する
- [ ] ユーザー別データ分離ができている
- [ ] フィルタリング・ソート機能が動作する
- [ ] エラーハンドリングが適切に機能する

### コード品質確認

- [ ] ESLint エラーなし (`bun run lint`)
- [ ] TypeScript エラーなし (`bunx tsc --noEmit`)
- [ ] Prettier 整形済み (`bun prettier --check .`)

### 性能・UX確認

- [ ] ページ読み込み時間が3秒以内
- [ ] API レスポンス時間が1秒以内
- [ ] モバイル表示が適切
- [ ] アクセシビリティ基本要件を満たす

### パフォーマンステスト

- [ ] 負荷テスト実施
  - [ ] 単一ユーザーでの100タスク作成・表示テスト
  - [ ] フィルタリング・ソート性能テスト (1000タスク規模)
  - [ ] TanStack Query キャッシング効果測定
  - [ ] API レスポンス時間測定 (平均1秒以内確認)
- [ ] フロントエンドパフォーマンス
  - [ ] LCP (Largest Contentful Paint) 3秒以内確認
  - [ ] FID (First Input Delay) 100ms以内確認
  - [ ] CLS (Cumulative Layout Shift) 0.1以下確認

### アクセシビリティテスト (WCAG 2.1 AA準拠)

- [ ] キーボードナビゲーション
  - [ ] Tab順序の論理的な流れ確認
  - [ ] 全機能のキーボード操作確認 (マウス不使用)
  - [ ] フォーカス表示の視認性確認
  - [ ] Escキーでのモーダル・メニュー閉じる動作

- [ ] スクリーンリーダー対応
  - [ ] aria-label属性の適切な設定
  - [ ] 見出し構造 (h1-h6) の論理的階層
  - [ ] ランドマークロール設定 (main, nav, aside等)
  - [ ] フォームラベルとinput要素の適切な関連付け

- [ ] 色・コントラスト
  - [ ] 4.5:1以上のコントラスト比確認
  - [ ] 色のみに依存しない情報伝達
  - [ ] カラーブラインドネスへの配慮確認

- [ ] レスポンシブアクセシビリティ
  - [ ] 200%拡大時のレイアウト崩れ確認
  - [ ] モバイル環境での最小タッチターゲット (44px)

---

**Phase 3 完了条件**: 認証済みユーザーが個人のタスクを作成・編集・削除・フィルタリングできる状態が整うこと。Tailwind CSS v4の@themeディレクティブとOKLCH色空間を活用したモダンUIが実装されていること。
