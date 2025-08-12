# CLAUDE.md

このファイルは、Claude Code がこのリポジトリでコードを操作する際のガイダンスを提供します。

## 🚨 必須ルール - 絶対に遵守すること

### ファイル編集時の必須操作

- **Edit ツール使用後**: 必ず `bun prettier --write ファイル名` を実行
- **Write ツール使用後**: 必ず `bun prettier --write ファイル名` を実行
- **MultiEdit ツール使用後**: 必ず `bun prettier --write ファイル名` を実行
- **複数ファイル編集時は最後に `bun run lint:fix` を実行**
- **目的**: ユーザー保存時の差分発生を防ぐため

### 開発サーバー起動前の必須チェック

**`bun run dev:https` 実行前に必ず以下を実行**：

1. **`mcp__ide__getDiagnostics` でVSCode診断情報確認**
2. **`bun run lint` でESLint品質チェック**
3. **`bunx tsc --noEmit` でTypeScript型チェック**

**エラーがある状態での開発サーバー起動は禁止**

### コミットルール

- **人間用**: `bunx cz`（対話式）
- **Claude用**: `git commit -m`（対話式コマンド使用不可のため）
- **準拠**: Conventional Commits形式必須

## プロジェクト概要

**技術スタック**: Next.js 15、TypeScript、PostgreSQL、Prisma ORM、Docker、TailwindCSS

**ディレクトリ構造**:

```
src/
├── app/                    # Next.js App Router
│   ├── api/               # APIルート
│   ├── _components/       # 再利用可能コンポーネント
│   ├── _lib/             # ユーティリティ (utils, validations, db, types)
│   └── _hooks/           # カスタムReactフック
├── generated/prisma/      # 生成されたPrismaクライアント
└── prisma/               # データベーススキーマとマイグレーション
```

**参照ドキュメント**:

- プロジェクト全体概要：[README.md](./README.md)
- 要件・設計書：[docs/ ディレクトリ](./docs/)
- 技術学習記録：[docs/tech_note/](./docs/tech_note/)

## 開発コマンド

### 基本コマンド

```bash
bun run dev           # HTTP開発サーバー
bun run dev:https     # HTTPS開発サーバー (hepと会話しているなら必ずこちらを使用)
bun run build         # 本番ビルド
bun run start         # 本番サーバー
bun run lint          # ESLint品質チェック
bun run lint:fix      # ESLint自動修正 + prettier全体整形

bunx cz              # 対話式コミット（推奨）
git commit           # Claude用（対話式使用不可）

bun prisma studio    # データベースGUI
```

### セットアップ

```bash
bash ./scripts/setup-dev.sh    # 開発環境自動セットアップ
bash ./scripts/setup-prd.sh    # 本番環境自動セットアップ

# 開発環境の場合、そのまま VSCode Dev Container で開発開始
code . # → Dev Containers: Reopen in Container
```

**Tips: コンテナ開発**

- 開発環境では `compose.yaml` を使用
- 本番環境では `compose.prd.yaml` を使用
- アプリはポート: 3000
- PostgreSQLはポート: 5432

## データベース・認証

### Prisma ORM

- **DATABASE_URL**: 環境変数で設定
- **生成場所**: `src/generated/prisma/`（カスタム）
- **マイグレーション**: `bun prisma migrate dev`
- **クライアント生成**: `bun prisma generate`

### NextAuth.js v5

- **認証プロバイダー**: GitHub OAuth、Google OAuth
- **セッション管理**: データベースベース（Prisma Adapter）
- **設定**: .env.example のテンプレート参照

## 開発ガイドライン

### 必須事項

- **TypeScript厳密型定義**
- **Next.js 15 App Router パターン準拠**
- **Zod バリデーション実装**
- **レスポンシブデザイン維持**
- **カスタムパスエイリアス `@/*` → `./src/*`**

### セキュリティ

- **CSP**: 開発環境では柔軟、本番環境では厳格
- **HTTPS**: 開発環境でも強制使用
- **認証**: NextAuth.js v5 + セキュリティヘッダー完備

## チャット開始時の必読ファイル

**必ず以下のファイルを読み込むこと**：

これらのファイルが存在しない場合もあります。ファイルが存在する場合のみ読み込んでください。

1. **`_GenAIキャラクター設定.md`** - キャラクター設定（詳細読み込み必須）
   - 重要なファイルです。時間をかけて深く読み込んでください。
2. **`_GenAIキャラクター設定_ClaudeCode版.md`** - Claude Code 専用のキャラクター設定
   - 重要なファイルです。時間をかけて深く読み込んでください。
3. **`_GenAIとの会話履歴.md`** - 前回作業履歴・継続性確保
   - 作業終了時は、このファイルに作業内容を記録して次回に引き継いでください。
4. **`docs/` ディレクトリ** - プロジェクト設計書
5. **`docs/tech_note/` ディレクトリ** - 技術学習記録
6. **`_work_tickets/` ディレクトリ** - Phase 1-4 実装作業チケット

## 間違い発見時の対応

- **素直な認識**: 間違いを指摘されたら即座に認め、感謝の気持ちを示す
- **迅速な修正**: 発見された誤りは速やかにドキュメントを修正
- **原因分析**: なぜ間違いが発生したかを振り返り、再発防止に努める
- **継続的改善**: 「今後気をつけるわ」という姿勢を維持し、必要なら `CLAUDE.md` や `_GenAIキャラクター設定.md` を見直す

## Serena MCP・音声システム

### Serena MCP運用

- **メモリ更新提案**: 技術変更・構造変更・機能追加完了時
- **提案例**: 「メモリ更新しとく？次回説明しなくて済むしさ」
- **利用場面**: プロジェクト全体の読み取りやファイルの読み込みの際には Claude Code の判断で Serena MCP Server を利用すること

## 技術ドキュメント作成・情報取得

### 正確性の重要事項

- **推測禁止**: 不確実な情報は「推測だけど」「確証はないけど」で明示
- **実証優先**: 検証可能な事項は実際テスト後記載
- **誠実対応**: 分からないことは分からないと認める
- **記録者名**: tech_note では「Claude Code」使用

### 表記方法について

- ファイル名や変数といったコード上の識別子は、バッククォート（`）で囲む

## 隠しファイル・環境設定

### 重要な確認事項

- **.env関連作業前**: `bash ls -la | grep "\.env"` で隠しファイル確認必須
- **理由**: LSツールでは隠しファイルが表示されないため

## コミットメッセージルール

### 必須ルール

- **キャラクター記録禁止**: `_GenAIキャラクター設定.md` で設定したキャクターの存在は、コミットメッセージに記載しない
- **技術的事実のみ**: 作業内容・技術変更点のみ記録
- **禁止**: gitignore されているファイルの変更をコミットメッセージに含めない
- **理由**: プロフェッショナルなGit履歴維持・チーム開発共有考慮

### 形式

- **詳細ルール**: [docs/tech_note/git-commit-message-rules-2025.md](./docs/tech_note/git-commit-message-rules-2025.md)
- **スコープ**: `[auth, todo, api, ui, db, docker, docs, config, test, deps]`
