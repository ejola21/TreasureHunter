# api_client.md — 신규 JSON REST API 클라이언트 가이드

> PlaySpot AR 서버의 신규 JSON API (`/api/v1/**`) 사용 안내. 레거시 PHP 호환 진입점(`/playspot/J_MyList.php` 등) 은 그대로 유지되지만, 신규 통합부터는 본 문서의 엔드포인트를 사용한다.
>
> 사양 원본: [api.md](api.md) (레거시 TR 코드) / 설계 결정: [plan_api.md](plan_api.md)

---

## 0. 기본 정보

| 항목 | 값 |
|---|---|
| Base URL (운영) | `http://nexapp.co.kr` *(또는 신규 도메인)* |
| Base URL (로컬) | `http://localhost:8080` |
| API prefix | `/api/v1` |
| Content-Type (요청) | `application/json; charset=UTF-8` (단 `/badges` 만 `multipart/form-data`) |
| Content-Type (응답) | `application/json; charset=UTF-8` |
| 인증 헤더 | `Authorization: Bearer {JWT}` (운영 `authenticated` 모드에서 필수) |
| 날짜/시간 포맷 | `yyyy-MM-dd HH:mm:ss` (Asia/Seoul) |
| 비밀번호 | **MD5 해시** 후 전송 (레거시 호환) |

---

## 1. 인증 — JWT 발급 / 사용

### 1.1 로그인 → JWT 받기

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "userId": "user@playspot.local",
  "password": "098f6bcd4621d373cade4e832627b4f6"
}
```

**응답 200**
```json
{ "token": "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJ1c2VyQHBsYXlz..." }
```

**응답 401**
```json
{ "code": "INVALID_CREDENTIALS", "message": "invalid credentials" }
```

### 1.2 토큰 사용

모든 보호 엔드포인트 호출 시 Authorization 헤더에 토큰을 붙인다.

```http
GET /api/v1/missions/mine002
Authorization: Bearer eyJhbGciOiJIUzUxMiJ9...
```

- 토큰 미동봉/만료 시 → `401 INVALID_CREDENTIALS` 또는 `401 TOKEN_EXPIRED`
- 로컬 개발 모드(`permit-all`) 에서는 토큰 없이도 호출 가능

### 1.3 회원가입

```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "userId": "newuser@playspot.local",
  "password": "098f6bcd4621d373cade4e832627b4f6"
}
```

**응답 201** (빈 body)
**응답 409** — 중복 시 `{"code":"DUPLICATE_DATA", ...}`

---

## 2. 응답 규칙

### 2.1 성공

| 카테고리 | HTTP | body |
|---|---|---|
| 단건 조회 | 200 | 객체 `{...}` |
| 목록 조회 | 200 | 배열 `[...]` |
| 생성 (서버 발급 ID 있음) | 201 | `{...}` (예: `{"missionId":"mine003"}`, `{"fileName":"abc.png","url":"/badge/abc.png"}`) |
| 명령 수신 (body 무의미) | 204 | 빈 body |
| 명령 수신 (결과 라벨 필요) | 200 | `{"result":"SUCCESS"}` |

### 2.2 실패 — 공통 포맷

```json
{
  "code": "DATA_NOT_FOUND",
  "message": "미션을 찾을 수 없습니다: mine002"
}
```

검증 실패 시 `details` 배열 추가:
```json
{
  "code": "VALIDATION_FAILED",
  "message": "요청 파라미터가 올바르지 않습니다",
  "details": [
    {"field":"userId", "reason":"공백일 수 없습니다"},
    {"field":"score",  "reason":"다음 값 이하여야 합니다 5.0"}
  ]
}
```

### 2.3 에러 코드 / HTTP status 매핑

| HTTP | code | 의미 |
|---|---|---|
| 400 | `VALIDATION_FAILED` | `@Valid` 검증 실패 (details 포함) |
| 400 | `INVALID_PARAMETER` | 필수 파라미터 누락/타입 오류 |
| 400 | `BUSINESS_ERROR` | 그 외 비즈니스 검증 실패 |
| 401 | `INVALID_CREDENTIALS` | 로그인 실패 / 비밀번호 불일치 |
| 401 | `TOKEN_EXPIRED` | JWT 만료 |
| 403 | `FORBIDDEN` | 권한 없음 |
| 404 | `DATA_NOT_FOUND` | 리소스 없음 (어떤 리소스인지는 `message` 에) |
| 409 | `DUPLICATE_DATA` | 중복 |
| 409 | `INVALID_STATE` | 상태 충돌 (예: 이미 진행중) |
| 500 | `INTERNAL_ERROR` | 서버 오류 |

---

## 3. 엔드포인트 — Mission

### 3.1 미션 상세 조회

```http
GET /api/v1/missions/{missionId}
```

**응답 200** — `MissionDetailRes`
```json
{
  "mission": {
    "MissionID": "mine002",
    "Title": "지뢰 & 레이더 미션",
    "Description": "...",
    "Place": "튜토리얼 광장",
    "Designer": "playspot",
    "RunLimitTime": 900,
    "Status": 2,
    "Virtual": 1,
    "Lang": "ko",
    "PlayCnt": 0,
    "FailCnt": 0,
    "RecommendCnt": 0,
    "RecommendAvg": 0,
    "WriteDate": "2026-05-13T00:00:00"
  },
  "items": [
    {
      "ItemID": 1, "Mandatory": 1, "ItemType": "49",
      "Latitude": 37.4860000, "Longitude": 126.8078000,
      "BlackCnt": 0, "BlackTime": 0, "RangeAR": 50,
      "ShowType": "4", "EffectiveTime": 0, "EffectiveRange": 0,
      "ItemGame": 0, "Info": "Start: ...", "RelationItemID": 0
    }
  ],
  "quizzes": [
    { "Seq": 1, "Quiz": "질문", "Answer": "정답", "Probability": 100 }
  ]
}
```

**응답 404** — `DATA_NOT_FOUND`

### 3.2 미션 목록 (전체)

```http
GET /api/v1/missions?page=0
```
- `page` (선택, 기본 0) — 0부터 시작하는 페이지 커서. 한 페이지 = 30건.

**응답 200** — 배열 (각 항목은 위 `mission` 과 동일한 필드. items/quizzes 는 없음)

### 3.3 위치 기반 목록 (가까운 순)

```http
GET /api/v1/missions/nearby?page=0&latitude=37.49&longitude=126.81
```
- `latitude`, `longitude` 필수
- 응답 객체에 `Dist` 필드 추가

### 3.4 인기 미션 (UI 탭1)

```http
GET /api/v1/missions/playing?page=0
```
PlayCnt 내림차순.

### 3.5 튜토리얼 미션

```http
GET /api/v1/missions/tutorial?lang=ko
```
- `lang=ko` → 한국어 미션, 그 외 → 비한국어. 기본 `ko`.

---

## 4. 엔드포인트 — Mission 댓글/평점

### 4.1 댓글 조회

```http
GET /api/v1/missions/{missionId}/replies
```

**응답 200**
```json
[
  { "UserID": "qa", "Nickname": "QA테스터", "Score": 4.5, "MReply": "재미있어요!" }
]
```
> 댓글이 없으면 `[]`.

### 4.2 댓글/평점 등록

```http
POST /api/v1/missions/{missionId}/replies
Content-Type: application/json

