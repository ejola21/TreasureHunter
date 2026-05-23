# test_design_plan.md — 미션 디자이너 회귀 테스트 계획

> 미션 디자이너 (Builder) 의 신규 `/api/v1/**` API 연동과 SwiftUI 화면 동작을 검증하기 위한 **사전 테스트 계획서**.
>
> 실행 후 결과는 [`test_design_report.md`](test_design_report.md) 에 같은 phase 번호로 기록한다.

## 0. 목적 / 범위

| 항목 | 내용 |
|---|---|
| **목적** | [`api_designer.md`](api_designer.md) 의 서버 사양 (R1.1 ~ R3.1) + [`plan_designer.md`](plan_designer.md) 의 클라이언트 구현을 회귀 검증 |
| **범위** | 서버 API (curl) + 클라이언트 빌드 (xcodebuild) + 시뮬레이터 부팅 |
| **범위 외** | XCUITest 자동화 (cliclick 권한 이슈로 불가) — 별도 작업으로 분리 |
| **소요 시간** | 약 10~15 분 (자동화 후 < 5 분 목표) |

---

## 1. 사전 조건

### 1.1 도구

- `bash` / `curl` / `python3` (JSON 파싱)
- `xcodebuild` 16+ (iPhone 16 Pro Simulator)
- 서비스 계정 불필요 — 매 실행마다 `testA_<ts>` / `testB_<ts>` 신규 등록

### 1.2 서버

- BASE: `http://43.201.188.35:8080`
- OpenAPI: `/api-docs` / Swagger UI: `/swagger-ui/index.html`
- 사전 헬스체크: `GET /api/v1/ping` → `200`

### 1.3 시드 JSON (`/tmp/new_mission.json`)

Start (49) / Quiz (40) / End (48) 3-아이템 + Quiz 변형 1개. api_designer.md §2.1 예시와 동일 구조.

### 1.4 클라이언트

- `PlaySpot.xcodeproj` 가 `xcodegen generate` 로 최신 상태
- `AppConfig.backend = .rest` (기본값)

---

## 2. 테스트 매트릭스 (Phase 별 케이스)

총 **9 Phase / 36 케이스**. 각 케이스마다 입력·기대 결과·검증 방법을 명시. 실행 후 PASS/FAIL 을 report 에 기록.

### Phase 1 — 서버 schema 확인 (5 케이스)

`GET /api-docs` 의 path / requestBody / responses 와 클라이언트 [`RestAPIDTO.swift`](PlaySpot/Network/RestAPIDTO.swift) 의 `Builder*` DTO 비교.

