# api_plan_new.md — 레거시 TR → 신규 `/api/v1/**` REST API 마이그레이션 계획

> PlaySpot iOS 클라이언트가 현재 호출하는 레거시 PHP 호환 엔드포인트(`POST /playspot/J_MyList.php?tr=...`)를 [api_client.md](api_client.md) 의 신규 JSON REST API 로 전환하기 위한 작업 계획 및 검증 절차.
>
> 사양 원본: [api_client.md](api_client.md) · 현재 구현: [PlaySpot/Network/](PlaySpot/Network/) · 서버 주소: `http://43.201.188.35:8080`

---

## 0. 현재 상태 진단

### 0.1 클라이언트 네트워크 레이어 (현행)

| 파일 | 역할 |
|---|---|
| [APIEndpoint.swift](PlaySpot/Network/APIEndpoint.swift) | enum case 별 url/parameters. **모든 케이스 POST + `tr=` 디스패처** |
| [APIClient.swift](PlaySpot/Network/APIClient.swift) | `send()` 단일 메서드: POST + 쿼리스트링 + `application/x-www-form-urlencoded` |
| [MissionDTO.swift](PlaySpot/Network/MissionDTO.swift) | `^M[mission]^I[items]^Q[quizzes]` 구분자 파서 (레거시 TR=200 응답) |
| [RemoteDataSource.swift](PlaySpot/Network/RemoteDataSource.swift) | 13 메서드 — fetch / submit / record / login / register / upload |
| [LocalDataSource.swift](PlaySpot/Network/LocalDataSource.swift) | 동일 인터페이스의 mock (JSON 번들 로더) |
| [AppConfig.swift](PlaySpot/Network/AppConfig.swift) | `dataSource: RemoteDataSource()` 하드코딩 |

### 0.2 신규 API 서버 사전 probe (2026-05-18 기준)

```bash
# 인증 없이 모든 /api/v1/** 호출 → 403
$ curl -i http://43.201.188.35:8080/api/v1/missions/mine002        # 403
$ curl -i http://43.201.188.35:8080/api/v1/missions?page=0          # 403
$ curl -i http://43.201.188.35:8080/api/v1/missions/mine002/ranking # 403

# 레거시 엔드포인트는 anonymous 그대로 동작
$ curl http://43.201.188.35:8080/playspot/J_MyList.php -d 'tr=500&last=0&lang=ko' # 200

# Swagger UI 접근 가능
$ curl -o /dev/null -w "%{http_code}\n" http://43.201.188.35:8080/swagger-ui/index.html # 200
```

→ **신규 API 는 모두 JWT 필수**. 레거시는 anonymous 유지.

### 0.3 주요 차이 (마이그레이션 영향도)

| 측면 | 레거시 | 신규 | 영향 |
|---|---|---|---|
| 메서드 | 모든 호출 POST | GET/POST/PATCH | URLRequest 메서드 분기 필요 |
| Body | form-urlencoded `tr=...&K=V` | `application/json` | JSONEncoder 도입 |
| 응답 | 평문/마커스트림/JSON 혼재 | 항상 JSON | `MissionDTO.parse` 폐기 |
| 인증 | 없음 | `Authorization: Bearer <JWT>` | AuthSession + 401 재시도 |
| 에러 | `"ERROR:..."` 평문 | `{code, message, details?}` + HTTP status | APIError 타입 + status 분기 |
| 페이지네이션 | `last=정수` | `page=0..N` | 시그니처 변경 |
| 언어 파라미터 | `gb=0%`/`1%` | `lang=ko`/`en` | 변환 |
| 플레이 식별 | `mission_play=ID,UID,Time,Virt` 콤마 4-필드 | path `{missionId}` + body | 페이로드 전면 교체 |
| 비밀번호 변경 | `/user.php tr=tr_pwd_chg` 별도 도메인 | `PATCH /users/{id}/password` | 신규 UI 가능 |
| 뱃지 업로드 | multipart `userfile` | multipart `file` | 폼 필드명 변경 |

---

## 1. 마이그레이션 전략

### 1.1 점진 전환 — 듀얼 백엔드 토글

