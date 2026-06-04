# api_designer.md — 미션 디자이너 (Builder) 추가 서버 API 사양

> 본 문서는 [`plan_designer.md`](plan_designer.md) §5 의 서버 측 작업(P0)을 별도로 떼어내, 서버 담당자가 바로 작업 가능한 수준의 사양으로 정리한다.
>
> 진단 일시: **2026-05-20** · OpenAPI probe: `http://43.201.188.35:8080/api-docs` · Swagger UI: `http://43.201.188.35:8080/swagger-ui/index.html`

---

## 0. 결론 요약 — 추가 필요 엔드포인트

| # | Method · Path | 우선순위 | 클라 측 호출자 | 차단되는 기능 |
|---|---|---|---|---|
| **R1.1** | `POST /api/v1/missions` | **블로커** | [`RestRemoteDataSource.createMission`](PlaySpot/Network/RestRemoteDataSource.swift) | 신규 미션 업로드 (빌더 → SERVER_UPLOAD) |
| **R1.2** | `PATCH /api/v1/missions/{missionId}` | **블로커** | [`RestRemoteDataSource.updateMission`](PlaySpot/Network/RestRemoteDataSource.swift) | 기존 미션 편집 |
| **R1.3** | `DELETE /api/v1/missions/{missionId}` | **블로커** | [`RestRemoteDataSource.deleteMission`](PlaySpot/Network/RestRemoteDataSource.swift) | 미션 삭제 |
| **R1.4** | `GET /api/v1/users/{userId}/missions/designed` *(시멘틱 명문화)* | **High** | [`RestRemoteDataSource.fetchMyDesigned`](PlaySpot/Network/RestRemoteDataSource.swift) | Design 탭 — **본인이 작성한 미션 전체 목록** |
| **R2.1** | `POST /api/v1/badges` *(존재 확인 + 사양 명문화)* | High | [`RestRemoteDataSource.uploadBadgeImage`](PlaySpot/Network/RestRemoteDataSource.swift) | 뱃지 이미지 첨부 |
| **R3.1** | `PATCH /api/v1/missions/{missionId}/status` | **🔴 P0 (즉시 필요)** | Flutter 웹/안드로이드 publish 토글 | **Flutter 측 publish/unpublish 동작 불가 (HTTP 400) — §7 상세** |

### 0.1 두 미션 목록의 분리 — **반드시 구분할 것**

PlaySpot 의 미션 목록은 **시멘틱이 완전히 다른 2개**가 공존한다. 서버 작업자가 자주 혼동하므로 명시:

| 화면 | 호출 API | 시멘틱 | 권한 | mutating 동작 |
|---|---|---|---|---|
| **Missions 탭** (Playing / Near Me / All) | `GET /api/v1/missions` <br> `GET /api/v1/missions/nearby` <br> `GET /api/v1/missions/tutorial` <br> `GET /api/v1/missions/playing` | **모든 사용자가 만든 공개 미션** (SERVER_UPLOAD 상태) | 누구나 조회 | 플레이만 가능 (start/finish/fail). 편집/삭제 X |
| **Design 탭** (내 디자인) | `GET /api/v1/users/{userId}/missions/designed` | **본인이 작성한 미션** 전체 (DESIGNING / TESTED / SERVER_UPLOAD) | 본인만 조회 (`userId == JWT.userId` 강제) | **본인이 작성한 미션이므로 모두 PATCH / DELETE 호출 가능** |

→ R1.4 의 핵심: "Design 탭이 반환하는 row 들은 **자동으로** PATCH/DELETE 가능한 미션이다." (Designer 필드 검증을 통과한다는 보장)

**서버 정책**: `GET /api/v1/users/{userId}/missions/designed` 의 응답은 **반드시 `Designer == userId` 인 row 만 반환**. 다른 사용자가 만든 미션이 섞이면 안 됨 — 클라가 "이 화면의 미션은 무조건 내 것"이라는 가정으로 PATCH/DELETE 버튼을 노출하므로, 가정이 깨지면 403 가 발생한다.

**현재 서버 v1 엔드포인트** (Swagger 확인):

읽기 전용:
- 공개 미션 — `GET /api/v1/missions[/{id}|/nearby|/tutorial|/playing]`
- 댓글 / 평점 — `GET /api/v1/missions/{id}/replies`, `POST` (등록)
  - **✅ R6.1 서버 픽스 완료 (2026-05-23)**: GET `/replies` 가 `Score`/`Nickname`/`WriteDate` 모두 반환.
  - 실제 응답 예:
    ```json
    [{"MReply":"smoke test comment","Score":4.5,"WriteDate":"2026-05-18T09:55:40.000+00:00","Nickname":null}, ...]
    ```
  - `WriteDate` 포맷: ISO 8601 + 밀리초 + tz offset. 클라 `RestRemoteDataSource.parseReplyDate` 가 처리.
  - `Nickname` null 은 작성자 프로필에 닉네임이 비어 있는 경우 — UI 는 닉 영역을 숨김 처리.
  - **🟡 R6.2 부분 픽스됨 + backfill 필요**: 신규 Reply POST 시점의 집계 갱신은 동작 (dark004 4.0, run003 2.0 정상 반환). 단, **이미 DB 에 있던 기존 Reply 들**에 대한 backfill 이 안 돼 있어 tutorial001 같이 후기 7개·평균 4.57 인 미션이 응답에서는 `RecommendAvg=0, RecommendCnt=0` 으로 옴.
    - 일회성 backfill SQL:
      ```sql
      UPDATE Mission m
      SET RecommendAvg = COALESCE((SELECT AVG(Score) FROM MissionReply r
                                   WHERE r.MissionID = m.MissionID AND r.Score IS NOT NULL), 0),
          RecommendCnt = (SELECT COUNT(*) FROM MissionReply r WHERE r.MissionID = m.MissionID);
      ```
    - 클라 사이드 수정 완료 (2026-05-23): `Mission.recommendAvg: Int → Double` — 서버가 4.5 같은 분수 평균을 보내도 디코드 성공. 이전엔 분수 평균 미션이 디코드 실패해 목록에서 행이 통째로 사라졌음.
- 랭킹 — `GET /api/v1/missions/{id}/ranking`
- 플레이 — `POST /api/v1/missions/{id}/plays/start|finish|fail`
- **본인 작성** — `GET /api/v1/users/{userId}/missions/designed` ✅ 엔드포인트 존재. 시멘틱은 R1.4 에서 명문화
- 본인 플레이 — `GET /api/v1/users/{userId}/missions/played|playing`

→ Builder 의 mutating 엔드포인트 3개 (R1.1~3) 가 v1 태그에 **전혀 없음**. R1 모두 신규 작업.
→ Design 탭 목록 (R1.4) 은 endpoint 자체는 있지만 **반환 시멘틱 (본인 미션만) + 모든 Status 포함** 보장이 필요. §6.5 참조.

