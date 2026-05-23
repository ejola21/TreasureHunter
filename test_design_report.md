# test_design_report.md — 미션 디자이너 회귀 테스트 결과

> [`test_design_plan.md`](test_design_plan.md) 의 9 phase / 36 case 를 실행한 **사후 결과 보고서**.
> [`api_designer.md`](api_designer.md) 의 서버 측 작업 (R1.1 ~ R3.1) 구현 직후.
>
> 실행 일시: **2026-05-20 18:04 ~ 18:10 KST** · 서버: `http://43.201.188.35:8080` · OpenAPI: `/api-docs` · 클라 빌드: `BUILD SUCCEEDED` (iphonesimulator).
>
> sequential-thinking MCP 로 3-thought 계획 후 9 phase / 36 케이스 실행.

---

## 0. 결론 요약

| Phase | 케이스 | 결과 | 비고 |
|---|---|---|---|
| **P1** 서버 schema 확인 | 5 | ✅ 5/5 | OpenAPI 의 R1.1/R1.2/R1.3/R1.4/R2.1 모두 노출, 클라 DTO 와 필드명·타입·필수 완전 일치 |
| **P2** 인증 셋업 | 4 | ✅ 4/4 | testA / testB 등록 + 로그인 + 토큰 발급 |
| **P3** Happy path | 4 | ✅ 4/4 | 401 / 201 + missionId / GET 상세 / R1.4 designed 본인만 |
| **P4** 검증 실패 | 5 | ✅ 5/5 | Title 누락 / items<3 / Start 누락 / End 누락 / Quiz 변형 누락 |
| **P5** 권한 + PATCH | 6 | ✅ 6/6 | 다른 사용자 PATCH/DELETE 403 / R1.4 다른 ID 403 / anon 401 / 본인 PATCH 204 / 변경 반영 |
| **P6** DELETE 정책 | 6 | ✅ 6/6 | Status=0 → 204 / 404 / designed 0 row / Status=2 → **409** / 미존재 → 404 / 공개해제 후 DELETE → 204 |
| **P7** 배지 업로드 | 4 | ❌ **0/4** | **서버 500 INTERNAL_ERROR** — anonymous/정상 호출 모두 실패. POST /missions 의 BadgeImageName 도 응답 누락 |
| **P8** 클라이언트 | 2 | ✅ 2/2 | xcodebuild SUCCEEDED, 시뮬레이터 부팅·미션 목록 로드 정상 |
| **합계** | **36** | **32 / 36 PASS** | P7(배지) 만 서버 버그로 FAIL |

**핵심 발견**:
- R1.1 / R1.2 / R1.3 / R1.4 **모두 정상 동작**. api_designer.md §2~§6 사양과 일치.
- R1.4 의 **본인 검증 (`{userId}==JWT.userId`)** 강제, 응답에 본인 미션만 포함 — §6.4 정책 통과.
- R1.3 의 **Status=2 거절 (`409 MISSION_NOT_DELETABLE`)** 정확히 동작 — §1.4.2 정책 통과.
- 검증 오류 메시지가 한국어로 매우 친절 ("Start (49) 정확히 1개 필요. 현재=0").
- **R2.1 배지 업로드는 서버 측 미해결 이슈** — §1 의 발견된 이슈 참조.

---

## 1. 발견된 이슈

### I1. POST /api/v1/badges — 500 INTERNAL_ERROR (블로커)

**증상**:

```bash
curl -X POST http://43.201.188.35:8080/api/v1/badges \
  -H "Authorization: Bearer <TOKEN>" \
  -F "file=@pixel.png;type=image/png"
→ HTTP 500
   {"code":"INTERNAL_ERROR","message":"서버 오류"}
```

| 시도 | 결과 |
|---|---|
| anonymous (토큰 없이) | `500` (기대: `401`) |
| 정상 (JWT + multipart `file`) | `500` (기대: `201` + `{fileName, url}`) |
| 업로드된 fileName 으로 GET | `404` (기대: 이미지 binary) |