빅뱅 대신 `AppConfig` 에 **백엔드 enum** 을 두고 런타임에 토글:

```swift
enum APIBackend: String { case legacy, rest }

enum AppConfig {
    static var backend: APIBackend = {
        UserDefaults.standard.string(forKey: "apiBackend").flatMap(APIBackend.init) ?? .legacy
    }()
    static var dataSource: MissionDataSource {
        switch backend {
        case .legacy: return LegacyRemoteDataSource()   // 현재 RemoteDataSource 의 이름 변경
        case .rest:   return RestRemoteDataSource()     // 신규 구현
        }
    }
}
```

**이유:**
- 신규 구현 도중에도 앱이 동작 가능 → 회귀 위험 최소
- Settings 화면에서 토글 → 빠른 A/B 비교
- 단계별 PR 머지 + 단계별 검증 가능
- 신규 API 장애 발생 시 즉시 legacy 롤백 (코드 변경 없이)

최종 상태: 기본값 `.rest`, `.legacy` 는 deprecate 단계로 6개월 유지 후 제거.

### 1.2 JWT 인증 설계

```
┌────────────────┐    login(email, MD5(pw))    ┌──────────────────┐
│   AuthSession  │ ─────────────────────────► │ /api/v1/auth/login│
│   (actor)      │ ◄───────────────────────── │   { token: ... }  │
│                │                             └──────────────────┘
│  - token       │
│  - keychain    │     header inject (인터셉터)
└───────┬────────┘     ──────────────────────►
        │                Authorization: Bearer <token>
        │                                       │
        │     401 Unauthorized                  ▼
        │     ◄───────────────────────  All /api/v1 endpoints
        │
        ▼ 한 번 자동 재로그인 → 원 요청 재시도
        (저장된 (UserID, MD5pw) 사용. 게스트면 자동 register 후 login)
```

**책임 분리:**
- `AuthSession` (actor singleton): 메모리 토큰 + Keychain 영속화.
- `KeychainStore`: 가벼운 wrapper (`SecItemAdd/Update/Delete`).
- `RestAPIClient`: send() 가 토큰 부착 + 401 인터셉트 + 1회 재시도.
- 게스트 사용자도 JWT 필요 → 클라이언트가 자동 `/auth/register` 후 `/auth/login` (UserID=`Guest@<ts>`, 비밀번호=클라이언트 생성 UUID 의 MD5; Keychain 에 저장).

---

## 2. 단계별 작업 계획

### Phase 0 — 사전 검증 (~30분, 코드 변경 0)

| # | 작업 | 산출물 |
|---|---|---|
| 0-1 | `/api/v1/auth/login` 으로 시드 사용자(`playspot`) 토큰 발급 가능 여부 확인. anonymous 403 정책 / 게스트 게이트웨이 정책 명문화. | api_probe_result.md |
| 0-2 | 토큰으로 13 endpoints (`/missions/**`, `/users/**`, `/missions/{id}/replies`, `/ranking`) 모두 호출 → 응답 스키마가 api_client.md 와 일치하는지 확인 | api_probe_result.md fixture json 들 |
| 0-3 | `/missions/{id}/plays/start` → `finish` 흐름 호출, 동일 `playerId + startTime` 조합으로 멱등성 확인 | api_probe_result.md |
| 0-4 | Swagger UI(`/swagger-ui/index.html`) 의 OpenAPI 스펙(`/v3/api-docs`) 다운로드 → 클라이언트 사양 reference | docs/playspot-openapi.json |

**Exit criteria:** anonymous 정책 합의 + 게스트 처리 방향 합의 + Phase 1 에서 사용할 fixture JSON 확보.

### Phase 1 — Network 인프라 (~3h)

