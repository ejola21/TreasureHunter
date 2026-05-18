# 신규 PlaySpot — API 사용 명세

> 신규 [PlaySpot Swift 포트](PlaySpot/) 가 사용하는 모든 외부 API (서버 통신) 의 정의, 호출처, 응답 형식, 알려진 이슈를 빠짐없이 정리한 문서. 레거시 ObjC 시스템의 [HTTPRequest 트랜잭션 모델](Classes/HTTPRequest.m) 을 그대로 포팅한 구조이며, 신규 코드 위치 기준 (`PlaySpot/Network/`).
>
> 문서 작성일: **2026-05-15**
> 분석 범위: `PlaySpot/Network/` 6개 파일 + `PlaySpot/Services/ImageCacheService.swift` + 호출처 7개 화면

---

## 목차

1. [API 계층 구조](#1-api-계층-구조)
2. [베이스 URL](#2-베이스-url)
3. [APIClient — HTTP 통신 어댑터](#3-apiclient--http-통신-어댑터)
4. [APIEndpoint — 17개 트랜잭션 정의](#4-apiendpoint--17개-트랜잭션-정의)
5. [MissionDataSource — 추상화 프로토콜](#5-missiondatasource--추상화-프로토콜)
6. [LocalDataSource (DEBUG) vs RemoteDataSource (Release)](#6-localdatasource-debug-vs-remotedatasource-release)
7. [응답 파싱](#7-응답-파싱)
8. [추가 API — 이미지 다운로드 / 업로드](#8-추가-api--이미지-다운로드--업로드)
9. [API 호출처 매핑](#9-api-호출처-매핑)
10. [신규 PlaySpot 의 구현 / 미구현 매트릭스](#10-신규-playspot-의-구현--미구현-매트릭스)
11. [보안 / 제약 / 알려진 이슈](#11-보안--제약--알려진-이슈)

---

## 1. API 계층 구조

```
SwiftUI View (MissionListView, LoginView, MyInfoView, ...)
        │
        ↓ DI: AppConfig.dataSource (DEBUG=Local / Release=Remote)
        │
MissionDataSource (protocol)
        │
        ├── LocalDataSource (mock JSON 파일)
        └── RemoteDataSource (실제 서버)
                    │
                    ↓ APIClient.shared.request(.endpoint)
                    │
            APIEndpoint (전송 명세)
                    │
                    ↓ URLSession.shared.data(for:)
                    │
                URL (3종 base) + POST + URL-encoded body
```

**대안 경로** — `ImageCacheService` 는 `APIClient` 우회하고 직접 `URLSession` 으로 뱃지 다운로드 / 이미지 업로드.

---

## 2. 베이스 URL

[`APIEndpoint.swift:5-10`](PlaySpot/Network/APIEndpoint.swift#L5-L10):

| 상수 | URL | 용도 |
|---|---|---|
| `baseURL` | `http://nexapp.co.kr/playspot/J_MyList.php` | 메인 API (대부분 트랜잭션) |
| `rankingURL` | `http://nexapp.co.kr/playspot/mission_play_info.php` | 랭킹 조회 (tr=c_mission_play_ranking 만) |
| `passwordURL` | `http://nexapp.co.kr/playspot/user.php` | 비밀번호 변경 (정의되어 있으나 **신규 코드에서 미사용**) |
| `badgeBaseURL` | `http://nexapp.co.kr/playspot/badge/` | 미션 뱃지 이미지 prefix (`{missionID}.png` 붙여서 GET) |
| `imageUploadURL` | `http://nexapp.co.kr/playspot/image_save.php` | 이미지 업로드 (multipart/form-data) |
| `userInfoURL` | `http://mking.elogin.co.kr/xe/user.php` | 별도 도메인. 유저 정보 조회/수정 (정의만, **신규 코드에서 미사용**) |

> **⚠ 모두 HTTP** (HTTPS 아님). [`PlaySpot/Info.plist`](PlaySpot/Info.plist) 의 `NSAppTransportSecurity → NSExceptionDomains` 에 `nexapp.co.kr` / `mking.elogin.co.kr` 두 도메인 ATS 예외 등록 필요 (CLAUDE.md §3).

---

## 3. APIClient — HTTP 통신 어댑터

[`APIClient.swift`](PlaySpot/Network/APIClient.swift) — `actor` (동시 안전).

### 3.1 메서드

| 메서드 | 시그니처 | 설명 |
|---|---|---|
| `request(_:)` | `func request(_ endpoint: APIEndpoint) async throws -> String` | **비동기**, 5초 timeout. 응답을 UTF-8 문자열로 반환 |
| `requestSync(_:)` | `func requestSync(_ endpoint: APIEndpoint) async throws -> String` | **30초 timeout** (이름은 sync 지만 실제로는 async). 레거시 `requestUrlsync:` 포팅 — 무거운 응답 / 업로드 용 |
| `md5(_:)` | `static func md5(_ string: String) -> String` | `Insecure.MD5.hash(data:)` (CryptoKit). 비밀번호 MD5 해시 |

### 3.2 HTTP 동작

- **메서드**: `POST` (모든 요청)
- **Content-Type**: 미설정 (서버가 form 으로 파싱하는 듯)
- **Body**: `key=value&key=value` URL-encoded UTF-8
- **Encoding**: `addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)` (private extension)
- **응답 처리**: `String(data:encoding:.utf8) ?? ""` — HTTP status code 검증 없음
- **에러 처리**: URLSession 에러만 throw, 비즈니스 에러 (서버 응답 "FAIL" 등) 는 호출처 책임

### 3.3 레거시 매핑

| 신규 (APIClient) | 레거시 (HTTPRequest.m) |
|---|---|
| `request(_:)` | `requestUrl:bodyObject:` (NSURLConnection async + delegate) |
| `requestSync(_:)` | `requestUrlsync:bodyObject:` (sendSynchronousRequest) |
| `md5(_:)` | `md5:` (CC_MD5) |

---

## 4. APIEndpoint — 17개 트랜잭션 정의

[`APIEndpoint.swift:12-29`](PlaySpot/Network/APIEndpoint.swift#L12-L29) 의 enum case 17개. 각 case 마다:
- `transactionCode`: `tr` 파라미터 값
- `url`: `baseURL` 또는 `rankingURL`
- `parameters: [String: String]`: form-body 키/값 (`tr` 자동 포함)

---

### 4.1 `missionDetail(missionID:)` — 미션 상세 다운로드

| 항목 | 값 |
|---|---|
| 트랜잭션 | `tr=200` |
| URL | `baseURL` |
| 파라미터 | `tr=200&missionID={missionID}` |
| 호출 메서드 | `MissionDataSource.fetchMissionDetail` |
| 호출처 | [`GameEngine.setup`](PlaySpot/Game/GameEngine.swift#L74) |

**응답 형식**: `^M{missionJSON}^I{itemsJSON}^Q{quizzesJSON}` 멀티파트 — [`MissionDTO.parse`](PlaySpot/Network/MissionDTO.swift) 에서 `^` split 후 첫 글자 prefix 제거하고 각 섹션 JSON decode.

**파싱 결과**: `(Mission, [MissionItem], [ItemQuiz])` 튜플

---

### 4.2 `missionReviews(missionID:)` — 미션 댓글 조회

| 항목 | 값 |
|---|---|
| 트랜잭션 | `tr=300` |
| URL | `baseURL` |
| 파라미터 | `tr=300&missionID={missionID}` |
| 호출 메서드 | `MissionDataSource.fetchReplies` |
| 호출처 | [`MissionDetailView.task`](PlaySpot/Views/MissionList/MissionDetailView.swift#L107) |
| 응답 | JSON 배열 `[MissionReply]` |

---

### 4.3 `submitReview(missionID:userID:score:reply:)` — 평점/리뷰 등록

| 항목 | 값 |
|---|---|
| 트랜잭션 | `tr=400` |
| URL | `baseURL` |
| 파라미터 | `tr=400&MID={mid}&UID={uid}&Score={float}&Reply={reply}` |
| 호출 메서드 | (RemoteDataSource 에 미정의 — APIClient 직접 호출 필요) |
| 호출처 | **없음** (UI 미구현) |
| 응답 | fire-and-forget |

---

### 4.4 `playingMissions(last:lang:)` — 미션 목록 (전체)

| 항목 | 값 |
|---|---|
| 트랜잭션 | `tr=500` |
| URL | `baseURL` |
| 파라미터 | `tr=500&last={cursor}&lang={lang}` |
| 호출 메서드 | `MissionDataSource.fetchMissionList(cursor:lang:)` |
| 호출처 | [`MissionListView.loadMissions`](PlaySpot/Views/MissionList/MissionListView.swift#L59) |
| 응답 | JSON 배열 `[Mission]` |

> **⚠ 명명 차이**: enum 이름 `playingMissions` 가 이름과 달리 "전체 미션 목록" (TR=500). research.md §8.3 참고.

---

### 4.5 `publishedMissions(last:lang:lat:lon:)` — 위치 기반 미션 목록

| 항목 | 값 |
|---|---|
| 트랜잭션 | `tr=501` |
| URL | `baseURL` |
| 파라미터 | `tr=501&last={cursor}&lang={lang}&latitude={lat}&longitude={lon}` |
| 호출 메서드 | (RemoteDataSource 에 미정의) |
| 호출처 | **없음** ("Near Me" 탭 UI 는 있으나 데이터소스 메서드 미연결) |
| 응답 | JSON 배열 `[Mission]` |

---

### 4.6 `myDesigns(last:lang:)` — 미션 목록 (탭2 — 내가 만든 것?)

| 항목 | 값 |
|---|---|
| 트랜잭션 | `tr=502` |
| URL | `baseURL` |
| 파라미터 | `tr=502&last={cursor}&lang={lang}` |
| 호출 메서드 | (RemoteDataSource 에 미정의) |
| 호출처 | **없음** |
| 응답 | JSON 배열 `[Mission]` |

---

### 4.7 `tutorials(lang:)` — 튜토리얼 미션 목록

| 항목 | 값 |
|---|---|
| 트랜잭션 | `tr=503` |
| URL | `baseURL` |
| 파라미터 | `tr=503&gb={lang}` (lang 파라미터 이름이 `gb`!) |
| 호출 메서드 | `MissionDataSource.fetchTutorialMissions(region:)` |
| 호출처 | **없음** (프로토콜 메서드 정의되어 있으나 호출 없음) |
| 응답 | JSON 배열 `[Mission]` |

> 레거시 `gb`: `0%` (한국어) / `1%` (기타) — research.md §8.3.

---

### 4.8 `designedCount(userID:)` — 내가 디자인한 미션 목록

| 항목 | 값 |
|---|---|
| 트랜잭션 | `tr=600` |
| URL | `baseURL` |
| 파라미터 | `tr=600&id={userID}` |
| 호출 메서드 | `MissionDataSource.fetchMyDesigned(userID:)` |
| 호출처 | [`MyInfoView.task`](PlaySpot/Views/MyInfo/MyInfoView.swift#L48) |
| 응답 | JSON 배열 `[Mission]` (`MissionID` 필드 포함) |

> **⚠ 명명 모호**: enum 이름 `designedCount` 가 카운트만 반환할 것 같지만 실제로는 **목록**. research.md §8.3 일치.

---

### 4.9 `playedCount(userID:)` — 내가 플레이한 미션 목록

| 항목 | 값 |
|---|---|
| 트랜잭션 | `tr=601` |
| URL | `baseURL` |
| 파라미터 | `tr=601&id={userID}` |
| 호출 메서드 | `MissionDataSource.fetchMyPlayed(userID:)` |
| 호출처 | [`MyInfoView.task`](PlaySpot/Views/MyInfo/MyInfoView.swift#L49), [`BadgeListView.task`](PlaySpot/Views/MyInfo/BadgeListView.swift#L53) |
| 응답 | JSON 배열 `[Mission]` |

---

### 4.10 `currentGames(userID:)` — 현재 플레이 중인 미션 목록

| 항목 | 값 |
|---|---|
| 트랜잭션 | `tr=602` |
| URL | `baseURL` |
| 파라미터 | `tr=602&id={userID}` |
| 호출 메서드 | `MissionDataSource.fetchCurrentGames(userID:)` |
| 호출처 | **없음** (프로토콜만 정의) |
| 응답 | JSON 배열 `[Mission]` |

---

### 4.11 `uploadMission(data:items:quizzes:)` — 미션 서버 업로드

| 항목 | 값 |
|---|---|
| 트랜잭션 | `tr=700` |
| URL | `baseURL` |
| 파라미터 | `tr=700&mission={data}&missionItem={items}&itemQuiz={quizzes}` |
| 호출 메서드 | (RemoteDataSource 에 미정의) |
| 호출처 | **없음** (빌더 미구현) |
| 응답 | `"SUCCESS"` 문자열 |

> 필드 구분자 `}}}`, 레코드 구분자 `**` (research.md §8.3) — 신규 포트는 빌더가 미구현이라 형식 빌드 코드도 없음.

---

### 4.12 `login(userID:passwordMD5:)` — 로그인

| 항목 | 값 |
|---|---|
| 트랜잭션 | `tr=800` |
| URL | `baseURL` |
| 파라미터 | `tr=800&user_id={email}&password={MD5}` |
| 호출 메서드 | `MissionDataSource.login(email:passwordMD5:)` |
| 호출처 | [`LoginView`](PlaySpot/Views/Auth/LoginView.swift#L69) |
| 응답 | `"SUCCESS"` 문자열 (trim 후 비교) |

---

### 4.13 `register(userID:passwordMD5:)` — 회원가입

| 항목 | 값 |
|---|---|
| 트랜잭션 | `tr=tr_user_reg` |
| URL | `baseURL` |
| 파라미터 | `tr=tr_user_reg&user_id={email}&password={MD5}` |
| 호출 메서드 | (RemoteDataSource 에 미정의) |
| 호출처 | **없음** (UI 미구현) |
| 응답 | `"SUCCESS"` 또는 오류 |

---

### 4.14 `playStart(data:)` — 플레이 시작 알림

| 항목 | 값 |
|---|---|
| 트랜잭션 | `tr=c_mission_play_start` |
| URL | `baseURL` |
| 파라미터 | `tr=c_mission_play_start&mission_play={data}` |
| `data` 형식 | `{missionID},{playerID},{startTime},{isVirtualMode}` (CSV) |
| 호출 메서드 | (RemoteDataSource 에 미정의) |
| 호출처 | **없음** (TODO — Start 획득 시 호출되어야) |

---

### 4.15 `playFinish(data:)` — 플레이 완료 알림

| 항목 | 값 |
|---|---|
| 트랜잭션 | `tr=c_mission_play_finish` |
| URL | `baseURL` |
| 파라미터 | `tr=c_mission_play_finish&mission_play={data}` |
| `data` 형식 | `{missionID},{playerID},{endTime},{isVirtualMode}` |
| 호출 메서드 | (RemoteDataSource 에 미정의) |
| 호출처 | **없음** (TODO — End 획득 시 호출되어야) |

---

### 4.16 `playFail(data:)` — 플레이 실패 알림

| 항목 | 값 |
|---|---|
| 트랜잭션 | `tr=c_mission_play_fail` |
| URL | `baseURL` |
| 파라미터 | `tr=c_mission_play_fail&mission_play={data}` |
| `data` 형식 | `{missionID},{playerID},{endTime},{isVirtualMode}` |
| 호출 메서드 | (RemoteDataSource 에 미정의) |
| 호출처 | **없음** |

---

### 4.17 `playRanking(missionID:)` — 미션 랭킹 조회

| 항목 | 값 |
|---|---|
| 트랜잭션 | `tr=c_mission_play_ranking` |
| URL | **`rankingURL`** (다른 엔드포인트!) |
| 파라미터 | `tr=c_mission_play_ranking&mission_id={missionID}` |
| 호출 메서드 | `MissionDataSource.fetchRanking(missionID:)` |
| 호출처 | **없음** (프로토콜만 정의) |
| 응답 | JSON 배열 `[RankingEntry]` |

---

## 5. MissionDataSource — 추상화 프로토콜

[`MissionDataSource.swift`](PlaySpot/Network/MissionDataSource.swift) — 9개 async 메서드. SwiftUI View 가 직접 APIClient 를 부르지 않고 이 프로토콜을 통해 데이터 소스를 추상화 (테스트 / mock 교체 용이).

```swift
protocol MissionDataSource {
    func fetchMissionList(cursor: Int, lang: String) async throws -> [Mission]
    func fetchMissionDetail(missionID: String) async throws -> (Mission, [MissionItem], [ItemQuiz])
    func fetchReplies(missionID: String) async throws -> [MissionReply]
    func fetchTutorialMissions(region: String) async throws -> [Mission]
    func fetchMyDesigned(userID: String) async throws -> [Mission]
    func fetchMyPlayed(userID: String) async throws -> [Mission]
    func fetchCurrentGames(userID: String) async throws -> [Mission]
    func fetchRanking(missionID: String) async throws -> [RankingEntry]
    func login(email: String, passwordMD5: String) async throws -> Bool
}

enum DataSourceError: Error {
    case fileNotFound(String)   // LocalDataSource 전용
    case decodingFailed         // RemoteDataSource MissionDTO.parse 실패
}
```

### 5.1 메서드 → 트랜잭션 매핑

| Protocol Method | APIEndpoint | tr |
|---|---|---|
| `fetchMissionList(cursor:lang:)` | `.playingMissions(last:lang:)` | `500` |
| `fetchMissionDetail(missionID:)` | `.missionDetail(missionID:)` | `200` |
| `fetchReplies(missionID:)` | `.missionReviews(missionID:)` | `300` |
| `fetchTutorialMissions(region:)` | `.tutorials(lang:)` | `503` |
| `fetchMyDesigned(userID:)` | `.designedCount(userID:)` | `600` |
| `fetchMyPlayed(userID:)` | `.playedCount(userID:)` | `601` |
| `fetchCurrentGames(userID:)` | `.currentGames(userID:)` | `602` |
| `fetchRanking(missionID:)` | `.playRanking(missionID:)` | `c_mission_play_ranking` |
| `login(email:passwordMD5:)` | `.login(userID:passwordMD5:)` | `800` |

---

## 6. LocalDataSource (DEBUG) vs RemoteDataSource (Release)

### 6.1 분기 — [`AppConfig.swift`](PlaySpot/Network/AppConfig.swift)

```swift
enum AppConfig {
    #if DEBUG
    static let dataSource: MissionDataSource = LocalDataSource()
    #else
    static let dataSource: MissionDataSource = RemoteDataSource()
    #endif
}
```

→ **Debug 빌드 = mock JSON, Release 빌드 = 실제 서버**.

### 6.2 LocalDataSource — [`LocalDataSource.swift`](PlaySpot/Network/LocalDataSource.swift)

- `Bundle.main.url(forResource:withExtension:subdirectory:"MockData")` 로 JSON 파일 로드
- 파일 위치: [`PlaySpot/Resources/MockData/`](PlaySpot/Resources/MockData/) — `mock_mission_list.json`, `mock_mission_<missionID>.json`, `mock_items_<missionID>.json`, `mock_quizzes_<missionID>.json` 등
- 캐싱 없음 (매번 디스크에서 fresh 읽기)
- 각 fetch 메서드가 해당 mock 파일 1개를 디코드해서 반환

### 6.3 RemoteDataSource — [`RemoteDataSource.swift`](PlaySpot/Network/RemoteDataSource.swift)

- 9개 메서드 모두 `client.request(.endpoint)` → `String` → `JSONDecoder().decode(...)` 패턴
- 예외: `fetchMissionDetail` 만 멀티파트 응답이라 `MissionDTO.parse(response:)` 사용
- 예외: `login` 은 응답 문자열 `"SUCCESS"` 와 비교
- HTTP status code / 비즈니스 에러 검증 없음

---

## 7. 응답 파싱

### 7.1 단순 JSON 디코딩 (대부분)

```swift
let response: String = try await client.request(.endpoint)
let result = try JSONDecoder().decode(T.self, from: Data(response.utf8))
```

→ `[Mission]`, `[MissionReply]`, `[RankingEntry]` 등.

### 7.2 멀티파트 응답 — [`MissionDTO.parse`](PlaySpot/Network/MissionDTO.swift)

`tr=200` 응답 형식:
```
^M{missionJSON}^I{itemsJSON}^Q{quizzesJSON}
```

파싱 흐름:
1. `response.components(separatedBy: "^")` → `["", "M{...}", "I{...}", "Q{...}"]` (첫 element 빈 문자열)
2. `sections.count >= 3` 검증
3. `String(sections[0].dropFirst())` 식으로 첫 글자 prefix (M/I/Q) 제거
4. 각 섹션 JSON 디코드 → `(Mission, [MissionItem], [ItemQuiz])` 튜플

**⚠ 인덱싱 버그 가능성**: `sections[0]` 이 빈 문자열 (split 의 첫 토큰) 인데 `.dropFirst()` 하면 또 빈 문자열. 실제로는 `sections[1]`/`[2]`/`[3]` 이어야 할 것 같음. [`MissionDTO.swift:11-19`](PlaySpot/Network/MissionDTO.swift#L11-L19) 검토 필요.

### 7.3 단순 문자열 응답

- `tr=800` (login): `"SUCCESS"` / 오류 메시지
- `tr=tr_user_reg` (register): `"SUCCESS"` / 오류
- `tr=700` (uploadMission): `"SUCCESS"`
- `tr=400` (submitReview): 무응답 (fire-and-forget)
- `tr=c_mission_play_*`: 무응답 (fire-and-forget)

---

## 8. 추가 API — 이미지 다운로드 / 업로드

`APIEndpoint` enum 외부. [`ImageCacheService.swift`](PlaySpot/Services/ImageCacheService.swift) 가 `URLSession` 직접 사용.

### 8.1 뱃지 이미지 다운로드 (GET)

| 항목 | 값 |
|---|---|
| URL | `http://nexapp.co.kr/playspot/badge/{missionID}.png` |
| 메서드 | `GET` (단순 다운로드) |
| 호출처 | `ImageCacheService.loadBadgeImage(missionID:)` + 직접 `AsyncImage(url:)` 도 사용 |
| 캐시 전략 | (1) 메모리 (`NSCache`) → (2) 디스크 (`Caches/badges/{missionID}.png`) → (3) 서버 다운로드 → (4) `empty02` 폴백 |
| 직접 호출처 | [`MissionDetailView`](PlaySpot/Views/MissionList/MissionDetailView.swift#L22), [`BadgeListView`](PlaySpot/Views/MyInfo/BadgeListView.swift#L94) (둘 다 `AsyncImage(url:)` 로 호출 — 캐시 우회) |

> ⚠️ AsyncImage 와 ImageCacheService 가 둘 다 사용되어 캐시가 분리됨. 통합 권장.

### 8.2 이미지 업로드 (multipart/form-data)

| 항목 | 값 |
|---|---|
| URL | `http://nexapp.co.kr/playspot/image_save.php` |
| 메서드 | `POST` |
| Content-Type | `multipart/form-data; boundary=treasurehunter` |
| Body | `--treasurehunter\r\nContent-Disposition: form-data; name="userfile"; filename="{imageID}"\r\nContent-Type: image/png\r\n\r\n{binary PNG data}\r\n--treasurehunter--\r\n` |
| 호출처 | `ImageCacheService.uploadImage(imageID:image:)` |
| 호출하는 화면 | **없음** (서비스 메서드 정의되어 있으나 호출 없음 — 빌더 미션 뱃지 업로드용) |

---

## 9. API 호출처 매핑

### 9.1 화면 → API 호출

| 화면 | 호출 메서드 | 트랜잭션 |
|---|---|---|
| [MissionListView](PlaySpot/Views/MissionList/MissionListView.swift) | `dataSource.fetchMissionList` | `tr=500` |
| [MissionDetailView](PlaySpot/Views/MissionList/MissionDetailView.swift) | `dataSource.fetchReplies` + `AsyncImage` 뱃지 | `tr=300` + GET 뱃지 |
| [LoginView](PlaySpot/Views/Auth/LoginView.swift) | `dataSource.login` | `tr=800` |
| [MyInfoView](PlaySpot/Views/MyInfo/MyInfoView.swift) | `dataSource.fetchMyDesigned` + `dataSource.fetchMyPlayed` | `tr=600` + `tr=601` |
| [BadgeListView](PlaySpot/Views/MyInfo/BadgeListView.swift) | `dataSource.fetchMyPlayed` + `AsyncImage` | `tr=601` + GET 뱃지 |
| [GameEngine.setup](PlaySpot/Game/GameEngine.swift#L74) | `dataSource.fetchMissionDetail` | `tr=200` |

### 9.2 트랜잭션별 호출 발생 빈도

| tr | 발생 빈도 | 예상 트래픽 |
|---|---|---|
| `200` (missionDetail) | 미션 시작마다 | 중 |
| `300` (replies) | 미션 상세 화면마다 | 중 |
| `500` (missionList) | MissionListView 표시마다 | 중 |
| `600`/`601` (designed/played) | MyInfo 진입마다 | 저 |
| `800` (login) | 로그인 시 1회 | 저 |
| GET 뱃지 | 미션 행마다 (캐시 미스 시) | 고 |
| `400`/`500`/`501`/`502`/`503`/`602`/`700`/`tr_user_reg`/`c_mission_play_*` | **호출 없음** | 0 |

---

## 10. 신규 PlaySpot 의 구현 / 미구현 매트릭스

| API | enum 정의 | DataSource 메서드 | 호출처 | 상태 |
|---|:---:|:---:|:---:|---|
| tr=200 missionDetail | ✅ | ✅ | ✅ | **완전 구현** |
| tr=300 missionReviews | ✅ | ✅ | ✅ | **완전 구현** |
| tr=400 submitReview | ✅ | ❌ | ❌ | 정의만 (UI 없음) |
| tr=500 missionList | ✅ | ✅ | ✅ | **완전 구현** |
| tr=501 publishedMissions | ✅ | ❌ | ❌ | 정의만 ("Near Me" 탭 미연결) |
| tr=502 myDesigns | ✅ | ❌ | ❌ | 정의만 |
| tr=503 tutorials | ✅ | ✅ | ❌ | 프로토콜만 (호출 없음) |
| tr=600 designedCount | ✅ | ✅ | ✅ | **완전 구현** |
| tr=601 playedCount | ✅ | ✅ | ✅ | **완전 구현** |
| tr=602 currentGames | ✅ | ✅ | ❌ | 프로토콜만 (호출 없음) |
| tr=700 uploadMission | ✅ | ❌ | ❌ | 정의만 (빌더 미구현) |
| tr=800 login | ✅ | ✅ | ✅ | **완전 구현** |
| tr_user_reg register | ✅ | ❌ | ❌ | 정의만 (회원가입 UI 없음) |
| tr_pwd_chg password | ❌ | ❌ | ❌ | URL 만 정의됨 (`passwordURL` 미사용) |
| tr_user_sel/chg userInfo | ❌ | ❌ | ❌ | URL 만 정의됨 (`userInfoURL` 미사용) |
| c_mission_play_start | ✅ | ❌ | ❌ | **TODO** (Start 획득 시 호출되어야) |
| c_mission_play_finish | ✅ | ❌ | ❌ | **TODO** (End 획득 시 호출되어야) |
| c_mission_play_fail | ✅ | ❌ | ❌ | TODO (Exit 시 호출되어야) |
| c_mission_play_ranking | ✅ | ✅ | ❌ | 프로토콜만 (랭킹 UI 호출 없음) |
| GET 뱃지 | (직접) | (캐시 서비스) | ✅ | **완전 구현** |
| POST 이미지 업로드 | (직접) | (캐시 서비스) | ❌ | 서비스만 (호출 없음) |

**요약**:
- **완전 구현**: 6개 (200, 300, 500, 600, 601, 800, 뱃지 GET)
- **enum 정의 + 미연결**: 11개
- **URL 정의 + enum 없음**: 3개 (tr_pwd_chg, tr_user_sel, tr_user_chg)

---

## 11. 보안 / 제약 / 알려진 이슈

### 11.1 보안

| 항목 | 현재 상태 | 권장 |
|---|---|---|
| HTTPS | ❌ 모두 HTTP (ATS 예외) | HTTPS 마이그레이션 |
| 비밀번호 | MD5 평문 전송 (CryptoKit `Insecure.MD5`) | bcrypt + TLS |
| 인증 | 매 요청마다 `user_id` 평문 (세션/토큰 없음) | JWT 도입 |
| 응답 검증 | `URLResponse`/HTTP status code 무시 | status 검증 |
| 입력 검증 | URL-encoding 만 적용 (SQL injection 방어 X) | 서버 측 prepared statement 필수 |

### 11.2 신뢰성

- **Timeout 짧음**: `request(_:)` 5초 — 모바일 네트워크 환경에선 부족
- **재시도 없음**: 일시적 네트워크 오류 시 즉시 실패
- **에러 모델 빈약**: `DataSourceError` 가 `fileNotFound`/`decodingFailed` 만 — 네트워크/HTTP 에러 표현 못 함
- **부분 응답 처리 없음**: `String(data:encoding:.utf8) ?? ""` 로 빈 문자열 fallback → JSON 파싱 실패만 throw

### 11.3 코드 정합성

- **enum 명명 모호**: `playingMissions` (= 전체 목록), `designedCount` (= 목록), `playedCount` (= 목록) — research.md 의 트랜잭션 의미와 명명 불일치
- **MissionDTO 인덱싱 의심**: [`MissionDTO.swift:11-13`](PlaySpot/Network/MissionDTO.swift#L11-L13) 에서 `sections[0]` 이 빈 문자열일 가능성 (split `^` 의 첫 토큰). 실제 응답 형식 확인 후 수정 필요할 수도 있음
- **AsyncImage vs ImageCacheService 분리**: 같은 뱃지 URL 을 두 경로로 호출 — 캐시 효율 낮음
- **passwordURL / userInfoURL**: 정의만 있고 호출 없음 — 죽은 코드

### 11.4 누락된 핵심 흐름

게임 진행 중 서버 동기화 누락:
- [`GameEngine.acquireItem`](PlaySpot/Game/GameEngine.swift) 의 Start/End 분기에서 `c_mission_play_start`/`finish` 호출 없음
- 사용자 통계 (PlayCnt, FailCnt) 가 서버에 반영 안 됨
- 랭킹도 서버에 안 올라감 → 다른 플레이어 비교 불가능

→ 운영 전 필수 추가 항목.

---

## 12. 참고

- 레거시 ObjC 트랜잭션 명세: [research.md §8](research.md#8-서버-통신-시스템) (전체 17개 트랜잭션 + 응답 형식)
- 신규 PlaySpot 데이터베이스: [db.sql](db.sql) (MySQL 8.4 스키마. 위 API 들과 매핑됨)
- 신규 PlaySpot 게임 룰: [game_rule.md](game_rule.md), [research2.md](research2.md)
- 신규 PlaySpot vs 레거시 룰 검증: [rule_check.md](rule_check.md)

---

*문서 끝. 신규 PlaySpot Swift 포트의 외부 API 사용 명세 — 17개 트랜잭션 + 2개 이미지 endpoint = 19개 API + 6개 미연결 (URL/enum) = 운영 전 추가 작업 필요.*
