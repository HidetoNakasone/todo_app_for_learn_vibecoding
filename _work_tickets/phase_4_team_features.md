# Phase 4: チーム機能 (Week 6-8)

## 4.1 チーム管理基盤

### データベース拡張

- [ ] Team モデル追加 (schema.prisma)
  - [ ] 基本フィールド
    - [ ] id: String @id @default(cuid())
    - [ ] name: String (必須, 最大100文字)
    - [ ] description: String? (任意, 最大500文字)
    - [ ] createdAt: DateTime @default(now())
    - [ ] updatedAt: DateTime @updatedAt
    - [ ] ownerId: String (外部キー to User)
  - [ ] リレーション定義
    - [ ] owner: User @relation (ownerId参照)
    - [ ] members: TeamMember[]
    - [ ] tasks: Task[]
    - [ ] categories: Category[]

- [ ] TeamMember モデル追加
  - [ ] 基本フィールド
    - [ ] id: String @id @default(cuid())
    - [ ] teamId: String
    - [ ] userId: String
    - [ ] role: TeamRole @default(MEMBER)
    - [ ] joinedAt: DateTime @default(now())
  - [ ] 複合ユニークキー
    - [ ] @@unique([teamId, userId])
  - [ ] リレーション定義
    - [ ] team: Team @relation (teamId参照)
    - [ ] user: User @relation (userId参照)

- [ ] TeamRole enum 定義
  - [ ] OWNER (チーム削除、権限変更)
  - [ ] ADMIN (メンバー管理、設定変更)
  - [ ] MEMBER (タスク作成・編集)

- [ ] TeamInvitation モデル追加
  - [ ] 基本フィールド
    - [ ] id: String @id @default(cuid())
    - [ ] teamId: String
    - [ ] email: String
    - [ ] role: TeamRole @default(MEMBER)
    - [ ] token: String @unique
    - [ ] expiresAt: DateTime
    - [ ] createdAt: DateTime @default(now())
    - [ ] invitedBy: String (User ID)

### 既存モデル拡張

- [ ] Task モデルチーム機能拡張
  - [ ] teamId: String? (任意, チームタスクの場合)
  - [ ] assigneeId: String? (任意, 担当者)
  - [ ] isTeamTask: Boolean @default(false)
  - [ ] リレーション追加
    - [ ] team: Team? @relation (teamId参照)
    - [ ] assignee: User? @relation (assigneeId参照)

- [ ] Category モデルチーム機能拡張
  - [ ] teamId: String? (任意, チームカテゴリの場合)
  - [ ] isTeamCategory: Boolean @default(false)
  - [ ] リレーション追加
    - [ ] team: Team? @relation (teamId参照)

- [ ] User モデルにチーム関連リレーション追加
  - [ ] ownedTeams: Team[]
  - [ ] teamMemberships: TeamMember[]
  - [ ] assignedTasks: Task[] (assigneeIdから逆参照)

### マイグレーション・初期データ

- [ ] マイグレーション実行
  - [ ] `bun prisma migrate dev --name "add-team-features"`
  - [ ] PostgreSQL MCP でテーブル構造確認

- [ ] Prisma Client 再生成
  - [ ] `bun prisma generate` 実行

- [ ] チーム機能シードデータ
  - [ ] サンプルチーム作成
  - [ ] チームメンバー関係
  - [ ] チームタスク・カテゴリ

## 4.2 チーム管理API実装

### Teams API Routes

- [ ] GET /api/teams (チーム一覧)
  - [ ] 認証チェック実装
  - [ ] 参加チーム一覧取得 (オーナー・メンバー含む)
  - [ ] ロール・メンバー数情報付与

- [ ] POST /api/teams (チーム作成)
  - [ ] 認証チェック実装
  - [ ] リクエストバリデーション
  - [ ] チーム作成・オーナー設定
  - [ ] 作成数制限チェック (1ユーザー5チームまで)

- [ ] GET /api/teams/[id] (特定チーム詳細)
  - [ ] 認証・メンバーシップチェック
  - [ ] チーム情報・メンバー一覧取得
  - [ ] 権限に応じた情報表示

- [ ] PUT /api/teams/[id] (チーム更新)
  - [ ] 認証・権限チェック (OWNER/ADMIN)
  - [ ] リクエストバリデーション
  - [ ] チーム情報更新

- [ ] DELETE /api/teams/[id] (チーム削除)
  - [ ] 認証・権限チェック (OWNERのみ)
  - [ ] 関連データ削除確認
  - [ ] カスケード削除実行

### Team Members API Routes

- [ ] GET /api/teams/[id]/members (メンバー一覧)
  - [ ] 認証・メンバーシップチェック
  - [ ] メンバー一覧・ロール情報取得

- [ ] POST /api/teams/[id]/members (メンバー招待)
  - [ ] 認証・権限チェック (OWNER/ADMIN)
  - [ ] 招待メール・トークン生成
  - [ ] 招待メール送信 (将来実装)
  - [ ] 招待リンク生成