| # | 작업 | 신규 파일 / 변경 |
|---|---|---|
| 1-1 | `KeychainStore` 추가 (set/get/delete) | [PlaySpot/Network/KeychainStore.swift](PlaySpot/Network/) |
| 1-2 | `AuthSession` actor 추가 — token in-memory + Keychain bridge | [PlaySpot/Network/AuthSession.swift](PlaySpot/Network/) |
| 1-3 | `APIError` enum — apiError(code, message, details, status) + transport(URLError) | [PlaySpot/Network/APIError.swift](PlaySpot/Network/) |
| 1-4 | `RestAPIClient` — URLRequest builder + Authorization 헤더 + 401 재시도 인터셉터 + JSONDecoder/Encoder | [PlaySpot/Network/RestAPIClient.swift](PlaySpot/Network/) |
| 1-5 | DTO 추가: `MissionDetailRes`, `LoginRes`, `ReplyReq`, `PlayReq`, `RegisterReq`, `UploadResultRes`, `UserRes`, `UserPatchReq`, `PasswordChangeReq`, `BadgeUploadRes`, `APIErrorRes` | [PlaySpot/Network/DTO/](PlaySpot/Network/DTO/) |
| 1-6 | `MissionDataSource` 확장 — fetchUser/updateUser/changePassword 추가 | [MissionDataSource.swift](PlaySpot/Network/MissionDataSource.swift) |
| 1-7 | 기존 `RemoteDataSource` → `LegacyRemoteDataSource` 로 rename | [LegacyRemoteDataSource.swift](PlaySpot/Network/) |
| 1-8 | `RestRemoteDataSource` 스켈레톤 (메서드는 nil/throw로 placeholder) | [RestRemoteDataSource.swift](PlaySpot/Network/) |
| 1-9 | `AppConfig` 에 `backend: APIBackend` enum + UserDefaults binding + `dataSource: MissionDataSource` 동적 반환 | [AppConfig.swift](PlaySpot/Network/AppConfig.swift) |
| 1-10 | DEBUG 빌드 Settings 탭에 backend 토글 Picker 추가 | [Views/Settings/SettingsView.swift](PlaySpot/Views/Settings/) |

**Exit criteria:** 빌드 성공 + 기본값 `.legacy` 유지하여 기존 동작 무변경.

### Phase 2 — 인증 흐름 (~2h)

| # | 작업 | 변경 |
|---|---|---|
| 2-1 | `RestRemoteDataSource.login()` 구현: POST `/auth/login` → token 추출 → `AuthSession.set(token)` | RestRemoteDataSource |
| 2-2 | `RestRemoteDataSource.register()` 구현: POST `/auth/register` → 즉시 login 호출 | RestRemoteDataSource |
| 2-3 | 게스트 모드 헬퍼: `AuthSession.ensureGuestSession()` — UserID=`Guest@<ts>`, MD5(UUID) → register + login, Keychain 에 보관 | AuthSession |
| 2-4 | `LoginView` 의 "Continue as Guest" 버튼 → backend=.rest 일 때 `ensureGuestSession()` 호출 | LoginView |
| 2-5 | `AppState.userID` 가 변경되면 AuthSession.clear() → 다음 호출에서 토큰 미동봉 → 401 → 자동 재로그인 사이클 | AppState |
| 2-6 | Settings 에 "Logout" 버튼 → AuthSession.clear() + Keychain 제거 + LoginView 표시 | SettingsView |

**Exit criteria:** backend=.rest 토글 후 LoginView → Mission 목록 진입까지 동작.

### Phase 3 — 읽기 마이그레이션 (~2h)

| # | 메서드 | 신규 호출 | 응답 디코딩 |
|---|---|---|---|
| 3-1 | `fetchMissionList(cursor, lang)` | GET `/api/v1/missions?page={cursor}` | `[Mission]` |
| 3-2 | `fetchPublishedMissions(cursor, lang, lat, lon)` | GET `/missions/nearby?page=&latitude=&longitude=` | `[Mission]` (+`Dist` 필드 무시) |
| 3-3 | `fetchCurrentGames(userID)` | GET `/users/{id}/missions/playing` | `[Mission]` |
| 3-4 | `fetchMyDesigned(userID)` | GET `/users/{id}/missions/designed` | `[Mission]` |
| 3-5 | `fetchMyPlayed(userID)` | GET `/users/{id}/missions/played` | `[Mission]` |
| 3-6 | `fetchTutorialMissions(region)` | GET `/missions/tutorial?lang={region}` | `[Mission]` |
| 3-7 | `fetchMissionDetail(missionID)` | GET `/missions/{id}` | `MissionDetailRes` → (Mission, [MissionItem], [ItemQuiz]) |
| 3-8 | `fetchReplies(missionID)` | GET `/missions/{id}/replies` | `[MissionReply]` (MReply→text 매핑) |
| 3-9 | `fetchRanking(missionID)` | GET `/missions/{id}/ranking` | `{ShortUser1, ShortRecord1, ...}` → `[RankingEntry]` (기존 변환 로직 재사용) |

