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

# NODE_ENVを開発環境用に設定
sed_inplace 's/NODE_ENV="production"/NODE_ENV="development"/' .env

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
echo "✅ NODE_ENVを開発環境用に設定しました"

# TODO: DB接続情報は `.env` から取得するようなので、実はこの `.mcp.json.template` に分離する必要なさそう。なので、このロジック今は機能していない。しばらく様子見して問題なければ `.mcp.json` のみにして `.mcp.json.example` は削除するかも。
# .mcp.json の生成 (.mcp.json.example から環境変数置換)
if [ -f .mcp.json.example ]; then
  echo "🔧 .mcp.json を .mcp.json.example から生成しています..."

  # .env から DB_PASSWORD を取得
  DB_PASSWORD=$(grep "^DB_PASSWORD=" .env | cut -d '=' -f2 | tr -d '"')

  if [ -z "$DB_PASSWORD" ]; then
    echo "❌ DB_PASSWORD が .env ファイルに見つかりません"
    exit 1
  fi

  # テンプレートファイルから .mcp.json を生成
  sed "s/\${DB_PASSWORD}/$DB_PASSWORD/g" .mcp.json.example > .mcp.json

  echo "✅ .mcp.json を生成しました"
else
  echo "ℹ️  .mcp.json.example が見つからないため、スキップしました"
fi

# clean up
docker compose -f compose.yaml down -v
rm -rf ./node_modules
rm -rf ./src/generated
rm -rf ./.next
rm -rf ./.serena

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

# node_modules の権限を修正
echo "🔧 node_modules の権限を修正しています..."
docker compose -f compose.yaml exec app bash -ic 'sudo chown -R ${USER_ID}:${GROUP_ID} /app/node_modules'

# src/generated ディレクトリの権限を確認・修正
echo "🔧 src/generated ディレクトリの権限を修正しています..."
docker compose -f compose.yaml exec app bash -ic 'sudo mkdir -p /app/src/generated && sudo chown -R ${USER_ID}:${GROUP_ID} /app/src/generated'

# .next ディレクトリの権限を確認・修正（将来のビルドに備えて）
echo "🔧 .next ディレクトリの権限を修正しています..."
docker compose -f compose.yaml exec app bash -ic 'sudo mkdir -p /app/.next && sudo chown -R ${USER_ID}:${GROUP_ID} /app/.next'

# .serena ディレクトリの権限を確認・修正
echo "🔧 .serena ディレクトリの権限を修正しています..."
docker compose -f compose.yaml exec app bash -ic 'sudo mkdir -p /app/.serena && sudo chown -R ${USER_ID}:${GROUP_ID} /app/.serena'

# 依存関係インストール
echo "📦  依存関係をインストールしています..."
docker compose -f compose.yaml exec app bash -ic 'bun install'

# Prisma セットアップ
echo "🔧 Prisma のセットアップを行っています..."
# `prisma/migrations` ディレクトリが存在しない場合は作成し、存在する場合はDBへマイグレーションを適用
docker compose -f compose.yaml exec app bash -ic 'bun prisma migrate dev'

# Prisma クライアントの生成 (Prismaを利用するために必要)
docker compose -f compose.yaml exec app bash -ic 'bun prisma generate'

# Install Claude Code
docker compose -f compose.yaml exec app bash -ic 'npm i -g @anthropic-ai/claude-code && echo "alias claude=\"npx claude\"" >> ~/.bashrc'

# Install uv (for Serena MCP Server)
docker compose -f compose.yaml exec app bash -ic 'curl -LsSf https://astral.sh/uv/install.sh | sh'

echo "✅ 開発環境のセットアップが完了しました！"
echo ""
echo "🎵 VOICEVOX 音声システムの起動"
echo "----------------------------------------"
echo "VOICEVOX 音声システムを起動しますか？"
echo "（Claude の返答を音声で聞くことができるようになります）"
echo ""

# ユーザー入力待機
while true; do
    read -p "VOICEVOX 音声システムを起動しますか？ (y/N): " yn
    case $yn in
        [Yy]* | [Yy][Ee][Ss]* )
            echo ""
            echo "🚀 VOICEVOX 音声システムを起動しています..."
            if nohup bash scripts/start-voicevox-system.sh > /dev/null 2>&1 &
            then
                echo "✅ VOICEVOX 音声システムが起動しました！"
                echo ""
                echo "📊 確認方法:"
                echo "  - API: http://localhost:50023/docs"
                echo "  - ログ: tail -f logs/voicevox-engine.log"
                echo ""
                echo "🎤 Claude Code を起動してください："
                echo "  claude"
                echo ""
                echo "⏹️  システム停止時は以下のコマンドを実行してください："
                echo "  bash scripts/stop-voicevox-system.sh"
            else
                echo "❌ VOICEVOX 音声システムの起動に失敗しました"
                echo "手動起動: nohup bash scripts/start-voicevox-system.sh &"
            fi
            break
            ;;
        [Nn]* | [Nn][Oo]* | "" )
            echo ""
            echo "ℹ️  VOICEVOX 音声システムをスキップしました"
            echo ""
            echo "後で起動する場合："
            echo "  nohup bash scripts/start-voicevox-system.sh &"
            echo ""
            echo "🎤 Claude Code を起動してください："
            echo "  claude"
            echo ""
            echo "💡 Tips: システム停止時は bash scripts/stop-voicevox-system.sh を実行してください"
            break
            ;;
        * )
            echo "y(yes) または n(no) で回答してください"
            ;;
    esac
done

echo ""
