import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async headers() {
    return [
      {
        // すべてのルートにセキュアヘッダーを適用
        source: "/(.*)",
        headers: [
          // ==================== 基本セキュリティヘッダー ====================

          // クリックジャッキング攻撃を防ぐ（iframe埋め込み完全禁止）
          {
            key: "X-Frame-Options",
            value: "DENY",
          },

          // ブラウザのMIME type推測を無効化（XSS攻撃防止）
          {
            key: "X-Content-Type-Options",
            value: "nosniff",
          },

          // リファラー情報の制御（外部サイトにはドメイン名のみ送信）
          {
            key: "Referrer-Policy",
            value: "origin-when-cross-origin",
          },

          // ==================== Content Security Policy ====================

          // 厳格なコンテンツセキュリティポリシー（XSS攻撃の根本的防止）
          {
            key: "Content-Security-Policy",
            value: [
              "default-src 'self'", // 基本: 自分のドメインからのリソースのみ許可
              "script-src 'self'" +
                (process.env.NODE_ENV === "development"
                  ? " 'unsafe-eval'"
                  : ""), // JS: 自分のドメイン + 開発環境ではeval許可(ホットリロードで利用)
              "style-src 'self' 'unsafe-inline'", // CSS: 自分のドメイン + インライン許可 (style属性に攻撃を仕込まれる可能性はあるが、SPAではstyle属性使うこと多いので妥協)
              "img-src 'self' data: https:", // 画像: 3つ許可。自分のドメイン, data(Base64 Encode Image), HTTPS(外部HTTPS画像)。反対にHTTPは禁止
              "font-src 'self' data:", // フォント: 自分のドメイン + data URL
              "connect-src 'self'", // AJAX/fetch: 自分のドメインへの通信のみ
              "frame-ancestors 'none'", // iframe埋め込み完全禁止（X-Frame-Options の強化版）
              "base-uri 'self'", // <base>タグ: 自分のドメインのみ
              "form-action 'self'", // フォーム送信: 自分のドメインのみ
              "object-src 'none'", // <object>, <embed>タグ: 完全禁止
              "media-src 'self'", // 音声・動画: 自分のドメインのみ
            ].join("; "),
          },

          // ==================== Permissions Policy ====================

          // ブラウザ機能の制限（本アプリに不要な機能について、明示的に無効化を伝える。XSS対策）
          {
            key: "Permissions-Policy",
            value: [
              "camera=()", // カメラアクセス禁止
              "microphone=()", // マイクアクセス禁止
              "geolocation=()", // 位置情報アクセス禁止
              "payment=()", // 支払いAPI禁止
              "usb=()", // USB機器アクセス禁止
              "magnetometer=()", // 磁気センサー禁止
              "gyroscope=()", // ジャイロスコープ禁止
              "accelerometer=()", // 加速度センサー禁止
              "bluetooth=()", // Bluetooth禁止
              "midi=()", // MIDI機器アクセス禁止
              "notifications=()", // プッシュ通知禁止
              "push=()", // プッシュメッセージ禁止
              "speaker-selection=()", // スピーカー選択禁止
              "sync-xhr=()", // 同期XMLHttpRequest禁止
              "fullscreen=(self)", // フルスクリーン: 自分のドメインのみ許可
              "web-share=(self)", // Web Share API: 自分のドメインのみ許可
            ].join(", "),
          },

          // ==================== 本番環境専用セキュリティヘッダー ====================

          // HTTPS強制（本番環境のみ）- 開発環境ではlocalhostで問題になるため除外
          ...(process.env.NODE_ENV === "production"
            ? [
                {
                  key: "Strict-Transport-Security",
                  value: "max-age=7776000; includeSubDomains; preload", // 3ヶ月間HTTPS強制 + サブドメイン + HSTS preload list登録
                },
                {
                  key: "X-DNS-Prefetch-Control",
                  value: "off", // DNS先読み無効化（プライバシー保護）
                },
              ]
            : []),
        ],
      },
    ];
  },
};

export default nextConfig;
