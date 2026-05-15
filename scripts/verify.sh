#!/bin/bash
# scripts/verify.sh — 빌드 → 시뮬레이터 설치 → 실행 → 스크린샷
# Usage: bash scripts/verify.sh [SimulatorName]
# Default simulator: iPhone 16 Pro

set -e

SIM_NAME="${1:-iPhone 16 Pro}"
SCHEME="PlaySpot"
BUNDLE_ID="com.ejola.playspot.dev"
PROJ_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHOT_PATH="/tmp/playspot_shot.png"

cd "$PROJ_ROOT"

echo "▶︎ Generating Xcode project from project.yml..."
xcodegen generate >/dev/null

echo "▶︎ Booting simulator: $SIM_NAME"
xcrun simctl boot "$SIM_NAME" 2>/dev/null || true
open -a Simulator

echo "▶︎ Building for $SIM_NAME..."
xcodebuild -project PlaySpot.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=$SIM_NAME" \
  -derivedDataPath ./build \
  build CODE_SIGNING_ALLOWED=NO | xcbeautify --quiet 2>/dev/null \
    || xcodebuild -project PlaySpot.xcodeproj \
        -scheme "$SCHEME" \
        -configuration Debug \
        -sdk iphonesimulator \
        -destination "platform=iOS Simulator,name=$SIM_NAME" \
        -derivedDataPath ./build \
        build CODE_SIGNING_ALLOWED=NO | tail -20

APP_PATH="./build/Build/Products/Debug-iphonesimulator/$SCHEME.app"
if [ ! -d "$APP_PATH" ]; then
  echo "✗ Build artifact not found at $APP_PATH"
  exit 1
fi

echo "▶︎ Installing & launching..."
xcrun simctl install booted "$APP_PATH"
xcrun simctl launch booted "$BUNDLE_ID"

sleep 2
xcrun simctl io booted screenshot "$SHOT_PATH"
echo "✓ Screenshot saved: $SHOT_PATH"
