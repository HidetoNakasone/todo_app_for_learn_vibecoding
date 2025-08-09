# Git コミットメッセージルール 2025

記録日: 2025-08-09  
記録者: Claude Code

## 概要

プロジェクトで使用する Git コミットメッセージの統一ルールを定義。業界標準の **Conventional Commits** 準拠で、自動化ツールとの連携も考慮。

## Conventional Commits とは

- **公式サイト**: https://www.conventionalcommits.org/
- **目的**: 人間と機械の両方が読みやすいコミットメッセージ標準
- **利点**: 自動リリースノート生成、セマンティックバージョニング、履歴検索性向上

## 基本書式

```
<type>(<scope>): <description>

<optional body>

<optional footer>
```

### ルール詳細

- **1行目**: 50文字以内を目安
- **本文**: 72文字で改行、空行で区切る
- **動詞**: 命令形を使用（"Fix bug" not "Fixed bug"）
- **言語**: 日本語または英語（プロジェクトで統一）

## Prefix Types（必須）

### コア prefixes
- `feat:` - 新機能追加
- `fix:` - バグ修正
- `docs:` - ドキュメント変更のみ
- `refactor:` - 機能を変えないコード整理

### サポート prefixes  
- `style:` - フォーマット・空白調整（機能変更なし）
- `test:` - テスト追加・修正
- `chore:` - ツール・設定・メンテナンス作業
- `build:` - ビルドシステム・依存関係変更
- `ci:` - CI/CD パイプライン変更

## Scope（オプション）

機能モジュールやファイル名で範囲を限定：

```bash
feat(auth): ユーザーログイン機能を追加
fix(api): タスク削除時の404エラーを修正  
docs(readme): セットアップ手順を更新
refactor(components): TaskCard を分離
```

## 破壊的変更（Breaking Changes）

### 方法1: Type に `!` を追加
```bash
feat!: APIレスポンス形式を変更（破壊的変更）
```

### 方法2: Footer に明記
```bash
feat: 新認証システム導入

BREAKING CHANGE: 旧APIトークンは無効になります
```

## 実用例

### 良い例 ✅
```bash
feat(todo): タスク優先度設定機能を追加
fix(auth): ログイン時のセッション切れを修正
docs: README.mdの重複内容を整理  
refactor(api): エラーハンドリングを統一
style: ESLint ルールに従ってフォーマット調整
test: TaskCard コンポーネントのテストを追加
chore: TypeScript を 5.3 に更新
build: Docker イメージの軽量化
ci: GitHub Actions でテスト自動化
```

### 悪い例 ❌
```bash
Fixed login bug (動詞が過去形)
Add new feature (prefix なし)
Updated documentation (曖昧すぎる)
WIP: work in progress (作業中コミット)
```

## 自動化ツール（推奨）

### commitlint + husky
```bash
# インストール
npm install --save-dev @commitlint/config-conventional @commitlint/cli
npm install --save-dev husky

# 設定ファイル
echo "module.exports = {extends: ['@commitlint/config-conventional']}" > commitlint.config.js

# Git フック設定
npx husky install
npx husky add .husky/commit-msg 'npx --no -- commitlint --edit ${1}'
```

### Commitizen（対話式コミット）
```bash
npm install --save-dev commitizen cz-conventional-changelog
npx commitizen init cz-conventional-changelog --save-dev --save-exact
```

## 履歴検索活用

```bash
# 新機能のみを検索
git log --grep="feat:"

# バグ修正のみを検索  
git log --grep="fix:"

# 特定スコープの変更を検索
git log --grep="feat(auth):"

# 破壊的変更を検索
git log --grep="BREAKING CHANGE"
```

## プロジェクト適用方針

1. **段階的導入**: 既存履歴はそのまま、新規コミットから適用
2. **チーム教育**: ルール共有とツール使い方のレクチャー
3. **自動チェック**: commitlint でルール違反を防止
4. **リリース自動化**: conventional-changelog でリリースノート生成

## セットアップ済み環境での使用方法

### 新しいチームメンバーの環境構築

```bash
# 1. リポジトリをクローン
git clone <repository-url>
cd todo-app

# 2. 依存関係をインストール（自動的にコミットツールもセットアップ）
bun install

# これで commitlint + husky + commitizen が自動設定完了！
```

### 日常的なコミット方法

#### 方法1: Commitizen を使用（推奨）
```bash
# ステージング
git add .

# 対話式コミット作成
bun run commit
# または
bunx cz

# 質問に答えるだけで正しいコミットメッセージが作成される
```

#### 方法2: 手動でルールに従う
```bash
git commit -m "feat(todo): タスク優先度設定機能を追加"
# commitlint が自動チェック。ルール違反なら拒否される
```

### コミットルールの詳細

#### 利用可能な scope（プロジェクト固有）
- `auth` - 認証機能
- `todo` - TODO機能  
- `api` - API関連
- `ui` - UI/UX
- `db` - データベース
- `docker` - Docker設定
- `docs` - ドキュメント
- `config` - 設定ファイル
- `test` - テスト
- `deps` - 依存関係

#### コミットメッセージ例
```bash
feat(auth): ユーザーログイン機能を追加
fix(api): タスク削除時の404エラーを修正
docs: コミットルールドキュメントを作成
refactor(ui): TaskCard コンポーネントを分離
test(todo): タスク作成機能のテストを追加
```

### トラブルシューティング

#### コミットが拒否された場合
```bash
❌ commitlint failed:
⧗   input: add new stuff
✖   type must be one of [feat, fix, docs, style, refactor, test, chore, build, ci]

# 解決: 正しい形式で再コミット
git commit -m "feat(todo): 新機能を追加"
```

#### husky が動作しない場合
```bash
# husky を再初期化
bunx husky install
chmod +x .husky/commit-msg
```

## 参考資料

- [Conventional Commits 公式](https://www.conventionalcommits.org/)
- [commitlint ドキュメント](https://commitlint.js.org/)
- [Angular Git Commit Guidelines](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit)
- [Semantic Release](https://semantic-release.gitbook.io/)

## 更新履歴

- 2025-08-09: 初版作成（業界標準調査・ルール策定）