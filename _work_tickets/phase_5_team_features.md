# Phase 5: チーム機能 (Week 6-8)

## 5.1 チーム管理基盤

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
  - [ ] 招待メール送信実装
    - [ ] メール送信サービス統合 (Nodemailer/SendGrid/Resend等)
    - [ ] 招待メールテンプレート作成 (HTML + Text形式)
    - [ ] メール送信エラーハンドリング・リトライ機能
    - [ ] 送信履歴・再送機能
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

- [ ] POST /api/invitations/reject/[token] (招待拒否)
  - [ ] トークン有効性確認
  - [ ] 有効期限チェック
  - [ ] 招待拒否処理・データベース記録
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

## 4.4 モダンチーム管理UI (TanStack Query + Zustand + shadcn/ui)

### チーム管理コンポーネント

- [ ] **Teams Query/Mutation フック**
  - [ ] `useTeams()` - 参加チーム一覧 (自動キャッシング)
  - [ ] `useTeam(id)` - 特定チーム詳細 (リアルタイム更新)
  - [ ] `useCreateTeam()` - 楽観的更新付きチーム作成
  - [ ] `useUpdateTeam(id)` - チーム情報更新
  - [ ] `useDeleteTeam()` - チーム削除
  - [ ] `useTeamMembers(teamId)` - メンバー一覧
  - [ ] `useInviteTeamMember()` - メンバー招待
  - [ ] `useRejectInvitation()` - 招待拒否 (楽観的更新)

- [ ] TeamCard コンポーネント (`src/app/_components/TeamCard.tsx`)
  - [ ] **TanStack Query統合**: `useTeam()` でリアルタイム更新
  - [ ] **Zustand統合**: `setActiveTeam()` でチーム切り替え
  - [ ] **UI状態管理**: `useUIStore()` でモーダル管理
  - [ ] チーム情報表示 (名前、説明、メンバー数)
  - [ ] ロール表示、管理ボタン (設定、脱退等)

- [ ] TeamForm コンポーネント (`src/app/_components/TeamForm.tsx`)
  - [ ] **TanStack Mutation**: `useCreateTeam()`, `useUpdateTeam()`
  - [ ] **Form State**: `useFormStore()` でドラフト機能
  - [ ] **楽観的更新**: 即座のUI反映
  - [ ] shadcn/ui Form統合、バリデーション実装

- [ ] TeamMemberList コンポーネント (`src/app/_components/TeamMemberList.tsx`)
  - [ ] **Query統合**: `useTeamMembers(teamId)` で自動更新
  - [ ] **楽観的更新**: ロール変更、メンバー削除
  - [ ] **Permission UI**: ロール別操作制御
  - [ ] メンバー一覧表示、ロール表示・変更

- [ ] MemberInviteModal コンポーネント (`src/app/_components/MemberInviteModal.tsx`)
  - [ ] **Mutation統合**: `useInviteTeamMember()` 楽観的更新
  - [ ] **UI状態管理**: `useUIStore()` でモーダル制御
  - [ ] **Form統合**: shadcn/ui + Zod バリデーション
  - [ ] 招待リンク生成・表示、ロール選択

### チーム関連ページ実装

### モダンチームページ実装 (Hybrid SSR + Client State)

- [ ] Teams 一覧ページ (`src/app/teams/page.tsx`)
  - [ ] **ハイブリッドアプローチ**: サーバー初期データ + クライアント更新
  - [ ] **Query統合**: `useTeams()` で参加チーム一覧
  - [ ] **Team Store**: `useTeamStore()` でチーム切り替え
  - [ ] **Modal統合**: `useUIStore()` でチーム作成モーダル
  - [ ] TeamCard コンポーネント使用

- [ ] Team 詳細ページ (`src/app/teams/[id]/page.tsx`)
  - [ ] **Server Component**: 初期チーム情報プリフェッチ
  - [ ] **TanStack Query**: `useTeam(id)` でリアルタイム更新
  - [ ] **権限制御**: ロール別UI表示制御
  - [ ] **統合表示**: チーム情報・メンバー・タスク概要

- [ ] Team 設定ページ (`src/app/teams/[id]/settings/page.tsx`)
  - [ ] **権限チェック**: ADMIN以上のみアクセス可能
  - [ ] **Multiple Mutations**: チーム更新、メンバー管理、削除
  - [ ] **楽観的更新**: 設定変更の即座反映
  - [ ] **Permission UI**: ロール別設定項目表示

- [ ] 招待受諾ページ (`src/app/invitations/[token]/page.tsx`)
  - [ ] **Server Component**: 招待トークン検証
  - [ ] **Mutation**: `useAcceptInvitation()`, `useRejectInvitation()` 楽観的更新
  - [ ] **認証統合**: NextAuth.js セッション確認
  - [ ] **UI改善**: 承認・拒否ボタンとチーム情報表示
  - [ ] **自動リダイレクト**: 受諾後チームページへ、拒否後ダッシュボードへ

## 4.5 チーム対応UI拡張

### コンテキスト切り替え

### モダンチーム状態管理 (TanStack Query + Zustand)

**前提条件**: Phase 2c (Modern State Management Setup) 完了

- [ ] **Team Context を Zustand で置き換え**
  - [ ] `useTeamStore()` - チームコンテキスト状態管理
    - [ ] `activeTeam: Team | null` - 現在のチーム
    - [ ] `teamMode: 'personal' | 'team'` - モード切り替え
    - [ ] `setActiveTeam: (team: Team) => void`
    - [ ] `toggleTeamMode: () => void`
  - [ ] **永続化**: localStorage連携でチーム選択記憶

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

### チーム機能拡張UI (既存コンポーネント統合)

