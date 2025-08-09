FROM ubuntu:24.04

# 必要なパッケージをインストール
# bash: シェルスクリプト実行用
# git: バージョン管理
# libc6-compat: Node.js の互換性確保
# curl: HTTP リクエスト用
# sudo: 管理者権限実行用
RUN apt-get update -y && \
  apt-get install -y --no-install-recommends \
  bash git libc6-dev curl sudo

WORKDIR /var/tmp

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
    groupadd -g ${GROUP_ID} devuser && GROUP_NAME=devuser; \
  fi && \
  # GROUP_NAMEが設定済み = 既存グループ利用、空なら新作成したdevuserグループ利用
  # UID競合がある場合は既存ユーザーを利用
  if ! useradd -u ${USER_ID} -g ${GROUP_NAME} -m -s /bin/bash devuser 2>/dev/null; then \
    echo "UID ${USER_ID} already exists, using existing user"; \
    EXISTING_USER=$(getent passwd ${USER_ID} | cut -d: -f1); \
    if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "devuser" ]; then \
      echo "Using existing user: $EXISTING_USER"; \
    fi; \
  fi && \
  # devuserにsudo権限を付与（パスワードなしでsudoを実行可能）
  echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 以降のコマンドは指定されたユーザーとして実行
USER ${USER_ID}:${GROUP_ID}

# install mise
RUN sudo apt install -y gpg sudo wget curl
RUN sudo install -dm 755 /etc/apt/keyrings
RUN wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1> /dev/null

# mise リポジトリをホストアーキテクチャに応じて自動設定
ARG TARGETARCH
RUN echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=${TARGETARCH}] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list

RUN sudo apt update
RUN sudo apt install -y mise

# register path
RUN echo 'export PATH="$HOME/.local/share/mise/shims:$PATH"' >> ~/.bashrc

# Node.js のインストール
RUN mise install node@24
RUN mise use -g node@24

# Bun パッケージマネージャーをインストール
# プロジェクトでは npm より高速な Bun を使用
RUN mise install bun@latest
RUN mise use -g bun@latest

WORKDIR /app
