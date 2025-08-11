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

# OS互換性のためのsed関数を定義
# macOS: sed -i '' 形式, Linux/WSL2: sed -i 形式
sed_inplace() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "$@"
  else
    # Linux (including Ubuntu, CentOS, WSL2/Ubuntu)
    sed -i "$@"
  fi
}

# 既存のUSER_ID/GROUP_ID設定を削除（重複回避）
sed_inplace '/^USER_ID=/d' .env
sed_inplace '/^GROUP_ID=/d' .env
sed_inplace '/^# Docker User Settings/d' .env

# 余分な空行を削除（連続する空行を1つにまとめる）
sed_inplace '/^$/N;/^\n$/d' .env

# NODE_ENVを本番環境用に確認・設定
sed_inplace 's/NODE_ENV="development"/NODE_ENV="production"/' .env

# 本番環境用NextAuth.js設定
echo "🔐 NextAuth.js認証設定を本番環境用に構成しています..."

# AUTH_DEBUG を削除または無効化（本番環境では不要）
sed_inplace '/^AUTH_DEBUG=/d' .env

# AUTH_SECRET を自動生成（まだ設定されていない場合）
if grep -q "your-auth-secret-here-please-change-this-to-random-string" .env; then
  echo "🔑 AUTH_SECRET を自動生成しています..."
  
  # 32文字のランダムシークレット生成
  AUTH_SECRET=$(openssl rand -hex 32)
  
  # AUTH_SECRET を置換
  sed_inplace "s/your-auth-secret-here-please-change-this-to-random-string/$AUTH_SECRET/" .env
  
  echo "✅ AUTH_SECRET を自動生成・設定しました"
else
  echo "ℹ️  AUTH_SECRET は既に設定されています"
fi

# NEXTAUTH_URL を本番環境用に設定（必要に応じて変更）
if grep -q "localhost:3000" .env; then
  echo "⚠️  NEXTAUTH_URL が開発環境設定になっています"
  echo "   本番環境では適切なドメインに手動で変更してください"
  echo "   例: NEXTAUTH_URL=\"https://your-domain.com\""
fi

# OAuth設定の確認
if grep -q "your-github-oauth-app-client-id" .env || grep -q "your-google-oauth-client-id" .env; then
  echo "⚠️  OAuth設定にプレースホルダーが残っています"
  echo "   本番環境では以下の設定を手動で行ってください："
  echo "   1. GitHub OAuth App: https://github.com/settings/developers"
  echo "   2. Google OAuth App: https://console.cloud.google.com/apis/credentials"
  echo "   3. 各プロバイダーの CLIENT_ID と CLIENT_SECRET を設定"
fi

# DB_PASSWORDを自動生成
if grep -q "your_secure_password_here" .env; then
  echo "🔐 安全なデータベースパスワードを自動生成しています..."

  # 16文字のランダムパスワード生成（英数字記号）
  DB_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)

  # DB_PASSWORDを置換
  sed_inplace "s/your_secure_password_here/$DB_PASSWORD/g" .env

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
rm -rf ./node_modules
rm -rf ./src/generated
rm -rf ./.next

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

# node_modules の権限を修正
echo "🔧 node_modules の権限を修正しています..."
docker compose -f compose.prd.yaml exec app bash -ic 'sudo chown -R ${USER_ID}:${GROUP_ID} /app/node_modules'

# src/generated ディレクトリの権限を確認・修正
echo "🔧 src/generated ディレクトリの権限を修正しています..."
docker compose -f compose.prd.yaml exec app bash -ic 'sudo mkdir -p /app/src/generated && sudo chown -R ${USER_ID}:${GROUP_ID} /app/src/generated'

# .next ディレクトリの権限を確認・修正（ビルド前に必要）
echo "🔧 .next ディレクトリの権限を修正しています..."
docker compose -f compose.prd.yaml exec app bash -ic 'sudo mkdir -p /app/.next && sudo chown -R ${USER_ID}:${GROUP_ID} /app/.next'

# 依存関係インストール
echo "📦  依存関係をインストールしています..."
docker compose -f compose.prd.yaml exec app bash -ic 'bun install'

# Prisma セットアップ
echo "🔧 Prisma のセットアップを行っています..."
docker compose -f compose.prd.yaml exec app bash -ic 'bun prisma migrate deploy'

# Prisma クライアントの生成 (Prismaを利用するために必要)
docker compose -f compose.prd.yaml exec app bash -ic 'bun prisma generate'

# アプリケーションビルド
echo "🏗️ アプリケーションをビルドしています..."
docker compose -f compose.prd.yaml exec app bash -ic 'bun run build'

# アプリケーション起動
echo "🚀 アプリケーションを起動しています..."
docker compose -f compose.prd.yaml exec -d app bash -ic 'bun run start'

echo "✅ 本番環境のセットアップが完了しました！"
