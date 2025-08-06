#!/bin/bash

# 実行に失敗した場合はスクリプトを終了
set -e

# 開発環境セットアップスクリプト

echo "🚀 開発環境をセットアップしています..."

# .envファイルの準備
if [ ! -f .env ]; then
  echo "📝 .envファイルを自動生成しています..."
  cp .env.example .env
else
  echo "ℹ️  .envファイルは既に存在しています"
fi

# 現在のユーザーID/グループIDを取得
CURRENT_USER_ID=$(id -u)
CURRENT_GROUP_ID=$(id -g)

# 既存のUSER_ID/GROUP_ID設定を削除（重複回避）
sed -i '' '/^USER_ID=/d' .env
sed -i '' '/^GROUP_ID=/d' .env
sed -i '' '/^# Docker User Settings/d' .env

# 余分な空行を削除（連続する空行を1つにまとめる）
sed -i '' '/^$/N;/^\n$/d' .env

# NODE_ENVを開発環境用に設定
sed -i '' 's/NODE_ENV="production"/NODE_ENV="development"/' .env

# 新しい設定を追加
echo "" >> .env
echo "# Docker User Settings (auto-generated)" >> .env
echo "USER_ID=${CURRENT_USER_ID}" >> .env
echo "GROUP_ID=${CURRENT_GROUP_ID}" >> .env

echo "✅ USER_ID/GROUP_IDを設定しました (USER_ID=${CURRENT_USER_ID}, GROUP_ID=${CURRENT_GROUP_ID})"
echo "✅ NODE_ENVを開発環境用に設定しました"

# clean up
docker compose -f compose.yaml down -v

# Docker Container 起動
docker compose -f compose.yaml up -d --build

# データベースコンテナ 起動
echo "🗄️  PostgreSQL データベースを起動しています..."
docker compose -f compose.yaml up -d db

# データベース 起動待機
echo "⏳ データベースの起動を待機しています..."
until docker compose -f compose.yaml exec db pg_isready -U postgres -d todo_app; do
  sleep 1
done

# node_modules の権限を修正（開発環境のみ）
docker compose -f compose.yaml exec -u root app sh -c 'chown -R devuser:$(id -gn devuser) /app/node_modules 2>/dev/null || true'

# 依存関係インストール
echo "📦  依存関係をインストールしています..."
docker compose -f compose.yaml exec app sh -c 'bun install'

# Prisma セットアップ
echo "🔧 Prisma のセットアップを行っています..."
# `prisma/migrations` ディレクトリが存在しない場合は作成し、存在する場合はDBへマイグレーションを適用
docker compose -f compose.yaml exec app sh -c 'bun prisma migrate dev'
# Prisma クライアントの生成 (Prismaを利用するために必要)
docker compose -f compose.yaml exec app sh -c 'bun prisma generate'

echo "✅ 開発環境のセットアップが完了しました！"
