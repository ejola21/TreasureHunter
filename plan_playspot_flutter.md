# plan_playspot_flutter.md — PlaySpot Flutter 전환 작업 계획 (미션·디자인 탭 우선)

> **목적**: iOS SwiftUI 앱 **PlaySpot** 을 **Flutter 단일 코드베이스**로 전환한다. 검증된 파일럿
> [`flutter_ar_spike/`](flutter_ar_spike/) 를 베이스로 키워(promote) 풀 앱으로 발전시키고,
> **미션 탭 → 디자인 탭** 순으로 차근차근 개발한다.
> **데이터·디자인은 그대로**: 기존 REST 백엔드(`/api/v1/**`)와 미션 콘텐츠를 그대로 호출하고,
> Duolingo 풍 디자인 시스템(DuoTokens)을 Flutter로 이식해 동일 룩앤필을 유지한다.
> **상위 맥락**: [plan_flutter.md](plan_flutter.md)(AR 파일럿 검증 — Web/Android/iOS PASS),
> [flutter_ar_spike/README.md](flutter_ar_spike/README.md), [CLAUDE.md](CLAUDE.md), [api_plan_new.md](api_plan_new.md).

---

## 1. 범위 / 우선순위

- **이번 범위**: ① 미션 탭(목록 + 상세) ② 디자인 탭(내 디자인 목록 + 미션 생성/편집 + 아이템 배치).
- **데이터 그대로**: 동일 서버 `http://43.201.188.35:8080` 의 `/api/v1/**` 를 그대로 사용 → iOS 앱과 **같은 데이터/계정/JWT 흐름** 공유. 서버·DB·미션 콘텐츠 변경 없음.
- **디자인 그대로**: `PlaySpot/Views/DesignSystem/DuoTokens.swift` 의 색/폰트/컴포넌트를 Flutter 위젯·테마로 이식.
- **차근차근**: Phase 0~4, 각 단계 끝에 `flutter analyze` + `flutter build web` + (가능 시) 실기기 스모크로 검증.

## 2. 비목표 (이번 범위에서 안 함)

- **Play / AR 화면 연결** — 단, 파일럿의 AR 자산([`ar_overlay_view.dart`](flutter_ar_spike/lib/ar_overlay_view.dart), `ar_coordinate.dart`, `compass_service*.dart`, `location_service.dart`) 은 **보존**하고 후속 Play 단계에서 재사용.
- My Info / Badge / Settings 탭, StoreKit/IAP, 미니게임(흔들기), 아이템 획득 팝업/HUD.
- 레거시 백엔드(`/playspot/J_MyList.php`) — REST 전용으로 간다.

## 3. 베이스 결정 + 기술 스택

- **베이스**: 새 프로젝트를 만들지 않고 **`flutter_ar_spike/` 를 그대로 발전**시킨다 (web/android/ios 플랫폼 + 빌드 검증 완료). 추후 안정화되면 별도 repo `playspot-flutter` 로 promote.
- **상태관리**: **Riverpod** (`flutter_riverpod`) — DI(`AppConfig.dataSource` 대응) + 비동기 목록/상세(`AsyncNotifier`/`FutureProvider`).

| 영역 | 패키지 | 용도 |
|---|---|---|
| HTTP | `dio` | RestApiClient (인터셉터로 JWT 부착 + 401 재로그인) |
| 상태관리/DI | `flutter_riverpod` | Provider/Notifier |
| 보안 저장 | `flutter_secure_storage` | JWT 토큰 + 자격증명 (KeychainStore 대응) |
| 지도 | `flutter_map` + `latlong2` | 디자인 빌더 맵 (OSM, 무료, web/모바일 공통, MapKit 대체) |
| 위치 | `geolocator` (파일럿 보유) | nearby 미션 / 빌더 현재위치 |
| 날짜 | `intl` | LimitTime/날짜 파싱·포맷 |
| (보유) | `camera`, `web`, `flutter_compass` | AR 자산용 — 유지 |

## 4. 아키텍처 매핑 (Swift → Dart)

