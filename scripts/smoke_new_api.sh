#!/usr/bin/env bash
#
# scripts/smoke_new_api.sh — 신규 /api/v1/** REST API 스모크 테스트
#
# 사용:
#   bash scripts/smoke_new_api.sh                    # 13 endpoint 스모크
#   BASE_URL=http://localhost:8080 bash scripts/...  # 베이스 URL 오버라이드
#
# 출력: 각 단계 PASS/FAIL 행. 마지막에 합계.
# 종료 코드: 실패 0건 = 0, 1건 이상 = 1.

set -u
BASE="${BASE_URL:-http://43.201.188.35:8080}"
PASS=0
FAIL=0
FAILED_CASES=()

red()   { printf '\033[31m%s\033[0m' "$1"; }
green() { printf '\033[32m%s\033[0m' "$1"; }
yellow(){ printf '\033[33m%s\033[0m' "$1"; }

# assert_eq <label> <expected> <actual>
assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$actual" = "$expected" ]; then
    green "  PASS"; echo " — $label (expected=$expected actual=$actual)"
    PASS=$((PASS+1))
  else
    red "  FAIL"; echo " — $label (expected=$expected actual=$actual)"
    FAIL=$((FAIL+1))
    FAILED_CASES+=("$label")
  fi
}

assert_in() {
  local label="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -q "$needle"; then
    green "  PASS"; echo " — $label (found '$needle')"
    PASS=$((PASS+1))
  else
    red "  FAIL"; echo " — $label (missing '$needle')"
    FAIL=$((FAIL+1))
    FAILED_CASES+=("$label")
  fi
}

echo "=== smoke @ $BASE ==="
echo

# ──────────────────────────────────────────────────────────────
# 0. Health
# ──────────────────────────────────────────────────────────────
echo "[0] GET /api/v1/ping (anonymous permit-all)"
status=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/api/v1/ping")
assert_eq "ping anonymous" "200" "$status"
echo

# ──────────────────────────────────────────────────────────────
# 1. anonymous 차단 검증 — 보호 엔드포인트
# ──────────────────────────────────────────────────────────────
echo "[1] GET /api/v1/missions without token → 403"
status=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/api/v1/missions?page=0")
assert_eq "anonymous → 403" "403" "$status"
echo

# ──────────────────────────────────────────────────────────────
# 2. register + login (게스트 자동 가입 시뮬레이션)
# ──────────────────────────────────────────────────────────────
TS=$(date +%s)
GUEST="Guest@${TS}-smoke"
PW=$(printf '%s' "$(uuidgen)" | md5)

echo "[2] register new guest"
status=$(curl -s -o /dev/null -w '%{http_code}' \
  -X POST "$BASE/api/v1/auth/register" \
  -H 'Content-Type: application/json' \
  -d "{\"userId\":\"$GUEST\",\"password\":\"$PW\"}")
assert_eq "register 201" "201" "$status"

echo "[3] login → JWT"
LOGIN_RES=$(curl -s -X POST "$BASE/api/v1/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"userId\":\"$GUEST\",\"password\":\"$PW\"}")
TOKEN=$(echo "$LOGIN_RES" | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null || echo "")
if [ -n "$TOKEN" ] && [ "${#TOKEN}" -gt 50 ]; then
  green "  PASS"; echo " — login (token len=${#TOKEN})"
  PASS=$((PASS+1))
else
  red "  FAIL"; echo " — login (no token: $LOGIN_RES)"
  FAIL=$((FAIL+1))
  FAILED_CASES+=("login")
  echo "Cannot continue without token. Aborting."
  exit 1
fi
echo

AUTH="-H Authorization:Bearer\ $TOKEN"
auth_curl() { curl -s -H "Authorization: Bearer $TOKEN" "$@"; }

# ──────────────────────────────────────────────────────────────
# 4. 401 자동 재로그인 시뮬레이션 (잘못된 토큰 → 401)
# ──────────────────────────────────────────────────────────────
echo "[4] GET /missions with INVALID token → 401/403"
status=$(curl -s -o /dev/null -w '%{http_code}' \
  -H 'Authorization: Bearer invalid_test_token' \
  "$BASE/api/v1/missions?page=0")
# Spring Security 는 invalid Bearer 를 401 또는 403 으로 응답. 둘 다 인증 실패 → 재로그인 트리거.
if [ "$status" = "401" ] || [ "$status" = "403" ]; then
  green "  PASS"; echo " — invalid token → $status (재로그인 대상)"
  PASS=$((PASS+1))
else
  red "  FAIL"; echo " — invalid token expected 401/403 actual=$status"
  FAIL=$((FAIL+1))
  FAILED_CASES+=("invalid token")
fi
echo

# ──────────────────────────────────────────────────────────────
# 5. 읽기 엔드포인트 9개
# ──────────────────────────────────────────────────────────────
echo "[5] GET /api/v1/missions?page=0"
data=$(auth_curl "$BASE/api/v1/missions?page=0")
count=$(echo "$data" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0)
if [ "$count" -gt 0 ]; then
  green "  PASS"; echo " — missions list ($count rows)"
  PASS=$((PASS+1))
else
  red "  FAIL"; echo " — missions empty"
  FAIL=$((FAIL+1))
  FAILED_CASES+=("missions list")
