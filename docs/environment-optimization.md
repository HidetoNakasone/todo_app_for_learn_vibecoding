# Docker 環境での開発最適化と OneDrive 対応

## 概要

このプロジェクトでは、Docker Anonymous Volume を使用して生成ファイルとキャッシュファイルをホスト環境から分離しています。これにより、環境の安定性確保、バイナリ競合の回避、そして開発環境（OneDrive 同期環境）での負荷軽減を実現しています。

## 解決すべき課題

### 1. 環境間でのバイナリ競合

- **問題**: OS 固有のバイナリファイル（.so.node, .dylib, .dll 等）が混在する
- **影響**: 開発環境（Mac/Windows）と本番環境（Linux）でバイナリが競合、実行時エラーの原因
- **対象**: node_modules 内の native modules、Prisma 生成バイナリ

### 2. 環境依存ファイルの混在

- **問題**: 環境・時間依存のキャッシュやメタデータが永続化される
- **影響**: 異なる環境で不適切なキャッシュが使われ、予期しない動作の原因
- **対象**: Next.js ビルドキャッシュ（.next）、Prisma クライアント生成物

### 3. 開発環境での同期負荷（OneDrive 環境固有）

- **問題**: 大量ファイル（数万〜数十万）の同期処理
- **影響**: OneDrive の同期負荷、ローカルストレージ容量の圧迫
- **対象**: node_modules、生成ファイル、キャッシュファイル

## 解決策: Docker Anonymous Volume による環境分離

### 実装方法

Docker Compose の anonymous volume 機能を使用して、対象ディレクトリをホストファイルシステム（OneDrive 同期対象）から分離します。

```yaml
# compose.yaml & compose.prd.yaml
services:
  app:
    volumes:
      - .:/app # プロジェクトルートをマウント
      - node_modules:/app/node_modules # node_modules を分離
      - generated:/app/src/generated # Prisma生成ファイルを分離
      - next_build:/app/.next # Next.jsキャッシュを分離
      - serena_data:/app/.serena # Serena MCP Server キャッシュを分離

volumes:
  node_modules: # anonymous volume
  generated: # anonymous volume
  next_build: # anonymous volume
  serena_data: # anonymous volume
```

### 動作原理

1. **コンテナ内専用領域**: anonymous volume により、対象ディレクトリがコンテナ内専用の領域に作成される
2. **OneDrive 除外**: ホストファイルシステムに存在しないため、OneDrive の同期対象外になる
3. **自動再生成**: 各セットアップスクリプトで必要なファイルが自動生成される

## セットアップスクリプトでの対応

### 開発環境 (setup-dev.sh)

```bash
# Prisma セットアップ
docker compose -f compose.yaml exec app sh -c 'bun prisma migrate dev'
docker compose -f compose.yaml exec app sh -c 'bun prisma generate'  # Prisma Client を生成
```

### 本番環境 (setup-prd.sh)

```bash
# Prisma セットアップ
docker compose -f compose.prd.yaml exec app sh -c 'bun prisma migrate deploy'
docker compose -f compose.prd.yaml exec app sh -c 'bun prisma generate'  # Prisma Client を生成
```

## 効果

### 1. 環境安定性の向上（全環境共通）

- **バイナリ競合の回避**: OS 固有のバイナリファイルが混在しない
- **環境分離**: 開発・本番環境でそれぞれ適切なファイルが生成される
- **クリーンな状態**: 環境構築のたびに clean な状態から開始
- **実行時エラー防止**: 不適切なバイナリによるクラッシュを防止

### 2. 本番環境での効果

- **安定したデプロイ**: Linux 環境専用のバイナリで確実に動作
- **ストレージ効率**: 不要なキャッシュファイル蓄積の防止
- **パフォーマンス**: 環境に最適化されたファイルでの動作

### 3. OneDrive 開発環境での追加効果

- **同期負荷軽減**: 数万ファイルの同期対象除外
- **同期速度向上**: 大容量ディレクトリの除外による高速化
- **容量削減**: 不要なバイナリファイルやキャッシュの除外

## 対象ディレクトリ一覧

| ディレクトリ     | 役割                     | 再生成方法            | 分離理由                   |
| ---------------- | ------------------------ | --------------------- | -------------------------- |
| `node_modules/`  | パッケージ依存関係       | `bun install`         | 大量ファイル、バイナリ競合 |
| `src/generated/` | Prisma 生成ファイル      | `bun prisma generate` | バイナリファイル、環境依存 |
| `.next/`         | Next.js ビルドキャッシュ | `bun run build/dev`   | キャッシュ、時間・環境依存 |
| `.serena/`       | Serena MCP 設定・メモリ  | オンボーディング実行  | 個人環境依存、キャッシュ   |

## メンテナンス

### 既存環境での適用方法

**セットアップ用スクリプトの実行**:

```bash
# 開発環境
bash ./scripts/setup-dev.sh

# 本番環境
bash ./scripts/setup-prd.sh
```

## 備考

この環境分離設定により、以下の利点が得られます：

### 全環境共通

- 環境間でのバイナリ競合を根本的に解決
- 各環境に最適化されたファイルでの安定動作
- DevOps ベストプラクティスの実現

### 開発環境特有（OneDrive 等のクラウドストレージ使用時）

- クラウド同期負荷の大幅軽減
- 他のクラウドストレージサービス（Google Drive、Dropbox 等）でも同様の効果

この設計により、本番環境の安定性と開発環境の快適性を両立しています。
