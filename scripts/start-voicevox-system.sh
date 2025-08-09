#!/bin/bash

# VOICEVOX 音声システム一括起動スクリプト
# 使用法: nohup ./start-voicevox-system.sh &
# これは VSCode devcontianer ではなく、ホスト機での実行を想定しています。

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$PROJECT_DIR/logs"

echo "🎵 VOICEVOX 音声システムを起動中..."
echo "プロジェクトディレクトリ: $PROJECT_DIR"

# ログディレクトリ作成
mkdir -p "$LOG_DIR"

# OS判定と音声再生コマンド設定
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    PLAY_CMD="afplay"
    # fswatch の確認・インストール
    if ! command -v fswatch &> /dev/null; then
        echo "❌ fswatch がインストールされていません"
        echo "インストール中: brew install fswatch"
        brew install fswatch
    fi
elif [[ -n "$WSL_DISTRO_NAME" ]] || grep -q Microsoft /proc/version 2>/dev/null; then
    # WSL2 環境 - Windows側のPowerShellを使用
    PLAY_CMD="powershell.exe -Command"
    echo "🔊 WSL2環境を検出: Windows側のPowerShellで音声再生"
    # fswatch の確認・インストール
    if ! command -v fswatch &> /dev/null; then
        echo "❌ fswatch がインストールされていません"
        echo "インストール中: sudo apt install -y fswatch"
        sudo apt install -y fswatch
    fi
else
    # Linux (その他)
    if command -v ffplay &> /dev/null; then
        PLAY_CMD="ffplay -nodisp -autoexit"
    elif command -v aplay &> /dev/null; then
        PLAY_CMD="aplay"
    else
        echo "❌ 音声再生コマンドが見つかりません (ffplay, aplayのいずれかが必要)"
        exit 1
    fi
    # fswatch の確認・インストール
    if ! command -v fswatch &> /dev/null; then
        echo "❌ fswatch がインストールされていません"
        echo "パッケージマネージャーでインストールしてください:"
        echo "  Ubuntu/Debian: sudo apt install fswatch"
        echo "  CentOS/RHEL: sudo yum install fswatch"
        exit 1
    fi
fi

echo "🔊 音声再生コマンド: $PLAY_CMD"

# Docker の確認
if ! command -v docker &> /dev/null; then
    echo "❌ Docker がインストールされていません"
    exit 1
fi

# 既存の VOICEVOX Engine プロセスを確認
if lsof -i :50023 &> /dev/null; then
    echo "⚠️  ポート 50023 は既に使用されています"
    echo "既存の VOICEVOX Engine が起動中の可能性があります"
else
    # VOICEVOX Engine をバックグラウンドで起動
    echo "🚀 VOICEVOX Engine 起動中..."
    docker run --rm -p '127.0.0.1:50023:50021' voicevox/voicevox_engine:cpu-latest \
        > "$LOG_DIR/voicevox-engine.log" 2>&1 &

    # Docker コンテナ起動まで待機
    echo "⏳ VOICEVOX Engine の起動を待機中..."
    for i in {1..30}; do
        if curl -s http://localhost:50023/docs > /dev/null 2>&1; then
            echo "✅ VOICEVOX Engine が正常に起動しました"
            break
        fi
        sleep 2
        if [ $i -eq 30 ]; then
            echo "❌ VOICEVOX Engine の起動がタイムアウトしました"
            exit 1
        fi
    done
fi

# 音声ファイル自動再生システム起動
echo "🔊 音声自動再生システム起動中..."
cd "$PROJECT_DIR"

# 再生済みファイルリスト
PLAYED_FILES="/tmp/voicevox_played_$$"
touch "$PLAYED_FILES"

# デバッグ用ログ記録を追加
echo "🔊 音声監視システム開始: $(date)" >> "$LOG_DIR/voice-player.log"

fswatch -o . --include=".*\.wav$" | while read; do
    # 最新の.wavファイルを取得（シンプルで確実な方法）
    latest=$(ls -t *.wav 2>/dev/null | head -1)
    
    # ファイルが検出された時のみログ出力
    if [ -n "$latest" ] && [ -f "$latest" ] && ! grep -q "^$latest$" "$PLAYED_FILES" 2>/dev/null; then
        echo "$latest" >> "$PLAYED_FILES"
        echo "$(date '+%H:%M:%S') 🔊 再生開始: $(basename "$latest")" >> "$LOG_DIR/voice-player.log"
        
        # WSL2環境では安全な音声再生
        if [[ "$PLAY_CMD" == "powershell.exe -Command" ]]; then
            # WindowsのPowerShellでSoundPlayerを使用（安全な方法）
            win_path=$(wslpath -w "$latest")
            echo "$(date '+%H:%M:%S') Windows音声再生: $win_path" >> "$LOG_DIR/voice-player.log"
            powershell.exe -Command "try { (New-Object Media.SoundPlayer '$win_path').PlaySync() } catch { Write-Host 'Audio playback failed' }" 2>/dev/null &
        else
            # その他の環境
            echo "$(date '+%H:%M:%S') 他環境音声再生: $PLAY_CMD" >> "$LOG_DIR/voice-player.log"
            $PLAY_CMD "$latest" &
        fi

        # 再生後3秒待ってからファイル削除
        (sleep 3 && rm -f "$latest") &
    fi
done 2>&1 &

echo "🎉 VOICEVOX 音声システムが正常に起動しました！"
echo ""
echo "📊 状態確認:"
echo "  - VOICEVOX Engine: http://localhost:50023/docs"
echo "  - ログファイル: $LOG_DIR/"
echo ""
echo "⏹️  システム停止: ./stop-voicevox-system.sh"
echo ""

# メインプロセスを維持（nohup使用時のため）
wait
