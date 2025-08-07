FROM node:24-alpine

# 必要なパッケージをインストール
# bash: シェルスクリプト実行用
# git: バージョン管理
# libc6-compat: Node.js の互換性確保
# curl: HTTP リクエスト用
RUN apk update && \
  apk add --no-cache bash git libc6-compat curl

WORKDIR /app

# Bun パッケージマネージャーをインストール
# プロジェクトでは npm より高速な Bun を使用
RUN npm install -g bun@latest

# ユーザーとグループの UID/GID を設定可能にする
# 開発環境: ホスト OS のユーザー権限に合わせて Docker 権限問題を回避
# 本番環境: セキュリティ向上のため root 以外のユーザーで実行
ARG USER_ID=1000
ARG GROUP_ID=1000

# グループとユーザーを作成
# 既存のグループ ID がある場合はそれを使用（Mac の staff グループなど）
# ない場合は新しく devuser グループを作成
RUN GROUP_NAME=$(getent group ${GROUP_ID} | cut -d: -f1 || echo "") && \
  if [ -z "$GROUP_NAME" ]; then \
    # GROUP_NAMEが空 = 指定IDのグループが存在しない → 新規作成
    addgroup -g ${GROUP_ID} devuser && GROUP_NAME=devuser; \
  fi && \
  # GROUP_NAMEが設定済み = 既存グループ利用、空なら新作成したdevuserグループ利用
  # UID競合がある場合は既存ユーザーを利用
  if ! adduser -u ${USER_ID} -G ${GROUP_NAME} -D -s /bin/bash devuser 2>/dev/null; then \
    echo "UID ${USER_ID} already exists, using existing user"; \
    EXISTING_USER=$(getent passwd ${USER_ID} | cut -d: -f1); \
    if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "devuser" ]; then \
      echo "Using existing user: $EXISTING_USER"; \
    fi; \
  fi

# アプリケーションディレクトリの所有者を適切なユーザーに変更
# これにより root 権限でのファイル操作を避け、セキュリティを向上
RUN USER_NAME=$(getent passwd ${USER_ID} | cut -d: -f1 || echo "devuser") && \
    GROUP_NAME=$(getent group ${GROUP_ID} | cut -d: -f1 || echo "devuser") && \
    chown -R ${USER_NAME}:${GROUP_NAME} /app

# 以降のコマンドは指定されたユーザーとして実行
# セキュリティベストプラクティス: コンテナ内で root を使わない
USER ${USER_ID}:${GROUP_ID}