**회귀 안전망**: `POST /playspot/J_MyList.php?tr=700` (Legacy API) 가 그대로 동작 — 클라이언트에 [`LegacyRemoteDataSource.createMission`](PlaySpot/Network/LegacyRemoteDataSource.swift) 으로 구현 완료. Settings → API Backend = Legacy 토글 시 즉시 폴백 가능. 단 update/delete 는 legacy 미지원.

---

## 1. 공통 사양

### 1.1 인증

- 모든 mutating 엔드포인트: `Authorization: Bearer <JWT>` 필수
- 토큰 검증 실패 → `401 Unauthorized` (현재 v1 표준)
- Spring Security 의 invalid JWT → `403` 도 동일 처리. 클라이언트는 401/403 양쪽 자동 재로그인 인터셉터 보유 ([RestAPIClient.swift](PlaySpot/Network/RestAPIClient.swift) lines 60-77)

### 1.2 권한 검증

- **PATCH / DELETE `/api/v1/missions/{id}`** — `Mission.Designer == JWT.userId` 검증. 불일치 시 `403 Forbidden`
- **GET `/api/v1/users/{userId}/missions/designed`** — path 의 `{userId} == JWT.userId` 강제 (R1.4 §6.4). 본인 외 다른 사용자의 작성 목록 조회 차단 + 응답에 `Designer != userId` row 가 섞이지 않도록 SQL WHERE 절 강제
- Admin role 처리는 1차 버전 범위 외 (필요 시 별도 R3 추가)

#### 1.2.1 두 권한 정책의 관계

R1.4 와 R1.2/R1.3 은 **연동된 신뢰 체인**이다:

1. 클라가 `GET /users/{me}/missions/designed` 호출 → 본인 미션만 N개 반환됐다고 신뢰
2. 클라가 행 탭/swipe → `PATCH/DELETE /missions/{id}` 즉시 호출 (사전 확인 없이)
3. 서버는 PATCH/DELETE 단계에서 다시 `Designer == JWT.userId` 검증

→ 만약 R1.4 가 다른 designer 의 row 를 새서 반환하면, 사용자는 "방금 보였는데 권한 오류" UX 를 경험한다. 따라서 **R1.4 의 §6.4 정책 강제는 R1.2/R1.3 의 정확성을 위한 전제 조건**.

### 1.3 일관된 오류 응답 (현재 v1 표준 유지)

```json
{
  "code": "VALIDATION_ERROR",
  "message": "Title is required",
  "details": ["mission.Title"]
}
```

대표 코드 (제안):

| code | HTTP | 설명 |
|---|---|---|
| `VALIDATION_ERROR` | 400 | 필드 검증 실패 (Title/Place 비어있음 등) |
| `UNAUTHORIZED` | 401 | 토큰 누락/만료 |
| `FORBIDDEN` | 403 | 작성자 불일치 |
| `MISSION_NOT_FOUND` | 404 | missionId 미존재 |
| `MISSION_NOT_DELETABLE` | 409 | DELETE 시 Status NOT IN (0,1) — 공개된 미션은 삭제 불가 (§1.4.2) |
| `DUPLICATE_MISSION_ID` | 409 | (서버 발급이라 이론상 발생 X. 디버깅용) |
| `INTERNAL_ERROR` | 500 | 서버 오류 |

### 1.4 데이터베이스 영향

테이블 구조는 [`db.sql`](db.sql) (Mission / MissionItem / ItemQuiz / MissionInPlay / MissionItemInPlay / ItemRnPInPlay). 모두 PK 는 `(MissionID, …)` 컴포지트.

#### 1.4.1 FK 정책 — **사용하지 않음**

- **DB 레벨 FK 제약을 걸지 않음**. 무결성·CASCADE 는 **애플리케이션 레벨에서 명시적으로** 보장한다.
- 이유: 플레이 기록(`MissionInPlay`, `MissionItemInPlay`)이 미션 삭제 후에도 보존되어야 하고 (통계·랭킹), FK 가 있으면 보존 vs CASCADE 간 충돌이 생긴다.

#### 1.4.2 Mission 삭제 정책 (R1.3 와 직접 연결)

| 항목 | 정책 |
|---|---|
| **삭제 허용 Status** | `0 (DESIGNING)` / `1 (TESTED)` 만 — 즉 **본인이 아직 공개하지 않은 미션만 삭제 가능** |
| **삭제 차단 Status** | `2 (SERVER_UPLOAD)` — 공개된 미션은 삭제 불가. 다른 사용자가 플레이 중일 수 있고 통계가 살아있음. 클라이언트는 별도 "공개 해제" 흐름(R3.1 status PATCH 2→1) 후 삭제하도록 안내 |
| **함께 삭제할 테이블** | `Mission`, `MissionItem WHERE MissionID = :id`, `ItemQuiz WHERE MissionID = :id` (각각 명시적 DELETE) |
| **보존할 테이블** | `MissionInPlay`, `MissionItemInPlay`, `ItemRnPInPlay` — 사용자의 플레이 기록·랭킹·통계 데이터는 미션 삭제와 무관하게 유지 |
| **MissionReply** (있다면) | 보존 권장 (댓글·평점 기록) |

→ 세부 흐름은 §4.4 참조.

### 1.5 트랜잭션

`POST /api/v1/missions` 와 `PATCH /api/v1/missions/{id}` 는 단일 트랜잭션으로:
1. Mission row INSERT/UPDATE
2. MissionItem rows (전체 교체)
3. ItemQuiz rows (전체 교체)

중간 실패 시 전부 롤백.

---

## 2. R1.1 — `POST /api/v1/missions` (신규)

### 2.1 요청

```http
POST /api/v1/missions
Authorization: Bearer <JWT>
Content-Type: application/json
```

```json
{
  "mission": {
    "Title": "튜토리얼 미션",
    "Description": "Start → 게임 → 퀴즈 → End 로 진행됩니다.",
    "Place": "튜토리얼 광장",
    "LimitTime": "00:10:00",
    "Status": 0,
    "Virtual": 1,
    "Lang": "ko",
    "BadgeImageName": "badge-a3c2.png"
  },
  "items": [
    {
      "ItemID": 1, "Mandatory": 1, "ItemType": "49",
      "Latitude": 37.4860000, "Longitude": 126.8078000,
      "BlackCnt": 0, "BlackTime": 0, "RangeAR": 50,
      "ShowType": "4", "EffectiveRange": 0, "EffectiveTime": 0,
      "ItemGame": 0, "Info": "Start: 미션을 시작합니다.", "RelationItemID": 0
    },
    {
      "ItemID": 2, "Mandatory": 1, "ItemType": "40",
      "Latitude": 37.4861, "Longitude": 126.8079,
      "BlackCnt": 0, "BlackTime": 0, "RangeAR": 30,
      "ShowType": "4", "EffectiveRange": 0, "EffectiveTime": 0,
      "ItemGame": 0, "Info": "", "RelationItemID": 0
    }
  ],
  "quizzes": [
    { "ItemID": 2, "Seq": 1, "Quiz": "대한민국의 수도는?", "Answer": "서울", "Probability": 100 }
  ]
}
```

