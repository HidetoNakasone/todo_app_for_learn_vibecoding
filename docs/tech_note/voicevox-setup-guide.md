# VOICEVOX 音声システム 完全活用ガイド

**作成日**: 2025-08-09  
**記録者**: Claude Code  
**更新履歴**:
- 2025-08-09: 詳細な使用法・設定・活用例を追加した完全版に更新

## プロジェクト起動手順

### 自動セットアップ（推奨）

```bash
# 開発環境セットアップと同時に音声システムも設定
bash scripts/setup-dev.sh

# 対話式で「VOICEVOX 音声システムを起動しますか？(y/N)」に y で回答
```

### 手動起動

```bash
# VOICEVOX 音声システム起動
nohup bash scripts/start-voicevox-system.sh &

# Claude Code 起動
claude

# システム停止
bash scripts/stop-voicevox-system.sh
```

## 基本的な音声生成コマンド

### 1. 音声ファイル生成 + 自動再生

```bash
mcp__voicevox__synthesize_file "/app/output.wav" "読み上げたいテキスト" [話者ID] [再生速度]
```

**例**:
```bash
# 基本的な使用法（四国めたん:ノーマル）
mcp__voicevox__synthesize_file "/app/hello.wav" "こんにちは、世界！" 2

# 速度調整（0.5倍速でゆっくり）
mcp__voicevox__synthesize_file "/app/slow.wav" "ゆっくり話します" 2 0.5

# 早口（2倍速）
mcp__voicevox__synthesize_file "/app/fast.wav" "早口で話します" 2 2.0
```

### 2. 話者一覧の確認

```bash
mcp__voicevox__get_speakers
```

### 3. 音声再生停止

```bash
mcp__voicevox__stop_speaker "dummy"
```

## 話者キャラクター完全ガイド

### 人気キャラクター

#### 四国めたん（関西弁系）
- **ノーマル**: `speaker: 2` - 標準的な話し方
- **あまあま**: `speaker: 0` - 甘えた話し方  
- **ツンツン**: `speaker: 6` - ツンデレな話し方
- **セクシー**: `speaker: 4` - 大人っぽい話し方
- **ささやき**: `speaker: 36` - 小声でささやく
- **ヒソヒソ**: `speaker: 37` - 内緒話風

#### ずんだもん（東北弁系）
- **ノーマル**: `speaker: 3` - 標準的な話し方
- **あまあま**: `speaker: 1` - 甘えた話し方
- **ツンツン**: `speaker: 7` - ツンデレな話し方
- **セクシー**: `speaker: 5` - 大人っぽい話し方
- **ヘロヘロ**: `speaker: 75` - 疲れた感じ
- **なみだめ**: `speaker: 76` - 泣いている感じ

#### 東北三姉妹
- **東北ずん子**: `speaker: 107` - 東北弁の姉
- **東北きりたん**: `speaker: 108` - 東北弁の妹
- **東北イタコ**: `speaker: 109` - 霊媒師キャラ

#### その他の特徴的なキャラクター
- **春日部つむぎ**: `speaker: 8` - 落ち着いた女性
- **九州そら**: `speaker: 16` - 九州弁系女性
- **No.7**: `speaker: 29` - ロボット系（アナウンス向き）

### 感情・用途別話者選択

#### コーディング用途別音声

**成功通知**:
```bash
# 喜びの表現
mcp__voicevox__synthesize_file "/app/success.wav" "ビルド成功！" 32  # 白上虎太郎:わーい
mcp__voicevox__synthesize_file "/app/success.wav" "テスト通過！" 79  # もち子さん:喜び
```

**エラー通知**:
```bash
# 悲しみ・絶望の表現
mcp__voicevox__synthesize_file "/app/error.wav" "エラーが発生しました" 98   # 中部つるぎ:絶望と敗北
mcp__voicevox__synthesize_file "/app/error.wav" "コンパイルエラー" 41      # 玄野武宏:悲しみ
```

**デバッグ・説明用**:
```bash
# 冷静な解説
mcp__voicevox__synthesize_file "/app/explain.wav" "バグの原因を説明します" 31  # No.7:読み聞かせ
mcp__voicevox__synthesize_file "/app/debug.wav" "プロセスを実況します" 93     # ぞん子:実況風
```

