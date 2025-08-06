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
  adduser -u ${USER_ID} -G ${GROUP_NAME} -D -s /bin/bash devuser

# アプリケーションディレクトリの所有者を devuser に変更
# これにより root 権限でのファイル操作を避け、セキュリティを向上
RUN chown -R devuser:$(id -gn devuser) /app

# 以降のコマンドは devuser として実行
# セキュリティベストプラクティス: コンテナ内で root を使わない
USER devuser
