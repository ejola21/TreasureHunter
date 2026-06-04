#!/bin/bash
# scripts/upload_mission.sh — JSON 페이로드 1개로 미션 생성 (POST /api/v1/missions)
# 사용:
#   bash scripts/upload_mission.sh mission_hwaseong_jeongjo.json
#   bash scripts/upload_mission.sh mission_hwaseong_jeongjo.json test@gmail.com 1234
#
# 기본 자격증명: test@gmail.com / 1234
# 서버: http://43.201.188.35:8080

set -e

BASE="${PLAYSPOT_BASE:-http://43.201.188.35:8080}"
JSON_FILE="${1:?JSON 파일 경로 필요 (예: mission_hwaseong_jeongjo.json)}"
USER="${2:-test@gmail.com}"
PASS="${3:-1234}"

if [ ! -f "$JSON_FILE" ]; then
  echo "✗ JSON 파일 없음: $JSON_FILE" >&2
  exit 1
fi

# JSON 검증
if ! python3 -m json.tool "$JSON_FILE" >/dev/null 2>&1; then
  echo "✗ JSON 형식 오류: $JSON_FILE" >&2
  exit 1
fi

echo "▶︎ 1. 로그인: $USER"
TOKEN=$(curl -s -X POST "$BASE/api/v1/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"userId\":\"$USER\",\"password\":\"$PASS\"}" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('token',''))" 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo "✗ 로그인 실패. 자격증명 확인." >&2
  exit 2
fi
echo "  ✓ 토큰 발급 (${#TOKEN} chars)"

echo "▶︎ 2. 미션 페이로드 미리보기:"
python3 -c "
import json
d = json.load(open('$JSON_FILE'))
m = d['mission']
print(f\"  제목:     {m['Title']}\")
print(f\"  설명:     {m['Description'][:60]}...\" if len(m['Description']) > 60 else f\"  설명:     {m['Description']}\")
print(f\"  장소:     {m['Place']}\")
print(f\"  제한시간: {m['LimitTime']}\")
print(f\"  공개:     {'예' if m['Status']==2 else '비공개'}\")
print(f\"  가상모드: {'ON' if m['Virtual']==1 else 'OFF'}\")
print(f\"  아이템:   {len(d['items'])}개\")
print(f\"  퀴즈변형: {len(d['quizzes'])}개\")
"

echo "▶︎ 3. POST /api/v1/missions"
HTTP_CODE=$(curl -s -o /tmp/upload_resp.json -w "%{http_code}" \
  -X POST "$BASE/api/v1/missions" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  --data @"$JSON_FILE")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
  MID=$(python3 -c "import sys,json; print(json.load(open('/tmp/upload_resp.json')).get('missionId',''))" 2>/dev/null)
  echo "  ✓ 생성 완료 — missionId=$MID  (HTTP $HTTP_CODE)"
  echo
  echo "▶︎ 4. 검증 — GET /api/v1/missions/$MID"
  curl -s -H "Authorization: Bearer $TOKEN" "$BASE/api/v1/missions/$MID" \
    | python3 -c "
import sys, json
d = json.load(sys.stdin)
m = d.get('mission', d)
items = d.get('items', [])
quizzes = d.get('quizzes', [])
print(f\"  서버 확인:\")
print(f\"    MissionID: {m.get('MissionID')}\")
print(f\"    Title:     {m.get('Title')}\")
print(f\"    Items:     {len(items)}개\")
print(f\"    Quizzes:   {len(quizzes)}개\")
print(f\"    Status:    {m.get('Status')} ({'공개' if m.get('Status')==2 else '비공개'})\")
"
  echo
  echo "✓ 완료. 앱의 'Design' 탭 → '내 디자인' 에서 확인 가능."
else
  echo "  ✗ 실패 (HTTP $HTTP_CODE)"
  cat /tmp/upload_resp.json
  exit 3
fi