| # | 항목 | 기대 |
|---|---|---|
| 1.1 | `POST /api/v1/missions` schema 노출 | `BuilderMissionReq → BuilderMissionCreatedRes`, responses 201/400/401 |
| 1.2 | `PATCH /api/v1/missions/{id}` schema | reqBody=`BuilderMissionReq`, responses 204/400/401/403/404 |
| 1.3 | `DELETE /api/v1/missions/{id}` schema | responses 204/401/403/404/**409** |
| 1.4 | `MissionFields` 8 필드 | Title/Description/Place/RunLimitTime/Status/Virtual/Lang/BadgeImageName |
| 1.5 | `ItemFields` 14 필드 | ItemID/Mandatory/ItemType (필수) + 좌표/rangeAR/showType 등 |

**합격 기준**: 5개 모두 매칭. 불일치 발견 시 DTO 또는 서버 어느 쪽을 맞출지 결정.

### Phase 2 — 인증 셋업 (4 케이스)

| # | 동작 | 기대 |
|---|---|---|
| 2.1 | `POST /api/v1/auth/register testA_<ts>` | 201 |
| 2.2 | `POST /api/v1/auth/register testB_<ts>` | 201 |
| 2.3 | `POST /api/v1/auth/login A` | 200 + `{token}` |
| 2.4 | `POST /api/v1/auth/login B` | 200 + `{token}` |

**합격 기준**: 두 토큰 모두 유효 (`/api/v1/ping` 호출 시 200).

### Phase 3 — Happy path (4 케이스)

| # | 입력 | 기대 |
|---|---|---|
| 3.1 | anonymous `POST /api/v1/missions` | **401 UNAUTHORIZED** |
| 3.2 | A 토큰 + 시드 JSON → `POST /missions` | **201** + `{missionId: "playspot_…"}` |
| 3.3 | `GET /missions/{id}` | Designer=`testA_<ts>`, items=3, quizzes=1, Title 일치 |
| 3.4 | A 토큰 → `GET /users/<A>/missions/designed` | rows=1, Designer=testA, Status=0 |

**합격 기준**: MissionID 형식 `playspot_<YYYYMMDD_HHmm>_<rand4>` 일치.

### Phase 4 — 검증 실패 (5 케이스)

| # | 변조 | 기대 |
|---|---|---|
| 4.1 | `mission.Title = ""` | 400, `details` 에 `mission.title` 또는 `Title` 포함 |
| 4.2 | `items.length = 2` | 400, "최소 3개 필요" 또는 동등 메시지 |
| 4.3 | items 에서 ItemType="49" 제거 (그대로 3개 유지) | 400, "Start (49) 정확히 1개 필요" |
| 4.4 | items 에서 ItemType="48" 제거 | 400, "End (48) 정확히 1개 필요" |
| 4.5 | `quizzes = []` (Quiz item 은 그대로) | 400, "Quiz 아이템 ItemID=2 에 매칭되는 quiz row 필요" |

**합격 기준**: 모두 400 + `details` 가 위반 필드 식별.

### Phase 5 — 권한 + PATCH 성공 (6 케이스)

| # | 동작 | 기대 |
|---|---|---|
| 5.1 | B 토큰으로 A 미션 PATCH | **403 FORBIDDEN** |
| 5.2 | B 토큰으로 A 미션 DELETE | **403 FORBIDDEN** |
| 5.3 | B 토큰으로 `GET /users/<A>/missions/designed` | **403 FORBIDDEN** |
| 5.4 | anonymous `GET /users/<A>/missions/designed` | **401 UNAUTHORIZED** |
| 5.5 | A 토큰으로 A 미션 PATCH (Title 변경) | **204** |
| 5.6 | 변경 후 GET → 새 Title 반영 | Title=신규 값 |

**합격 기준**: `Designer == JWT.userId` 강제 + R1.4 의 `{userId} == JWT.userId` 강제 (api_designer.md §1.2 신뢰 체인).

### Phase 6 — DELETE 정책 (6 케이스, §1.4.2)

| # | 동작 | 기대 |
|---|---|---|
| 6.1 | Status=0 미션 DELETE | **204** |
| 6.2 | 삭제 후 GET | **404** (code 는 `DATA_NOT_FOUND` 또는 `MISSION_NOT_FOUND`) |
| 6.3 | 삭제 후 designed 목록 조회 | rows=0 |
| 6.4 | Status=2 미션 만들고 DELETE 시도 | **409 MISSION_NOT_DELETABLE** + 메시지에 "DESIGNING/TESTED only" 포함 |
| 6.5 | 미존재 missionId DELETE | **404** |
| 6.6 | 공개해제 (PATCH Status 2→1) + 다시 DELETE | PATCH 204 + DELETE 204 |

**합격 기준**: §1.4.2 정책 (Status NOT IN (0,1) 거절) 동작.

### Phase 7 — 배지 업로드 (4 케이스)

| # | 동작 | 기대 |
|---|---|---|
| 7.1 | anonymous `POST /api/v1/badges` (multipart `file`) | **401** |
| 7.2 | A 토큰 + 1×1 PNG | **201** + `{fileName, url}` |
| 7.3 | 응답 `url` 로 GET | 200 + image binary |
| 7.4 | `POST /missions` body 에 `BadgeImageName=<fileName>` 포함 → GET 응답에 반영 | `mission.BadgeImageName == fileName` |

**합격 기준**: 모두 201/200 + 미션 응답에 반영.

### Phase 8 — 클라이언트 빌드 + 시뮬레이터 (2 케이스)

| # | 동작 | 기대 |
|---|---|---|
| 8.1 | `xcodebuild -scheme PlaySpot -sdk iphonesimulator build CODE_SIGNING_ALLOWED=NO` | `BUILD SUCCEEDED` (deprecated 경고만) |
| 8.2 | `bash scripts/verify.sh` | 시뮬레이터 부팅·앱 실행·`/tmp/playspot_shot.png` 생성. Missions 탭에 미션 목록 로드 |

**합격 기준**: 빌드 에러 0, 런타임 crash 없음.

### Phase 9 — 결과 기록 (운영)

- [`test_design_report.md`](test_design_report.md) 에 Phase 1~8 결과를 같은 번호로 기록
- 발견된 이슈는 §1 (발견된 이슈) 에 I-prefix 로 추가
- 미실행/추후 항목은 §4 (추후 권장 테스트) 로 분리

---

## 3. 실행 절차 (수동)

> 자동화는 [`scripts/smoke_new_api.sh`](scripts/smoke_new_api.sh) 에 case 함수로 추가 권장.

```bash
# 0. 환경
BASE=http://43.201.188.35:8080
ts=$(date +%s)
USER_A="testA_$ts"
USER_B="testB_$ts"

# 1. 등록 + 로그인
curl -s -X POST $BASE/api/v1/auth/register -H 'Content-Type: application/json' \
  -d "{\"userId\":\"$USER_A\",\"password\":\"pass1234\"}"
curl -s -X POST $BASE/api/v1/auth/register -H 'Content-Type: application/json' \
  -d "{\"userId\":\"$USER_B\",\"password\":\"pass1234\"}"
TOKEN_A=$(curl -s -X POST $BASE/api/v1/auth/login -H 'Content-Type: application/json' \
  -d "{\"userId\":\"$USER_A\",\"password\":\"pass1234\"}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])')
TOKEN_B=$(curl -s -X POST $BASE/api/v1/auth/login -H 'Content-Type: application/json' \
  -d "{\"userId\":\"$USER_B\",\"password\":\"pass1234\"}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])')

# 2. 시드 미션 JSON 생성 후 Phase 3 ~ 7 의 case 별 호출
#    (구체적 case 들은 §2 매트릭스 참조. 한 case = 한 curl)

# 3. 클라이언트 검증
bash scripts/verify.sh
```

---

## 4. 자동화 권장 (향후)

| 항목 | 권장 도구 |
|---|---|
| API 36 case smoke | `scripts/smoke_designer.sh` 신규 — case 별 bash 함수 + summary 출력 |
| 클라이언트 UI E2E | XCUITest (`PlaySpotUITests/MissionBuilderFlowTests.swift`) — longTap → ItemPicker → Save → 서버 도달 검증 |
| CI 통합 | PR 마다 위 두 스크립트 실행 + result 를 `test_design_report.md` 에 자동 갱신 |

---

## 5. 참고

- [`api_designer.md`](api_designer.md) — 서버 사양 (R1.1~R3.1)
- [`plan_designer.md`](plan_designer.md) — 클라 작업 계획
- [`test_design_report.md`](test_design_report.md) — 직전 회귀 결과
- [`PlaySpot/Network/RestAPIDTO.swift`](PlaySpot/Network/RestAPIDTO.swift) — Builder DTO
- [`PlaySpot/Views/MissionBuilder/`](PlaySpot/Views/MissionBuilder/) — 빌더 UI
- Swagger UI: <http://43.201.188.35:8080/swagger-ui/index.html>
