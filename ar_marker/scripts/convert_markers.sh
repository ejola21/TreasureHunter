#!/bin/bash
# 마커 폴더의 JPEG/JPG 를 PNG 1024×1024 로 일괄 변환.
# (JPEG 그대로 둬도 인식되지만 PNG 가 ARKit/ARCore 안정성 높음)
#
# 사용:
#   ./scripts/convert_markers.sh          # 노란 배경 (FFFF00)
#   ./scripts/convert_markers.sh FFFFFF   # 흰 배경
#
# 결과: JPEG 원본은 .bak 으로 백업, .png 생성

set -e

DIR="$(cd "$(dirname "$0")/.." && pwd)/flutter_ar_poc/assets/markers"
PAD="${1:-FFFFFF}"

if [ ! -d "$DIR" ]; then
  echo "❌ Markers dir not found: $DIR"
  exit 1
fi

cd "$DIR"

converted=0
skipped=0

for f in *.jpg *.jpeg *.JPG *.JPEG; do
  [ -e "$f" ] || continue
  base="${f%.*}"
  png="${base}.png"

  # 같은 이름의 .png 가 이미 있으면 건너뜀 (덮어쓰기 방지)
  if [ -e "$png" ] && [ "$png" != "$f" ]; then
    echo "⚠  $f → ${png} (이미 존재, 건너뜀)"
    skipped=$((skipped + 1))
    continue
  fi

  tmp="${png}.tmp"
  sips -s format png "$f" --out "$tmp" >/dev/null
  sips -p 1024 1024 --padColor "$PAD" "$tmp" --out "$png" >/dev/null
  rm "$tmp"

  # 원본 백업 (덮어쓰기 안전)
  if [ "$f" != "$png" ]; then
    mv "$f" "${f}.bak"
  fi

  echo "✓ $f → $png (1024×1024)"
  converted=$((converted + 1))
done

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Converted: $converted"
echo "  Skipped:   $skipped"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $converted -gt 0 ]; then
  echo
  echo "다음:"
  echo "  cd flutter_ar_poc && flutter clean && flutter run -d <device>"
fi