| Swift (PlaySpot) | Dart (flutter_ar_spike) | 비고 |
|---|---|---|
| `Network/AppConfig.swift` | `network/app_config.dart` | dataSource 주입 (Riverpod provider) |
| `Network/RestAPIClient.swift` (actor) | `network/rest_api_client.dart` | dio + Bearer 자동부착 + 401/403 1회 재로그인 인터셉터 |
| `Network/AuthSession.swift` (actor) | `network/auth_session.dart` | JWT+자격증명 → flutter_secure_storage |
| `Network/AuthBootstrap.swift` | `network/auth_bootstrap.dart` | 게스트 자동 register+login, inflight Future 공유 |
| `Network/MissionDataSource.swift` | `network/mission_data_source.dart` | 추상 인터페이스 |
| `Network/RestRemoteDataSource.swift` | `network/rest_remote_data_source.dart` | `/api/v1/**` 구현 |
| `Models/Mission.swift` 등 | `models/*.dart` | fromJson/toJson, 서버 CodingKeys 매핑 |
| `Views/MissionList/*` | `features/missions/*` | 목록/상세/카드 |
| `Views/MissionBuilder/*` + `Game/MissionBuilderViewModel.swift` | `features/design/*` | 빌더 목록/생성/아이템 에디터/맵 |
| `Views/DesignSystem/DuoTokens.swift` | `design_system/*` | 테마 + 위젯 |
| `Views/MainTabView` | `app/main_tab.dart` | 우선 2탭(미션/디자인) |

## 5. 폴더 구조 (feature-first)

```
flutter_ar_spike/lib/
├── main.dart                      # 진입점 (ProviderScope + MainTab)
├── app/
│   ├── theme.dart                 # DuoTokens → ThemeData
│   ├── main_tab.dart              # 하단 탭 (미션 / 디자인) — 이후 확장
│   └── router.dart                # 화면 전환
├── design_system/                 # DuoTokens 이식
│   ├── duo_tokens.dart            # 색/반경/폰트 상수
│   ├── candy_button.dart  duo_chip.dart  form_group.dart  fox_mascot.dart ...
├── models/
│   ├── mission.dart  mission_item.dart  item_type.dart  show_type.dart
│   ├── item_quiz.dart  mission_reply.dart  ranking_entry.dart  game_state.dart
├── network/
│   ├── app_config.dart  rest_api_client.dart  auth_session.dart
│   ├── auth_bootstrap.dart  mission_data_source.dart  rest_remote_data_source.dart
├── features/
│   ├── missions/
│   │   ├── mission_list_page.dart  mission_detail_page.dart  mission_card.dart
│   │   └── mission_providers.dart
│   └── design/
│       ├── design_list_page.dart  mission_setup_page.dart  item_editor_page.dart
│       ├── builder_map.dart  item_picker.dart  quiz_variants.dart
│       └── design_providers.dart   # MissionBuilderViewModel 대응
└── ar/                            # 파일럿 자산 보존 (이동만)
    └── ar_overlay_view.dart  ar_coordinate.dart  compass_service*.dart  location_service.dart
```

## 6. "데이터·디자인 그대로" 전략

### 6.1 데이터 (동일 백엔드)
- `RestRemoteDataSource` 가 iOS와 **동일 경로/페이로드**로 호출 → 같은 미션이 그대로 보임.
- 게스트 부트스트랩(`Guest@<ts>` 자동 register+login)도 동일 → 최초 실행 즉시 데이터 조회 가능.
- **주의**: `createMission` 의 `BuilderMissionReq` JSON 스펙을 Swift와 **바이트 단위로 일치**시켜야 서버가 수락 (필드명/형식/날짜·LimitTime "HH:MM:SS").

### 6.2 디자인 (DuoTokens 이식)
- 색상(`duoGreen500=#58CC02` 등), 반경, 그림자, Candy 버튼(아래 그림자 offset), DuoChip, FormGroup/FormRow, 미션 카드, 말풍선을 Dart 위젯으로.
- **폰트**: `Jalnan2TTF.ttf`(duoDisplay) 등 .ttf 를 `assets/fonts/` 로 복사 + `pubspec.yaml fonts:` 등록.

### 6.3 에셋 마이그레이션 (이미지)
- `PlaySpot/Assets.xcassets` 의 imageset(168개) 중 **미션·디자인에 필요한 것만 우선** 추출:
  아이템 아이콘(`Items/i_*`, `AR/ar_*`), 탭바 아이콘(`UI/menu_*`), `FoxMascot`, `Minigame/playspot_logo*`.
- 스크립트(Phase 0): 각 `*.imageset/`의 `@2x/@3x` PNG → `assets/items/`, `assets/ar/`, `assets/ui/` 로 복사하고
  Flutter 해상도 변형(`2.0x/3.0x` 하위폴더) 으로 매핑. `ItemType.mapIcon/arIcon` 경로 규칙을 Dart에서 동일 재현.

## 7. Phase별 작업