**Exit criteria:** Settings 에서 backend=.rest 로 토글한 상태에서 MissionList 6개 표시 + 미션 상세 화면 진입 성공.

### Phase 4 — 쓰기 마이그레이션 (~2h)

| # | 메서드 | 신규 호출 |
|---|---|---|
| 4-1 | `submitReview(missionID, userID, score, reply)` | POST `/missions/{id}/replies` body=`{userId, score, reply}` |
| 4-2 | `recordPlayStart(playJSON)` | **시그니처 변경** → `recordPlayStart(missionID, playerID, startTime, isVirtual)`. POST `/missions/{id}/plays/start` body=`{playerId, startTime, isVirtual}` |
| 4-3 | `recordPlayFinish(...)` | POST `/missions/{id}/plays/finish` body=`{playerId, startTime, endTime, isVirtual}` |
| 4-4 | `recordPlayFail(...)` | POST `/missions/{id}/plays/fail` body=동일 |
| 4-5 | `fetchUser(userID)` (신규) | GET `/users/{id}` |
| 4-6 | `updateUser(userID, patch: UserPatchReq)` (신규) | PATCH `/users/{id}` |
| 4-7 | `changePassword(userID, oldPW, newPW)` (신규) | PATCH `/users/{id}/password` |
| 4-8 | `uploadMission(...)` | **합의 후 후속 PR**. POST `/missions` body 구조 정의 필요 (api_client.md "스키마 별도 합의 필요") |
| 4-9 | 뱃지 업로드 (신규 UI 가능 시) | POST `/api/v1/badges` multipart `file` |

`GameEngine.recordPlay(action:)` 의 콤마-문자열 페이로드 빌더 폐기 → `RestRemoteDataSource` 가 받은 인자로 직접 JSON 생성.

**Exit criteria:** Virtual Play 1 회 완주 시 서버 DB(`MissionPlayRecord`) 에 row 1 개 추가 확인.

### Phase 5 — 정리 (~1h)

| # | 작업 |
|---|---|
| 5-1 | `AppConfig.backend` 기본값 `.rest` 로 전환 |
| 5-2 | `LegacyRemoteDataSource` 와 [`MissionDTO.swift`](PlaySpot/Network/MissionDTO.swift) (^M^I^Q 파서) `@available(*, deprecated)` 마킹 |
| 5-3 | [APIEndpoint.swift](PlaySpot/Network/APIEndpoint.swift) 의 모든 `case` 에 deprecated 코멘트 (legacy backend 전용) |
| 5-4 | CLAUDE.md / README 갱신 — 신규 API 가 기본 백엔드임을 명시 |
| 5-5 | 6개월 후 PR 로 LegacyRemoteDataSource + APIEndpoint + MissionDTO 삭제 (별도 PR) |

---

## 3. 테스트 계획

### 3.1 Test Phase A — Unit (XCTest 도입, ~2h)

현재 [project.yml](project.yml) 에 테스트 타겟이 없을 수 있음 → 추가 필요. 우선 mock 가능한 핵심 단위 위주:

| 대상 | 케이스 |
|---|---|
| `AuthSession` | set/get/clear/Keychain round-trip; 동시 set 경합 시 마지막 win |
| `RestAPIClient` (URLProtocol mock) | 200 디코딩; 401→재로그인→재시도→200 한 번만; 401 두 번 → APIError throw; 404→DATA_NOT_FOUND; 400+details→VALIDATION_FAILED; 500→INTERNAL_ERROR; 네트워크 timeout |
| `MissionDetailRes` 디코더 | Phase 0 산출 fixture JSON 으로 디코딩 검증 |
| `KeychainStore` | set/get/delete + 같은 키 덮어쓰기 |
| `RestRemoteDataSource` (URLProtocol mock) | 각 메서드 happy/empty/error path 1개씩 (총 ~30 케이스) |