#### 필드 사양

`mission`:

| 필드 | 타입 | 필수 | 검증 |
|---|---|---|---|
| `Title` | String | Y | non-empty, max 255 |
| `Description` | String | Y | non-empty |
| `Place` | String | Y | non-empty, max 255 |
| `LimitTime` | String `"HH:MM:SS"` | Y | `"00:00:00"` = 무제한 |
| `Status` | Int | Y | 0~3 (DESIGNING/TESTED/SERVER_UPLOAD/FIRST_DESIGN) |
| `Virtual` | Int | Y | 0 또는 1 |
| `Lang` | String | Y | non-empty (예: `"ko"`, `"en"`) |
| `BadgeImageName` | String? | N | null 가능. R2.1 응답의 fileName |

> **서버가 채우는 필드** (요청 body 에 포함하지 않음):
> - `MissionID` — 서버 발급 ("playspot_{YYYYMMDD_HHmm_random4}" 권장. 충돌 시 재시도)
> - `Designer` — JWT.userId 로 자동 (보안: 클라가 변조 불가)
> - `WriteDate` — 서버 시각 (`yyyy-MM-dd'T'HH:mm:ss`)
>
> 클라이언트는 [`BuilderMissionFields`](PlaySpot/Network/RestAPIDTO.swift) 에 이 3개 필드를 **포함하지 않는다**.

`items[]` (16 필드 → 14 필드):

| 필드 | 타입 | 비고 |
|---|---|---|
| `ItemID` | Int | 미션 내 1~N |
| `Mandatory` | Int | 0/1 |
| `ItemType` | String | "49"/"40" 등. plan_designer.md §3.1 매트릭스 참조 |
| `Latitude` / `Longitude` | Double | WGS84 |
| `BlackCnt` / `BlackTime` | Int | Mine 용 (런타임 미사용, DB 저장) |
| `RangeAR` | Int | 5~500 |
| `ShowType` | String | "1"~"4" |
| `EffectiveRange` | Int | Run End 자동 계산 거리(m) |
| `EffectiveTime` | Int | Run End 제한 시간(초) |
| `ItemGame` | Int | 0~3 |
| `Info` | String | 안내문 (multiline 가능) |
| `RelationItemID` | Int | Run Start↔End 페어링. 미사용 시 0 |

> **MissionID 는 body 에 포함하지 않음** — 서버가 자체 발급한 ID 로 채워 INSERT.

`quizzes[]` (6 필드 → 5 필드):

| 필드 | 타입 |
|---|---|
| `ItemID` | Int (대응 Quiz/Quiz20 아이템 ID) |
| `Seq` | Int (변형 시퀀스 1~N) |
| `Quiz` | String |
| `Answer` | String |
| `Probability` | Int (0~100, 미사용 시 100 권장. 런타임은 균등 randomElement) |

### 2.2 응답

```http
HTTP/1.1 201 Created
Location: /api/v1/missions/playspot_20260520_1845_a3c2
Content-Type: application/json

{
  "missionId": "playspot_20260520_1845_a3c2"
}
```

→ 클라 측 [`BuilderMissionCreatedRes.missionId`](PlaySpot/Network/RestAPIDTO.swift) 와 케이스 일치 (camelCase).

### 2.3 검증 규칙 (서버 측 — 클라 dataCheck 와 동일하게)

서버는 클라 검증을 신뢰하지 말고 동일 규칙을 다시 적용:

1. Title / Description / Place non-empty
2. LimitTime 형식 `"HH:MM:SS"` (`"00:00:00"` = 무제한)
3. items.length ≥ 3
4. items 중 ItemType="49" (Start) 정확히 1개
5. items 중 ItemType="48" (End) 정확히 1개
6. items 중 ItemType="42" (Run Start) 와 "43" (Run End) 개수 동일
7. items 중 Mandatory=1 인 row ≥ 1
8. Radar 종류 (65/66/67/68/69) 각각 ≤ 1
9. Quiz/Quiz20 (ItemType="40"/"41") 아이템마다 quizzes 에 매칭되는 row ≥ 1
10. 모든 quiz.Quiz / quiz.Answer non-empty
11. Run End (ItemType="43") 의 EffectiveTime > 0
12. Run End 의 RelationItemID 가 같은 mission 내 Run Start 의 ItemID 와 일치

위반 시 `400 VALIDATION_ERROR` + `details` 에 위반 항목 명시.

### 2.4 동작 순서 (서버)

```
1. JWT 검증 → designer = JWT.userId
2. body 검증 (위 §2.3)
3. missionId 발급 (충돌 시 재시도 3회)
4. BEGIN TRANSACTION
   INSERT INTO Mission (MissionID, Title, Description, Place, Designer,
                        LimitTime, Status, Virtual, Lang, BadgeImageName,
                        WriteDate)
     VALUES (?, ?, ?, ?, designer, ?, ?, ?, ?, ?, NOW())
   FOR each item in items:
     INSERT INTO MissionItem (...) VALUES (...)
   FOR each quiz in quizzes:
     INSERT INTO ItemQuiz (...) VALUES (...)
   COMMIT
5. RETURN 201 + { missionId }
```

---

## 3. R1.2 — `PATCH /api/v1/missions/{missionId}` (편집)

### 3.1 요청

```http
PATCH /api/v1/missions/playspot_20260520_1845_a3c2
Authorization: Bearer <JWT>
Content-Type: application/json
```

Body 는 §2.1 의 `BuilderMissionReq` 와 **완전히 동일**. PUT 의 의미 (전체 교체) 지만 PATCH 메서드 사용 (관례).

### 3.2 응답

```http
HTTP/1.1 204 No Content
```

(또는 `200 OK` 빈 body)

### 3.3 권한

- `404 MISSION_NOT_FOUND` — missionId 가 존재하지 않음
- `403 FORBIDDEN` — `Mission.Designer != JWT.userId`
- 검증 실패 — `400 VALIDATION_ERROR` (§2.3 와 동일)
- 클라이언트는 본 미션이 §6 의 `GET /users/{me}/missions/designed` 응답에서 왔다고 가정하고 권한 사전 확인 없이 호출함 — 정상 흐름에서는 403 발생하지 않아야 함 (§1.2.1)

### 3.4 동작 순서 (서버)

```
1. JWT 검증 → callerId = JWT.userId
2. SELECT Mission WHERE MissionID = :id
   IF row 없음 → 404 MISSION_NOT_FOUND
   IF row.Designer != callerId → 403 FORBIDDEN
3. body 검증 (§2.3 와 동일)
4. BEGIN TRANSACTION
   UPDATE Mission SET Title=?, ..., WriteDate = NOW() WHERE MissionID = :id
   DELETE FROM MissionItem WHERE MissionID = :id        -- 전체 교체
   DELETE FROM ItemQuiz WHERE MissionID = :id            -- 전체 교체
   FOR each item: INSERT INTO MissionItem
   FOR each quiz: INSERT INTO ItemQuiz
   COMMIT
5. RETURN 204
```

