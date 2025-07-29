#!/bin/bash

# 実行に失敗した場合はスクリプトを終了
set -e

# 開発環境セットアップスクリプト

echo "🚀 本番環境をセットアップしています..."

# clean up
docker compose -f compose.prd.yaml down -v

# Docker Container 起動
docker compose -f compose.prd.yaml up -d --build

# データベースコンテナ 起動
echo "🗄️  PostgreSQL データベースを起動しています..."
docker compose -f compose.prd.yaml up -d db

# データベース 起動待機
echo "⏳ データベースの起動を待機しています..."
until docker compose -f compose.prd.yaml exec db pg_isready -U postgres -d todo_app; do
  sleep 1
done

# 依存関係インストール
echo "📦  依存関係をインストールしています..."
docker compose -f compose.prd.yaml exec app sh -c 'bun install'

# Prisma セットアップ
echo "🔧 Prisma のセットアップを行っています..."
docker compose -f compose.prd.yaml exec app sh -c 'bun prisma migrate deploy'

echo "✅ 本番環境のセットアップが完了しました！"
