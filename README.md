# TODO アプリ プロジェクト概要

## プロジェクト構成

Next.js + TypeScript + PostgreSQL を使用したモダンな TODO アプリケーションです。Docker 環境での運用を前提として設計されています。

## ドキュメント一覧

### 1. [要件定義書](./docs/requirements.md)

- プロジェクト概要と目的
- 技術要件と制約事項
- 非機能要件と成功基準

### 2. [機能要件書](./docs/functional-requirements.md)

- 詳細な機能仕様
- UI/UX 要件
- データ構造定義
- エラーハンドリング仕様

### 3. [アーキテクチャ設計書](./docs/architecture.md)

- システム全体アーキテクチャ
- フロントエンド・バックエンド設計
- データベース設計
- セキュリティ・パフォーマンス考慮事項

### 4. [Docker 構成設計](./docs/docker-setup.md)

- Docker Compose 設定
- デプロイメント構成
- 運用スクリプト
- モニタリング設定

## 開発の進め方

### Phase 1: 基盤構築 (Week 1)

1. Next.js プロジェクトセットアップ
2. shadcn/ui と Tailwind CSS 設定
3. Prisma セットアップとデータベース設計
4. 基本的なレイアウトコンポーネント作成

### Phase 2: コア機能実装 (Week 2)

1. タスク CRUD 機能実装
2. カテゴリ管理機能実装
3. API Routes 実装
4. フォームバリデーション (Zod)

### Phase 3: 追加機能実装 (Week 3)

1. 検索・フィルタ機能
2. ソート機能
3. データエクスポート/インポート
4. レスポンシブデザイン調整

### Phase 4: 運用準備 (Week 4)

1. Docker 環境構築
2. 本番環境デプロイ
3. パフォーマンス最適化
4. テスト・バグ修正

## セットアップガイド

### 前提条件

- Node.js 18 以上
- Docker & Docker Compose
- Git
- VSCode (Dev Container 使用時)

### 開発環境セットアップ

#### 1. セットアップスクリプト実行

```shell
# 環境変数を設定
cp .env.example .env.local
vim .env

# 実行
bash ./scripts/setup-dev.sh
```

#### 2. devcontainer 起動

```bash
# VSCode でプロジェクトを開く
code .

# コマンドパレット（Ctrl+Shift+P）で以下を実行
# > Dev Containers: Reopen in Container
```

### 本番環境デプロイ

#### 1. ファイル転送

手順割愛する。
scp コマンドなどを利用してファイルを PRD Env. へ転送する

#### 2. "セットアップ & 起動スクリプト" を実行

```bash
# 環境変数を設定
cp .env.example .env
vim .env

# 実行
bash ./scripts/setup-prd.sh
```

### 🔧 トラブルシューティング

#### スクリプトに実行権限がない場合

```bash
chmod +x scripts/*.sh
```

#### Docker ネットワークが既に存在する場合

```bash
docker network rm todo_network
./scripts/setup-dev.sh
```

#### データベース接続エラーの場合

```bash
# コンテナを再起動
docker-compose restart db

# ログを確認
docker-compose logs db
```

## デプロイ手順

本番環境は ConoHa VPS に存在するレンタルサーバーです。

1. git コマンドで最新ファイルを pull する
2. 本番用のセットアップスクリプトを実行し Docker コンテナは起動する

### 1. git コマンドで最新ファイルを pull する

#### 初回のみ実施

```shell
cd ~/apps
git clone git@github.com:HidetoNakasone/todo_app_for_learn_vibecoding.git
```

#### 2 回目以降の実施

```shell
cd ~/apps/todo_app_for_learn_vibecoding
git switch main
git pull
```

### 2. 本番用のセットアップスクリプトを実行し Docker コンテナは起動する

```shell
cp .env.example .env

# edit .env
vim .env

# セットアップスクリプトを実行して Docker コンテナを起動
bash ./scripts/setup-prd.sh
```
