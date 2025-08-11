# Web セキュリティ詳細学習記録

**記録者**: Claude Code  
**記録日**: 2025-08-11  
**対象プロジェクト**: TODO アプリ Phase 1 セキュリティ実装

## 学習概要

Phase 1 セキュリティ強化作業を通じて、Web セキュリティの重要な概念と実装方法について深く学習した。NextAuth.js v5 のセッション設定、CSRF 攻撃対策、セキュリティヘッダーの詳細実装を行い、理論と実践の両面から理解を深めた。

## 主要学習内容

### 1. NextAuth.js v5 セッション設定の詳細

#### セッション設定の最適化
- **maxAge**: 7日間（604800秒）に設定
- **updateAge**: 4時間（14400秒）に設定
- **strategy**: "database" - Prisma Adapter使用時

#### 重要な発見：クッキーセキュリティの判定ロジック

**誤った理解の修正**:
- 当初、NextAuth.js が `NODE_ENV` を基に secure cookies を判定すると誤解
- 実際は `url.protocol === "https:"` で判定している

**実際のコード**（`/node_modules/@auth/core/lib/init.js:69`）:
```javascript
cookies: merge(
  cookie.defaultCookies(
    config.useSecureCookies ?? url.protocol === "https:"
  ), 
  config.cookies
),
```

**学んだ教訓**:
- 推測による技術説明は危険
- 実際のソースコードを確認する重要性
- 不確実な情報は明示的に区別すべき

### 2. CSRF（Cross-Site Request Forgery）攻撃の理解

#### CSRF 攻撃の基本メカニズム
1. ユーザーが信頼できるサイト A にログイン
2. 悪意のあるサイト B がサイト A への不正なリクエストを作成
3. ユーザーのブラウザが自動的に A のクッキーを送信
4. A のサーバーが正当なリクエストと誤認して処理

#### XSS + CSRF 複合攻撃の脅威
- **XSS攻撃**: DOM を操作してCSRFトークンを取得
- **組み合わせた攻撃**: 取得したトークンを使って CSRF 攻撃を実行
- **対策の多層防御**: トークンベース + SameSite Cookie + Origin 検証

#### NextAuth.js の CSRF 対策
- 自動的な CSRF トークン生成・検証
- `__Host-authjs.csrf-token` クッキーの使用
- POST リクエストでのトークン検証

### 3. セキュリティヘッダーの実装と理解

#### Content Security Policy (CSP) の詳細設定

```typescript
"Content-Security-Policy": [
  "default-src 'self'",
  "script-src 'self'" + (process.env.NODE_ENV === "development" ? " 'unsafe-eval'" : ""),
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: https:",
  "font-src 'self' data:",
  "connect-src 'self'",
  "frame-ancestors 'none'",
  "base-uri 'self'",
  "form-action 'self'",
  "object-src 'none'",
  "media-src 'self'"
].join("; ")
```

**設計上の決定と妥協点**:
- `unsafe-eval`: 開発環境でのホットリロード対応
- `unsafe-inline`: CSS-in-JS フレームワーク対応（リスクは認識）
- `img-src https:`: 外部 HTTPS 画像の柔軟性
- セキュリティと開発効率のバランス

#### Permissions Policy の設定
不要なブラウザ機能を明示的に無効化:
```typescript
"Permissions-Policy": [
  "camera=()", "microphone=()", "geolocation=()",
  "payment=()", "usb=()", "magnetometer=()",
  "gyroscope=()", "accelerometer=()", "bluetooth=()",
  "midi=()", "notifications=()", "push=()",
  "speaker-selection=()", "sync-xhr=()",
  "fullscreen=(self)", "web-share=(self)"
].join(", ")
```

#### HSTS (Strict-Transport-Security) の期間設定

**議論した設定値**:
- **大手企業**: 1年間（31536000秒）
- **個人プロジェクト**: 3ヶ月（7776000秒）に決定

**決定理由**:
- ドメイン所有の一時性を考慮
- セキュリティと運用柔軟性のバランス
- 転送時のリスク軽減

### 4. 基本セキュリティヘッダーの役割

- **X-Frame-Options: DENY**: クリックジャッキング攻撃防止
- **X-Content-Type-Options: nosniff**: MIME type 推測攻撃防止
- **Referrer-Policy: origin-when-cross-origin**: リファラー情報制御
- **X-DNS-Prefetch-Control: off**: DNS 先読み無効化（本番環境のみ）

## 実装ファイルと変更点

### 修正されたファイル

#### `/app/src/auth.ts`
```typescript
session: {
  strategy: "database",
  maxAge: 7 * 24 * 60 * 60, // 7 days
  updateAge: 4 * 60 * 60, // 4 hours
},
```

#### `/app/next.config.ts`
- 包括的なセキュリティヘッダー実装
- 環境別設定（開発・本番）
- 詳細なコメントによる設定理由の記録

#### `/app/_work_tickets/phase_1_auth_foundation.md`
- 完了条件の明確化（必須・推奨の分類）
- セキュリティ項目の完了状況更新

## 技術調査方法と情報源

### 使用した調査ツール
- **Gemini MCP Server**: CSRF 攻撃に関する日本語記事検索
- **Claude WebSearch**: 技術情報の補完確認
- **ソースコード直接確認**: NextAuth.js の実装詳細調査

### 参考情報源
- Qiita での CSRF 攻撃解説記事
- NextAuth.js v5 公式ドキュメント
- MDN Web セキュリティガイド
- OWASP セキュリティ指針

## 学んだベストプラクティス

### 技術調査における原則
1. **推測の明示**: 不確実な情報は必ず前置きする
2. **ソースコード確認**: 重要な仕様は実装を直接確認
3. **多層防御**: 単一の対策に依存しない設計
4. **バランス重視**: セキュリティと実用性の適切な妥協点

### セキュリティ実装の考え方
1. **段階的強化**: 基本対策から順次拡張
2. **環境別設定**: 開発・本番での適切な設定分離
3. **文書化重視**: 設定理由の明確な記録
4. **継続的見直し**: 要件変化に応じた設定更新

## 今後の課題と改善点

### セキュリティの継続的改善
- CSP 設定の段階的厳格化
- セキュリティヘッダーの定期的見直し
- 脆弱性スキャンの定期実行
- セキュリティベストプラクティスの追跡

## まとめ

今回の学習を通じて、Web セキュリティは単なるチェックリスト作業ではなく、攻撃手法の理解と適切な対策選択が重要であることを深く理解した。特に、技術的な推測による説明の危険性と、実際のコードを確認することの重要性を痛感した。

個人プロジェクトであっても、基本的なセキュリティ対策を怠らず、かつ過度に複雑化しない適切なバランスを保つことが、実用的で安全なアプリケーション開発につながると確信している。