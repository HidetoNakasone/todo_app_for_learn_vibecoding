module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    // 日本語を許可
    "subject-case": [0, "never"],
    // 本文の最大文字数を調整
    "body-max-line-length": [2, "always", 100],
    // scope の列挙（プロジェクト固有）
    "scope-enum": [
      2,
      "always",
      [
        "auth", // 認証機能
        "todo", // TODO機能
        "api", // API関連
        "ui", // UI/UX
        "db", // データベース
        "docker", // Docker設定
        "docs", // ドキュメント
        "config", // 設定ファイル
        "test", // テスト
        "deps", // 依存関係
      ],
    ],
  },
};
