#!/bin/bash
# Asset Migration Script
# Copies images from legacy Resources/img/ to Assets.xcassets structure
# Run from project root: bash PlaySpot/Resources/migrate_assets.sh

PROJ_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$PROJ_ROOT/Resources/img"
BADGE_SRC="$PROJ_ROOT/Resources/ImgBadg"
ASSETS="$PROJ_ROOT/PlaySpot/Assets.xcassets"

create_imageset() {
    local dir="$1"
    local name="$2"
    local file="$3"

    mkdir -p "$dir/$name.imageset"
    cp "$file" "$dir/$name.imageset/"
    local basename=$(basename "$file")

    # Check for @2x variant
    local ext="${basename##*.}"
    local nameonly="${basename%.*}"
    local twox="${nameonly}@2x.${ext}"

    cat > "$dir/$name.imageset/Contents.json" << EOF
{
  "images" : [
    { "filename" : "$basename", "idiom" : "universal", "scale" : "1x" },
    $(if [ -f "$SRC/$twox" ]; then echo "{ \"filename\" : \"$twox\", \"idiom\" : \"universal\", \"scale\" : \"2x\" },"; cp "$SRC/$twox" "$dir/$name.imageset/"; else echo "{ \"idiom\" : \"universal\", \"scale\" : \"2x\" },"; fi)
    { "idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
EOF
}

create_group() {
    local dir="$1"
    mkdir -p "$dir"
    cat > "$dir/Contents.json" << 'EOF'
{
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : { "provides-namespace" : true }
}
EOF
}

echo "Creating asset catalog groups..."
create_group "$ASSETS/AR"
create_group "$ASSETS/Items"
create_group "$ASSETS/Radar"
create_group "$ASSETS/Game"
create_group "$ASSETS/Tutorial"
create_group "$ASSETS/UI"
create_group "$ASSETS/Auth"
create_group "$ASSETS/Badges"

echo "Migrating AR icons..."
for f in "$SRC"/ar_*.png; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .png)
    [[ "$name" == *"@2x"* ]] && continue
    create_imageset "$ASSETS/AR" "$name" "$f"
done

for f in "$SRC"/arn_*.png; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .png)
    [[ "$name" == *"@2x"* ]] && continue
    create_imageset "$ASSETS/AR" "$name" "$f"
done

echo "Migrating map icons..."
for f in "$SRC"/i_*.png; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .png)
    [[ "$name" == *"@2x"* ]] && continue
    create_imageset "$ASSETS/Items" "$name" "$f"
done

for f in "$SRC"/in_*.png; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .png)
    [[ "$name" == *"@2x"* ]] && continue
    create_imageset "$ASSETS/Items" "$name" "$f"
done

echo "Migrating radar images..."
for f in "$SRC"/radar_*.png; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .png)
    [[ "$name" == *"@2x"* ]] && continue
    create_imageset "$ASSETS/Radar" "$name" "$f"
done

echo "Migrating game images..."
for f in "$SRC"/game_*.png; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .png)
    [[ "$name" == *"@2x"* ]] && continue
    create_imageset "$ASSETS/Game" "$name" "$f"
done

echo "Migrating tutorial images..."
for f in "$SRC"/tutorial*; do
    [ -f "$f" ] || continue
    name=$(basename "$f")
    ext="${name##*.}"
    nameonly="${name%.*}"
    [[ "$nameonly" == *"@2x"* ]] && continue
    create_imageset "$ASSETS/Tutorial" "$nameonly" "$f"
done

echo "Migrating UI images..."
for prefix in button_ popup icon badge star detail_ menu_ list playing clock delete_ help info setting logo missiondesign playAR; do
    for f in "$SRC"/${prefix}*; do
        [ -f "$f" ] || continue
        name=$(basename "$f")
        ext="${name##*.}"
        nameonly="${name%.*}"
        [[ "$nameonly" == *"@2x"* ]] && continue
        create_imageset "$ASSETS/UI" "$nameonly" "$f"
    done
done

echo "Migrating auth images..."
for f in "$SRC"/login*; do
    [ -f "$f" ] || continue
    name=$(basename "$f")
    nameonly="${name%.*}"
    [[ "$nameonly" == *"@2x"* ]] && continue
    create_imageset "$ASSETS/Auth" "$nameonly" "$f"
done

echo "Migrating badge images..."
for f in "$BADGE_SRC"/*.png; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .png)
    [[ "$name" == *"@2x"* ]] && continue
    create_imageset "$ASSETS/Badges" "$name" "$f"
done

echo "Asset migration complete!"
echo "Total imagesets created:"
find "$ASSETS" -name "*.imageset" -type d | wc -l
