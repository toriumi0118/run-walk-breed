#!/bin/bash
set -euo pipefail

# Run Walk Breed — iOS プラグインビルドスクリプト
# Usage: ./build.sh [debug|release]
#
# xcodebuild を使用して iOS 向けにビルドする。
# 成果物は .framework として出力される。

CONFIG="${1:-release}"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="${PROJECT_ROOT}/bin/ios/${CONFIG}"

echo "=== Building iOS plugins (${CONFIG}) ==="

cd "${PLUGIN_DIR}"

# xcodebuild の configuration 名に変換
if [ "$CONFIG" = "release" ]; then
    XCODE_CONFIG="Release"
else
    XCODE_CONFIG="Debug"
fi

# xcodebuild でビルド（iOS device arm64）
echo "--- Building for iOS device (arm64) via xcodebuild ---"
xcodebuild build \
    -scheme "RunWalkBreedPlugins-Package" \
    -configuration "${XCODE_CONFIG}" \
    -destination "generic/platform=iOS" \
    -derivedDataPath "${PLUGIN_DIR}/.build/DerivedData" \
    -skipPackagePluginValidation \
    ONLY_ACTIVE_ARCH=NO

# ビルド成果物のパスを特定
BUILD_PRODUCTS_DIR="${PLUGIN_DIR}/.build/DerivedData/Build/Products/${XCODE_CONFIG}-iphoneos"
FRAMEWORKS_DIR="${BUILD_PRODUCTS_DIR}/PackageFrameworks"

# 出力先を作成
mkdir -p "${BIN_DIR}"

# フレームワークをコピー
echo "--- Copying frameworks to ${BIN_DIR} ---"

for fw in HealthKitPlugin LocationPlugin MapViewPlugin SwiftGodot; do
    if [ -d "${FRAMEWORKS_DIR}/${fw}.framework" ]; then
        rm -rf "${BIN_DIR}/${fw}.framework"
        cp -R "${FRAMEWORKS_DIR}/${fw}.framework" "${BIN_DIR}/"
        echo "  Copied ${fw}.framework"
    else
        echo "  Warning: ${fw}.framework not found in ${FRAMEWORKS_DIR}"
    fi
done

# .gdextension をプロジェクトの addons/ にコピー（iOS エクスポート用）
ADDONS_DIR="${PROJECT_ROOT}/addons"
mkdir -p "${ADDONS_DIR}"
if [ -f "${PLUGIN_DIR}/ios_plugins.gdextension.template" ]; then
    cp "${PLUGIN_DIR}/ios_plugins.gdextension.template" "${ADDONS_DIR}/ios_plugins.gdextension"
    echo "--- Copied ios_plugins.gdextension to addons/ ---"
fi

echo "=== Build complete ==="
echo "Output: ${BIN_DIR}"
ls -la "${BIN_DIR}/"
