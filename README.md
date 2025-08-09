# TODO アプリ

Next.js 15 + TypeScript + PostgreSQL を使用したモダンな TODO アプリケーション

## 📚 ドキュメント

### 設計・要件書
- [要件定義書](./docs/requirements.md) - プロジェクト概要と目的、技術要件
- [機能要件書](./docs/functional-requirements.md) - 詳細な機能仕様、UI/UX要件
- [アーキテクチャ設計書](./docs/architecture.md) - システム設計、データベース設計

### 環境・運用
- [Docker環境最適化](./docs/environment-optimization.md) - 環境分離・セットアップ最適化
- [開発者向けガイド (CLAUDE.md)](./CLAUDE.md) - 開発コマンド・運用ルール

### 技術学習記録
- [バイブコーディングガイド](./docs/tech_note/claude-vibe-coding-complete-guide-2025.md)
- [Serena MCP サーバー活用法](./docs/tech_note/serena-mcp-server-basics.md)
- [VOICEVOX 音声システム](./docs/tech_note/voicevox-setup-guide.md)

## 🚀 クイックスタート

### 開発環境

```bash
# セットアップ（.env 自動生成）
bash ./scripts/setup-dev.sh

# VSCode Dev Container で開発
code . # → Dev Containers: Reopen in Container
```

### 本番環境

```bash
# 初回
git clone git@github.com:HidetoNakasone/todo_app_for_learn_vibecoding.git
cd todo_app_for_learn_vibecoding

# デプロイ
git pull
bash ./scripts/setup-prd.sh
```

## 📋 前提条件

- Node.js 18+
- Docker & Docker Compose  
- Git
- VSCode (推奨)

詳細なセットアップ手順・トラブルシューティングは [CLAUDE.md](./CLAUDE.md) を参照してください。
