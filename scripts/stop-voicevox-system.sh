#!/bin/bash

# VOICEVOX 音声システム停止スクリプト

echo "🛑 VOICEVOX 音声システムを停止中..."

# VOICEVOX Engine のコンテナを停止
echo "📦 Docker コンテナ停止中..."
docker ps -q --filter "ancestor=voicevox/voicevox_engine:cpu-latest" | xargs -r docker stop

# fswatch プロセスを停止
echo "🔍 fswatch プロセス停止中..."
pkill -f "fswatch.*\.wav"

# afplay プロセスを停止（再生中の音声があれば）
echo "🔊 音声再生プロセス停止中..."
pkill afplay 2>/dev/null || true

# 残った音声ファイルをクリーンアップ（オプション）
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "🧹 音声ファイルクリーンアップ中..."
find "$PROJECT_DIR" -name "voice_*.wav" -type f -delete 2>/dev/null || true

echo "✅ VOICEVOX 音声システムが停止しました"