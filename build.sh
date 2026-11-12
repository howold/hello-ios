#!/usr/bin/env bash
# 编译最小 iOS App 并打包成未签名 .ipa
# 依赖：macOS + Xcode 命令行工具（GitHub Actions 的 macos runner 自带）
set -euo pipefail

APP_NAME="HelloApp"
BUNDLE_ID="com.demo.helloios"
MIN_IOS="15.0"

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "==> 环境"
echo "    工作目录 : $ROOT"
xcodebuild -version 2>/dev/null | head -2 || true
echo "    Xcode 路径: $(xcode-select -p 2>/dev/null || echo unknown)"

SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
SDK_VER="$(xcrun --sdk iphoneos --show-sdk-version)"
echo "    iOS SDK  : $SDK_VER"
echo "    SDK 路径 : $SDK_PATH"

echo "==> 清理"
rm -rf build
APP_DIR="build/Payload/${APP_NAME}.app"
mkdir -p "$APP_DIR"

echo "==> 编译 (arm64, iOS ${MIN_IOS}+)"
xcrun --sdk iphoneos swiftc \
  -target "arm64-apple-ios${MIN_IOS}" \
  -sdk "$SDK_PATH" \
  -O \
  -framework UIKit \
  -o "${APP_DIR}/${APP_NAME}" \
  "App/main.swift"

echo "==> 组装 .app 包"
cp "App/Info.plist" "${APP_DIR}/Info.plist"
printf 'APPL????' > "${APP_DIR}/PkgInfo"

echo "==> 校验产物"
file "${APP_DIR}/${APP_NAME}"
if ! file "${APP_DIR}/${APP_NAME}" | grep -q 'Mach-O 64-bit executable arm64'; then
  echo "错误：产物不是 arm64 Mach-O 可执行文件" >&2
  exit 1
fi

# 交叉核对 Info.plist 里的 bundle id 与预期一致
ACTUAL_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${APP_DIR}/Info.plist")"
if [ "$ACTUAL_ID" != "$BUNDLE_ID" ]; then
  echo "错误：Bundle ID 不匹配（$ACTUAL_ID != $BUNDLE_ID）" >&2
  exit 1
fi
echo "    Bundle ID: $ACTUAL_ID"

echo "==> 打包 IPA"
(
  cd build
  rm -f "${APP_NAME}.ipa"
  zip -qry "${APP_NAME}.ipa" Payload
)

echo "==> 完成"
ls -lh "build/${APP_NAME}.ipa"
if command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "build/${APP_NAME}.ipa"
fi

# 未签名产物，需在本地用 zsign + 企业/开发证书签名后才能安装
