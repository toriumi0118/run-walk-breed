#!/bin/bash
set -euo pipefail

# Run Walk Breed — iOS エクスポートスクリプト
# プラグインビルド + Godot エクスポートを一括実行
#
# Usage:
#   ./scripts/ios_export.sh          # デバッグビルド（デフォルト）
#   ./scripts/ios_export.sh debug    # デバッグビルド
#   ./scripts/ios_export.sh release  # リリースビルド
#   ./scripts/ios_export.sh --skip-plugins debug  # プラグインビルドをスキップ

SKIP_PLUGINS=false
CONFIG="debug"

for arg in "$@"; do
    case "$arg" in
        --skip-plugins) SKIP_PLUGINS=true ;;
        debug|release) CONFIG="$arg" ;;
    esac
done

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXPORT_DIR="${PROJECT_ROOT}/../run-walk-breed-export/ios"

echo "=== iOS Export (${CONFIG}) ==="

# 1. プラグインビルド
if [ "$SKIP_PLUGINS" = true ]; then
    echo "--- Skipping plugin build (--skip-plugins) ---"
else
    echo "--- Building iOS plugins ---"
    "${PROJECT_ROOT}/plugins/ios/build.sh" "${CONFIG}"
fi

# 2. エクスポート先ディレクトリの作成
mkdir -p "${EXPORT_DIR}"

# 3. Godot エクスポート
echo "--- Exporting Xcode project ---"
EXPORT_FLAG="--export-debug"
if [ "$CONFIG" = "release" ]; then
    EXPORT_FLAG="--export-release"
fi

godot --headless ${EXPORT_FLAG} "iOS" "${EXPORT_DIR}/RunWalkBreed.xcodeproj"

# 4. Active Development セットアップ（.pck 除外 + フォルダ参照 + godot_path）
echo "--- Setting up Active Development workflow ---"
ruby "${PROJECT_ROOT}/scripts/setup_active_dev.rb" \
    "${EXPORT_DIR}/RunWalkBreed.xcodeproj" \
    "${PROJECT_ROOT}"

echo ""
echo "=== Export complete ==="
echo "Xcode project: ${EXPORT_DIR}/RunWalkBreed.xcodeproj"
echo ""
echo "Next: open ${EXPORT_DIR}/RunWalkBreed.xcodeproj"