{
  "userId": "qa@playspot.local",
  "score": 4.5,
  "reply": "신규 API 테스트 댓글"
}
```
- `userId` 필수
- `score` 0.0 ~ 5.0 (선택)
- `reply` 본문 (선택)

**응답 204** (빈 body)

---

## 5. 엔드포인트 — Mission 플레이

> 플레이는 `(missionId, playerId, startTime)` **복합키**로 식별. 서버는 별도 playId 를 발급하지 않는다. 따라서 finish/fail 호출 시 클라이언트가 시작 시각을 그대로 전달해야 한다.

### 5.1 플레이 시작

```http
POST /api/v1/missions/{missionId}/plays/start
Content-Type: application/json

{
  "playerId": "user@playspot.local",
  "startTime": "2026-05-18 10:00:00",
  "isVirtual": 0
}
```
- `startTime` 미지정 시 서버 시각 사용 — 그러나 finish/fail 호출 시 시작 시각을 다시 보내야 하므로 **클라이언트가 명시 권장**
- `isVirtual` 0/1, 기본 0

**응답 200** — `{"result":"SUCCESS"}`

### 5.2 플레이 완료

```http
POST /api/v1/missions/{missionId}/plays/finish
Content-Type: application/json

{
  "playerId": "user@playspot.local",
  "startTime": "2026-05-18 10:00:00",
  "endTime":   "2026-05-18 10:15:30",
  "isVirtual": 0
}
```

**응답 204**

### 5.3 플레이 실패

```http
POST /api/v1/missions/{missionId}/plays/fail
```
요청 body 는 finish 와 동일.

**응답 204**

### 5.4 랭킹 Top3

```http
GET /api/v1/missions/{missionId}/ranking
```

**응답 200**
```json
{
  "ShortUser1": "신규API테스터", "ShortRecord1": "00:15:00",
  "ShortUser2": "",              "ShortRecord2": "",
  "ShortUser3": "",              "ShortRecord3": ""
}
```
> 항상 3개 슬롯이 채워진 형태로 반환 (빈 슬롯은 빈 문자열). 클라이언트가 length 체크 없이 바로 매핑 가능.

---

## 6. 엔드포인트 — User

### 6.1 유저 단건 조회

```http
GET /api/v1/users/{userId}
```

**응답 200** — `UserRes`
```json
{
  "userId": "user@playspot.local",
  "email":  "user@playspot.local",
  "phone":  "010-1111-2222",
  "nickname": "신규API테스터",
  "isGuest": 0,
  "solutionCount": 0,
  "timeAddCount": 0,
  "lastLoginAt": "2026-05-18T12:43:34"
}
```
> 비밀번호는 **절대 응답되지 않는다**.

**응답 404** — 없는 유저

### 6.2 유저 정보 수정 (부분)

```http
PATCH /api/v1/users/{userId}
Content-Type: application/json

