#!/usr/bin/env bash
# scripts/migrate_redesign_assets.sh
# 디자인 핸드오프 어셋을 PlaySpot/Assets.xcassets/Minigame/ 으로 마이그레이션.
# Items/ 의 i_*.png 19개는 commit af645a0 에서 이미 이관 완료.
# 본 스크립트는 minigame 6개 PNG 만 imageset 으로 추가한다 (idempotent).
#
# 사용:
#   bash scripts/migrate_redesign_assets.sh
#   bash scripts/migrate_redesign_assets.sh --dry-run

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/design_handoff_playspot_redesign/source/assets/minigame"
DST="$ROOT/PlaySpot/Assets.xcassets/Minigame"

DRY=0
if [ "${1:-}" = "--dry-run" ]; then DRY=1; fi

run() {
  if [ $DRY -eq 1 ]; then echo "DRY: $*"; else eval "$@"; fi
}

if [ ! -d "$SRC" ]; then
  echo "❌ Source not found: $SRC"
  exit 1
fi

run "mkdir -p '$DST'"

# Minigame/Contents.json — namespace 활성화
if [ ! -f "$DST/Contents.json" ] || ! grep -q "provides-namespace" "$DST/Contents.json"; then
  if [ $DRY -eq 1 ]; then
    echo "DRY: write $DST/Contents.json"
  else
    cat > "$DST/Contents.json" <<'EOF'
{
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : { "provides-namespace" : true }
}
EOF
  fi
fi

# 6개 PNG → imageset
for name in playspot_logo playspot_logo_color shake_0 shake_1 touch_0 touch_1; do
  src_png="$SRC/$name.png"
  imageset="$DST/$name.imageset"

  if [ ! -f "$src_png" ]; then
    echo "⚠️  Missing source PNG: $src_png — skipping"
    continue
  fi

  run "mkdir -p '$imageset'"
  run "cp '$src_png' '$imageset/$name.png'"

  if [ $DRY -eq 1 ]; then
    echo "DRY: write $imageset/Contents.json"
  else
    cat > "$imageset/Contents.json" <<EOF
{
  "images" : [
    {
      "filename" : "$name.png",
      "idiom" : "universal",
      "scale" : "3x"
    },
    {
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "scale" : "2x"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
EOF
  fi
  echo "✅ $name.imageset"
done

echo "Done."