- [ ] PUT /api/teams/[id]/members/[userId] (ロール変更)
  - [ ] 認証・権限チェック (OWNERのみ)
  - [ ] ロール変更実行
  - [ ] オーナー権限譲渡処理

- [ ] DELETE /api/teams/[id]/members/[userId] (メンバー削除)
  - [ ] 認証・権限チェック
  - [ ] 自分の退退またはADMIN/OWNERによる除名
  - [ ] 関連データ処理 (担当タスクの処理)

### Team Invitations API Routes

- [ ] POST /api/invitations/accept/[token] (招待承認)
  - [ ] トークン有効性確認
  - [ ] 有効期限チェック
  - [ ] チームメンバー追加
  - [ ] 招待削除

- [ ] DELETE /api/invitations/[id] (招待キャンセル)
  - [ ] 認証・権限チェック (招待者またはADMIN/OWNER)
  - [ ] 招待削除

## 4.3 チーム対応タスク・カテゴリAPI拡張

### Tasks API 拡張

- [ ] GET /api/tasks チーム機能対応
  - [ ] ?teamId パラメーター追加
  - [ ] ?context=personal|team パラメーター
  - [ ] 個人タスク/チームタスクのフィルタリング
  - [ ] 担当者情報付与

- [ ] POST /api/tasks チーム機能対応
  - [ ] チームタスク作成機能
  - [ ] 担当者アサイン機能
  - [ ] チームメンバーシップ確認

- [ ] PUT /api/tasks/[id] チーム機能対応
  - [ ] 担当者変更機能
  - [ ] チームタスクの権限チェック
  - [ ] 個人↔チームタスク変換

### Categories API 拡張

- [ ] GET /api/categories チーム機能対応
  - [ ] ?teamId パラメーター追加
  - [ ] 個人カテゴリ/チームカテゴリ分離
  - [ ] アクセス権限チェック

- [ ] POST /api/categories チーム機能対応
  - [ ] チームカテゴリ作成機能
  - [ ] チーム権限チェック

## 4.4 チーム管理UIフロントエンド

### チーム管理コンポーネント

- [ ] TeamCard コンポーネント (`src/app/_components/TeamCard.tsx`)
  - [ ] チーム情報表示 (名前、説明、メンバー数)
  - [ ] ロール表示
  - [ ] 管理ボタン (設定、脱退等)

- [ ] TeamForm コンポーネント (`src/app/_components/TeamForm.tsx`)
  - [ ] チーム作成・編集フォーム
  - [ ] バリデーション実装
  - [ ] チーム数制限チェック

- [ ] TeamMemberList コンポーネント (`src/app/_components/TeamMemberList.tsx`)
  - [ ] メンバー一覧表示
  - [ ] ロール表示・変更
  - [ ] 削除・招待機能

- [ ] MemberInviteModal コンポーネント (`src/app/_components/MemberInviteModal.tsx`)
  - [ ] メンバー招待フォーム
  - [ ] 招待リンク生成・表示
  - [ ] ロール選択

### チーム関連ページ実装

- [ ] Teams 一覧ページ (`src/app/teams/page.tsx`)
  - [ ] 参加チーム一覧表示
  - [ ] チーム作成ボタン
  - [ ] チーム切り替え機能

- [ ] Team 詳細ページ (`src/app/teams/[id]/page.tsx`)
  - [ ] チーム情報表示
  - [ ] メンバー一覧
  - [ ] チームタスク概要
  - [ ] 管理機能 (権限に応じて)

- [ ] Team 設定ページ (`src/app/teams/[id]/settings/page.tsx`)
  - [ ] チーム情報編集
  - [ ] メンバー管理
  - [ ] 権限設定
  - [ ] チーム削除

- [ ] 招待受諾ページ (`src/app/invitations/[token]/page.tsx`)
  - [ ] 招待情報表示
  - [ ] 承認・拒否機能
  - [ ] ログイン促進

## 4.5 チーム対応UI拡張

### コンテキスト切り替え

- [ ] TeamContextProvider (`src/app/_contexts/TeamContext.tsx`)
  - [ ] 現在のチームコンテキスト管理
  - [ ] 個人モード ↔ チームモード切り替え
  - [ ] チーム切り替え機能

- [ ] ContextSwitcher コンポーネント (`src/app/_components/ContextSwitcher.tsx`)
  - [ ] 個人/チーム切り替えUI
  - [ ] 現在のコンテキスト表示
  - [ ] チーム選択ドロップダウン

### Next.js App Router チーム機能対応

- [ ] チーム関連ページのServer Component実装
  - [ ] `/app/teams/[id]/page.tsx` でのチーム情報取得
  - [ ] `notFound()` でのチーム未発見処理
  - [ ] Dynamic Routing でのチーム切り替え対応

- [ ] チーム権限チェック最適化 (WANT)
  - [ ] Server Component レベルでの認可チェック
  - [ ] `redirect()` での権限不足時リダイレクト

### タスク管理UI拡張

- [ ] TaskCard コンポーネントチーム機能拡張
  - [ ] 担当者表示・変更
  - [ ] チーム/個人タスク区別表示
  - [ ] チームメンバー選択