### Phase 0 — 기반 (베이스 정비)
- [ ] `pubspec.yaml`: dio, flutter_riverpod, flutter_secure_storage, flutter_map, latlong2, intl 추가
- [ ] 폴더 구조 생성, 기존 AR 파일을 `lib/ar/` 로 이동 (import 경로 갱신, 빌드 유지)
- [ ] `design_system/duo_tokens.dart` + `app/theme.dart` (색/폰트/기본 위젯 3~4개: CandyButton, DuoChip, FormGroup)
- [ ] 폰트/핵심 아이콘 에셋 복사 + `pubspec` 등록, 에셋 마이그레이션 스크립트
- [ ] `app/main_tab.dart`: 미션/디자인 2탭 골격(빈 화면) + `main.dart` ProviderScope
- **산출물/검증**: 2탭 빈 앱 `flutter run -d chrome` 표시, analyze 통과

### Phase 1 — 데이터/네트워크
- [ ] 모델 fromJson/toJson (Mission, MissionItem, ItemType, ShowType, ItemQuiz, MissionReply, RankingEntry) — 서버 CodingKeys + LimitTime/Status/Virtual/날짜 다중포맷 파싱 이식
- [ ] `rest_api_client.dart` (dio + Authorization Bearer + 401/403 1회 재로그인 인터셉터)
- [ ] `auth_session.dart`(secure storage) + `auth_bootstrap.dart`(게스트 부트스트랩, inflight 공유)
- [ ] `mission_data_source.dart`(추상) + `rest_remote_data_source.dart` — **우선 read 9개 + auth 2개 + create/update/delete 3개**
- **산출물/검증**: 앱 시작 시 게스트 발급 로그 + `fetchMissionList()` 결과 콘솔 출력 (실서버 1건 이상)

### Phase 2 — 미션 탭
- [ ] `mission_list_page.dart`: 4세그(Popular/New/Near Me/All) + 헤더(폭스/스트릭) + 미션 카드 리스트(페이지네이션). NearMe는 geolocator 좌표로 `fetchPublishedMissions`
- [ ] `mission_card.dart`: 제목/장소/디자이너/플레이수/평점
- [ ] `mission_detail_page.dart`: 히어로 카드 + 정보행 + 랭킹 Top3(`fetchRanking`) + 리뷰(`fetchReplies`) + 리뷰 작성(`submitReview`). 플레이 진입 버튼은 placeholder(후속 AR 연결)
- **산출물/검증**: 실서버 미션이 목록·상세로 보임, 리뷰 작성 반영

### Phase 3 — 디자인 탭
- [ ] `design_list_page.dart`: 내 디자인(`fetchMyDesigned`) → 비공개/공개 그룹, 행 탭 → 액션(수정/Test placeholder/공개·해제/삭제)
- [ ] `mission_setup_page.dart`: 새 미션(제목/설명/장소/제한시간/virtual) → `createMission`
- [ ] `builder_map.dart`: flutter_map(OSM) — longTap 으로 아이템 배치, 드래그 이동, 핀(ItemType 아이콘) + rangeAR 원(CircleLayer). Run Start↔End 자동 페어 로직 이식
- [ ] `item_editor_page.dart` + `item_picker.dart` + `quiz_variants.dart`: 아이템 타입/ShowType/필수/반경/info/퀴즈 편집
- [ ] `design_providers.dart`: MissionBuilderViewModel 대응(상태/dirty/save/publish/delete), `updateMission`/`deleteMission`
- **산출물/검증**: 새 미션 생성→아이템 배치→공개→미션 탭에서 노출, 수정/삭제 동작 (iOS 앱과 데이터 공유 확인)

### Phase 4 — 통합/검증
- [ ] 탭 네비/딥링크, 공통 로딩·에러·빈상태 위젯, 토큰 만료 재로그인 E2E
- [ ] 3플랫폼 빌드(web/android/ios) + 실기기 스모크 (Android `flutter run`, iOS 서명 후, Web 릴리스+터널)
- [ ] `test_flutter.md` 에 미션/디자인 테스트 절차 추가
- **산출물**: 미션·디자인 탭 실사용 가능 버전

### 후속(범위 밖, 순서 메모)
Play/AR 연결(파일럿 자산) → My Info/Badge → Settings → IAP → 미니게임/HUD.

## 8. 모델·엔드포인트 참조