> **주의**: items / quizzes 가 **전체 교체** 시멘틱. 부분 업데이트가 필요하면 별도 엔드포인트로 분리해야 함. 1차 버전에서는 전체 교체로 통일.

### 3.5 동시 편집 (선택)

낙관적 잠금 (ETag) 은 1차 범위 외. 마지막-쓰기-승리(last-write-wins). 추후 R5 로 추가 가능:

```http
If-Match: "<etag>"
→ 412 Precondition Failed (충돌 시)
```

---

## 4. R1.3 — `DELETE /api/v1/missions/{missionId}`

### 4.1 요청

```http
DELETE /api/v1/missions/playspot_20260520_1845_a3c2
Authorization: Bearer <JWT>
```

### 4.2 응답

```http
HTTP/1.1 204 No Content
```

### 4.3 권한 / 차단 사유

| HTTP | code | 발생 조건 |
|---|---|---|
| `401` | `UNAUTHORIZED` | 토큰 누락/만료 |
| `403` | `FORBIDDEN` | `Mission.Designer != JWT.userId` |
| `404` | `MISSION_NOT_FOUND` | missionId 미존재 |
| `409` | `MISSION_NOT_DELETABLE` | `Mission.Status NOT IN (0, 1)` — **공개 (Status=2) 또는 그 외 상태 미션은 삭제 불가** (§1.4.2) |

- 정상 흐름: §6 의 designed 목록에서 swipe delete → 본인 미션 + Status 0/1 만이므로 403 / 409 발생하지 않음 (§1.2.1)
- 클라이언트는 Status=2 (SERVER_UPLOAD) 행에서 swipe delete 노출하지 않도록 처리 권장 — §4.5 참조

### 4.4 삭제 흐름 (서버 — FK 없이 manual)

§1.4 의 정책에 따라 DB FK / CASCADE 가 없으므로 서버가 명시적으로 삭제 순서를 보장:

```sql
BEGIN TRANSACTION;

-- 0. 권한·상태 검증
SELECT Status, Designer FROM Mission WHERE MissionID = :id;
  IF row 없음          → 404 MISSION_NOT_FOUND
  IF Designer != caller → 403 FORBIDDEN
  IF Status NOT IN (0,1) → 409 MISSION_NOT_DELETABLE

-- 1. 자식 테이블 명시적 삭제 (FK 없음)
DELETE FROM ItemQuiz    WHERE MissionID = :id;
DELETE FROM MissionItem WHERE MissionID = :id;

-- 2. Mission row 본체 삭제
DELETE FROM Mission     WHERE MissionID = :id;

-- 3. 플레이 기록은 보존 — 절대 손대지 않음
--    (MissionInPlay, MissionItemInPlay, ItemRnPInPlay)
--    필요 시 MissionReply 도 보존

COMMIT;
RETURN 204 No Content
```

#### 4.4.1 보존 테이블 (의도적으로 두는 row)

| 테이블 | 보존 사유 |
|---|---|
| `MissionInPlay` | 누가 어떤 미션을 시작/종료했는지 — 사용자 통계·랭킹 |
| `MissionItemInPlay` | 아이템별 획득 기록 — 사용자 플레이 히스토리 |
| `ItemRnPInPlay` | 파워업 사용 기록 |
| `MissionReply` (있다면) | 댓글·평점 |

→ FK 가 없으므로 MissionID 가 가리키는 Mission row 가 사라져도 위 테이블은 그대로 살아있음. 클라이언트는 이 데이터를 활용한 화면 (MyInfo / 플레이 기록) 에서 "[삭제된 미션]" 같은 placeholder 로 표시.

### 4.5 클라이언트 측 영향

현재 [`MissionBuilderView.deleteUploaded(offsets:)`](PlaySpot/Views/MissionBuilder/MissionBuilderView.swift) 는 uploaded 섹션(Status=2) 에서도 swipe delete 를 호출하고 있음 → 서버 거절(`409`) 시 UX 불일치.

권장 변경:

- uploaded 섹션의 행은 **swipe delete 자체를 비활성** (`.deleteDisabled(mission.status == .serverUpload)`)
- "삭제하려면 먼저 공개 해제하세요" 안내 메시지를 별도 액션으로 제공 (R3.1 status PATCH 2→1 후 삭제)

본 변경은 별도 PR — 본 작업 (plan_designer.md 구현) 범위 외. §10.1 의 C5 로 트래킹.

---

## 5. R2.1 — `POST /api/v1/badges` (사양 명문화)

### 5.1 현황

OpenAPI 에 endpoint 자체는 노출됨. 그러나 **요청 필드명·응답 스키마가 미명문화** — 클라이언트가 추측하여 호출 중:

- 클라이언트는 multipart field name = `file` (camelCase) 사용 ([RestRemoteDataSource.swift:213](PlaySpot/Network/RestRemoteDataSource.swift))
- Legacy 는 multipart field name = `userfile`

서버가 어떤 field name 을 받는지 미확인 → **본 R2.1 의 핵심 작업은 사양 확정 + Swagger 문서화**.

### 5.2 요청 (제안 — 합의 필요)

```http
POST /api/v1/badges
Authorization: Bearer <JWT>
Content-Type: multipart/form-data; boundary=----PlaySpot...

------PlaySpot...
Content-Disposition: form-data; name="file"; filename="badge-a3c2.png"
Content-Type: image/png

<PNG binary>
------PlaySpot...--
```

- field name: **`file`** (현 클라 호출 형식 — 합의 시 그대로)
- max size: 5 MB (제안)
- 허용 MIME: `image/png`, `image/jpeg`

### 5.3 응답

```http
HTTP/1.1 201 Created
{
  "fileName": "badge-a3c2.png",
  "url": "/badge/badge-a3c2.png"
}
```

→ [`BadgeUploadRes`](PlaySpot/Network/RestAPIDTO.swift) 와 매칭. 클라이언트는 `fileName` 만 미션 POST 본문에 포함.

### 5.4 보안

- 인증 사용자만 업로드 가능
- 파일명 무결성: 서버가 자체 생성 (UUID 등), 클라가 보낸 filename 은 참고용
- 절대 경로 traversal 차단 (`..` 등 sanitize)

---

## 6. R1.4 — `GET /api/v1/users/{userId}/missions/designed` (시멘틱 명문화)

### 6.1 위치 / 시멘틱

- Design 탭 ([`MissionBuilderView`](PlaySpot/Views/MissionBuilder/MissionBuilderView.swift)) 의 목록 데이터 소스.
- **본인이 작성한 미션 전체** (DESIGNING + TESTED + SERVER_UPLOAD) 를 반환.
- `Missions 탭` (`GET /api/v1/missions`) 과 **별개**. Missions 탭은 다른 사용자가 만든 공개 미션 포함, Design 탭은 오직 본인 것.

### 6.2 요청

