#!/bin/bash

# 実行に失敗した場合はスクリプトを終了
set -e

# 開発環境セットアップスクリプト

echo "🚀 本番環境をセットアップしています..."

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

# NODE_ENVを本番環境用に確認・設定
sed -i '' 's/NODE_ENV="development"/NODE_ENV="production"/' .env

# DB_PASSWORDを自動生成
if grep -q "your_secure_password_here" .env; then
  echo "🔐 安全なデータベースパスワードを自動生成しています..."
  
  # 16文字のランダムパスワード生成（英数字記号）
  DB_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
  
  # DB_PASSWORDを置換
  sed -i '' "s/your_secure_password_here/$DB_PASSWORD/g" .env
  
  echo "✅ データベースパスワードを自動生成・設定しました"
else
  echo "ℹ️  データベースパスワードは既に設定されています"
fi

# 新しい設定を追加
echo "" >> .env
echo "# Docker User Settings (auto-generated)" >> .env
echo "USER_ID=${CURRENT_USER_ID}" >> .env
echo "GROUP_ID=${CURRENT_GROUP_ID}" >> .env

echo "✅ USER_ID/GROUP_IDを設定しました (USER_ID=${CURRENT_USER_ID}, GROUP_ID=${CURRENT_GROUP_ID})"
echo "✅ NODE_ENVを本番環境用に設定しました"

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

# node_modules の権限を修正（本番環境）
docker compose -f compose.prd.yaml exec -u root app sh -c 'chown -R devuser:$(id -gn devuser) /app/node_modules 2>/dev/null || true'

# 依存関係インストール
echo "📦  依存関係をインストールしています..."
docker compose -f compose.prd.yaml exec app sh -c 'bun install'

# Prisma セットアップ
echo "🔧 Prisma のセットアップを行っています..."
docker compose -f compose.prd.yaml exec app sh -c 'bun prisma migrate deploy'
# Prisma クライアントの生成 (Prismaを利用するために必要)
docker compose -f compose.prd.yaml exec app sh -c 'bun prisma generate'

# アプリケーションビルド
echo "🏗️ アプリケーションをビルドしています..."
docker compose -f compose.prd.yaml exec app sh -c 'bun run build'

# アプリケーション起動
echo "🚀 アプリケーションを起動しています..."
docker compose -f compose.prd.yaml exec -d app sh -c 'bun run start'

echo "✅ 本番環境のセットアップが完了しました！"
