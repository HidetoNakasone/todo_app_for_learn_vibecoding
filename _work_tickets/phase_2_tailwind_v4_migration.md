# Phase 2: Tailwind CSS v4 導入・移行 (推定工数: 9-15日)

## 概要

Phase 3のUI開発開始前にTailwind CSS v4に移行する作業チケット。革新的な@themeディレクティブ、OKLCH色空間、パフォーマンス改善を導入し、UI開発の基盤を整える。

**技術スタック**: Next.js 15 + TypeScript + Docker + bun  
**実施タイミング**: Phase 1 (認証基盤) 完了後、Phase 3 (個人TODO機能UI開発) 開始前  
**優先度**: MUST (Phase 3以降のUI開発で@themeディレクティブ・新機能を活用するため必須)

## Phase A: 事前準備・調査 (1-2日)

### A.1 現状把握

- [ ] 現在のTailwind CSSバージョン確認
  ```bash
  bun list tailwindcss
  cat package.json | grep -E "(tailwind|postcss)"
  ```
- [ ] PostCSS設定の確認
  ```bash
  ls -la | grep -E "(postcss|tailwind)"
  cat postcss.config.js # 存在する場合
  ```
- [ ] カスタムCSS/Tailwind設定の調査
  - [ ] globals.css の内容確認
  - [ ] カスタムテーマ・ユーティリティ確認
  - [ ] 使用中のTailwindプラグイン調査
- [ ] shadcn/ui の導入状況確認
  - [ ] components.json の存在確認
  - [ ] 既存コンポーネントでの Tailwind クラス使用パターン調査

### A.2 依存関係・互換性チェック

- [ ] ブラウザサポート要件確認
  - [ ] Safari 16.4+, Chrome 111+, Firefox 128+ 対応可能か検証
  - [ ] プロジェクトのブラウザサポートポリシーとの照合
- [ ] 動的クラス名使用箇所の洗い出し
  ```bash
  # 動的クラス名のパターンを検索
  grep -r "bg-\${" src/
  grep -r "\`.*-\${.*}\`" src/
  ```
- [ ] 関連依存関係の影響調査
  ```bash
  bun list | grep -E "(tailwind|postcss|sass|css)"
  ```

### A.3 移行判断のための事前検証

- [ ] 公式アップグレードツールでの影響範囲確認
  ```bash
  npx @tailwindcss/upgrade --dry-run
  ```
- [ ] Breaking Changes の具体的影響評価
- [ ] 推定工数の再計算

## Phase B: 検証環境での試験導入 (2-3日)

### B.1 実験環境構築

- [ ] 検証専用ブランチ作成
  ```bash
  git checkout -b experiment/tailwindcss-v4-migration
  ```
- [ ] バックアップの作成
  ```bash
  git tag backup/before-tailwind-v4-migration
  ```

### B.2 v4パッケージ導入

- [ ] 既存Tailwind CSS関連パッケージの削除
  ```bash
  bun remove tailwindcss @tailwindcss/typography autoprefixer
  ```
- [ ] Tailwind CSS v4のインストール
  ```bash
  bun add -D tailwindcss@latest @tailwindcss/postcss postcss
  ```
- [ ] PostCSS設定の更新
  ```javascript
  // postcss.config.js
  export default {
    plugins: {
      "@tailwindcss/postcss": {},
    },
  };
  ```

### B.3 CSS設定ファイルの移行

- [ ] globals.cssの@importディレクティブ変更

  ```css
  /* 修正前 */
  @tailwind base;
  @tailwind components;
  @tailwind utilities;

  /* 修正後 */
  @import "tailwindcss";
  ```

- [ ] カスタムテーマの@theme移行
  ```css
  @theme {
    --color-primary-500: oklch(0.72 0.11 178);
    --color-secondary-500: oklch(0.6 0.15 280);
    --font-heading: "Inter", "system-ui", "sans-serif";
    --spacing-content: clamp(1rem, 5vw, 3rem);
  }
  ```

