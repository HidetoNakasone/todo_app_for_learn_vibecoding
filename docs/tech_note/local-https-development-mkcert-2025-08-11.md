# ローカルHTTPS開発環境構築ガイド（mkcert版）

**記録者**: Claude Code  
**記録日**: 2025-08-11  
**対象プロジェクト**: TODO アプリ開発環境HTTPS化

## 概要

Next.js開発環境でHTTPSを有効にし、セキュリティヘッダーやCookieの動作を実際のHTTPS環境でテストできるようにする。mkcertを使用することで、ブラウザに信頼される証明書を簡単に作成する。

## mkcertの利点

- ブラウザが信頼する証明書を自動生成
- 面倒な設定ファイル不要
- macOS Keychain、Linux証明書ストア自動対応
- 開発専用に最適化

## mkcert導入手順

### 1. mkcertインストール

#### macOS

```bash
brew install mkcert
```

#### Ubuntu/Debian

```bash
sudo apt install libnss3-tools
curl -s https://api.github.com/repos/FiloSottile/mkcert/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4 | wget -qi -
chmod +x mkcert-v*-linux-amd64
sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert
```

#### Windows

```powershell
choco install mkcert
```

### 2. ローカル認証局（CA）セットアップ

#### 基本セットアップ

```bash
# ローカルCAを作成してシステムに追加
mkcert -install
```

#### macOSでのFirefox対応

```bash
# Firefox用のnssツールインストール
brew install nss

# CA設定を再実行（Firefox対応）
mkcert -install
```

**実行結果例**:

```
Created a new local CA 💥
The local CA is now installed in the system trust store! ⚡️
Warning: "certutil" is not available, so the CA can't be automatically installed in Firefox! ⚠️
Install "certutil" with "brew install nss" and re-run "mkcert -install" 👈
```

**nss追加後の実行結果**:

```
The local CA is already installed in the system trust store! 👍
The local CA is now installed in the Firefox trust store (requires browser restart)! 🦊
```

#### ブラウザ別対応状況

- ✅ **Chrome/Safari**: 基本の `mkcert -install` で即座に対応
- ✅ **Firefox**: `brew install nss` 後に `mkcert -install` で対応（ブラウザ再起動必要）

### 3. 開発用証明書作成

```bash
# プロジェクトのcertsディレクトリで実行
cd /path/to/project/certs

# 複数ドメイン・IPアドレス対応証明書作成
mkcert hep.local localhost 127.0.0.1 ::1

# 生成されるファイル:
# - hep.local+3.pem (証明書)
# - hep.local+3-key.pem (秘密鍵)
```

### 4. ファイル名を統一

```bash
# プロジェクト用にリネーム
mv hep.local+3.pem hep-local.crt
mv hep.local+3-key.pem hep-local.key
```

## プロジェクトでの設定

### 1. 証明書ファイル配置

```bash
# プロジェクトのcertsディレクトリに配置
cp hep-local.crt /app/docker/app/certs/
cp hep-local.key /app/docker/app/certs/

cd /app/docker/app/certs/

# 適切な権限設定
chmod 600 hep-local.key
chmod 644 hep-local.crt
```

### 2. package.json設定

```json
{
  "scripts": {
    "dev": "next dev --turbopack",
    "dev:https": "next dev --turbopack --experimental-https --experimental-https-key ./docker/app/certs/hep-local.key --experimental-https-cert ./docker/app/certs/hep-local.crt"
  }
}
```

### 3. hosts設定（macOS/Linux）

```bash
# /etc/hostsに追加
echo "127.0.0.1 hep.local" | sudo tee -a /etc/hosts

# 設定確認
cat /etc/hosts | grep hep.local
ping hep.local  # 127.0.0.1 に解決されることを確認
```

### 4. 環境変数設定

`.env` ファイルの次の設定値を更新する

```bash
NEXTAUTH_URL=https://hep.local:3000
```

## HTTPS開発サーバー起動

### 起動コマンド

```bash
# スクリプト使用（推奨）
bun run dev:https

# 直接実行
bun next dev --turbopack --experimental-https --experimental-https-key ./docker/app/certs/hep-local.key --experimental-https-cert ./docker/app/certs/hep-local.crt
```

### 起動確認

```
▲ Next.js 15.4.3 (Turbopack)
- Local:        https://localhost:3000
- Network:      https://172.20.0.3:3000
- Environments: .env

✓ Ready in 785ms
⚠ Self-signed certificates are currently an experimental feature, use with caution.
```

「自己証明書の読み込みは試験的な機能です」と言われるが開発環境なので大丈夫

## 動作確認

### アクセスURL

- ✅ `https://hep.local:3000` （推奨・メイン）
- ✅ `https://localhost:3000`
- ✅ `https://127.0.0.1:3000`

### ブラウザでの確認事項

1. **証明書警告なし**: mkcertで作成した証明書はブラウザが信頼
2. **セキュアコンテキスト**: HTTPSでのみ動作するAPI（Service Worker等）が利用可能
3. **セキュリティヘッダー確認**: ブラウザ開発者ツールでCSP等のヘッダー動作確認
4. **Cookie設定確認**: Secure属性付きCookieの動作確認

### 証明書信頼エラー

```bash
# CA再インストール
mkcert -uninstall
mkcert -install
```

### hosts解決失敗

```bash
# DNS キャッシュクリア（macOS）
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

## セキュリティ考慮事項

### 本番環境との違い

- **開発専用**: mkcert証明書は本番環境で使用不可
- **ローカル限定**: 作成したCAは開発マシンでのみ有効
- **自動有効期限**: mkcertは適切な有効期限を自動設定

### 証明書管理

- **秘密鍵保護**: `.key`ファイルはgitignoreに追加必須
- **定期更新**: 長期開発時は証明書の定期的な再作成推奨
- **クリーンアップ**: プロジェクト終了時は証明書削除

## まとめ

mkcertを使用することで、ローカルHTTPS開発環境を簡単かつ確実に構築できる。特に：

1. **開発効率向上**: 証明書エラーでの開発中断がない
2. **実環境テスト**: セキュリティヘッダーやSecure Cookie等の実際の動作確認
3. **チーム統一**: 全開発者が同じ手順で同一環境構築可能

開発環境でのHTTPS化には最適な選択肢である。