- [ ] TaskForm コンポーネントチーム機能拡張
  - [ ] 担当者選択フィールド
  - [ ] チーム/個人タスク切り替え
  - [ ] チームカテゴリ表示

- [ ] TaskList コンポーネントチーム機能拡張
  - [ ] 担当者別フィルター
  - [ ] チーム/個人タスク分離表示
  - [ ] 担当者アバター表示

### カテゴリ管理UI拡張

- [ ] CategoryList コンポーネントチーム機能拡張
  - [ ] チーム/個人カテゴリ分離
  - [ ] チームカテゴリ作成権限制御

## 4.6 権限・セキュリティ実装

### 権限チェック実装

- [ ] チーム権限ヘルパー関数 (`src/app/_lib/team-auth.ts`)
  - [ ] checkTeamMembership(userId, teamId)
  - [ ] checkTeamRole(userId, teamId, minRole)
  - [ ] requireTeamMembership(userId, teamId)
  - [ ] requireTeamRole(userId, teamId, minRole)

- [ ] API 権限チェック統合
  - [ ] 全チーム関連APIに権限チェック適用
  - [ ] 階層的権限制御実装
  - [ ] リソースアクセス制限

### データセキュリティ

- [ ] Row Level Security 相当の実装
  - [ ] Prisma クエリレベルでの権限フィルター
  - [ ] チーム間データ漏洩防止
  - [ ] 個人データ保護

## 4.7 協業機能実装

### タスクコメント機能

- [ ] TaskComment モデル追加 (`schema.prisma`)
  - [ ] 基本フィールド
    - [ ] id: String @id @default(cuid())
    - [ ] content: String (必須, 最大1000文字)
    - [ ] taskId: String
    - [ ] authorId: String
    - [ ] createdAt: DateTime @default(now())
    - [ ] updatedAt: DateTime @updatedAt

- [ ] Comments API実装 (`src/app/api/tasks/[id]/comments/`)
  - [ ] GET - コメント一覧取得
  - [ ] POST - コメント作成
  - [ ] PUT - コメント編集 (作成者のみ)
  - [ ] DELETE - コメント削除

- [ ] コメントUI実装
  - [ ] TaskComments コンポーネント
  - [ ] コメント作成フォーム
  - [ ] コメント一覧表示

### 活動履歴・通知 (WANT)

- [ ] Activity モデル追加 (WANT)
  - [ ] タスク作成・更新・削除のログ
  - [ ] 担当者変更のログ
  - [ ] コメント追加のログ

- [ ] 活動履歴UI (WANT)
  - [ ] ActivityFeed コンポーネント
  - [ ] チーム活動履歴ページ

- [ ] リアルタイム更新機能 (WANT)
  - [ ] Server-Sent Events での更新通知
  - [ ] WebSocket での協業リアルタイム機能

## 4.8 チームデータ管理

### チーム単位でのデータエクスポート/インポート

- [ ] Team Export API拡張
  - [ ] チーム全体のタスク・カテゴリエクスポート
  - [ ] メンバー情報・権限情報含む
  - [ ] 管理者権限チェック

- [ ] Team Import API拡張
  - [ ] チームデータの一括インポート
  - [ ] メンバーマッピング機能
  - [ ] 権限チェック・競合処理

### チーム統計・レポート

- [ ] チーム統計API (`src/app/api/teams/[id]/stats`)
  - [ ] タスク完了率
  - [ ] メンバー別活動状況
  - [ ] カテゴリ別統計

- [ ] 統計UI実装
  - [ ] TeamDashboard コンポーネント
  - [ ] 統計グラフ・チャート
  - [ ] レポート生成機能

## 4.9 テスト実装

### チーム機能API テスト

- [ ] Teams API テスト
  - [ ] チーム CRUD 操作
  - [ ] メンバー管理機能
  - [ ] 権限チェック

- [ ] チーム権限テスト
  - [ ] ロール別アクセス制御
  - [ ] データ漏洩防止
  - [ ] 権限昇格防止

### E2E テスト

- [ ] チーム作成・管理フロー
- [ ] メンバー招待・参加フロー
- [ ] チームタスク協業フロー

## 4.10 Phase 4 完了チェック

### 機能動作確認

- [ ] チーム作成・管理が正常動作
- [ ] メンバー招待・ロール管理が正常動作
- [ ] チームタスク・カテゴリ管理が正常動作
- [ ] 権限制御が適切に機能
- [ ] 個人モード ↔ チームモード切り替えが正常動作

### セキュリティ確認

- [ ] チーム間データ分離ができている
- [ ] 権限チェックが適切に機能
- [ ] セキュリティ脆弱性がない

### 性能・スケーラビリティ確認

- [ ] 50ユーザー/チームでの動作確認
- [ ] 大量タスクでのパフォーマンス確認
- [ ] 同時接続でのレスポンス確認

---

**Phase 4 完了条件**: チーム機能が完全に統合され、個人・チーム両方のコンテキストでタスク管理ができる完成したアプリケーションになること。
