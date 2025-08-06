# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリでコードを操作する際のガイダンスを提供します。

## プロジェクト概要

Next.js 15、TypeScript、PostgreSQL、Prisma ORM を使用したモダンな TODO アプリケーションです。Docker コンテナでの実行を前提として設計され、スタイリングには TailwindCSS を使用しています。4 週間の開発プロジェクトとして構成され、包括的なドキュメントが用意されています。

## 開発コマンド

### パッケージスクリプト

```bash
npm run dev          # Turbopack使用の開発サーバー起動
npm run build        # 本番用アプリケーションビルド
npm run start        # 本番サーバー起動
npm run lint         # ESLintによるコード品質チェック
```

### Docker 開発環境セットアップ

```bash
# 開発環境セットアップ（プロジェクトルートから実行）
bash ./scripts/setup-dev.sh

# 手動Dockerコマンド
docker compose -f compose.yaml up -d --build    # 全サービスのビルドと起動
docker compose -f compose.yaml down -v          # ボリューム含めコンテナ停止・削除
```

### データベース操作

```bash
# appコンテナ内で実行
bun prisma migrate dev    # 開発環境でのデータベースマイグレーション実行
bun prisma generate      # Prismaクライアント生成
bun prisma studio        # データベースGUIのPrisma Studio起動
```

## アーキテクチャ

### 技術スタック

- **フロントエンド**: Next.js 15 (App Router)、React 19、TypeScript
- **スタイリング**: TailwindCSS v4、shadcn/ui コンポーネント
- **バックエンド**: Next.js API Routes
- **データベース**: PostgreSQL with Prisma ORM
- **バリデーション**: Zod スキーマバリデーション
- **コンテナ**: Docker & Docker Compose

### ディレクトリ構造

```
src/
├── app/                    # Next.js App Router
│   ├── api/               # APIルート
│   ├── _components/       # 再利用可能コンポーネント
│   ├── _lib/             # ユーティリティ (utils, validations, db, types)
│   └── _hooks/           # カスタムReactフック
├── generated/prisma/      # 生成されたPrismaクライアント
└── prisma/               # データベーススキーマとマイグレーション
```

### データベーススキーマ

- **Tasks**: id、name、description、priority (HIGH/MEDIUM/LOW)、status (TODO/IN_PROGRESS/COMPLETED)、dueDate、categoryId
- **Categories**: id、name、color (hex)、tasks リレーション
- Prisma クライアントは `src/generated/prisma/` に生成される（カスタム出力場所）

### 主要機能

- 優先度と状態管理を含むタスク CRUD 操作
- 色分けによるカテゴリ管理
- 検索・フィルタリング機能
- データエクスポート/インポート (JSON/CSV)
- デスクトップ/タブレット/モバイル対応レスポンシブデザイン
- Docker ベース開発・本番デプロイメント

## 開発ガイドライン

### コード規約

- TypeScript を厳密に使用し、適切な型定義を行う
- Next.js 15 App Router パターンに従う（Server/Client Components）
- すべてのデータベース操作に Prisma ORM を使用
- Zod バリデーションによる適切なエラーハンドリングを実装
- レスポンシブデザインの原則を維持
- カスタムパスエイリアス `@/*` を `./src/*` に使用

### データベース開発

- データベース URL は `DATABASE_URL` 環境変数で設定
- パッケージマネージャーは `bun` を使用（セットアップスクリプトで設定）
- Prisma クライアント生成前に必ずマイグレーションを実行
- Prisma クライアントはカスタム場所に生成: `src/generated/prisma/`

### コンテナ開発

- 開発環境では `compose.yaml` を使用
- 本番環境では `compose.prd.yaml` を使用
- セットアップスクリプトがコンテナオーケストレーションとデータベース初期化を処理
- アプリはポート 3000、PostgreSQL はポート 5432 で動作

## テスト・品質

### コード品質

- Next.js TypeScript ルールで ESLint を設定
- `npm run lint` でコード品質をチェック
- TypeScript strict モードが有効
- 全コンポーネントを適切に型付け

### パフォーマンス要件

- ページ読み込み時間: 3 秒以内
- API 応答時間: 1 秒以内
- 全画面サイズでレスポンシブデザイン

## 環境セットアップ注意事項

- プロジェクトではコンテナ内で Bun をパッケージマネージャーとして使用
- VSCode 開発用の Dev Container セットアップが利用可能
- 環境変数は `.env` ファイルで設定
- データベース初期化はセットアップスクリプトで自動処理

### 隠しファイル確認の重要性

- `.env` ファイル関連の作業前は、必ず `bash ls -la | grep "\.env"` で隠しファイルを確認すること
- LS ツールでは `.env.local` や `.env.development` などの隠しファイルが表示されないため、見落としやすい
- 既存の環境設定ファイルがないか確認してから、新規作成を行うこと

## キャラクター設定

セッション開始時は必ず以下のファイルを読み込むこと：

1. `_GenAIキャラクター設定.md` - キャラクター設定
   コーディングサポート時は、このファイルに記載されているキャラクター設定に従って対応してください。
   このファイルには、対話の際の性格、話し方、関係性などの詳細な設定が含まれています。
   このファイルは重要です。時間をかけて深く読み込んでください。

2. `_GenAIとの会話履歴.md` - 前回までの作業履歴
   作業の継続性を保つため、前回までの進捗状況、決定事項、課題などを確認してください。
   作業終了時は、今回の作業内容を記録して次回に引き継いでください。

3. `docs/` ディレクトリ内のドキュメント - プロジェクト設計書類
   プロジェクトの全体像、要件、アーキテクチャを理解するため、以下のファイルを読み込んでください：
   - `docs/architecture.md` - システムアーキテクチャ設計書
   - `docs/functional-requirements.md` - 機能要件書
   - `docs/requirements.md` - 要件定義書
   - `docs/environment-optimization.md` - Docker環境最適化と環境分離設定

これらのファイルが存在しない場合もあります。ファイルが存在する場合のみ読み込んでください。