### 3.2 Test Phase B — 시뮬레이터 E2E (~1h)

순서대로 실행하며 매 단계 스크린샷:

1. **Backend 전환:** Settings → "API Backend" Picker → `rest` 선택. UserDefaults 즉시 반영 확인.
2. **로그인 사이클:**
   - 이메일 로그인: 시드 사용자(`playspot`/시드비번MD5)로 LoginView 통해 인증 → Mission 탭으로 이동 → 6 미션 표시.
   - 회원가입: 신규 이메일 → 자동 로그인 → MissionList 진입 (빈 목록).
   - Guest: "Continue as Guest" → 자동 register+login → MissionList 진입.
3. **읽기:** MissionList 3 탭 토글 (Playing/Near Me/All) → 각 탭의 응답 시각 확인.
4. **상세:** 미션 행 탭 → MissionDetailView 표시 (배지 이미지, 평점, 댓글 영역).
5. **플레이:** Virtual Play → 지도 → AR → Start → 미니게임(힌트) → Quiz → End 완주.
6. **쓰기 검증:** 서버 DB 직접 쿼리(`SELECT COUNT(*) FROM MissionPlayRecord WHERE PlayerID=?`)로 row 1개 추가 확인. PlayCnt 트리거(`Mission.PlayCnt+=1`) 동작 확인.
7. **에러 시나리오:** AuthSession 강제 clear → 다음 fetch → 401 자동 재로그인 → 정상 응답 확인 (Logger 출력).
8. **회귀:** Settings → backend=.legacy 로 토글 → 동일 시나리오 1회 → 기존 동작 변함 없음 확인.

### 3.3 Test Phase C — curl 회귀 스모크 (~10분)

각 PR 머지 직전 자동화 가능한 curl 스모크:

```bash
# .scripts/smoke_new_api.sh
TOKEN=$(curl -s -X POST http://43.201.188.35:8080/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"userId":"playspot","password":"<시드MD5>"}' | jq -r .token)

curl -s -H "Authorization: Bearer $TOKEN" http://43.201.188.35:8080/api/v1/missions?page=0 | jq 'length'
curl -s -H "Authorization: Bearer $TOKEN" http://43.201.188.35:8080/api/v1/missions/mine002 | jq '.mission.MissionID'
curl -s -H "Authorization: Bearer $TOKEN" http://43.201.188.35:8080/api/v1/missions/mine002/ranking | jq .
# ... 13개
```

---

## 4. 위험 및 미합의 사항

| # | 항목 | 상태 | 대응 |
|---|---|---|---|
| R-1 | `/api/v1/auth/login` 도 anonymous 403 응답 | **블로커** | Phase 0 에서 서버 담당과 정책 합의. permit-all 인증 화이트리스트 또는 시드 토큰 발급 |
| R-2 | 게스트 사용자 흐름 정의 없음 | **블로커** | "Guest@<ts>" 자동 register+login (본 문서 §1.2) 안으로 합의 |
| R-3 | TR=700 uploadMission body 스키마 미합의 | 후순위 | Phase 4 에서 분리. 빌더 UI 완성 시점에 재논의 |
| R-4 | `MissionReply` 응답 필드(`MReply`) → 모델 `text` 매핑 검증 안 됨 | Phase 0 fixture 로 확인 | CodingKeys 추가 |
| R-5 | RankingRes(`{ShortUser1, ShortRecord1, ...}`) 가 String 만 보장하는지 (현재 코드 `[String: String]` 캐스팅) | Phase 0 에서 1회 호출로 확인 | 필요 시 Codable 구조체로 강타입화 |
| R-6 | JWT 만료 시간 미명시 (api_client.md 에서 `TOKEN_EXPIRED` 코드만 정의) | 운영 정책 확인 | 1회 자동 재시도 + 실패 시 LoginView 강제 표시 |
| R-7 | `RunLimitTime`/`WriteDate` 가 신규 API 도 동일 포맷 혼용인지 | Phase 0 fixture | Mission 디코더 이미 다중 포맷 흡수하므로 대부분 OK |
| R-8 | XCTest 타겟 없음 | Phase 1 의존성 | project.yml 에 `PlaySpotTests` 타겟 추가 |