```http
GET /api/v1/users/{userId}/missions/designed
Authorization: Bearer <JWT>
```

- `{userId}` path param — 클라가 보내는 사용자 ID
- 권한: `{userId} == JWT.userId` 강제 (§6.4)

### 6.3 응답

```http
HTTP/1.1 200 OK
Content-Type: application/json

[
  {
    "MissionID": "playspot_20260520_1845_a3c2",
    "Title": "튜토리얼 미션",
    "Description": "...",
    "Place": "튜토리얼 광장",
    "Designer": "playspot",
    "LimitTime": "00:10:00",
    "Status": 0,
    "Virtual": 1,
    "Lang": "ko",
    "BadgeImageName": "badge-a3c2.png",
    "WriteDate": "2026-05-20T18:45:22",
    "PlayCnt": 0, "FailCnt": 0, "RecommendCnt": 0, "RecommendAvg": 0
  },
  ...
]
```

- 기존 `Mission` 모델 ([`PlaySpot/Models/Mission.swift`](PlaySpot/Models/Mission.swift)) 의 PascalCase 키 그대로
- `items` / `quizzes` 는 **포함하지 않음** — 행 클릭 후 `GET /api/v1/missions/{id}` 로 별도 로드

### 6.4 권한 정책 (필수)

**서버는 반드시 다음을 강제**:

```sql
-- 잘못된 구현 (다른 사용자 미션이 새는 경우)
SELECT * FROM Mission WHERE Designer = :userId

-- 올바른 구현 — 권한 검증 후 동일 쿼리
IF JWT.userId != :userId
  → 403 FORBIDDEN
SELECT * FROM Mission WHERE Designer = :userId
ORDER BY WriteDate DESC
```

- `{userId} != JWT.userId` → `403 FORBIDDEN`
- 다른 사용자가 만든 미션이 응답에 섞이면 **클라이언트가 PATCH/DELETE 호출 시 403 가 터져서 UX 깨짐**.

### 6.5 Status 필터 정책

**기본: 필터 없이 모든 Status 반환**. 클라가 그룹핑/필터링 책임.

| Status | 의미 | Design 탭 노출? |
|---|---|---|
| 0 — DESIGNING | 빌더 저장 직후 (draft) | ✅ "작성 중" 섹션 |
| 1 — TESTED | 테스트 플레이 통과 | ✅ "작성 중" 섹션 (수정 가능) |
| 2 — SERVER_UPLOAD | 업로드 완료 (공개) | ✅ "업로드됨" 섹션 |
| 3 — FIRST_DESIGN | 초기 진입 (사용 안 함) | (선택) |

(선택) Query parameter 로 필터 제공:

```http
GET /api/v1/users/{userId}/missions/designed?status=0,1
```

권장: 1차에서는 필터 없이 전체 반환. 트래픽 증가 시 추가.

### 6.6 정렬

`ORDER BY WriteDate DESC` — 최근 작성/수정 순.

### 6.7 페이지네이션 (선택)

1차: 미적용 (개인 작성 미션 수가 많지 않음).
필요 시: `?page=0&size=20` 추가, 응답 헤더에 `X-Total-Count`.

### 6.8 클라이언트 동작 — 본인 미션 보장

이 API 의 모든 row 가 본인 것임을 클라이언트가 신뢰하므로:

- [`MissionBuilderView`](PlaySpot/Views/MissionBuilder/MissionBuilderView.swift) 의 **모든 행에 수정/삭제 가능**
- swipe delete → `DELETE /api/v1/missions/{id}` 즉시 호출 (확인 후)
- 행 탭 → `MissionSetupView(mission:)` 진입 → 편집 후 PATCH

→ 서버가 `Designer != JWT.userId` row 를 끼우면 클라는 PATCH/DELETE 시 403 받음 = 사용자에게는 "방금 보였는데 갑자기 권한 없음" UX. 반드시 §6.4 강제.

### 6.9 클라이언트 측 추가 작업 권고

현재 [`MissionBuilderView.swift`](PlaySpot/Views/MissionBuilder/MissionBuilderView.swift) 의 `load()` 는 **로컬 DB (`MissionRepository`) 만** 조회:

```swift
private func load() {
    drafts   = (try? missionRepo.fetchByStatus(.designing)) ?? []
    let tested = (try? missionRepo.fetchByStatus(.tested)) ?? []
    if !tested.isEmpty { drafts.append(contentsOf: tested) }
    uploaded = (try? missionRepo.fetchByStatus(.serverUpload)) ?? []
}
```

→ 다른 디바이스에서 작성한 미션이 보이지 않음. R1.4 가 살아나면 다음과 같이 보강 필요:

```swift
private func load() async {
    // 1. 로컬 draft (오프라인 작업) — 빠른 우선 표시
    drafts   = (try? missionRepo.fetchByStatus(.designing)) ?? []
    let tested = (try? missionRepo.fetchByStatus(.tested)) ?? []
    if !tested.isEmpty { drafts.append(contentsOf: tested) }

    // 2. 서버 동기화 — R1.4 호출
    let serverMissions = (try? await dataSource.fetchMyDesigned(userID: AppState.shared.userID)) ?? []
    let bySttatus = Dictionary(grouping: serverMissions, by: \.status)
    // 로컬 draft 와 머지 (같은 MissionID 면 서버 우선)
    uploaded = bySttatus[.serverUpload] ?? []
    // …
}
```

본 보강은 R1.4 가 §6.4 정책으로 정상 동작 확인 후 별도 PR 권장. 본 작업 (plan_designer.md 클라이언트 구현) 범위 외.

### 6.10 검증 시나리오 (R1.4)

```bash
# 본인 토큰
TOKEN=$(curl -s -X POST .../auth/login -d '{"userId":"playspot","password":"..."}' | jq -r .token)

# 본인 미션 조회 — OK
curl -s http://43.201.188.35:8080/api/v1/users/playspot/missions/designed \
  -H "Authorization: Bearer $TOKEN" | jq '.[] | .Designer' | sort -u
# 기대: "playspot" 만 (다른 designer 절대 X)

# 다른 사용자 미션 조회 시도 — 차단
curl -i -s http://43.201.188.35:8080/api/v1/users/other_user/missions/designed \
  -H "Authorization: Bearer $TOKEN" | head -1
# 기대: HTTP/1.1 403 Forbidden

# 토큰 없이 시도 — 차단
curl -i -s http://43.201.188.35:8080/api/v1/users/playspot/missions/designed | head -1
# 기대: HTTP/1.1 401 Unauthorized
```

---

## 7. R3.1 — `PATCH /api/v1/missions/{missionId}/status` 🔴 **신규 필수**

### 7.1 동기

**현 문제**: 기존 `PATCH /api/v1/missions/{missionId}` 는 `BuilderMissionReq` (mission + items + quizzes 모두 required) 의 전체 교체 (PUT 의미). 부분 업데이트 미지원.

→ Flutter 웹/안드로이드 클라가 publish 토글 시 mission.Status 만 변경하는 작은 페이로드 전송 → **HTTP 400 VALIDATION_FAILED**.

