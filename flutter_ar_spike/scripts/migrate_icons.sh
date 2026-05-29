#!/usr/bin/env bash
# migrate_icons.sh — PlaySpot Assets.xcassets 의 imageset PNG 를 Flutter assets 로 변환.
# imageset 의 @2x/@3x → Flutter 해상도 변형(2.0x/3.0x), @1x(또는 단일) → 기본.
# 사용: bash scripts/migrate_icons.sh <xcassets_group> <flutter_assets_subdir>
#   예: bash scripts/migrate_icons.sh Items items   # PlaySpot/.../Items/*.imageset → assets/items/
# 그룹 미지정 시 Items/AR/UI 기본 처리.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"          # .../TreasureHunter
XCASSETS="$REPO/PlaySpot/Assets.xcassets"
OUT_ROOT="$(cd "$(dirname "$0")/.." && pwd)/assets"  # flutter_ar_spike/assets

migrate_group() {
  local group="$1" sub="$2"
  local src="$XCASSETS/$group"
  local dst="$OUT_ROOT/$sub"
  [ -d "$src" ] || { echo "skip: $src 없음"; return; }
  mkdir -p "$dst/2.0x" "$dst/3.0x"
  local count=0
  for set in "$src"/*.imageset; do
    [ -d "$set" ] || continue
    local name; name="$(basename "$set" .imageset)"
    # @3x / @2x / @1x(또는 단일) 우선순위로 복사
    local x1 x2 x3
    x1="$(ls "$set"/*@1x.png 2>/dev/null | head -1 || true)"
    x2="$(ls "$set"/*@2x.png 2>/dev/null | head -1 || true)"
    x3="$(ls "$set"/*@3x.png 2>/dev/null | head -1 || true)"
    # 단일(스케일 표기 없는) png 폴백
    local single; single="$(ls "$set"/*.png 2>/dev/null | grep -vE '@[123]x' | head -1 || true)"
    [ -n "$x1" ] && cp "$x1" "$dst/$name.png" || { [ -n "$single" ] && cp "$single" "$dst/$name.png" || { [ -n "$x2" ] && cp "$x2" "$dst/$name.png"; }; }
    [ -n "$x2" ] && cp "$x2" "$dst/2.0x/$name.png" || true
    [ -n "$x3" ] && cp "$x3" "$dst/3.0x/$name.png" || true
    count=$((count+1))
  done
  echo "$group → assets/$sub : ${count}개 imageset 처리"
}

if [ $# -ge 2 ]; then
  migrate_group "$1" "$2"
else
  migrate_group Items items
  migrate_group AR ar
  migrate_group UI ui
fi
echo "완료. pubspec.yaml 의 flutter.assets 에 해당 디렉터리를 등록하세요."