{
  "nickname": "새닉네임",
  "phone": "010-3333-4444"
}
```
- 모든 필드 선택. **null/공백/미지정 필드는 변경되지 않음**
- `password` 필드도 여기서 변경 가능 (MD5)

**응답 204**

### 6.3 비밀번호 변경

```http
PATCH /api/v1/users/{userId}/password
Content-Type: application/json

{
  "oldPassword": "16d7a4fca7442dda3ad93c9a726597e4",
  "newPassword": "newhash..."
}
```
- 두 값 모두 MD5
- `oldPassword` 불일치 시 401 `INVALID_CREDENTIALS`

**응답 204**

### 6.4 유저의 미션 목록

| URL | 의미 |
|---|---|
| `GET /api/v1/users/{userId}/missions/designed` | 내가 디자인한 미션 |
| `GET /api/v1/users/{userId}/missions/played`   | 내가 완료한 미션 |
| `GET /api/v1/users/{userId}/missions/playing`  | 내가 현재 플레이 중인 미션 |

응답은 `/api/v1/missions` 목록과 동일 스키마(배열).

---

## 7. 엔드포인트 — Badge (이미지)

### 7.1 뱃지 업로드

```http
POST /api/v1/badges
Content-Type: multipart/form-data; boundary=----...

----...
Content-Disposition: form-data; name="file"; filename="badge-mine002.png"
Content-Type: image/png

{바이너리}
----...--
```

- 폼 필드명: **`file`** (레거시 `userfile` 이 아님)
- PNG 권장 (자동으로 `.png` 확장자 보정됨)

**응답 201**
```json
{ "fileName": "badge-mine002.png", "url": "/badge/badge-mine002.png" }
```

### 7.2 뱃지 다운로드

```http
GET /badge/{fileName}
```
정적 자원. 신규 API prefix 적용 안 함 — 레거시 URL 그대로 유지.

---

## 8. 레거시 → 신규 매핑 치트시트

| 레거시 TR | 레거시 호출 | 신규 |
|---|---|---|
| TR=200 | POST `/playspot/J_MyList.php` body=`tr=200&missionID=` | `GET /api/v1/missions/{id}` |
| TR=300 | `tr=300&missionID=` | `GET /api/v1/missions/{id}/replies` |
| TR=400 | `tr=400&MID=&UID=&Score=&Reply=` | `POST /api/v1/missions/{id}/replies` |
| TR=500 | `tr=500&last=` | `GET /api/v1/missions?page=` |
| TR=501 | `tr=501&last=&latitude=&longitude=` | `GET /api/v1/missions/nearby?page=&latitude=&longitude=` |
| TR=502 | `tr=502&last=` | `GET /api/v1/missions/playing?page=` |
| TR=503 | `tr=503&gb=0%\|1%` | `GET /api/v1/missions/tutorial?lang=ko\|en` |
| TR=600 | `tr=600&id=` | `GET /api/v1/users/{id}/missions/designed` |
| TR=601 | `tr=601&id=` | `GET /api/v1/users/{id}/missions/played` |
| TR=602 | `tr=602&id=` | `GET /api/v1/users/{id}/missions/playing` |
| TR=700 | `tr=700&mission=A}}}B...&missionItem=...&itemQuiz=...` | `POST /api/v1/missions` body: `{mission, items[], quizzes[]}` *(스키마 별도 합의 필요)* |
| TR=800 | `tr=800&user_id=&password=` | `POST /api/v1/auth/login` |
| tr_user_reg | `tr=tr_user_reg&user_id=&password=` | `POST /api/v1/auth/register` |
| tr_pwd_chg | `/playspot/user.php` `tr=tr_pwd_chg&...` | `PATCH /api/v1/users/{id}/password` |
| tr_user_sel | `tr=tr_user_sel&user_id=` | `GET /api/v1/users/{id}` |
| tr_user_chg | `tr=tr_user_chg&user_id=&...` | `PATCH /api/v1/users/{id}` |
| c_mission_play_start | `tr=c_mission_play_start&mission_play=A,B,C,D` | `POST /api/v1/missions/{id}/plays/start` |
| c_mission_play_finish | `tr=c_mission_play_finish&mission_play=` | `POST /api/v1/missions/{id}/plays/finish` |
| c_mission_play_fail | `tr=c_mission_play_fail&mission_play=` | `POST /api/v1/missions/{id}/plays/fail` |
| c_mission_play_ranking | `/playspot/mission_play_info.php` `tr=c_mission_play_ranking&mission_id=` | `GET /api/v1/missions/{id}/ranking` |
| image upload | `POST /playspot/image_save.php` multipart `userfile` | `POST /api/v1/badges` multipart `file` |

### 8.1 주요 차이 요약

| 측면 | 레거시 | 신규 |
|---|---|---|
| 메서드 | 거의 POST 만 | GET/POST/PATCH (시맨틱 준수) |
| body 포맷 | `application/x-www-form-urlencoded` + `tr=` 디스패처 | `application/json` |
| 응답 포맷 | 평문 / `^M^I^Q` 마커스트림 / JSON 배열·객체 혼재 | 항상 JSON |
| 에러 | `"ERROR:user not found"` 평문 | `{"code":"...","message":"..."}` + HTTP status |
| 인증 | 없음 (URL 자체가 노출) | JWT Bearer |
| 페이지네이션 | `last` (정수 커서) | `page=0` (0부터) |
| 언어 파라미터 | `gb=0%`/`1%` | `lang=ko`/`en`/... |
| 뱃지 업로드 폼 필드 | `userfile` | `file` |
| 플레이 식별 | `mission_play=missionID,playerID,time,virt` (콤마 4필드) | path 의 `{missionId}` + body 의 `playerId`/`startTime`/`isVirtual` |

---

## 9. 실전 예시 — JavaScript (fetch)

```js
const BASE = "http://localhost:8080";   // 운영은 도메인으로 교체
let TOKEN = null;