검증 (2026-06-02):
```bash
curl -X PATCH /api/v1/missions/{id} -d '{"mission":{"Status":2}}'
# → 400 {"code":"VALIDATION_FAILED","details":[
#   {"field":"mission.title","reason":"must not be blank"},
#   {"field":"mission.limitTime","reason":"must not be null"},
#   {"field":"mission.lang","reason":"must not be blank"},
#   {"field":"quizzes","reason":"must not be null"},
#   {"field":"mission.description","reason":"must not be blank"},
#   {"field":"mission.place","reason":"must not be blank"},
#   {"field":"mission.virtual","reason":"must not be null"},
#   {"field":"items","reason":"must not be empty"}
# ]}
```

iOS 는 SwiftUI 빌더가 메모리에 전체 보유 → 항상 전체 페이로드 전송 → OK. **Flutter (웹/안드로이드) 와 향후 추가될 모든 클라이언트가 publish 못 함**.

### 7.2 요청

```http
PATCH /api/v1/missions/{missionId}/status
Authorization: Bearer <JWT>
Content-Type: application/json

{ "status": 2 }
```

| 필드 | 타입 | 필수 | 값 | 의미 |
|---|---|---|---|---|
| `status` | int | ✅ | `0` 또는 `2` | 0 = 비공개 (DESIGNING/unpublished) / 2 = 공개 (SERVER_UPLOAD/published) |

> 클라이언트(iOS·Flutter) 모두 [`MissionStatus`](PlaySpot/Models/GameState.swift) 가 `unpublished=0, published=2` 두 값만 사용. legacy 1/3 은 사용 안 함.

### 7.3 응답

| HTTP | 의미 | Body |
|---|---|---|
| **204 No Content** | 성공 — 상태 변경됨 | (없음) |
| **400** `INVALID_STATUS_VALUE` | `status` 가 0/2 외의 값 | `{"code":"INVALID_STATUS_VALUE","message":"status 는 0 또는 2 만 허용"}` |
| **401** | 토큰 없음/만료 | 표준 에러 |
| **403** `FORBIDDEN` | 본인 작성 미션 아님 (`Designer != JWT.userId`) | 표준 에러 |
| **404** `NOT_FOUND` | missionId 없음 | 표준 에러 |
| **409** `INVALID_STATE_TRANSITION` *(선택 — 1차에선 생략 가능)* | 룰 위반 전이 시도 | `{"code":"INVALID_STATE_TRANSITION","message":"현재 ${current} → ${target} 불가"}` |

### 7.4 권한 검증

`PATCH /api/v1/missions/{id}` 와 동일:
1. JWT 검증 → userId 추출
2. `SELECT Designer FROM Mission WHERE MissionID = :id`
3. `Designer != JWT.userId` → 403
4. 통과 시 `UPDATE Mission SET Status = :new_status WHERE MissionID = :id`

### 7.5 동작 순서 (서버)

```
1. JWT 인증 (필터)
2. status 값 검증 (0 또는 2)
3. SELECT mission WHERE MissionID = path_id
   → 없으면 404
4. mission.Designer == JWT.userId ?
   → 아니면 403
5. (선택) 전이 룰 검사
   - status 0→0, 2→2: idempotent OK (204)
   - 0→2: OK
   - 2→0: OK (unpublish 허용 — 디자이너가 비공개로 되돌릴 수 있어야 함)
6. UPDATE Mission SET Status = :new_status WHERE MissionID = :id
   - WriteDate 갱신 안 함 (메타 보존)
   - items / quizzes 절대 손대지 않음
7. 204 응답
```

### 7.6 사이드 이펙트 / 비검토 사항

- ❌ `WriteDate` 변경 안 함 — 메타데이터 무결성
- ❌ items / quizzes 삭제·재삽입 안 함 — 전체 PATCH 와 다른 점
- ❌ RecommendAvg / PlayCnt 등 통계 컬럼 영향 없음
- ✅ Audit 로그는 일반 PATCH 와 동일 수준 (선택)

### 7.7 클라이언트 통합

**Flutter (Dart)** 예시:
```dart
Future<bool> publishMission(String missionId) async {
  final response = await dio.patch(
    '/api/v1/missions/$missionId/status',
    data: {'status': 2},
  );
  return response.statusCode == 204;
}
```

**iOS (Swift)** 예시 — `MissionDataSource` 프로토콜에 추가:
```swift
func updateMissionStatus(missionID: String, status: Int) async throws -> Bool
```

기존 `updateMission()` (전체 페이로드) 는 빌더의 메타·아이템·퀴즈 통째 변경용으로 그대로 유지. publish 토글 같은 단일 status 전환에만 R3.1 사용.

### 7.8 우선순위 / 일정

- **🔴 P0 — 즉시 필요**. Flutter publish 기능 동작 불가 상태.
- **공수 추정**: 컨트롤러 1개 + Service 메서드 1개 + 권한 검증 (기존 재사용) + 단위 테스트 1개 ≈ **반나절**
- **롤아웃**:
  1. 서버 배포 후 `curl -X PATCH /api/v1/missions/{id}/status -d '{"status":2}'` 단독 테스트
  2. Flutter / iOS 의 publish 호출 부분만 신규 엔드포인트로 교체 (기존 `updateMission` 호출 유지)
  3. 회귀 영향 없음 — 기존 PATCH 엔드포인트 그대로

### 7.9 임시 우회 (서버 배포 전)

서버 배포 전 디자이너가 publish 필요한 경우, 다음 스크립트로 토글 가능:

```bash
bash scripts/toggle_mission_status.sh <missionId> publish
bash scripts/toggle_mission_status.sh <missionId> unpublish
```

스크립트 동작: GET 으로 미션 전체 받아 → 메모리에서 Status 만 변경 → 기존 PATCH 로 전체 전송. 본질적으로 R3.1 의 클라 측 흉내내기.

### 7.10 향후 확장 (참고)

같은 패턴으로 향후 추가 가능:
- `PATCH /missions/{id}/badge` — 뱃지만 교체
- `PATCH /missions/{id}/place` — 장소만 교체
- `POST /missions/{id}/report` — 신고

하지만 R3.1 (status) 가 가장 빈번하고 시급. 나머지는 필요할 때 추가.

---

## 8. 마이그레이션 / 롤백 전략

### 8.1 마이그레이션 순서

