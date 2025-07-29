-- データベース初期化スクリプト

-- 拡張機能の有効化
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- デフォルトカテゴリの作成（後でPrismaから管理するので、ここではテーブル作成準備のみ）
-- カテゴリとタスクのテーブルはPrismaのマイグレーションで作成される