---

## 5. PR 분할 / 일정

| PR # | 범위 | 머지 후 상태 | 추정 |
|---|---|---|---|
| PR-1 | Phase 0 결과 (api_probe_result.md, openapi.json 커밋, 본 plan 문서) | 동작 변경 0 | 1h |
| PR-2 | Phase 1 + Phase 2 (인프라 + 인증). 기본값 `.legacy` | backend 토글 가능, rest 로그인까지 동작 | 5h |
| PR-3 | Phase 3 (읽기 9개 메서드) | rest 모드에서 모든 조회 동작 | 2h |
| PR-4 | Phase 4 (쓰기 6개 + GameEngine 페이로드 갱신) | rest 모드 풀 동작 | 2h |
| PR-5 | Phase 5 (기본값 `.rest` 전환 + deprecate) | 신규 API 가 기본 | 1h |
| PR-6 | 후속 — uploadMission, badge upload, XCTest 보강 | — | 별도 |

총 추정: **약 11h, 단일 개발자 기준 2-3 day**.

---

## 6. 작업 체크리스트 (요약)

### Phase 0
- [ ] `/auth/login` 으로 시드 사용자 토큰 발급 (성공 또는 차단 사유 명확화)
- [ ] 13 endpoints 응답 fixture JSON 수집
- [ ] OpenAPI 스펙 다운로드
- [ ] R-1, R-2 합의 결과 본 문서에 업데이트

### Phase 1
- [ ] KeychainStore, AuthSession, APIError 추가
- [ ] RestAPIClient (Authorization 부착 + 401 인터셉터)
- [ ] DTO 9 종 (MissionDetailRes, LoginRes, ReplyReq, PlayReq, ...)
- [ ] MissionDataSource 확장 (fetchUser/updateUser/changePassword)
- [ ] RemoteDataSource → LegacyRemoteDataSource rename
- [ ] RestRemoteDataSource skeleton
- [ ] AppConfig 백엔드 토글 + Settings UI
- [ ] 빌드 검증 (기본 .legacy, 무회귀)

### Phase 2
- [ ] login/register 신규 구현
- [ ] Guest 자동 register+login
- [ ] Logout 메뉴
- [ ] backend=.rest 토글 후 LoginView 통한 진입 확인

### Phase 3
- [ ] fetchMissionList/Published/Tutorial/CurrentGames/MyDesigned/MyPlayed
- [ ] fetchMissionDetail (MissionDetailRes 디코딩)
- [ ] fetchReplies / fetchRanking
- [ ] backend=.rest 에서 MissionList 6개 표시 + 상세 진입

### Phase 4
- [ ] submitReview / recordPlayStart/Finish/Fail
- [ ] fetchUser / updateUser / changePassword
- [ ] GameEngine.playPayload 폐기, 인자 기반 API 호출
- [ ] Virtual Play 완주 → 서버 DB row 추가 확인

### Phase 5
- [ ] backend 기본값 .rest 로 전환
- [ ] LegacyRemoteDataSource / MissionDTO / APIEndpoint deprecated
- [ ] CLAUDE.md / README 갱신

### 테스트
- [ ] XCTest 타겟 추가 + Phase A 단위 테스트 ~30 케이스
- [ ] Phase B 시뮬레이터 E2E 8 단계 모두 통과
- [ ] Phase C curl 스모크 스크립트 + CI 통합

---

## 7. 참고 자료

- 신규 API 사양: [api_client.md](api_client.md)
- 레거시 API 정리: [new_api.md](new_api.md)
- 신규 서버: `http://43.201.188.35:8080`
- Swagger UI: `http://43.201.188.35:8080/swagger-ui/index.html`
- 현재 네트워크 레이어: [PlaySpot/Network/](PlaySpot/Network/)
- DB 스키마 (서버 측): [db.sql](db.sql)
- 빌드 검증 스크립트: [scripts/verify.sh](scripts/verify.sh)