```
Phase A — 서버 작업 (병렬 가능)
  □ R1.1 POST  /api/v1/missions
  □ R1.2 PATCH /api/v1/missions/{id}
  □ R1.3 DELETE /api/v1/missions/{id}
  □ R1.4 GET   /api/v1/users/{userId}/missions/designed
         (시멘틱 명문화 — 본인 미션만 + 모든 Status)
  □ R2.1 POST  /api/v1/badges (사양 문서화 + 검증)
  □ OpenAPI 갱신 (Swagger UI 에 노출)

Phase B — 클라 검증 (서버 작업 완료 후)
  □ AppConfig.backend = .rest (기본값) 로 빌더 동작 확인
  □ 6 시드 미션 (tutorial001 ~ standard006) 재생성 테스트
  □ 편집 → PATCH → /missions/{id} GET 으로 일관성 확인
  □ 삭제 → DELETE → /users/{id}/missions/designed 에서 사라짐 확인
  □ R1.4 — 다른 사용자 missionID 호출 시 403 확인 (§6.10)

Phase C — 안정화
  □ Legacy 백엔드 deprecated 표시 강화
  □ LegacyRemoteDataSource.createMission(TR=700) 호출 통계 모니터링
  □ 6개월 후 LegacyRemoteDataSource 제거 PR
```

### 8.2 롤백

문제 발생 시 클라는 **앱 변경 없이** Settings 에서 backend = `.legacy` 토글로 즉시 폴백:

| Backend | 빌더 동작 |
|---|---|
| `.rest` (기본) | `POST /api/v1/missions` 신규 API 사용 |
| `.legacy` | `POST /playspot/J_MyList.php?tr=700` (`}}` 페이로드) 사용 |

Legacy 경로는 [`LegacyRemoteDataSource.swift`](PlaySpot/Network/LegacyRemoteDataSource.swift) 에서 정상 동작 확인됨 (TR=700, MissionBuilderList.m:124-220 페이로드 변환).

단, legacy 폴백 시 **편집(PATCH)·삭제(DELETE) 불가** — `NotSupportedError` 가 throw 됨. 사용자는 신규 생성만 가능.

### 8.3 데이터 호환성

- TR=700 으로 업로드한 미션의 MissionID 형식: `<userID>_<yyyyMMddHHmmss>` (예: `Guest@1748241245678_20260520183022`)
- 신규 API 로 업로드한 MissionID 형식: `playspot_<yyyyMMdd_HHmm>_<random4>` (제안)
- 두 형식이 공존해도 PK 충돌 없음. 클라는 ID 형식 가정하지 않고 사용.

---

## 9. 검증 시나리오 (E2E)

서버 작업 완료 후 클라 측에서 다음 시나리오로 회귀 확인. 본 시나리오는 [`scripts/smoke_new_api.sh`](scripts/smoke_new_api.sh) 에 추가 권장.

### 9.1 신규 미션 생성

```bash
# 1. 로그인 → JWT 획득
TOKEN=$(curl -s -X POST http://43.201.188.35:8080/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"userId":"playspot","password":"test"}' | jq -r .token)

# 2. 미션 생성 (anonymous 차단 확인)
curl -i -X POST http://43.201.188.35:8080/api/v1/missions \
  -H 'Content-Type: application/json' \
  -d @new_mission.json
# 기대: 401 UNAUTHORIZED

# 3. 인증 호출
curl -i -X POST http://43.201.188.35:8080/api/v1/missions \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d @new_mission.json
# 기대: 201 Created, body = {"missionId":"playspot_..."}

# 4. 생성된 미션 조회
MID=$(<response from #3>.missionId)
curl -s http://43.201.188.35:8080/api/v1/missions/$MID | jq .mission.Designer
# 기대: "playspot" (JWT 사용자)
```

### 9.2 편집 (Designer 검증)

```bash
# 다른 사용자 토큰으로 시도
TOKEN_OTHER=$(curl -s -X POST .../auth/login -d '{"userId":"other","password":"..."}' | jq -r .token)
curl -i -X PATCH http://43.201.188.35:8080/api/v1/missions/$MID \
  -H "Authorization: Bearer $TOKEN_OTHER" \
  -H 'Content-Type: application/json' \
  -d @new_mission.json
# 기대: 403 FORBIDDEN

# 본인 토큰으로 시도
curl -i -X PATCH .../missions/$MID \
  -H "Authorization: Bearer $TOKEN" \
  -d @new_mission_updated.json
# 기대: 204 No Content
```

### 9.3 삭제

```bash
# Case 1 — Status=0/1 (DESIGNING/TESTED) 인 미션 삭제: 정상
curl -i -X DELETE http://43.201.188.35:8080/api/v1/missions/$MID \
  -H "Authorization: Bearer $TOKEN"
# 기대: 204 No Content

curl -s http://43.201.188.35:8080/api/v1/missions/$MID
# 기대: 404 MISSION_NOT_FOUND

# Case 2 — Status=2 (SERVER_UPLOAD) 미션 삭제 시도: 거절 (§1.4.2)
# (사전: 다른 미션을 Status=2 상태로 만들어 둠)
curl -i -X DELETE http://43.201.188.35:8080/api/v1/missions/$PUBLISHED_MID \
  -H "Authorization: Bearer $TOKEN"
# 기대: 409 MISSION_NOT_DELETABLE

# Case 3 — 삭제 후 자식 테이블 확인 (FK 없음, 명시적 DELETE 수행 여부 — §4.4)
# SELECT COUNT(*) FROM MissionItem WHERE MissionID = $MID  → 0
# SELECT COUNT(*) FROM ItemQuiz    WHERE MissionID = $MID  → 0

# Case 4 — 플레이 기록 보존 확인 (§4.4.1)
# SELECT COUNT(*) FROM MissionInPlay     WHERE MissionID = $MID  → 보존 (>0 가능)
# SELECT COUNT(*) FROM MissionItemInPlay WHERE MissionID = $MID  → 보존

# CASCADE 확인 — MissionItem 조회 (별도 endpoint 없으면 SQL 확인)
# SELECT COUNT(*) FROM MissionItem WHERE MissionID = $MID  → 0
```

### 9.4 검증 실패 케이스

```bash
# Title 누락
curl -i -X POST .../missions -H "Authorization: Bearer $TOKEN" \
  -d '{"mission":{"Description":"x","Place":"y","LimitTime":"00:00:00","Status":0,"Virtual":0,"Lang":"ko"},"items":[],"quizzes":[]}'
# 기대: 400 VALIDATION_ERROR, details = ["mission.Title"]

# items < 3
curl -i -X POST ... -d '{"mission":{...valid...},"items":[],"quizzes":[]}'
# 기대: 400 VALIDATION_ERROR, details = ["items"]
```

---

## 10. 본 작업 중 발견된 이슈 / 한계

다음 항목은 본 작업 (plan_designer.md 클라이언트 구현) 진행 중 발견된 이슈로, 본 api_designer.md 와 별도로 트래킹 필요.

### 10.1 클라이언트 한계