**アラート・警告**:
```bash
# 注意喚起
mcp__voicevox__synthesize_file "/app/warning.wav" "注意してください！" 34    # 白上虎太郎:おこ
mcp__voicevox__synthesize_file "/app/alert.wav" "メモリ使用量が危険です" 49  # ナースロボ_タイプT:恐怖
```

## 高度な設定・カスタマイズ

### 環境変数による詳細制御

`.mcp.json` の `env` セクションで以下を設定可能:

```json
{
  "env": {
    "VOICEVOX_URL": "http://host.docker.internal:50023"
  }
}
```

**注意**: 他の環境変数（`VOICEVOX_DEFAULT_SPEAKER` 等）は、MCP Server の `speak` 機能用のため、現在の `synthesize_file` + 自動再生システムでは使用されません。

### 再生速度の調整

```bash
# 超ゆっくり（0.3倍速）- 重要な説明時
mcp__voicevox__synthesize_file "/app/important.wav" "重要な説明です" 31 0.3

# 標準速度（1.0倍速）
mcp__voicevox__synthesize_file "/app/normal.wav" "通常の速度です" 2 1.0

# 高速（1.5倍速）- 効率重視
mcp__voicevox__synthesize_file "/app/quick.wav" "素早く伝えます" 3 1.5

# 超高速（2.5倍速）- 緊急時
mcp__voicevox__synthesize_file "/app/urgent.wav" "緊急事態です！" 34 2.5
```

## 実践的な活用例

### バイブコーディング統合例

```bash
# プロジェクト開始の挨拶
mcp__voicevox__synthesize_file "/app/start.wav" "バイブコーディングを開始するのだ！" 3

# 作業完了の報告
mcp__voicevox__synthesize_file "/app/complete.wav" "実装が完了しました〜♪" 15  # 九州そら:あまあま

# 休憩の提案
mcp__voicevox__synthesize_file "/app/break.wav" "少し休憩しませんか？" 8  # 春日部つむぎ

# 終了の挨拶
mcp__voicevox__synthesize_file "/app/goodbye.wav" "今日もお疲れさまでした" 2
```

### 開発フローとの連携

```bash
# ビルド開始
mcp__voicevox__synthesize_file "/app/build_start.wav" "ビルドを開始します" 29  # No.7:ノーマル

# テスト実行
mcp__voicevox__synthesize_file "/app/test_start.wav" "テストを実行中です" 93  # ぞん子:実況風

# デプロイ成功
mcp__voicevox__synthesize_file "/app/deploy_success.wav" "デプロイ成功だっぺ〜！" 107  # 東北ずん子
```

## トラブルシューティング

### よくある問題と対処法

1. **音声が出ない**
   - macOS の自動再生システムが起動しているか確認
   - `tail -f logs/voice-player.log` でログ確認

2. **ポート競合エラー**
   - `lsof -i :50023` で使用プロセス確認
   - 別のポートで起動: Docker の `-p` オプションを変更

3. **話者IDが見つからない**
   - `mcp__voicevox__get_speakers` で利用可能な話者を確認

4. **音声が途切れる・重複する**
   - 自動再生システムを再起動
   - `bash scripts/stop-voicevox-system.sh && nohup bash scripts/start-voicevox-system.sh &`

### ログファイルの確認

```bash
# VOICEVOX Engine のログ
tail -f logs/voicevox-engine.log

# 音声再生システムのログ  
tail -f logs/voice-player.log

# エラーが発生している場合の詳細確認
curl http://localhost:50023/docs
```

## システム仕様・制限事項

### リソース要件
- **Docker**: 最新版推奨
- **メモリ**: 2GB以上推奨（音声モデル読み込み用）
- **ストレージ**: 音声ファイル保存用に十分な空き容量

### 対応環境
- **macOS**: 13 (Ventura) 以降
- **音声出力**: macOS の afplay コマンド使用
- **ファイル監視**: fswatch 使用（Homebrew でインストール）

### パフォーマンス最適化
- 生成された音声ファイルは3秒後に自動削除
- 同時に5つ以上の音声ファイルが存在する場合、古いものを自動削除
- バックグラウンドプロセスでの効率的なリソース管理

---

**関連ドキュメント**:
- [バイブコーディング完全ガイド](./claude-vibe-coding-complete-guide-2025.md)
- [AI レスポンス読み上げガイド](./ai-response-tts-guide-2025.md)

**最終更新**: 2025-08-09  
**次回更新予定**: 新機能追加時または重要な変更発生時