fi

echo "[6] GET /api/v1/missions/tutorial001"
status=$(auth_curl -o /dev/null -w '%{http_code}' "$BASE/api/v1/missions/tutorial001")
assert_eq "mission detail 200" "200" "$status"

DETAIL=$(auth_curl "$BASE/api/v1/missions/tutorial001")
assert_in "detail.mission.MissionID=tutorial001" 'tutorial001' "$DETAIL"
assert_in "detail.items exists" '"items"' "$DETAIL"

echo "[7] GET /api/v1/missions/tutorial001/replies"
status=$(auth_curl -o /dev/null -w '%{http_code}' "$BASE/api/v1/missions/tutorial001/replies")
assert_eq "replies 200" "200" "$status"

echo "[8] GET /api/v1/missions/tutorial001/ranking"
status=$(auth_curl -o /dev/null -w '%{http_code}' "$BASE/api/v1/missions/tutorial001/ranking")
assert_eq "ranking 200" "200" "$status"

echo "[9] GET /api/v1/missions/nearby"
status=$(auth_curl -o /dev/null -w '%{http_code}' "$BASE/api/v1/missions/nearby?page=0&latitude=37.485&longitude=126.808")
assert_eq "nearby 200" "200" "$status"

echo "[10] GET /api/v1/missions/tutorial (lang=ko)"
status=$(auth_curl -o /dev/null -w '%{http_code}' "$BASE/api/v1/missions/tutorial?lang=ko")
assert_eq "tutorial 200" "200" "$status"

echo "[11] GET /api/v1/missions/playing"
status=$(auth_curl -o /dev/null -w '%{http_code}' "$BASE/api/v1/missions/playing?page=0")
assert_eq "popular 200" "200" "$status"

echo "[12] GET /api/v1/users/$GUEST"
status=$(auth_curl -o /dev/null -w '%{http_code}' "$BASE/api/v1/users/$GUEST")
assert_eq "users/{id} 200" "200" "$status"

echo "[13] GET /api/v1/users/$GUEST/missions/designed"
status=$(auth_curl -o /dev/null -w '%{http_code}' "$BASE/api/v1/users/$GUEST/missions/designed")
assert_eq "designed 200" "200" "$status"

echo "[14] GET /api/v1/users/$GUEST/missions/played"
status=$(auth_curl -o /dev/null -w '%{http_code}' "$BASE/api/v1/users/$GUEST/missions/played")
assert_eq "played 200" "200" "$status"

echo "[15] GET /api/v1/users/$GUEST/missions/playing"
status=$(auth_curl -o /dev/null -w '%{http_code}' "$BASE/api/v1/users/$GUEST/missions/playing")
assert_eq "playing 200" "200" "$status"
echo

# ──────────────────────────────────────────────────────────────
# 16. 쓰기 — 플레이 사이클
# ──────────────────────────────────────────────────────────────
START_TIME=$(date -u +"%Y-%m-%d %H:%M:%S")

echo "[16] POST /missions/tutorial001/plays/start"
status=$(curl -s -o /dev/null -w '%{http_code}' \
  -X POST "$BASE/api/v1/missions/tutorial001/plays/start" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{\"playerId\":\"$GUEST\",\"startTime\":\"$START_TIME\",\"isVirtual\":1}")
assert_eq "plays/start 200" "200" "$status"

sleep 1
END_TIME=$(date -u +"%Y-%m-%d %H:%M:%S")

echo "[17] POST /missions/tutorial001/plays/finish"
status=$(curl -s -o /dev/null -w '%{http_code}' \
  -X POST "$BASE/api/v1/missions/tutorial001/plays/finish" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{\"playerId\":\"$GUEST\",\"startTime\":\"$START_TIME\",\"endTime\":\"$END_TIME\",\"isVirtual\":1}")
assert_eq "plays/finish 204" "204" "$status"

echo "[18] GET /users/$GUEST/missions/played 후 tutorial001 포함 확인"
data=$(auth_curl "$BASE/api/v1/users/$GUEST/missions/played")
assert_in "played includes tutorial001" 'tutorial001' "$data"

echo "[19] POST /missions/tutorial001/replies"
status=$(curl -s -o /dev/null -w '%{http_code}' \
  -X POST "$BASE/api/v1/missions/tutorial001/replies" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{\"userId\":\"$GUEST\",\"score\":4.5,\"reply\":\"smoke test comment\"}")
# 204 또는 200 모두 허용
if [ "$status" = "204" ] || [ "$status" = "200" ]; then
  green "  PASS"; echo " — replies POST ($status)"
  PASS=$((PASS+1))
else
  red "  FAIL"; echo " — replies POST status=$status"
  FAIL=$((FAIL+1))
  FAILED_CASES+=("replies POST")
fi
echo

# ──────────────────────────────────────────────────────────────
# 결과
# ──────────────────────────────────────────────────────────────
echo "─────────────────────────────────────"
echo "총 PASS: $(green "$PASS")"
echo "총 FAIL: $(red "$FAIL")"
if [ "$FAIL" -gt 0 ]; then
  echo
  echo "실패 케이스:"
  for c in "${FAILED_CASES[@]}"; do echo "  - $c"; done
  exit 1
fi
exit 0