| ID | 항목 | 상태 |
|---|---|---|
| C1 | SwiftUI `Map` 의 longPress 좌표 캡처 불가 — 현재 카메라 중심 사용 ([`MissionBuilderMapView.swift`](PlaySpot/Views/MissionBuilder/MissionBuilderMapView.swift)) | 향후 `UIViewRepresentable` 로 `MKMapView` 래퍼 필요 시 개선 |
| C2 | DEBUG 빌드에서 게스트의 Design 탭 진입 허용 ([`MainTabView.swift`](PlaySpot/Views/App/MainTabView.swift):32) | 회귀 테스트 편의용. 릴리스 빌드에서는 기존 정책 유지됨 |
| C3 | quiz 변형의 빌더 저장은 로컬 DB 에 반영되지 않음 — Mission 모델 내 items[i].quizzes 만 사용 | DB 스키마 확장 필요 시 별도 PR |
| C4 | cliclick 로 시뮬레이터 GUI 자동화 시 권한 이슈 — 빌더 UI 의 end-to-end 자동 검증 불가 | 향후 XCUITest 도입 필요 |
| C5 | [`MissionBuilderView.deleteUploaded()`](PlaySpot/Views/MissionBuilder/MissionBuilderView.swift) 가 Status=2 행에서도 swipe delete 호출 — 서버 §1.4.2 정책상 409 거절됨 | uploaded 섹션은 `.deleteDisabled(true)` 처리 + "공개 해제 후 삭제" 별도 액션 (§4.5) |

### 10.2 서버 미합의 사항

| ID | 항목 | 권장 |
|---|---|---|
| R-A | MissionID 발급 정책 | 서버 발급 (충돌 방지). 형식: `playspot_<YYYYMMDD_HHmm>_<rand4>` |
| R-B | Designer 필드 — body vs JWT | **JWT.userId 자동** (보안: 임의 Designer 변조 차단) |
| R-C | Status 전이 게이트 | 1차: 클라 자유 명시 / 2차: R3.1 별도 엔드포인트 |
| R-D | DB FK 사용 여부 | **사용 안 함** (§1.4.1) — 무결성·삭제 cascade 는 애플리케이션 레벨에서 처리 |
| R-D.1 | Mission 삭제 허용 Status | **`{0, 1}` 만** (§1.4.2). Status=2 (SERVER_UPLOAD) 는 409 거절 |
| R-D.2 | Mission 삭제 시 함께 제거 | `MissionItem`, `ItemQuiz` (manual DELETE WHERE MissionID) |
| R-D.3 | Mission 삭제 시 보존 | `MissionInPlay`, `MissionItemInPlay`, `ItemRnPInPlay` (사용자 플레이 기록·통계) |
| R-E | Badge 파일 max size | 5 MB |
| R-F | 미션 레벨 Quiz/Answer 필드 | 빈 문자열 허용 (TR=700 페이로드 호환 — `BuilderMissionFields` 에 포함하지 않음) |
| R-G | R1.4 응답에 Status 필터 query | 1차: 미적용 (전체 반환) / 2차: `?status=0,1` 추가 가능 |
| R-H | R1.4 응답에 items / quizzes 포함 여부 | **미포함** (목록 화면용 슬림 응답). 상세는 `GET /missions/{id}` |

---

## 11. 작업 체크리스트 (서버)

복사 가능한 PR 체크리스트:

```markdown
### Builder API 신규 작업

#### R1.1 POST /api/v1/missions
- [ ] Controller / Service / Repository 작성
- [ ] §2.3 검증 12 규칙 적용
- [ ] §2.4 트랜잭션 흐름 적용
- [ ] MissionID 발급 + 충돌 재시도
- [ ] Designer = JWT.userId
- [ ] OpenAPI 어노테이션 추가
- [ ] 단위 테스트 (성공 / 401 / 400)

#### R1.2 PATCH /api/v1/missions/{id}
- [ ] Designer 검증 → 403
- [ ] missionId 미존재 → 404
- [ ] §2.3 검증 재적용
- [ ] §3.4 트랜잭션 흐름
- [ ] OpenAPI 어노테이션

#### R1.3 DELETE /api/v1/missions/{id}
- [ ] Designer 검증 → 403
- [ ] missionId 미존재 → 404
- [ ] **Status NOT IN (0,1) 거절 → 409 `MISSION_NOT_DELETABLE`** (§1.4.2)
- [ ] FK 없음 — `DELETE FROM ItemQuiz / MissionItem` 명시적 호출 (§4.4)
- [ ] `Mission` row 삭제
- [ ] `MissionInPlay`, `MissionItemInPlay`, `ItemRnPInPlay` **건드리지 않음** (§4.4.1)
- [ ] 트랜잭션 적용 (중간 실패 시 전체 롤백)
- [ ] OpenAPI 어노테이션

#### R1.4 GET /api/v1/users/{userId}/missions/designed (시멘틱 명문화)
- [ ] `{userId} == JWT.userId` 강제 → 403 (§6.4)
- [ ] WHERE Designer = :userId 절 강제 (다른 사용자 row 절대 금지)
- [ ] 모든 Status (0/1/2/3) 반환 — 빌더의 draft 표시용
- [ ] ORDER BY WriteDate DESC
- [ ] items / quizzes 미포함 (슬림 응답)
- [ ] OpenAPI 어노테이션 — Designer 검증 정책 명시
- [ ] §6.10 검증 시나리오 통과

#### R2.1 POST /api/v1/badges (사양 명문화)
- [ ] multipart field name 확정 (`file`)
- [ ] max size 5MB 검증
- [ ] MIME 검증 (image/png, image/jpeg)
- [ ] 응답 스키마 확정 ({fileName, url})
- [ ] OpenAPI 어노테이션 추가

#### 공통
- [ ] §9 E2E 시나리오 통과
- [ ] §1.3 에러 응답 형식 일관성
- [ ] §1.2.1 R1.4↔R1.2/R1.3 신뢰 체인 동작 확인
- [ ] DEBUG / Prod 양쪽 로그 레벨 점검
```

---

## 12. 참고 자료

- 클라이언트 구현: [`plan_designer.md`](plan_designer.md) (특히 §5 / §6 / §10)
- 클라 DTO 정의: [`PlaySpot/Network/RestAPIDTO.swift`](PlaySpot/Network/RestAPIDTO.swift) `Builder*`
- 클라 호출자: [`PlaySpot/Network/RestRemoteDataSource.swift`](PlaySpot/Network/RestRemoteDataSource.swift) `createMission` / `updateMission` / `deleteMission` / `uploadBadgeImage`
- 클라 fallback: [`PlaySpot/Network/LegacyRemoteDataSource.swift`](PlaySpot/Network/LegacyRemoteDataSource.swift) (TR=700 `}}` 페이로드)
- 클라 검증: [`PlaySpot/Game/MissionValidator.swift`](PlaySpot/Game/MissionValidator.swift) (14 규칙)
- 클라 ViewModel: [`PlaySpot/Game/MissionBuilderViewModel.swift`](PlaySpot/Game/MissionBuilderViewModel.swift) `save()` 흐름
- DB 스키마: [`db.sql`](db.sql)
- 레거시 페이로드 원본: [`Classes/MissionBuilderList.m:124-220`](Classes/MissionBuilderList.m)
- Swagger UI: <http://43.201.188.35:8080/swagger-ui/index.html>
- OpenAPI JSON: <http://43.201.188.35:8080/api-docs>