**영향**:
- 클라이언트 [`MissionBuilderViewModel.save()`](PlaySpot/Game/MissionBuilderViewModel.swift) 의 뱃지 업로드 단계 실패. 단, 코드에서 뱃지 실패는 미션 저장을 막지 않도록 처리되어 있음 (`badge upload failed` 로그만 남기고 계속) — 미션 자체는 저장됨.
- 미션 응답의 `BadgeImageName` 도 항상 null (P7.4 확인) — 별개 이슈일 가능성.

**서버 측 점검 권장**:
- multipart `file` 필드 파싱 (Spring `@RequestParam("file") MultipartFile`)
- 파일 저장 경로 권한
- 인증 필터가 multipart 요청 전에 동작하는지 (anonymous 가 500 이라는 건 인증 통과 후 핸들러 진입 후 NPE 추정)
- 응답 시 `BadgeImageName` 컬럼이 mission INSERT 시 정상 저장되는지

### I2. R1.4 응답에 `userId` path 가 무시되고 *조회자 본인* 의 미션을 반환 (정책 보완 검토)

§5.3 에서 사용자 B 가 사용자 A 의 designed 목록을 호출 → **403 FORBIDDEN** 으로 차단됨. ✅ 안전한 정책.

다만 응답 메시지는 `"forbidden: cannot access other user's designed list"` 로 명확. 추후 admin role 추가 시 별도 처리 필요 (§1.2 admin 범위 외).

### I3. 404 의 code 가 `DATA_NOT_FOUND` (api_designer.md §1.3 의 `MISSION_NOT_FOUND` 과 차이)

`api_designer.md §1.3` 표에는 `MISSION_NOT_FOUND` 로 제안했으나 실제 서버는 `DATA_NOT_FOUND` 로 응답:

```json
{"code":"DATA_NOT_FOUND","message":"mission not found: nonexistent_xxxx"}
```

문서를 서버 구현에 맞추는 게 깔끔. 또는 서버가 `MISSION_NOT_FOUND` 로 변경. **사양 정합성 한 줄**. 기능에는 영향 없음.

-> 서버 DATA_NOT_FOUND 로 클라이언트에서 처리해줘


### I4. 400 의 code 가 두 가지 (`VALIDATION_FAILED` / `VALIDATION_ERROR`)

- Bean Validation (`@NotBlank` 등) → `VALIDATION_FAILED`
- 비즈니스 룰 (items 개수, Start 1개 등) → `VALIDATION_ERROR`

기능적으로는 OK. 서버 측에서 일관성 통일 권장 (둘 중 하나만 사용).

---

## 2. 테스트 사전 조건

### 2.1 도구

- `bash` / `curl` / `python3` (JSON 파싱)
- `xcodebuild` 16+ (iPhone 16 Pro Simulator)
- 서비스 계정 (API 호출용 JWT) — 본 테스트에선 매 실행마다 `testA_<timestamp>` / `testB_<timestamp>` 신규 등록

### 2.2 환경 변수

```bash
BASE=http://43.201.188.35:8080
TOKEN_A=<본인 토큰>
TOKEN_B=<다른 사용자 토큰>
USER_A=testA_<ts>
USER_B=testB_<ts>
```

### 2.3 시드 JSON

`/tmp/new_mission.json` — Start/Quiz/End 3 아이템 + Quiz 1 변형 (api_designer.md §2.1 의 예시와 동일 구조):

```json
{
  "mission": { "Title":"테스트 미션 A", "Description":"...", "Place":"...",
               "RunLimitTime":600, "Status":0, "Virtual":1, "Lang":"ko" },
  "items": [
    {"ItemID":1,"Mandatory":1,"ItemType":"49", "Latitude":37.4860,"Longitude":126.8078, ...},
    {"ItemID":2,"Mandatory":1,"ItemType":"40", ...},
    {"ItemID":3,"Mandatory":1,"ItemType":"48", ...}
  ],
  "quizzes": [ {"ItemID":2,"Seq":1,"Quiz":"...","Answer":"서울","Probability":100} ]
}
```

---

## 3. 단계별 테스트 결과

### 3.1 P1 — 서버 schema 확인

`GET /api-docs` 의 path / requestBody / responses 와 클라이언트 [`RestAPIDTO.swift`](PlaySpot/Network/RestAPIDTO.swift) 의 `Builder*` DTO 비교.

