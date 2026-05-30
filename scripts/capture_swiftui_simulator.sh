#!/usr/bin/env bash
# scripts/capture_swiftui_simulator.sh
# SwiftUI PlaySpot 을 iOS Simulator 에 빌드·설치·실행 후, 사용자가 네비게이션 할 때마다
# 화면 캡처를 저장한다. Flutter 1:1 매칭 작업 시 SwiftUI 원본을 즉시 참조하기 위함.
#
# 사용:
#   bash scripts/capture_swiftui_simulator.sh build   # 빌드+설치+실행 (1회)
#   bash scripts/capture_swiftui_simulator.sh cap <name>   # 현재 화면 캡처 → design_ref/swiftui_simulator/<name>.png
#   bash scripts/capture_swiftui_simulator.sh watch  # 5초마다 자동 캡처 (sequential_NNN.png)
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$REPO/flutter_ar_spike/design_ref/swiftui_simulator"
SIM_NAME="${SIM_NAME:-iPhone 16 Pro}"  # 환경변수로 변경 가능
SCHEME="${SCHEME:-PlaySpot}"
PROJ="$REPO/PlaySpot.xcodeproj"
BUNDLE_ID="${BUNDLE_ID:-com.ejola.playspot}"  # ❗ `.dev` 아님 (Info.plist 실 ID)

mkdir -p "$OUT"

# 시뮬레이터 UDID 찾기 (이름 매칭, iOS 18+ 우선).
find_sim_udid() {
  xcrun simctl list devices available 2>/dev/null \
    | grep "^    $SIM_NAME (" | head -1 \
    | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/'
}

boot_sim() {
  local udid="$1"
  local state=$(xcrun simctl list devices booted 2>/dev/null | grep "$udid" || true)
  if [ -z "$state" ]; then
    echo "→ 시뮬레이터 부팅 중: $SIM_NAME ($udid)"
    xcrun simctl boot "$udid"
    open -a Simulator
    sleep 3
  fi
}

cmd_build() {
  local udid=$(find_sim_udid)
  if [ -z "$udid" ]; then
    echo "✗ 시뮬레이터 '$SIM_NAME' 못 찾음. SIM_NAME=... 으로 지정 또는 사용 가능 목록 확인:"
    xcrun simctl list devices available
    exit 1
  fi
  boot_sim "$udid"

  echo "→ Xcode 빌드 중..."
  xcodebuild \
    -project "$PROJ" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,id=$udid" \
    CODE_SIGNING_ALLOWED=NO \
    build 2>&1 | tail -15

  # .app 경로 찾기
  local app=$(find ~/Library/Developer/Xcode/DerivedData -name "$SCHEME.app" -path "*Debug-iphonesimulator*" -print -quit)
  [ -z "$app" ] && { echo "✗ .app 못 찾음"; exit 1; }

  echo "→ 앱 설치: $app"
  xcrun simctl install "$udid" "$app"
  echo "→ 앱 실행..."
  xcrun simctl launch "$udid" "$BUNDLE_ID"
  echo "✓ 준비 완료. cap <name> 으로 캡처하세요."
}

cmd_cap() {
  local name="${1:-shot_$(date +%H%M%S)}"
  local udid=$(xcrun simctl list devices booted 2>/dev/null | head -2 | tail -1 \
    | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')
  [ -z "$udid" ] && { echo "✗ 부팅된 시뮬레이터 없음. build 먼저 실행"; exit 1; }
  local file="$OUT/$name.png"
  xcrun simctl io "$udid" screenshot "$file" 2>/dev/null
  echo "→ $file ($(du -h "$file" | cut -f1))"
}

cmd_watch() {
  echo "→ 5초마다 자동 캡처. Ctrl+C 로 종료."
  local i=1
  while true; do
    cmd_cap "sequential_$(printf '%03d' $i)"
    i=$((i+1))
    sleep 5
  done
}

case "${1:-}" in
  build) cmd_build ;;
  cap)   shift; cmd_cap "$@" ;;
  watch) cmd_watch ;;
  *)
    cat <<EOF
사용법:
  $0 build              # 시뮬레이터 부팅 + Xcode 빌드 + 앱 실행 (1회)
  $0 cap <name>         # 현재 화면 캡처 → design_ref/swiftui_simulator/<name>.png
  $0 watch              # 5초마다 자동 캡처 (sequential_NNN.png)

환경변수:
  SIM_NAME=iPhone 16 Pro    # 시뮬레이터 이름 변경
  SCHEME=PlaySpot           # Xcode scheme
  BUNDLE_ID=com.ejola.playspot.dev

캡처 위치: $OUT
EOF
    ;;
esac
