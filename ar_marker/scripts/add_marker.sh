#!/bin/bash
# 새 마커 이미지를 PNG 1024×1024 로 변환하여 assets/markers/ 에 저장.
#
# 사용:
#   ./scripts/add_marker.sh <원본_경로> <마커_ID> [패딩색=FFFFFF]
#
# 예:
#   ./scripts/add_marker.sh ~/Desktop/cafe.jpg cafe_arc
#   ./scripts/add_marker.sh ~/Downloads/sign.png hanok_door EEDDBB
#
# 이후 lib/models/treasure_marker.dart 에 TreasureMarker 엔트리 추가 필요.

set -e

SRC="$1"
ID="$2"
PAD="${3:-FFFFFF}"

if [ -z "$SRC" ] || [ -z "$ID" ]; then
  echo "Usage: $0 <source_image> <marker_id> [pad_color_hex=FFFFFF]"
  exit 1
fi

if [ ! -f "$SRC" ]; then
  echo "❌ Source file not found: $SRC"
  exit 1
fi

DST="$(cd "$(dirname "$0")/.." && pwd)/flutter_ar_poc/assets/markers/${ID}.png"
TMP="${DST}.tmp"

echo "→ Source : $SRC"
echo "→ Target : $DST"
echo "→ Pad    : #$PAD"

# 1. JPEG/HEIC/WEBP → 진짜 PNG 로 인코딩
sips -s format png "$SRC" --out "$TMP" >/dev/null

# 2. 1024×1024 정사각형으로 패딩 (비율 유지, 빈공간 채움)
sips -p 1024 1024 --padColor "$PAD" "$TMP" --out "$DST" >/dev/null
rm "$TMP"

# 3. 결과 확인
echo
echo "✓ Marker saved:"
sips -g pixelWidth -g pixelHeight -g format "$DST" 2>&1 | tail -3
echo
echo "다음 단계:"
echo "  1. lib/models/treasure_marker.dart 에 엔트리 추가:"
echo "     TreasureMarker("
echo "       id: '$ID',"
echo "       label: '...',"
echo "       clue: '...',"
echo "       rewardPts: 100,"
echo "       widthCm: 20,"
echo "     ),"
echo "  2. flutter clean && flutter run -d <device>"