### B.4 検証項目の実行

- [ ] 開発サーバー起動確認
  ```bash
  bun run dev:https
  ```
- [ ] 既存ページの表示確認
  - [ ] ホームページ
  - [ ] 認証関連ページ (ログイン・ログアウト)
  - [ ] エラーページ
- [ ] ビルドプロセス動作確認
  ```bash
  bun run build
  ```
- [ ] バンドルサイズ測定・比較

## Phase C: 段階的移行実装 (3-5日)

### C.1 自動移行ツールの適用

- [ ] Tailwind公式アップグレードツール実行
  ```bash
  npx @tailwindcss/upgrade
  ```
- [ ] 変更内容の詳細確認
  ```bash
  git diff --name-only
  git diff
  ```
- [ ] 自動変更の妥当性検証

### C.2 手動修正が必要な箇所の対応

- [ ] 動的クラス名の修正

  ```typescript
  // ❌ 修正前 (v4では動作しない)
  const className = `bg-${color}-500`;

  // ✅ 修正後
  const colorClasses = {
    blue: "bg-blue-500",
    red: "bg-red-500",
    green: "bg-green-500",
  } as const;
  const className = colorClasses[color as keyof typeof colorClasses];
  ```

- [ ] カスタムCSS@layer使用箇所の調整
- [ ] 廃止されたユーティリティクラスの置換

### C.3 プロジェクト固有テーマシステム実装

- [ ] デザイントークンの@theme定義

  ```css
  @theme {
    /* ブランドカラー */
    --color-brand-primary: oklch(0.7 0.2 200);
    --color-brand-secondary: oklch(0.6 0.15 280);

    /* UI状態カラー */
    --color-success: oklch(0.7 0.15 145);
    --color-warning: oklch(0.8 0.15 85);
    --color-error: oklch(0.65 0.2 25);

    /* タイポグラフィ */
    --font-heading: "Inter", "system-ui", "sans-serif";
    --font-body: "Source Sans Pro", "sans-serif";

    /* スペーシング */
    --spacing-xs: 0.5rem;
    --spacing-sm: 1rem;
    --spacing-md: 1.5rem;
    --spacing-lg: 2rem;
    --spacing-xl: 3rem;
  }
  ```

- [ ] レスポンシブブレイクポイントの定義（必要に応じて）
- [ ] ダークモードテーマの実装（存在する場合）

### C.4 コンポーネント修正・最適化

- [ ] 既存コンポーネントでの新機能活用
- [ ] shadcn/ui コンポーネントのv4最適化
- [ ] CSS変数を活用した動的スタイリング実装

## Phase D: 品質保証・最適化 (2-3日)

### D.1 包括的テスト実行

- [ ] TypeScript型チェック
  ```bash
  bunx tsc --noEmit
  ```
- [ ] ESLint品質チェック
  ```bash
  bun run lint
  ```
- [ ] 全ページの視覚的確認
  - [ ] デスクトップ表示確認
  - [ ] モバイル表示確認
  - [ ] ダークモード確認（存在する場合）
- [ ] テストスイート実行（存在する場合）
  ```bash
  bun run test
  ```

### D.2 パフォーマンス測定・比較

- [ ] ビルド後バンドルサイズ測定
  ```bash
  bun run build
  ls -lah .next/static/css/
  ```
- [ ] ビルド時間の測定・記録
- [ ] 開発サーバー起動時間の測定
- [ ] First Contentful Paint (FCP) 測定
  - [ ] Chrome DevTools Lighthouse実行
  - [ ] Core Web Vitals確認

### D.3 shadcn/ui互換性・統合確認

- [ ] shadcn/ui最新バージョン確認
  ```bash
  pnpm dlx shadcn@latest --version
  ```
- [ ] 必要に応じてshadcn/uiコンポーネント更新
  ```bash
  pnpm dlx shadcn@latest add button --overwrite
  pnpm dlx shadcn@latest add card --overwrite
  ```
