#!/bin/bash
# scripts/toggle_mission_status.sh — 미션 publish/unpublish 토글 (서버 PATCH partial 미지원 우회)
# 사용:
#   bash scripts/toggle_mission_status.sh <missionId> publish
#   bash scripts/toggle_mission_status.sh <missionId> unpublish
#   bash scripts/toggle_mission_status.sh <missionId> publish test@gmail.com 1234

set -e

BASE="${PLAYSPOT_BASE:-http://43.201.188.35:8080}"
MID="${1:?missionId 필요}"
ACTION="${2:?action 필요 (publish | unpublish)}"
USER="${3:-test@gmail.com}"
PASS="${4:-1234}"

case "$ACTION" in
  publish)    NEW_STATUS=2; LABEL="공개" ;;
  unpublish)  NEW_STATUS=0; LABEL="비공개" ;;
  *) echo "✗ action 은 publish 또는 unpublish 만 가능" >&2; exit 1 ;;
esac

echo "▶︎ 로그인: $USER"
TOKEN=$(curl -s -X POST "$BASE/api/v1/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"userId\":\"$USER\",\"password\":\"$PASS\"}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))")

[ -z "$TOKEN" ] && { echo "✗ 로그인 실패"; exit 2; }

echo "▶︎ GET 미션 전체 (서버 PATCH 가 전체 페이로드 요구하므로)"
curl -s -H "Authorization: Bearer $TOKEN" "$BASE/api/v1/missions/$MID" > /tmp/mission_full.json

echo "▶︎ Status → $NEW_STATUS ($LABEL) 변환 후 PATCH"
python3 << EOF
import json
d = json.load(open('/tmp/mission_full.json'))
m = d.get('mission', d)

# Builder payload 형식으로 재조립
mission_fields = {
    "Title": m.get("Title", ""),
    "Description": m.get("Description", ""),
    "Place": m.get("Place", ""),
    "LimitTime": m.get("LimitTime", "00:00:00"),
    "Status": $NEW_STATUS,
    "Virtual": m.get("Virtual", 0),
    "Lang": m.get("Lang", "ko"),
    "BadgeImageName": m.get("BadgeImageName"),
}

# items 와 quizzes 도 builder 형식으로
items = []
for it in d.get("items", []):
    items.append({
        "ItemID": it.get("ItemID"),
        "Mandatory": it.get("Mandatory", 0),
        "ItemType": it.get("ItemType"),
        "Latitude": it.get("Latitude", 0),
        "Longitude": it.get("Longitude", 0),
        "BlackCnt": it.get("BlackCnt", 5),
        "BlackTime": it.get("BlackTime", 300),
        "RangeAR": it.get("RangeAR", 30),
        "ShowType": it.get("ShowType", "4"),
        "EffectiveRange": it.get("EffectiveRange", 0),
        "EffectiveTime": it.get("EffectiveTime", 0),
        "ItemGame": it.get("ItemGame", 0),
        "Info": it.get("Info", ""),
        "RelationItemID": it.get("RelationItemID", 0),
    })

quizzes = []
for q in d.get("quizzes", []):
    quizzes.append({
        "ItemID": q.get("ItemID"),
        "Seq": q.get("Seq"),
        "Quiz": q.get("Quiz", ""),
        "Answer": q.get("Answer", ""),
        "Probability": q.get("Probability", 100),
    })

payload = {"mission": mission_fields, "items": items, "quizzes": quizzes}
open('/tmp/patch_payload.json','w').write(json.dumps(payload, ensure_ascii=False))
print(f"  → mission + items({len(items)}) + quizzes({len(quizzes)}) 페이로드 준비")
EOF

HTTP=$(curl -s -o /tmp/resp.json -w "%{http_code}" \
  -X PATCH "$BASE/api/v1/missions/$MID" \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  --data @/tmp/patch_payload.json)

if [ "$HTTP" = "200" ] || [ "$HTTP" = "204" ]; then
  echo "  ✓ $LABEL 으로 변경 완료 (HTTP $HTTP)"
else
  echo "  ✗ 실패 (HTTP $HTTP)"
  cat /tmp/resp.json
  exit 3
fi