### 핵심 모델 필드 (서버 CodingKeys)
- **Mission**: `MissionID,Title,Description,Place,Designer,StartTime,LimitTime("HH:MM:SS"),Quiz,Answer,Status(0/2),Virtual(bool/int),WriteDate,seq,lang,PlayCnt,FailCnt,RecommendCnt,RecommendAvg,ShortUser1~3,ShortRecord1~3,BadgeImageName,items[]`
- **MissionItem**: `MissionID,ItemID,Mandatory(0/1),ItemType,Latitude,Longitude,BlackCnt,BlackTime,RangeAR,ShowType,EffectiveRange,EffectiveTime,ItemGame,Info,RelationItemID,quizSeq,rnpSeq,quizzes[]`

### 엔드포인트 (이번 범위에서 쓰는 것)
| 메서드 | HTTP | 경로 |
|---|---|---|
| fetchMissionList | GET | `/api/v1/missions?page={n}` |
| fetchPublishedMissions(nearby) | GET | `/api/v1/missions/nearby?page&latitude&longitude` |
| fetchMissionDetail | GET | `/api/v1/missions/{id}` |
| fetchReplies / submitReview | GET/POST | `/api/v1/missions/{id}/replies` |
| fetchRanking | GET | `/api/v1/missions/{id}/ranking` |
| fetchMyDesigned | GET | `/api/v1/users/{id}/missions/designed` |
| login / register | POST | `/api/v1/auth/login` · `/register` |
| createMission | POST | `/api/v1/missions` |
| updateMission | PATCH | `/api/v1/missions/{id}` |
| deleteMission | DELETE | `/api/v1/missions/{id}` |

(전체 26개 메서드 목록은 `PlaySpot/Network/MissionDataSource.swift` 참조 — read 9 / write/play 등 후속 단계에서 추가)

## 9. 리스크 / 함정

| 리스크 | 완화 |
|---|---|
| `createMission` 페이로드 스펙 불일치 | iOS `BuilderMissionReq` JSON 과 필드/형식 1:1 대조, 서버 스모크(`scripts/smoke_new_api.sh` 참고)로 검증 |
| 날짜/LimitTime 커스텀 파싱 엣지케이스 | Swift 디코더 로직 그대로 이식 + 단위 테스트 |
| MapKit→flutter_map 좌표/오버레이 차이 | 빌더 배치/드래그/원(rangeAR)을 실좌표로 수동 검증 |
| 폰트/이미지 에셋 누락 | 마이그레이션 스크립트 + 필요한 것만 우선, 누락 시 fallback 위젯 |
| iOS 서명(Personal Team) | 개발 설치만, Bundle ID 고유화 (파일럿에서 확인된 절차) |
| Web 카메라/지도 한계 | 미션·디자인은 카메라 불필요, 지도는 flutter_map web 지원 OK |

## 10. 검증 전략 / 일정 개략

- 각 Phase: `flutter analyze`(무경고) + `flutter build web` + 실기기 1회 스모크.
- 데이터 정합성: 동일 미션이 iOS 앱과 Flutter 앱에 같이 보이는지 교차 확인.
- 개략 일정(1인): Phase0 1~2일 · Phase1 2~3일 · Phase2 2~3일 · Phase3 4~5일 · Phase4 1~2일 = **약 2~3주**.

## 11. 참조

- AR 파일럿 검증: [plan_flutter.md](plan_flutter.md), [flutter_ar_spike/README.md](flutter_ar_spike/README.md)
- 테스트 런북: [test_flutter.md](test_flutter.md)
- 기존 구조/규칙: [CLAUDE.md](CLAUDE.md)
- REST API SoT: [api_plan_new.md](api_plan_new.md) (Swagger `http://43.201.188.35:8080/swagger-ui/index.html`)
- 원본 코드: `PlaySpot/Network/*`, `PlaySpot/Models/*`, `PlaySpot/Views/MissionList/*`, `PlaySpot/Views/MissionBuilder/*`, `PlaySpot/Game/MissionBuilderViewModel.swift`, `PlaySpot/Views/DesignSystem/DuoTokens.swift`

---

**진행 현황** (2026-05-29):
- ✅ Phase 0 기반 정비 (deps/폴더/DuoTokens/폰트/2탭 골격)
- ✅ Phase 1 데이터/네트워크 (모델 + RestApiClient + Auth + DataSource, 백엔드 실호출 확인)
- ✅ Phase 2 미션 탭 (4세그 목록 + 카드 + 상세/랭킹/리뷰)
- ✅ Phase 3 디자인 탭 (목록 + 생성 + 빌더맵 + 아이템 편집 + 공개/삭제)
- ✅ Phase 4 통합/검증 (3플랫폼 web/android/ios 빌드 통과, test_flutter.md 갱신)
- 후속(범위 밖): Play/AR 연결, 아이콘 일괄 마이그레이션, My Info/Badge/Settings, IAP.