- [ ] 新しいTailwind CSS v4機能との統合テスト

## Phase E: 本番導入準備 (1-2日)

### E.1 最終確認・品質チェック

- [ ] 全機能の動作確認
  - [ ] 認証フロー (GitHub・Google OAuth)
  - [ ] セッション管理
  - [ ] エラーハンドリング
  - [ ] セキュリティヘッダー
- [ ] アクセシビリティ確認
  - [ ] キーボードナビゲーション
  - [ ] スクリーンリーダー対応
  - [ ] カラーコントラスト比確認

### E.2 ドキュメント・環境整備

- [ ] README.mdの更新
  - [ ] Tailwind CSS v4導入について記載
  - [ ] セットアップ手順の更新
- [ ] 開発環境セットアップスクリプト更新
  ```bash
  # setup-dev.sh に必要に応じて追記
  ```
- [ ] .env.exampleの確認・更新（環境依存がある場合）

### E.3 チーム共有・引き継ぎ準備

- [ ] 移行内容の技術ドキュメント作成
  - [ ] @themeディレクティブの使用方法
  - [ ] OKLCH色空間の活用方法
  - [ ] 動的クラス名の制限と対処法
- [ ] トラブルシューティングガイド作成
- [ ] 履歴ファイルへの作業記録

  ```markdown
  # \_GenAIとの会話履歴.md への追記

  ### 2025-08-XX Tailwind CSS v4移行完了

  - @themeディレクティブ・OKLCH色空間導入
  - パフォーマンス改善: バンドルサイズXX%削減
  - 開発体験向上: 新機能活用パターン確立
  ```

## 移行時の重要注意事項

### Breaking Changes 対応

1. **@tailwindディレクティブ完全廃止**
   - すべて `@import "tailwindcss";` に統一
2. **JavaScript設定からCSS設定への移行**
   - tailwind.config.js → @theme CSS ディレクティブ
3. **ブラウザサポート変更**
   - Safari 16.4+, Chrome 111+, Firefox 128+ が必須
   - プロジェクト要件との整合性確認

### リスク軽減策

- [ ] **段階的デプロイ**: 機能フラグでの部分的導入検討
- [ ] **ロールバック計画**: git tagでの即座復旧準備
- [ ] **モニタリング体制**: パフォーマンス指標の継続監視

## 完了判定基準

### 導入成功の条件

- [ ] すべての既存機能が正常動作する
- [ ] パフォーマンス改善が確認される（バンドルサイズ削減・ビルド時間短縮）
- [ ] 新しい@theme機能が適切に活用されている
- [ ] 開発体験が改善されている（新機能による効率化）

### 導入見送りの条件

- [ ] 重大な互換性問題が解決できない
- [ ] パフォーマンス劣化が確認される
- [ ] 移行コストが予想以上に高く、ROIが見込めない

## 推定工数・担当

| Phase    | 作業内容             | 推定工数   | 担当者 |
| -------- | -------------------- | ---------- | ------ |
| Phase A  | 事前準備・調査       | 1-2日      | hep    |
| Phase B  | 検証環境での試験導入 | 2-3日      | hep    |
| Phase C  | 段階的移行実装       | 3-5日      | hep    |
| Phase D  | 品質保証・最適化     | 2-3日      | hep    |
| Phase E  | 本番導入準備         | 1-2日      | hep    |
| **合計** | **全プロセス**       | **9-15日** | -      |

## 実施タイミング

1. **Phase 1完了後**: NextAuth.js v5認証基盤完了後
2. **Phase 3開始前**: 個人TODO機能のUI開発開始前に必須
3. **理由**: Phase 3以降でTaskCard、TaskForm、TaskList等のコンポーネントを@themeディレクティブとOKLCH色空間で最初から構築するため

---

**Phase 2 優先度**: MUST  
**長期的価値**: HIGH （開発体験・パフォーマンス・保守性の大幅改善）  
**実装判断**: Phase 3 UI開発の前提条件として必須実施