async function api(method, path, body) {
  const init = {
    method,
    headers: {
      "Content-Type": "application/json",
      ...(TOKEN ? { Authorization: `Bearer ${TOKEN}` } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  };
  const res = await fetch(`${BASE}${path}`, init);
  if (res.status === 204) return null;
  const data = await res.json();
  if (!res.ok) {
    // data = { code, message, details? }
    throw Object.assign(new Error(data.message), { code: data.code, status: res.status, details: data.details });
  }
  return data;
}

// 로그인
const { token } = await api("POST", "/api/v1/auth/login", {
  userId: "qa@playspot.local",
  password: "098f6bcd4621d373cade4e832627b4f6",   // MD5
});
TOKEN = token;

// 미션 조회
const detail = await api("GET", "/api/v1/missions/mine002");

// 댓글 등록
await api("POST", "/api/v1/missions/mine002/replies", {
  userId: "qa@playspot.local", score: 4.5, reply: "좋아요!"
});

// 플레이 사이클
const startTime = "2026-05-18 10:00:00";
await api("POST", "/api/v1/missions/mine002/plays/start", {
  playerId: "qa@playspot.local", startTime, isVirtual: 0
});
// ... 게임 진행 ...
await api("POST", "/api/v1/missions/mine002/plays/finish", {
  playerId: "qa@playspot.local",
  startTime,
  endTime: "2026-05-18 10:15:30",
  isVirtual: 0
});

// 에러 처리
try {
  await api("GET", "/api/v1/missions/없는미션");
} catch (e) {
  if (e.code === "DATA_NOT_FOUND") { /* 404 분기 */ }
  else if (e.code === "VALIDATION_FAILED") { console.log(e.details); }
}
```

---

## 10. 운영 체크리스트

- [ ] 클라이언트가 신규 도메인/URL prefix(`/api/v1`) 로 호출하는지 확인
- [ ] Authorization 헤더 누락 시 자동 재로그인 로직 (401 → /auth/login 재호출) 구현 권장
- [ ] 응답 status 가 2xx 가 아니면 모두 에러로 처리 (body 의 `code` 로 분기)
- [ ] 날짜는 ISO/`yyyy-MM-dd HH:mm:ss` 둘 다 정상 파싱되지만, 클라이언트에서 **`yyyy-MM-dd HH:mm:ss` (KST)** 로 통일 권장
- [ ] 비밀번호는 **반드시 MD5 해시 후 전송** (네트워크에 평문 노출 금지)
- [ ] Swagger UI 로 실시간 명세 확인: `${BASE}/swagger-ui/index.html`
