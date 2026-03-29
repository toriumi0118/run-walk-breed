#!/bin/bash
set -euo pipefail

# Run Walk Breed — iOS プラグインビルドスクリプト
# Usage: ./build.sh [debug|release]

CONFIG="${1:-release}"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BIN_DIR="${PROJECT_ROOT}/bin/ios/${CONFIG}"

echo "=== Building iOS plugins (${CONFIG}) ==="

cd "$(dirname "$0")"

# Swift Package のビルド（iOS arm64）
echo "--- Building for iOS device (arm64) ---"
swift build \
    -c "${CONFIG}" \
    --triple arm64-apple-ios

# ビルド成果物のパスを取得
BUILD_DIR=".build/arm64-apple-ios/${CONFIG}"

# 出力先を作成
mkdir -p "${BIN_DIR}"

# ビルド成果物をコピー
echo "--- Copying build artifacts to ${BIN_DIR} ---"

for lib in libHealthKitPlugin.dylib libLocationPlugin.dylib libMapViewPlugin.dylib; do
    if [ -f "${BUILD_DIR}/${lib}" ]; then
        cp "${BUILD_DIR}/${lib}" "${BIN_DIR}/"
        echo "  Copied ${lib}"
    else
        echo "  Warning: ${lib} not found in ${BUILD_DIR}"
    fi
done

# SwiftGodot ライブラリもコピー
if [ -f "${BUILD_DIR}/libSwiftGodot.dylib" ]; then
    cp "${BUILD_DIR}/libSwiftGodot.dylib" "${BIN_DIR}/"
    echo "  Copied libSwiftGodot.dylib"
fi

# .gdextension をプロジェクトの addons/ にコピー（iOS エクスポート用）
ADDONS_DIR="${PROJECT_ROOT}/addons"
mkdir -p "${ADDONS_DIR}"
cp "$(dirname "$0")/ios_plugins.gdextension" "${ADDONS_DIR}/"
echo "--- Copied ios_plugins.gdextension to addons/ ---"

echo "=== Build complete ==="
echo "Output: ${BIN_DIR}"
ls -la "${BIN_DIR}/"