- [ ] TaskCard コンポーネントチーム機能拡張
  - [ ] **Team State統合**: `useTeamStore()` で現在のチーム取得
  - [ ] **Query統合**: `useTeamMembers()` で担当者選択
  - [ ] **楽観的更新**: 担当者変更の即座反映
  - [ ] 担当者表示・変更、チーム/個人タスク区別表示

- [ ] TaskForm コンポーネントチーム機能拡張
  - [ ] **Team Context**: `useTeamStore()` でチーム/個人モード判定
  - [ ] **Dynamic Options**: チームメンバー・カテゴリの動的選択
  - [ ] **Form Integration**: 担当者選択、チームカテゴリ表示
  - [ ] **Validation**: チームタスクの追加バリデーション

- [ ] TaskList コンポーネントチーム機能拡張
  - [ ] **Filter拡張**: `useFilterStore()` に担当者フィルター追加
  - [ ] **Team Query**: `useTasks({ teamId, assigneeId })` 複合条件
  - [ ] **UI拡張**: 担当者アバター、チーム/個人分離表示
  - [ ] **Permission**: ロール別操作制御

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

## 4.8 メール通知システム実装

### メール送信基盤構築

- [ ] メール送信サービス選定・設定
  - [ ] サービス選択 (Resend推奨/SendGrid/Nodemailer等)
  - [ ] 環境変数設定 (API Key, 送信元アドレス等)
  - [ ] Docker環境での設定統合

- [ ] メール送信ユーティリティ (`src/app/_lib/email.ts`)
  - [ ] メール送信クライアント初期化
  - [ ] 送信エラーハンドリング・リトライ機能
  - [ ] 送信ログ記録機能
  - [ ] 開発環境でのテスト送信機能

### 招待メール機能

- [ ] 招待メールテンプレート
  - [ ] HTML版テンプレート作成 (`templates/invite-email.html`)
  - [ ] プレーンテキスト版テンプレート (`templates/invite-email.txt`)
  - [ ] 日本語・英語対応 (国際化準備)
  - [ ] レスポンシブメールデザイン

- [ ] 招待メール送信機能 (`src/app/_lib/email/team-invitations.ts`)
  - [ ] 招待メール生成・送信関数
  - [ ] トークン有効期限情報の含有
  - [ ] チーム情報・招待者情報の含有
  - [ ] 送信失敗時のフォールバック処理

- [ ] 招待メール管理機能
  - [ ] 送信履歴の記録・表示
  - [ ] 再送機能実装
  - [ ] 送信エラー時の管理者通知

## 4.9 チームデータ管理

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

### チーム機能エラーハンドリング

- [ ] チーム管理エラー処理
  - [ ] チーム作成数上限エラー (5チーム上限)
  - [ ] 権限不足エラーと必要権限の明示
  - [ ] チーム削除時のデータ保護確認

- [ ] 招待システムエラー処理
  - [ ] 招待トークン期限切れエラーと再招待オプション
  - [ ] 無効なトークンエラーとサポート連絡先表示
  - [ ] 既存メンバー招待エラーと現状確認リンク
  - [ ] メール送信失敗時のマニュアル招待リンク生成

- [ ] 協業機能エラー処理
  - [ ] 同時編集競合エラーと自動マージ機能
  - [ ] 担当者削除時のタスク再割り当て処理
  - [ ] コメント投稿失敗時の下書き保存機能

- [ ] データ同期エラー処理
  - [ ] チーム切り替え時の同期エラー回復
  - [ ] リアルタイム更新失敗時のポーリング代替
  - [ ] 権限変更時のUI状態同期

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

### チーム機能パフォーマンステスト

- [ ] 大規模チーム性能テスト
  - [ ] 50メンバーチームでの同時アクセステスト
  - [ ] 1000タスク/チームでの一覧表示性能
  - [ ] 複数チーム切り替え時の性能測定
  - [ ] チームタスクの権限チェック性能

- [ ] 協業機能性能テスト
  - [ ] 同時タスク編集でのリアルタイム更新性能
  - [ ] コメント機能の大量データでの表示性能
  - [ ] 担当者変更時の楽観的更新性能

- [ ] メール送信性能テスト
  - [ ] 大量招待メール送信性能 (50通/分)
  - [ ] メール送信失敗時のリトライ性能
  - [ ] メールテンプレート生成性能

- [ ] データベース性能
  - [ ] チーム権限クエリの最適化確認
  - [ ] 大量データでのJOINクエリ性能
  - [ ] インデックス効果の測定

### チーム機能アクセシビリティテスト

- [ ] チーム管理UIのアクセシビリティ
  - [ ] チーム切り替えドロップダウンのキーボード操作
  - [ ] メンバー一覧テーブルのスクリーンリーダー対応
  - [ ] 権限表示の視覚・音声両対応 (Owner/Admin/Member)
  - [ ] チーム作成フォームのエラー表示アクセシビリティ

- [ ] 招待システムのアクセシビリティ
  - [ ] 招待リンクのQRコード代替テキスト
  - [ ] 招待受諾ページのキーボードナビゲーション
  - [ ] 承認・拒否ボタンの明確なラベル設定

- [ ] 協業機能のアクセシビリティ
  - [ ] 担当者選択UIのコンボボックス対応
  - [ ] リアルタイム更新通知のライブリージョン
  - [ ] コメント機能のスレッド表示とナビゲーション
  - [ ] 同時編集状態の視覚・音声表示

- [ ] 複合機能のアクセシビリティ
  - [ ] 個人・チーム切り替えの状態表示
  - [ ] 複数チーム所属時の現在位置明示
  - [ ] 権限制御されたUI要素の理由説明

---

**Phase 4 完了条件**: チーム機能が完全に統合され、個人・チーム両方のコンテキストでタスク管理ができる完成したアプリケーションになること。