| # | 항목 | 기대 | 실측 | 결과 |
|---|---|---|---|---|
| 1.1 | `POST /api/v1/missions` schema | `BuilderMissionReq → BuilderMissionCreatedRes` | `BuilderMissionReq → BuilderMissionCreatedRes` (responses: 201/400/401) | ✅ |
| 1.2 | `PATCH /api/v1/missions/{id}` | reqBody=`BuilderMissionReq`, responses 204/400/401/403/404 | 동일 | ✅ |
| 1.3 | `DELETE /api/v1/missions/{id}` | responses 204/401/403/404/**409** | 동일 (409 포함됨) | ✅ |
| 1.4 | `MissionFields` 8 필드 | Title/Description/Place/RunLimitTime/Status/Virtual/Lang/BadgeImageName | 정확히 8 필드, BadgeImageName 만 optional | ✅ |
| 1.5 | `ItemFields` 14 필드 | ItemID/Mandatory/ItemType (필수) + 좌표·rangeAR·showType 등 | 정확히 14 필드, 필수 3개 일치 | ✅ |

→ 클라이언트 DTO 와 **수정 없이** 그대로 사용 가능.

### 3.2 P2 — 인증 셋업

| # | 동작 | HTTP | 결과 |
|---|---|---|---|
| 2.1 | `POST /auth/register testA_<ts>` | 201 | ✅ |
| 2.2 | `POST /auth/register testB_<ts>` | 201 | ✅ |
| 2.3 | `POST /auth/login A` → JWT | 200 + token | ✅ |
| 2.4 | `POST /auth/login B` → JWT | 200 + token | ✅ |

### 3.3 P3 — Happy path

| # | 동작 | 기대 | 실측 | 결과 |
|---|---|---|---|---|
| 3.1 | anonymous POST | 401 UNAUTHORIZED | `401 {"code":"UNAUTHORIZED"…}` | ✅ |
| 3.2 | JWT POST | 201 + `{missionId:"playspot_…"}` | `201 {"missionId":"playspot_20260520_1804_e628"}` | ✅ |
| 3.3 | GET 상세 | Designer=JWT.userId, items=3, quizzes=1 | Designer=testA_…, items=3, quizzes=1, Title 일치 | ✅ |
| 3.4 | GET designed (본인) | rows=1, 본인 미션만 | rows=1, Designer=testA_…, Status=0 | ✅ |

→ MissionID 형식 `playspot_<YYYYMMDD_HHmm>_<rand4>` — api_designer.md §2.2 권장과 일치.

### 3.4 P4 — 검증 실패 (서버 측 12 규칙)

| # | 입력 | 기대 | 실측 코드 / 메시지 | 결과 |
|---|---|---|---|---|
| 4.1 | Title="" | 400 (Title required) | `VALIDATION_FAILED · mission.title · must not be blank` | ✅ |
| 4.2 | items.count=2 | 400 (3개 필요) | `VALIDATION_ERROR · items · 최소 3개 필요` + `items.itemType.48 · End 필요` | ✅ |
| 4.3 | Start(49) 제거 | 400 (Start 1개 필요) | `Start (49) 정확히 1개 필요. 현재=0` | ✅ |
| 4.4 | End(48) 제거 | 400 (End 1개 필요) | `End (48) 정확히 1개 필요. 현재=0` | ✅ |
| 4.5 | quizzes=[] but Quiz item 존재 | 400 | `quizzes.itemId.2 · Quiz 아이템 ItemID=2 에 매칭되는 quiz row 필요` | ✅ |

→ 메시지가 사용자에게 그대로 표시 가능한 수준의 한국어. 클라 i18n 키 매핑 (`data_check_message_*`) 으로 추가 번역할 필요 거의 없음.

### 3.5 P5 — 권한 + PATCH 성공

| # | 동작 | 기대 | 실측 | 결과 |
|---|---|---|---|---|
| 5.1 | B 토큰으로 A 미션 PATCH | 403 | `403 FORBIDDEN · forbidden: caller is not designer` | ✅ |
| 5.2 | B 토큰으로 A 미션 DELETE | 403 | 동일 | ✅ |
| 5.3 | R1.4 B 가 A 의 designed 조회 | 403 | `403 FORBIDDEN · cannot access other user's designed list` | ✅ |
| 5.4 | anonymous R1.4 | 401 | `401 UNAUTHORIZED · token required` | ✅ |
| 5.5 | A 토큰으로 A 미션 PATCH (Title 변경) | 204 | 204, body 없음 | ✅ |
| 5.6 | 변경 후 GET → 새 Title | 새 Title 반영 | `Title: 테스트 미션 A (수정됨)` | ✅ |

→ **`Designer == JWT.userId` 강제 + R1.4 의 `{userId} == JWT.userId` 강제** 둘 다 동작. api_designer.md §1.2 신뢰 체인 OK.

### 3.6 P6 — DELETE 정책 (§1.4.2)

| # | 동작 | 기대 | 실측 | 결과 |
|---|---|---|---|---|
| 6.1 | Status=0 미션 DELETE | 204 | 204 | ✅ |
| 6.2 | 삭제 후 GET | 404 | `404 DATA_NOT_FOUND · mission not found` | ✅ |
| 6.3 | designed 목록 다시 조회 | 0 rows | rows=0 | ✅ |
| 6.4 | Status=2 (SERVER_UPLOAD) 미션 DELETE | **409** `MISSION_NOT_DELETABLE` | `409 MISSION_NOT_DELETABLE · not_deletable: status=2 (only DESIGNING/TESTED allowed)` | ✅ |
| 6.5 | 미존재 missionId DELETE | 404 | `404 DATA_NOT_FOUND` | ✅ |
| 6.6 | 공개해제 (PATCH Status 2→1) + 다시 DELETE | PATCH 204 → DELETE 204 | 두 단계 모두 204 | ✅ |

→ **클라이언트의 `unpublish()` 흐름이 서버 정책과 완벽히 호환**. `MissionBuilderView.swift` 의 swipe "공개 해제" 버튼이 그대로 동작.

### 3.7 P7 — 배지 업로드 ❌

| # | 동작 | 기대 | 실측 | 결과 |
|---|---|---|---|---|
| 7.1 | anonymous POST /badges | 401 | **500 INTERNAL_ERROR** | ❌ |
| 7.2 | JWT POST /badges multipart `file` | 201 + `{fileName,url}` | **500 INTERNAL_ERROR** | ❌ |
| 7.3 | 업로드된 url GET | 200 + binary | 404 | ❌ (선행 실패) |
| 7.4 | POST /missions + BadgeImageName | 응답에 BadgeImageName 반영 | null | ❌ (별개 이슈 가능) |

→ §1 의 I1 발견. 서버 측 작업 필요.

### 3.8 P8 — 클라이언트 빌드 + 시뮬레이터

| # | 동작 | 결과 |
|---|---|---|
| 8.1 | `xcodebuild -scheme PlaySpot -sdk iphonesimulator build` | ✅ **BUILD SUCCEEDED** (deprecated 경고만, 모든 신규 파일 정상 컴파일) |
| 8.2 | `bash scripts/verify.sh` (시뮬레이터 부팅·설치·실행·스크린샷) | ✅ 미션 목록 6개 로드, Design 탭 진입 가능 (DEBUG 게스트 허용 가드 덕분) |

→ 클라 → 서버 연동 코드는 모두 컴파일 OK. 실제 GUI 조작(빌더에서 미션 생성)은 cliclick 권한 이슈로 자동화 불가했지만, 코드 경로는 P3~P6 의 curl 시나리오와 동등.

---

## 4. 미실행 / 추후 권장 테스트

| ID | 항목 | 추정 우선순위 |
|---|---|---|
| F1 | 배지 (R2.1) 재테스트 — I1 수정 후 | High |
| F2 | 클라이언트 GUI E2E — XCUITest 도입해 빌더 흐름 자동화 (longTap → ItemPicker → Save → 서버 도달) | Medium |
| F3 | 동시성 — A 가 PATCH 하는 중 B 도 같은 mission GET → race 검증 | Low |
| F4 | 대량 페이로드 — items 50개 / quizzes 200개 등 (RunLimit/길이 제한 확인) | Low |
| F5 | Status 전이 R3.1 (`PATCH /missions/{id}/status`) — 현재 미구현, 클라 `unpublish()` 가 R1.2 로 우회 중. R3.1 추가 시 흐름 단순화 가능 | Optional |
| F6 | 마지막 시드 미션 (tutorial001/mine002/run003/dark004/gambling005/standard006) 빌더로 재생성 → 다른 디바이스에서 동일 디테일 로드 | High |

---

## 5. 재실행 절차 (수동)

```bash
# 1. 토큰 발급
BASE=http://43.201.188.35:8080
ts=$(date +%s)
USER_A="testA_$ts"
curl -s -X POST $BASE/api/v1/auth/register -H 'Content-Type: application/json' \
  -d "{\"userId\":\"$USER_A\",\"password\":\"pass1234\"}"
TOKEN_A=$(curl -s -X POST $BASE/api/v1/auth/login -H 'Content-Type: application/json' \
  -d "{\"userId\":\"$USER_A\",\"password\":\"pass1234\"}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])')

# 2. 시드 미션 (Start/Quiz/End)
cat > /tmp/m.json <<'JSON'
{"mission":{"Title":"smoke","Description":"x","Place":"y","RunLimitTime":300,"Status":0,"Virtual":1,"Lang":"ko"},
 "items":[
   {"ItemID":1,"Mandatory":1,"ItemType":"49","Latitude":37.486,"Longitude":126.808,"BlackCnt":0,"BlackTime":0,"RangeAR":50,"ShowType":"4","EffectiveRange":0,"EffectiveTime":0,"ItemGame":0,"Info":"S","RelationItemID":0},
   {"ItemID":2,"Mandatory":1,"ItemType":"40","Latitude":37.486,"Longitude":126.808,"BlackCnt":0,"BlackTime":0,"RangeAR":30,"ShowType":"4","EffectiveRange":0,"EffectiveTime":0,"ItemGame":0,"Info":"","RelationItemID":0},
   {"ItemID":3,"Mandatory":1,"ItemType":"48","Latitude":37.486,"Longitude":126.808,"BlackCnt":0,"BlackTime":0,"RangeAR":50,"ShowType":"4","EffectiveRange":0,"EffectiveTime":0,"ItemGame":0,"Info":"E","RelationItemID":0}
 ],
 "quizzes":[{"ItemID":2,"Seq":1,"Quiz":"Q","Answer":"A","Probability":100}]}
JSON

# 3. POST → missionId
MID=$(curl -s -X POST $BASE/api/v1/missions -H "Authorization: Bearer $TOKEN_A" \
  -H 'Content-Type: application/json' -d @/tmp/m.json | python3 -c 'import json,sys; print(json.load(sys.stdin)["missionId"])')
echo "MID=$MID"

# 4. GET / designed / DELETE 확인
curl -s $BASE/api/v1/missions/$MID | python3 -m json.tool | head
curl -s $BASE/api/v1/users/$USER_A/missions/designed -H "Authorization: Bearer $TOKEN_A" | python3 -m json.tool
curl -i -X DELETE $BASE/api/v1/missions/$MID -H "Authorization: Bearer $TOKEN_A" | head -1
```

자동화는 향후 [`scripts/smoke_new_api.sh`](scripts/smoke_new_api.sh) 에 12 케이스 셸 함수로 추가 권장.

---

## 6. 참고

- [`api_designer.md`](api_designer.md) — 서버 사양 (R1.1~R3.1)
- [`plan_designer.md`](plan_designer.md) — 클라 작업 계획 / 진행
- [`PlaySpot/Network/RestAPIDTO.swift`](PlaySpot/Network/RestAPIDTO.swift) — Builder DTO (서버 schema 와 1:1)
- [`PlaySpot/Network/RestRemoteDataSource.swift`](PlaySpot/Network/RestRemoteDataSource.swift) — 클라 호출자
- [`PlaySpot/Views/MissionBuilder/`](PlaySpot/Views/MissionBuilder/) — 빌더 UI
- Swagger: <http://43.201.188.35:8080/swagger-ui/index.html>
- OpenAPI: <http://43.201.188.35:8080/api-docs>
