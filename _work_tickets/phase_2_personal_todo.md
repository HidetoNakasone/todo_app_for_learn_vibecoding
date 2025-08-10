# Phase 2: 個人TODO機能 (Week 3-4)

## 2.1 データベース基盤構築

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

## 2.2 バリデーション・型定義基盤

### TypeScript 型定義

- [ ] Task関連型定義 (src/app/_lib/types.ts)
  - [ ] TaskStatus、TaskPriority type
  - [ ] Task interface (Prisma型ベース)
  - [ ] TaskCreateInput interface  
  - [ ] TaskUpdateInput interface
  - [ ] TaskFilters interface

### Zod バリデーションスキーマ

- [ ] Task バリデーション (src/app/_lib/validations.ts)
  - [ ] taskCreateSchema
    - [ ] name: z.string().min(1).max(100)
    - [ ] description: z.string().max(500).optional()
    - [ ] priority: z.enum(["HIGH", "MEDIUM", "LOW"])
    - [ ] status: z.enum(["TODO", "IN_PROGRESS", "COMPLETED"])  
    - [ ] dueDate: z.date().optional()
  - [ ] taskUpdateSchema (partial)
  - [ ] taskQuerySchema (フィルター用)

## 2.3 API実装 (バックエンド)

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

- [ ] 認証ヘルパー関数 (src/app/_lib/auth.ts)
  - [ ] getCurrentUser(): Promise<User | null>
  - [ ] requireAuth(): Promise<User> (認証必須)

- [ ] エラーレスポンスヘルパー (src/app/_lib/api-utils.ts)
  - [ ] createErrorResponse(message, status)
  - [ ] handlePrismaError(error)
  - [ ] handleValidationError(zodError)

### Server Actions 実装 (推奨)

- [ ] Task操作 Server Actions (src/app/_lib/actions/task-actions.ts)
  - [ ] createTaskAction(formData: FormData)
  - [ ] updateTaskAction(id: string, formData: FormData)
  - [ ] deleteTaskAction(id: string)
  - [ ] toggleTaskStatusAction(id: string, status: TaskStatus)
  - [ ] `revalidatePath("/tasks")` でキャッシュ無効化

- [ ] Server Actions バリデーション
  - [ ] formData からの型安全なデータ抽出
  - [ ] Zodスキーマでのサーバーサイドバリデーション
  - [ ] エラーハンドリング（try-catch + redirect）

## 2.4 フロントエンド - コンポーネント実装

### 基本UI コンポーネント

- [ ] TaskCard コンポーネント (src/app/_components/TaskCard.tsx)
  - [ ] タスク情報表示 (name, description, status, priority, dueDate)
  - [ ] ステータスバッジ表示
  - [ ] 優先度カラー表示
  - [ ] 編集・削除ボタン
  - [ ] ステータス変更機能

- [ ] TaskForm コンポーネント (src/app/_components/TaskForm.tsx)
  - [ ] 新規作成用フォーム
  - [ ] 編集用フォーム (プリフィル機能)
  - [ ] フィールドバリデーション (Zod + react-hook-form)
  - [ ] Server Actions との連携 (action属性使用)
  - [ ] `useFormState` フックでの状態管理 (WANT)
  - [ ] `useFormStatus` フックでのローディング状態表示 (WANT)
  - [ ] 楽観的更新 `useOptimistic` 実装 (WANT)

- [ ] TaskList コンポーネント (src/app/_components/TaskList.tsx)
  - [ ] タスク一覧表示
  - [ ] ソート機能 (ドロップダウン)
  - [ ] フィルタリング機能 (status, priority)
  - [ ] 空状態の表示
  - [ ] ローディング状態表示

### ページ実装

- [ ] Tasks 一覧ページ (src/app/tasks/page.tsx)
  - [ ] Server Component でのデータ取得（Prisma直接呼び出し）
  - [ ] `searchParams` での フィルター・ソート対応
  - [ ] TaskList コンポーネント使用
  - [ ] 新規作成ボタン
  - [ ] loading.tsx, error.tsx 実装
  - [ ] ページネーション（将来拡張用）

- [ ] Tasks ローディング・エラー UI
  - [ ] src/app/tasks/loading.tsx (Skeleton UI)
  - [ ] src/app/tasks/error.tsx (Error Boundary)
  - [ ] Suspense境界での段階的表示 (WANT)

- [ ] Task 新規作成ページ (src/app/tasks/new/page.tsx)
  - [ ] TaskForm コンポーネント使用
  - [ ] 作成成功時のリダイレクト
  - [ ] キャンセル機能

- [ ] Task 編集ページ (src/app/tasks/[id]/edit/page.tsx)
  - [ ] 既存タスクデータ取得
  - [ ] TaskForm コンポーネント使用 (編集モード)
  - [ ] 更新成功時の処理
  - [ ] 404エラー処理

- [ ] Task 詳細ページ (src/app/tasks/[id]/page.tsx)
  - [ ] タスク詳細表示
  - [ ] 編集・削除リンク
  - [ ] ステータス変更機能

### フロントエンド状態管理・API連携

- [ ] カスタムフック実装 (src/app/_hooks/)
  - [ ] useTasks() - タスク一覧取得・更新
  - [ ] useTask(id) - 特定タスク取得
  - [ ] useCreateTask() - タスク作成
  - [ ] useUpdateTask(id) - タスク更新  
  - [ ] useDeleteTask(id) - タスク削除

## 2.5 フィルタリング・ソート機能

### バックエンド拡張

- [ ] GET /api/tasks クエリパラメーター拡張
  - [ ] ?status=TODO|IN_PROGRESS|COMPLETED
  - [ ] ?priority=HIGH|MEDIUM|LOW  
  - [ ] ?sortBy=createdAt|dueDate|priority|name
  - [ ] ?sortOrder=asc|desc
  - [ ] 複数条件の組み合わせ対応

### フロントエンド UI

- [ ] FilterBar コンポーネント (src/app/_components/FilterBar.tsx)
  - [ ] ステータスフィルター (ラジオボタン/タブ)
  - [ ] 優先度フィルター (チェックボックス)
  - [ ] ソート選択 (ドロップダウン)
  - [ ] フィルター初期化ボタン

- [ ] TaskList コンポーネント拡張
  - [ ] FilterBar 統合
  - [ ] フィルター状態管理
  - [ ] URL パラメーター連携

## 2.6 テスト実装

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

## 2.7 Phase 2 完了チェック

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

---

**Phase 2 完了条件**: 認証済みユーザーが個人のタスクを作成・編集・削除・フィルタリングできる状態が整うこと。