# plan_designer.md — 미션 디자이너 (Builder) 신규 API 연동 리팩토링 계획

> PlaySpot 의 미션 디자이너 화면을 레거시 ObjC ([`Classes/MissionBuilder*.m`](Classes/), 4572 라인) 의 모든 기능을 보존하면서 SwiftUI + 신규 `/api/v1/**` REST API 로 전환하기 위한 작업 계획.
>
> **참조**:
> - 레거시 화면: [`old_img/design_img/`](old_img/design_img/) 19장 (지도/팝업/세부설정 흐름)
> - 레거시 소스: [`Classes/MissionBuilder.m`](Classes/MissionBuilder.m) 1196 / [`MissionBuilderInfo.m`](Classes/MissionBuilderInfo.m) 1019 / [`MissionBuilderDetail.m`](Classes/MissionBuilderDetail.m) 1394 / [`MissionBuilderList.m`](Classes/MissionBuilderList.m) 494
> - 게임플레이 분석: [`research.md`](research.md) / [`research2.md`](research2.md)
> - 서버 사양: [`api_client.md`](api_client.md) / [`api_plan_new.md`](api_plan_new.md)
> - 현재 신규 빌더 (stub): [`PlaySpot/Views/MissionBuilder/`](PlaySpot/Views/MissionBuilder/) 4 파일 251 라인

---

## 0. 결론 요약

| 영역 | 현황 | 작업 규모 |
|---|---|---|
| **클라이언트 UI** | 기초 stub 4 파일 (251 라인). 지도 배치/itemType 별 분기/Quiz 변형/Badge/RunLimit/짝맞춤 모두 미구현 | **대규모 — 11개 itemType subform + Map view + QuizVariants** |
| **클라이언트 데이터/DTO** | RestRemoteDataSource.uploadMission 은 **placeholder** (`return false`). DTO 미정의 | 중간 — 신규 DTO + ViewModel |
| **서버 신규 API** | **POST/PATCH/DELETE `/api/v1/missions` 모두 미존재** (OpenAPI 미등록). 뱃지 업로드(`POST /api/v1/badges`)만 사용 가능 | **블로커 — 서버 측 신규 엔드포인트 4개 필요** |
| **레거시 폴백** | `POST /playspot/J_MyList.php?tr=700` (`}}`-구분자 페이로드) 동작 검증 완료. LegacyRemoteDataSource 에 구현됨 | 회귀 안전망으로 유지 |

> 신규 API 가 추가되기 전까지 **Settings 의 backend 토글 `.legacy` 로 TR=700 업로드** 사용 가능. UI 리팩토링은 backend 와 독립적으로 선행 가능.

### 0.1 Swagger 재확인 (2026-05-20)

> 참조: Swagger UI <http://43.201.188.35:8080/swagger-ui/index.html> · OpenAPI JSON `/api-docs` · [`new_api.md`](new_api.md) (클라이언트 측 레거시 17 TR 정리 — 신규 서버 사양 아님)

#### v1 — Mission 태그 (서버 자체 설명)

> `"미션 상세/목록 (TR=200/500/501/502/503)"` — **읽기 전용 명시**. 빌더 업로드(TR=700) 는 아직 미노출.

OpenAPI `/api-docs` 의 `/api/v1/missions/**` 전체 메서드 (probe 결과):

| Path | GET | POST | PATCH | DELETE | 비고 |
|---|---|---|---|---|---|
| `/api/v1/missions` | ✅ listAll | ❌ | — | — | **POST(create) 미존재** |
| `/api/v1/missions/nearby` | ✅ | — | — | — | |
| `/api/v1/missions/playing` | ✅ | — | — | — | |
| `/api/v1/missions/tutorial` | ✅ | — | — | — | |
| `/api/v1/missions/{missionId}` | ✅ detail | — | ❌ | ❌ | **PATCH(edit)/DELETE(remove) 미존재** |
| `/api/v1/missions/{missionId}/replies` | ✅ | ✅ | — | — | |
| `/api/v1/missions/{missionId}/ranking` | ✅ | — | — | — | |
| `/api/v1/missions/{missionId}/plays/{start\|finish\|fail}` | — | ✅ | — | — | |

**결론**: 이전 분석과 동일. 빌더 업로드/편집/삭제 3개 엔드포인트 (POST/PATCH/DELETE `/api/v1/missions[/{id}]`) 가 **서버 측에 여전히 미구현**. R1 블로커 유효.

#### Swagger 태그 전체 (24 paths, 10 tags)

| Tag | 설명 | 빌더 관련 여부 |
|---|---|---|
| **v1 — Mission** | 미션 상세/목록 (TR=200/500/501/502/503) | 읽기만 |
| **v1 — MissionPlay** | 미션 플레이 (start/finish/fail/ranking) | — |
| **v1 — MissionReply** | 미션 댓글/평점 (TR=300/400) | — |
| **v1 — Auth** | 신버전 로그인/회원가입 (TR=800/tr_user_reg) | — |
| **v1 — User** | 유저 조회/수정 + 유저별 미션 목록 (600/601/602) | designed/played/playing 목록만 |
| **v1 — Badge** | 뱃지 이미지 업로드 (image_save.php) | ✅ `POST /api/v1/badges` 사용 |
| **v1 — Ping** | 헬스체크 | — |
| **Auth (legacy)** | 구버전 /auth/login | — |
| **Image** | 뱃지 이미지 업로드 (legacy) | — |
| **Legacy API** | PHP 레거시 URL 호환 (19개 TR 코드, **TR=700 포함**) | ✅ 폴백 가능 |

→ 빌더 업로드는 **Legacy API 태그의 `POST /playspot/J_MyList.php?tr=700`** 으로만 가능. 신규 v1 — Mission 태그에 mutating 메서드 추가가 R1 의 핵심.

---

## 1. 레거시 빌더 구조 분석

### 1.1 4 컨트롤러 + 흐름

```
MissionBuilderList   ─tap row→   MissionBuilder ─longTap map→  MissionBuilderInfo (메타)
(내가 만든 미션 목록)             (지도 + 아이템 배치)        ↓ tap "i" button
                                  ↑ tap pin              MissionBuilderDetail (per-item)
                                                          ↓ 퀴즈 아이템 시
                                                          itemQuizzes inline 추가
```

| 컨트롤러 | 라인 | 역할 | 신규 매핑 |
|---|---|---|---|
| [`MissionBuilderList.m`](Classes/MissionBuilderList.m) | 494 | 내 디자인 목록, "+" 신규, swipe delete, "Upload" 액션 (`uploadServer:`) | `MissionBuilderListView` 확장 |
| [`MissionBuilder.m`](Classes/MissionBuilder.m) | 1196 | MapKit 지도, longTap → 아이템 picker, pin drag/tap, dataCheck, save | **`MissionBuilderMapView` 신규** |
| [`MissionBuilderInfo.m`](Classes/MissionBuilderInfo.m) | 1019 | 미션 메타 폼 (Title/Desc/Place/RunLimit/Virtual/Lang/Badge), 좌표→장소명 자동 (`getGooglePlaceMark:`) | `MissionSetupView` 대폭 확장 |
| [`MissionBuilderDetail.m`](Classes/MissionBuilderDetail.m) | 1394 | itemType **별로 다른 폼** 동적 구성 (`makeTableSectionInfo`), itemQuizzes 인라인 편집 | `ItemDetailView` **대대적 리팩토링 + 11개 subform** |

### 1.2 스크린샷 매핑 (`old_img/design_img/`)

| 스크린샷 | 화면/단계 | 레거시 컨트롤러 |
|---|---|---|
| `미션디자인목록화면.png` | 디자인 목록 | MissionBuilderList |
| `미션디자인목록클릭시 나오는 팝업화면.png` | 미션 항목 선택 팝업 (수정/삭제/업로드) | MissionBuilderList |
| `미션디자인목록에서플러스버튼클릭후화면.png` | 신규 디자인 진입 | MissionBuilder + MissionBuilderInfo |
| `미션디자인 상단 연필모양 아이콘(수정) 클릭시 미션 설명 설정화면1.png` | 메타 편집 진입 | MissionBuilderInfo |
| `미션 설명 설정화면2.png` | 메타 입력 (Title/Place/Desc/RunLimit) | MissionBuilderInfo |
| `미션디자인 설정 주요 흐름 설명 화면화면.png` | 지도 배치 흐름 안내 | MissionBuilder |
| `미션디자인지도화면 아이템  배치 및 설정 화면 - 아이템 터치(세부설정) 아이템드래그(무브).png` | pin tap/drag | MissionBuilder |
| `미션디자인지도화면에서아이템설정화면-아이템명 showType 유효반경.png` | itemPicker (itemType/showType/rangeAR 3-pole) | MissionBuilder.itemPicker |
| `미션디자인지도화면 에서 아이템 수정을 위한 세부설정 진입화면.png` | pin 탭 → detail 진입 | MissionBuilderDetail |
| `아이템세부설정화면-아이템마다 틀림.png` | **itemType 별 다른 폼** 핵심 화면 | MissionBuilderDetail.makeTableSectionInfo |
| `미션 End 아이템 설정배치화면1.png` | End 아이템 폼 (info textbox) | MissionBuilderDetail (case I_END) |
| `런아이템 설정시 Run Start, Run End 두개 표시 및 설정 되는 화면.png` | Run Start 배치 → 자동 Run End 페어링 | MissionBuilder.openItemPicker (line 625-665) |
| `런아이템 세부설정 진입화면.png` | Run Start/End detail 진입 | MissionBuilderDetail (case I_TIMEOUT_S/E) |
| `런 end 아이템 세부설정 화면1.png` | Run End — effectiveTime 입력 | MissionBuilderDetail (case I_TIMEOUT_E) |
| `런 end 아이템 세부 설정화면2.png` | Run End — 짝맞춤 relationItemID | MissionBuilderDetail.relatedItems |
| `런 end 아이템 세부 설정화면3.png` | Run End — effectiveRange 자동 거리 | MissionBuilderDetail (line 549-555) |
| `지뢰 아이템 설정배치화면.png` | Mine — itemType + rangeAR 만 | MissionBuilderDetail (case I_MINE, 단순 2-필드) |
| `지뢰 아이템 설정배치화면2.png` | Mine 배치 + 폭발 반경 표시 | MissionBuilder.overlayRefresh |
| `미션디자인테스트플레이.png` | 빌더 → 테스트 플레이 진입 | MissionBuilder.btnTestPlay |
| `미션디자인테스트화면1.png`, `2.png` | 테스트 플레이 (DESIGNING 상태 미션) | MissionPlay (재사용) |

### 1.3 레거시 업로드 페이로드 형식 ([`MissionBuilderList.m:124-220`](Classes/MissionBuilderList.m#L124-L220))

```text
POST /playspot/J_MyList.php
Content-Type: application/x-www-form-urlencoded
tr=700
&mission=<MissionID>}}<Title>}}<Description>}}<Place>}}<Designer>}}<RunLimitTime>}}<Status>}}<Quiz>}}<Answer>}}<Virtual>}}<Lang>}}<WriteDate>
&missionItem=<row1>**<row2>**...
  where row = <MissionID>}}<ItemID>}}<Mandatory>}}<ItemType>}}<Latitude>}}<Longitude>
              }}<BlackCnt>}}<BlackTime>}}<RangeAR>}}<ShowType>}}<EffectiveRange>
              }}<EffectiveTime>}}<ItemGame>}}<Info>}}<RelationItemID>}}<WriteDate>
&itemQuiz=<row1>**<row2>**...
  where row = <MissionID>}}<ItemID>}}<Seq>}}<Quiz>}}<Answer>}}<Probability>
```

- `}}` = 컬럼 구분, `**` = 행 구분
- Mission 행 12 필드, MissionItem 행 16 필드, ItemQuiz 행 6 필드
- 응답: 평문 `"SUCCESS"`
- 별도로 뱃지 이미지 → `POST /playspot/image_save.php` multipart `userfile`

---

## 2. 미션 데이터 정의 (Mission 레벨)

레거시 [`Mission.h`](Classes/Mission.h) + [`MissionBuilderInfo.m`](Classes/MissionBuilderInfo.m) 와 신규 [`Models/Mission.swift`](PlaySpot/Models/Mission.swift) 동기화.

| 필드 | 타입 | 입력 방식 | 검증 | 비고 |
|---|---|---|---|---|
| `MissionID` | String | **서버 발급 권장** (또는 `<userID>_<yyyyMMddHHmmss>`) | unique | 신규 API: POST 응답에서 받음 / 레거시: 클라 생성 |
| `Title` | String | TextField (max ~50자) | non-empty (`data_check_message_0`) | 필수 |
| `Description` | String | TextEditor multiline | non-empty (`data_check_message_1`) | 필수 |
| `Place` | String | TextField (자동 채움 가능) | non-empty (`data_check_message_2`) | 필수. 좌표 → CLGeocoder.reverseGeocode 자동 |
| `Designer` | String | **JWT 자동** (서버 측에서 채움 권장) | — | 클라이언트 body 에 명시하지 않음 (보안) |
| `RunLimitTime` | Int (초) | DatePicker (HH:MM:SS) | ≥ 0 | 0 = 무제한. UI 는 시:분:초 |
| `Status` | Int (0~3) | 자동 | 빌더 저장: `DESIGNING` / 테스트 통과: `TESTED` / 업로드: `SERVER_UPLOAD` | enum [`MissionStatus`](PlaySpot/Models/GameState.swift) |
| `Quiz` | String? | (현재 미션 레벨 퀴즈는 미사용) | — | TR=700 페이로드에 포함되지만 UI 입력 없음 |
| `Answer` | String? | (동일) | — | 동일 |
| `Virtual` | Int (0/1) | Toggle | — | 0=Real only, 1=Virtual 도 가능 |
| `Lang` | String | Picker (ko/en/...) | non-empty | 기본: 시스템 언어 |
| `BadgeImageName` | String? | PhotosPicker → POST `/api/v1/badges` → 응답 `fileName` 저장 | optional | 빌더에서 선택 가능. mission 페이로드에 fileName 만 |
| `WriteDate` | Date | **서버 발급** | — | 클라이언트 입력 없음 |
| `PlayCnt`/`FailCnt`/`RecommendCnt`/`RecommendSum` | Int | (집계, 서버 관리) | — | 빌더는 입력 안 함 |

**검증 규칙** (legacy `MissionBuilder.dataCheck` 재현):
1. Title, Description, Place 비어있지 않음
2. RunLimitTime 은 0 또는 양의 정수
3. items 배열 ≥ 3
4. items 안에 Start (`"49"`) **정확히 1개**, End (`"48"`) **정확히 1개**
5. Run Start (`"42"`) 개수 == Run End (`"43"`) 개수, 모두 짝맞춤 (`relationItemID` 양방향)
6. Mandatory=Y 아이템 ≥ 1
7. Quiz 아이템은 itemQuizzes ≥ 1, 각 변형의 quiz/answer 비어있지 않음
8. 동일 itemType 중복 제한 — Radar 류는 종류당 1개 (mine/black/quiz 는 다수 허용)

---

## 3. 아이템별 입력 데이터 정의 (핵심)

레거시 [`MissionBuilderDetail.m:405-696 `makeTableSectionInfo`](Classes/MissionBuilderDetail.m#L405-L696) 의 **itemType 별 분기 로직 그대로 재현**.

### 3.1 필드 매트릭스

✓=수정 가능 / ⓐ=자동결정 / —=미사용 / R=ReadOnly

| ItemType | mandatory | showType | rangeAR | info | itemGame | effTime | effRange | relationItemID | itemQuizzes | 비고 |
|---|---|---|---|---|---|---|---|---|---|---|
| **Start** `"49"` | ⓐ=Y | ✓ | ✓ (def 30) | ✓ | — | — | — | — | — | 미션당 1개 |
| **End** `"48"` | ⓐ=Y | — | ✓ | ✓ | — | — | — | — | — | 미션당 1개 |
| **Hint** `"51"` | ✓ switch | ✓ | ✓ | ✓ | ✓ (0~3) | — | — | — | — | itemGame≠0이면 미니게임 |
| **Quiz** `"40"` | ⓐ=Y | ✓ | ✓ | — | — | — | — | — | ✓ ≥1 | itemQuizzes 인라인 편집 |
| **Run Start** `"42"` | ⓐ=Y | ✓ | ✓ | ✓ | — | — | — | ⓐ (auto-pair) | — | Run End 와 동시 배치 |
| **Run End** `"43"` | ⓐ=Y | ✓ | ✓ | ✓ | — | ✓ (HH:MM:SS) | R (auto) | ⓐ (auto-pair) | — | effRange = 두 좌표 거리 |
| **Mine** `"55"` | ⓐ=N | — | ✓ | — | — | — | — | — | — | rangeAR 만 |
| **Dark** `"56"` | ⓐ=N | — | ✓ | — | — | — | — | — | — | rangeAR 만 |
| **Defense** `"61"` | ✓ switch | ✓ | ✓ | ✓ | ✓ (0~3) | — | — | — | — | mineNoBomb |
| **Gambling** `"50"` | ✓ switch | ✓ | ✓ | ✓ | ✓ (0~3) | — | — | — | — | random |
| **Solution** `"52"` | ⓐ=N | — | ✓ | — | ✓ (0~3) | — | — | — | — | itemGame 만 |
| **Stealth Radar** `"65"` | ✓ switch | ✓ | ✓ | ✓ | — | — | — | — | — | radarAR |
| **Map Radar** `"66"` | ✓ switch | ✓ | ✓ | ✓ | — | — | — | — | — | radarMap |
| **Mine Radar** `"68"` | ✓ switch | ✓ | ✓ | ✓ | — | — | — | — | — | radarMine |
| **Coupon** `"59"` | ✓ switch | ✓ | ✓ | ✓ | ✓ (0~3) | — | — | — | — | itemGame 가능 |
| **Store** `"91"` | ⓐ=N | — | ✓ | — | — | — | — | — | — | rangeAR 만 |

**Builder Picker 비노출** (서버 데이터 only): Quiz20(`41`), Penalty Remove(`54`), Radar All(`67`), Radar Black(`69`), Number 0~9 + Alphabet (`00~10`)

### 3.2 자동 결정 로직 정밀 재현

#### Mandatory 자동값 ([`MissionBuilderDetail.m:442-451`](Classes/MissionBuilderDetail.m#L442-L451))

```swift
func defaultMandatory(for type: ItemType) -> MandatoryFlag {
    if type.rawValue.first == "4" { return .mandatory }   // 40/42/43/48 (49 는 Start 도 자동 Y)
    if type == .start { return .mandatory }
    if [.store, .mine, .black, .solution].contains(type) { return .optional }
    return .optional  // 사용자 toggle 로 결정
}

func canEditMandatory(for type: ItemType) -> Bool {
    // 자동 결정되는 type 은 UI toggle disabled
    if type.rawValue.first == "4" || type == .start { return false }
    if [.store, .mine, .black, .solution].contains(type) { return false }
    return true
}
```

#### Run Start/End 자동 페어링 ([`MissionBuilder.m:625-665`](Classes/MissionBuilder.m#L625-L665))

지도에서 Run Start 선택 시:
1. `_annoItem` (Run Start) 생성, 사용자 longTap 좌표
2. `_annoItem2` (Run End) 자동 생성, 좌표 = (lat+0.0003, lon+0.0003)
3. `_annoItem.relationItemID = _annoItem2.itemID`
4. `_annoItem2.relationItemID = _annoItem.itemID`
5. `_annoItem2.mandatory = MANDATORY_Y` 강제
6. `_annoItem2.effectiveRange = 42` (초기값, 편집 시 자동 재계산)
7. **두 핀 모두 지도에 추가** (`addAnnotation`)

#### Run End 의 effectiveRange 자동 ([`MissionBuilderDetail.m:539-556`](Classes/MissionBuilderDetail.m#L539-L556))

Run End 편집 화면 진입 시:
```swift
if itemType == .timeoutEnd {
    if let pair = items.first(where: { $0.itemType == .timeoutStart && $0.itemID == relationItemID }) {
        let distance = CLLocation(lat: pair.lat, lon: pair.lon)
            .distance(from: CLLocation(lat: self.lat, lon: self.lon))
        effectiveRange = Int(distance)  // ReadOnly 표시
        pair.relationItemID = self.itemID  // 양방향 보장
    }
}
```

#### Quiz 변형 추가 ([`MissionBuilderDetail.m:682-694`](Classes/MissionBuilderDetail.m#L682-L694))

Quiz 아이템 detail 마지막에 "+ Add Quiz" 버튼:
```swift
func addQuizVariant() {
    let nextSeq = (item.quizzes.map(\.seq).max() ?? 0) + 1
    item.quizzes.append(ItemQuiz(
        missionID: mission.id, itemID: item.itemID, seq: nextSeq,
        quiz: "", answer: "", probability: 100))
}
```

### 3.3 공통 필드 / 자동 부여

모든 아이템 공통:
- `itemID`: 미션 내 1부터 자동 증가 (mission.items.count + 1)
- `missionID`: 부모 mission 의 ID
- `latitude`/`longitude`: 지도 longTap 좌표 (drag 시 갱신)
- `writeDate`: 미션 저장 시점

-> rangAR: AR화면에서 아이템 유효 반경 공통 확인

기본값:
- `rangeAR`: 30 (m). UI: Stepper 5~500 step 5 또는 미리 정의된 picker `[10, 20, 30, 40, 50, 75, 100, 150, 200, 300]` ([`AppDelegate.rangeAR`](Classes/TreasureHunterAppDelegate.m) 와 호환)
- `showType`: `.all` (`"4"`)
- `blackCnt`: 5 (Mine 용, 런타임 미사용) -> dark 이이템용 이다
- `blackTime`: 300 초 (Mine 용, 런타임 미사용) -> dark 아이템 용이디
- `effectiveTime`: 0 (Run End 만 의미. 기본 60초 권장)
- `effectiveRange`: 0 (Run End 자동 계산)
- `itemGame`: 0 (None)
- `info`: ""
- `relationItemID`: 0

---

-> 신규 플레이스팟 플레이 화면은 검증이됨.신규 플레이 로직 및 목업 데이터등을 참조로 아이템별 데이터 정의를 다시 분석해서 작성해줘 rule_check.md 참조해줘

## 4. 데이터 검증 규칙 (`dataCheck` 재현)

레거시 [`MissionBuilder.m:380-650`](Classes/MissionBuilder.m#L380-L650) + [`MissionBuilderDetail.m:dataCheck`](Classes/MissionBuilderDetail.m) 통합.

### 4.1 미션 레벨

| # | 조건 | 위반 시 메시지 (`Localizable.xcstrings`) | 차단 |
|---|---|---|---|
| 1 | `Title.isEmpty == false` | `data_check_message_0` | Save 차단 |
| 2 | `Description.isEmpty == false` | `data_check_message_1` | Save 차단 |
| 3 | `Place.isEmpty == false` | `data_check_message_2` | Save 차단 |
| 4 | `items.count >= 3` | `data_check_message_3` | Save 차단 |
| 5 | `items.filter(start).count == 1` | `data_check_message_4` | Save 차단 |
| 6 | `items.filter(end).count == 1` | `data_check_message_5` | Save 차단 |
| 7 | `items.filter(timeoutStart).count == items.filter(timeoutEnd).count` | `data_check_message_6` | Save 차단 |
| 8 | `items.filter(\.isMandatory).count >= 1` | `data_check_message_7` | Save 차단 |
| 9 | Radar 종류(65/66/67/68/69) 각 ≤ 1개 | `data_check_message_8` | Save 차단 |

### 4.2 아이템 레벨

| # | 조건 | 적용 itemType |
|---|---|---|
| 10 | Quiz 아이템의 `itemQuizzes.count >= 1` | Quiz, Quiz20 |
| 11 | 모든 ItemQuiz 의 `quiz.isEmpty == false` && `answer.isEmpty == false` | Quiz, Quiz20 |
| 12 | Hint/Defense/Gambling/Coupon 의 `info` 비어있으면 경고 (차단 X) | 해당 type |
| 13 | Run End 의 `effectiveTime > 0` | Run End |
| 14 | Run End 의 `relationItemID` 가 실제 존재하는 Run Start ID | Run End |

### 4.3 검증 UI 표시

- Save 버튼 disabled (검증 실패 시)
- 각 필드 옆 빨간 텍스트
- 첫 실패 항목으로 자동 스크롤
- Alert: 첫 실패 메시지

---

## 5. 서버 API 정의 + 존재 유무

### 5.1 OpenAPI `/api-docs` 빌더 관련 상태 (Swagger probe 2026-05-20)

> Swagger UI: <http://43.201.188.35:8080/swagger-ui/index.html> · 총 24 paths / 10 tags
> 자세한 태그 분류 및 전체 매트릭스는 §0.1 참조.

| 엔드포인트 | 메서드 | Swagger 태그 | 존재? | 비고 |
|---|---|---|---|---|
| `/api/v1/missions` | POST | (없음) | **❌ 미존재** | 빌더 신규 — **서버 추가 필요 (R1)** |
| `/api/v1/missions/{id}` | PATCH/PUT | (없음) | **❌ 미존재** | 편집 — **서버 추가 필요** |
| `/api/v1/missions/{id}` | DELETE | (없음) | **❌ 미존재** | 삭제 — **서버 추가 필요** |
| `/api/v1/missions/{id}/status` | PATCH | (없음) | **❌ 미존재** | 상태 전환 — (선택) |
| `/api/v1/missions[/...]` | GET | v1 — Mission | ✅ 존재 | listAll / detail / nearby / playing / tutorial 5개 |
| `/api/v1/missions/{id}/replies` | GET/POST | v1 — MissionReply | ✅ 존재 | — |
| `/api/v1/missions/{id}/ranking` | GET | v1 — MissionPlay | ✅ 존재 | — |
| `/api/v1/missions/{id}/plays/start\|finish\|fail` | POST | v1 — MissionPlay | ✅ 존재 | — |
| `/api/v1/badges` | POST | **v1 — Badge** | ✅ **존재** | **빌더 뱃지 업로드 사용**. multipart `file` 필드 |
| `/api/v1/users/{id}/missions/designed` | GET | v1 — User | ✅ 존재 | MyDesigns 화면 — designed/played/playing 3종 |
| `/playspot/J_MyList.php?tr=700` | POST | **Legacy API** | ✅ 동작 | **회귀 안전망 — TR=700 `}}` 페이로드** |
| `/playspot/image_save.php` | POST | Image (legacy) | ✅ 동작 | legacy 뱃지 (multipart `userfile`) |

→ Swagger `v1 — Mission` 태그 설명 자체가 `"미션 상세/목록 (TR=200/500/501/502/503)"` — **읽기 전용 명시**. 빌더용 mutating 엔드포인트 3개 (POST/PATCH/DELETE `/missions[/{id}]`) 는 **추가가 필요한 신규 영역**. R1 블로커 유효.

> 참고: [`new_api.md`](new_api.md) 는 **클라이언트 측 레거시 17 TR 분석 문서**(작성일 2026-05-15)이며 신규 서버 사양과는 별개. 빌더 API 정의는 본 문서 §5.2 / §6 가 정답 출처.

### 5.2 신규 API 계약 제안 (서버 담당 합의 필요)

#### POST /api/v1/missions — 미션 생성

```http
POST /api/v1/missions
Authorization: Bearer <JWT>
Content-Type: application/json
{
  "mission": {
    "Title": "튜토리얼 미션",
    "Description": "Start → 게임 → 퀴즈 → End",
    "Place": "튜토리얼 광장",
    "RunLimitTime": 600,
    "Status": 0,
    "Virtual": 1,
    "Lang": "ko",
    "BadgeImageName": "badge-abc.png"
  },
  "items": [
    {
      "ItemID": 1, "Mandatory": 1, "ItemType": "49",
      "Latitude": 37.485, "Longitude": 126.808,
      "BlackCnt": 0, "BlackTime": 0, "RangeAR": 50,
      "ShowType": "4", "EffectiveRange": 0, "EffectiveTime": 0,
      "ItemGame": 0, "Info": "Start: ...", "RelationItemID": 0
    }
  ],
  "quizzes": [
    { "ItemID": 3, "Seq": 1, "Quiz": "대한민국의 수도?", "Answer": "서울", "Probability": 100 }
  ]
}
```

응답:
```http
HTTP/1.1 201 Created
Location: /api/v1/missions/playspot_20260520_1845_a3c2
{ "missionId": "playspot_20260520_1845_a3c2" }
```

**합의 사항**:
- `MissionID` 서버 발급 (충돌 방지). 요청 body 에 명시하지 않음.
- `Designer` JWT 의 userId 로 서버 자동 채움 (보안).
- `WriteDate` 서버 시각.
- `Status` 클라이언트 명시 (DESIGNING=0 으로 저장하다가 별도 호출로 전환).

#### PATCH /api/v1/missions/{missionId} — 편집 (전체 교체)

```http
PATCH /api/v1/missions/playspot_20260520_1845_a3c2
{ "mission": { ... }, "items": [...], "quizzes": [...] }
```
- 동일 body. items/quizzes 전체 교체.
- 403: Designer ≠ JWT userId
- 404: 없는 미션
- 응답 204

#### DELETE /api/v1/missions/{missionId}

```http
DELETE /api/v1/missions/playspot_20260520_1845_a3c2
```
- 204 No Content
- 403: 권한 없음
- ON DELETE CASCADE 로 MissionItem/ItemQuiz/MissionPlayRecord 도 같이 삭제

#### PATCH /api/v1/missions/{missionId}/status — 상태 전환 (선택)

```http
PATCH .../status
{ "status": 2 }
```
- 전이 규칙: DESIGNING(0) → TESTED(1) → SERVER_UPLOAD(2)
- 역방향 차단 (400)

### 5.3 뱃지 업로드 흐름 (기존 활용)

```text
1) 사용자 PhotosPicker 선택
2) PNG 변환 (UIImage.pngData)
3) POST /api/v1/badges multipart/form-data
   - 폼 필드명: file (레거시 userfile 아님)
4) 응답 201 { "fileName": "badge-xxx.png", "url": "/badge/badge-xxx.png" }
5) mission.BadgeImageName = fileName
6) POST /api/v1/missions 호출 시 body 에 포함
```

---

## 6. 입력 API 정의 (클라이언트 페이로드)

신규 DTO 정의 ([PlaySpot/Network/RestAPIDTO.swift](PlaySpot/Network/RestAPIDTO.swift) 추가):

```swift
// MARK: - Builder upload

struct BuilderMissionReq: Encodable {
    let mission: BuilderMissionFields
    let items: [BuilderItemFields]
    let quizzes: [BuilderQuizFields]
}

struct BuilderMissionFields: Encodable {
    let Title: String
    let Description: String
    let Place: String
    let RunLimitTime: Int
    let Status: Int
    let Virtual: Int          // 0 / 1
    let Lang: String
    let BadgeImageName: String?
}

struct BuilderItemFields: Encodable {
    let ItemID: Int
    let Mandatory: Int        // 0 / 1
    let ItemType: String      // "49" 등
    let Latitude: Double
    let Longitude: Double
    let BlackCnt: Int
    let BlackTime: Int
    let RangeAR: Int
    let ShowType: String      // "1"~"4"
    let EffectiveRange: Int
    let EffectiveTime: Int
    let ItemGame: Int         // 0~3
    let Info: String
    let RelationItemID: Int
}

struct BuilderQuizFields: Encodable {
    let ItemID: Int
    let Seq: Int
    let Quiz: String
    let Answer: String
    let Probability: Int
}

struct BuilderMissionCreatedRes: Decodable {
    let missionId: String
}
```

`MissionDataSource` 프로토콜 확장:

```swift
// 기존 uploadMission(missionJSON:itemsJSON:quizzesJSON:) 제거 (콤마/구분자 페이로드는 legacy 한정).
// 대체 — 구조화 인자 메서드:
func createMission(_ req: BuilderMissionReq) async throws -> String   // missionId 반환
func updateMission(_ missionID: String, _ req: BuilderMissionReq) async throws -> Bool
func deleteMission(_ missionID: String) async throws -> Bool
func uploadBadgeImage(pngData: Data) async throws -> String?          // fileName 반환
```

구현:
- `RestRemoteDataSource`: POST/PATCH/DELETE 위 엔드포인트 호출. uploadBadgeImage 는 `/api/v1/badges` multipart.
- `LegacyRemoteDataSource`: createMission 은 내부에서 `BuilderMissionReq` → `}}` 구분자 페이로드로 변환 후 TR=700 호출. update/delete 는 legacy 미지원 → throws.
- `LocalDataSource`: 모두 noop (mock 성공).

---

## 7. SwiftUI 화면 리팩토링 계획

### 7.1 화면별 작업 분해

| View | 현재 상태 | 작업 내용 | 추가 신규 파일 |
|---|---|---|---|
| `MissionBuilderListView` ([기존 58 라인](PlaySpot/Views/MissionBuilder/MissionBuilderView.swift)) | 기초 | status badge, swipe delete (DELETE), Upload 버튼 (TESTED→SERVER_UPLOAD), 행 탭 → Map 진입 | — |
| `MissionSetupView` ([기존 71 라인](PlaySpot/Views/MissionBuilder/MissionSetupView.swift)) | 기초 | RunLimitTime (DatePicker .hourMinuteAndSecond), Lang Picker, Badge image (PhotosPicker), CLGeocoder 자동 Place | — |
| **`MissionBuilderMapView`** | **신규** | MapKit Map + Annotation, longTap → ItemPickerView sheet, pin tap → ItemDetailView sheet, pin drag → 좌표 갱신, Save/Cancel toolbar, dataCheck 통과 시 Save 활성화 | `MissionBuilderMapView.swift` |
| `ItemPickerView` ([기존 61 라인](PlaySpot/Views/MissionBuilder/ItemPickerView.swift)) | 기초 | 카테고리별 itemType 선택 → 다음 단계 (showType / rangeAR 초기값) 또는 ItemDetailView 직진 | — |
| `ItemDetailView` ([기존 58 라인](PlaySpot/Views/MissionBuilder/ItemDetailView.swift)) | **공통 폼만** | **itemType 별 11개 SubView 분리** + 공통 BasicSection | 아래 11개 |
| `QuizVariantsView` | **신규** | Quiz/Quiz20 전용. ItemQuiz 리스트 + Add Variant + 행 삭제 | `QuizVariantsView.swift` |

#### itemType 별 SubForm (11개, `ItemForms.swift` 한 파일에 묶기 권장)

| SubForm | 노출 필드 |
|---|---|
| `StartItemForm` | (mandatory readonly Y) + showType + rangeAR + info |
| `EndItemForm` | (mandatory readonly Y) + rangeAR + info |
| `HintItemForm` | mandatory(switch) + showType + rangeAR + itemGame + info |
| `QuizItemForm` | (mandatory readonly Y) + showType + rangeAR + → QuizVariantsView |
| `RunStartItemForm` | (mandatory readonly Y) + showType + rangeAR + info |
| `RunEndItemForm` | (mandatory readonly Y) + showType + rangeAR + effectiveTime + effectiveRange(readonly) + info |
| `MineItemForm` | (mandatory readonly N) + rangeAR |
| `BlackItemForm` | (mandatory readonly N) + rangeAR |
| `DefenseItemForm` | mandatory(switch) + showType + rangeAR + itemGame + info |
| `GambleItemForm` | mandatory(switch) + showType + rangeAR + itemGame + info |
| `SolutionItemForm` | (mandatory readonly N) + rangeAR + itemGame |
| `RadarARForm` / `RadarMapForm` / `RadarMineForm` | mandatory(switch) + showType + rangeAR + info |
| `CouponItemForm` | mandatory(switch) + showType + rangeAR + itemGame + info |
| `StoreItemForm` | (mandatory readonly N) + rangeAR |

ItemDetailView 분기:
```swift
struct ItemDetailView: View {
    @Binding var item: MissionItem
    @Binding var allItems: [MissionItem]   // Run pair lookup 용

    var body: some View {
        Form {
            CommonHeader(item: item)
            switch item.itemType {
            case .start: StartItemForm(item: $item)
            case .end: EndItemForm(item: $item)
            case .simple: HintItemForm(item: $item)
            case .quiz, .quiz20: QuizItemForm(item: $item)
            case .timeoutStart: RunStartItemForm(item: $item)
            case .timeoutEnd: RunEndItemForm(item: $item, allItems: $allItems)
            case .mine: MineItemForm(item: $item)
            case .black: BlackItemForm(item: $item)
            case .mineNoBomb: DefenseItemForm(item: $item)
            case .random: GambleItemForm(item: $item)
            case .solution: SolutionItemForm(item: $item)
            case .radarAR: RadarARForm(item: $item)
            case .radarMap: RadarMapForm(item: $item)
            case .radarMine: RadarMineForm(item: $item)
            case .coupon: CouponItemForm(item: $item)
            case .store: StoreItemForm(item: $item)
            default: EmptyView()
            }
            DeleteButton(item: item)
        }
    }
}
```

### 7.2 데이터 흐름

```
MissionBuilderListView
    ↓ tap "+" / row
MissionBuilderViewModel (@Observable)  ← 모든 화면이 공유
    │
    ├── mission: BuilderMissionFields
    ├── items: [MissionItem]
    ├── quizzes: [ItemQuiz] (flat list, ItemID 로 group)
    ├── badgeImage: UIImage?  (업로드 전 메모리)
    ├── isDirty: Bool
    │
    ↓ Save
    1. validate (dataCheck)
    2. uploadBadgeImage → fileName 채움
    3. dataSource.createMission(req) or updateMission(id, req)
    4. localDB MissionRepository 동기화
```

자동 저장 (auto-save):
- `isDirty` 가 true 인 상태로 화면 dismiss 또는 백그라운드 진입 시
- LocalDataSource (MissionRepository) 에 `Status: .designing` 으로 저장
- 다음 진입 시 목록에서 노출 (Draft 배지)

---

## 8. Phase 분해

| Phase | 범위 | 서버 의존 | 추정 |
|---|---|---|---|
| **P0** | 서버 측 신규 API (POST/PATCH/DELETE `/api/v1/missions`) 스펙 합의 + 구현 | **서버 작업 필수** | (서버 일정 의존) |
| **P1** | 클라이언트 DTO + ViewModel + 프로토콜 확장 (서버 무관) | — | 3h |
| **P2** | SwiftUI View 리팩토링 — MissionSetupView 확장 + MissionBuilderMapView 신규 + ItemDetailView 11 분기 + QuizVariantsView 신규 | — | 8h |
| **P3** | 신규 API 실제 호출 (RestRemoteDataSource.create/update/delete) + 뱃지 업로드 | P0 완료 | 2h |
| **P4** | Legacy 폴백 검증 — backend=.legacy 토글로 TR=700 동작 확인 (회귀 안전망) | — | 1h |
| **P5** | E2E 검증 — 6 시드 미션 빌더로 재생성 → 업로드 → /missions 목록 노출 | P3 완료 | 2h |
| **P6** | dataCheck UI (검증 실패 메시지/스크롤) + 자동저장 + 뒤로가기 confirm | — | 2h |

**총 추정**: 클라이언트 단독 ~16h, 서버 의존 P0/P3/P5 별도.

병렬 진행 권장:
- P1 + P2 + P4 + P6 → 클라이언트 단독 (서버 작업과 무관하게 진행)
- P0 → 서버 담당
- P3 + P5 → P0 완료 후 합류

---

## 9. 위험 및 미합의 사항

| ID | 항목 | 상태 | 대응 |
|---|---|---|---|
| R1 | **POST/PATCH/DELETE `/api/v1/missions` 미존재** | **블로커 (서버 측)** | P0 합의 + 구현 선행. 그동안 P4 (legacy 폴백) 로 운영 |
| R2 | MissionID 발급 정책 (서버 vs 클라이언트) | 미합의 | 서버 발급 권장 (충돌 방지). POST 응답에서 받음 |
| R3 | Designer 필드 — body 명시 vs JWT 자동 | 미합의 | **JWT 자동** 권장 (보안: 사용자가 임의로 Designer 변조 불가) |
| R4 | Status 전환 정책 | 미합의 | 클라이언트 자유 vs 별도 PATCH `/status` 엔드포인트 게이트 |
| R5 | 동시 편집 충돌 (낙관적 잠금/etag) | 미고려 | 1차에는 last-write-wins. 필요 시 ETag 추후 |
| R6 | Legacy TR=700 응답에 MissionID 미반환 | 알려진 한계 | LegacyRemoteDataSource 는 클라이언트 임시 ID (userID+timestamp) 그대로 사용 |
| R7 | Badge 이미지 — `BadgeImageName` 만 저장 vs 전체 URL | 미합의 | fileName 만 저장. URL 은 `/badge/{fileName}` 컨벤션 |
| R8 | RunLimitTime — 레거시는 DATETIME(시:분:초), 신규는 Int(초) | 확정 | 신규 Int 초 사용. UI 는 DatePicker .hourMinuteAndSecond 로 입력받아 변환 |
| R9 | Quiz20 (`41`) 빌더 노출 여부 | 레거시 비노출 | 빌더 picker 에서 제외. 데이터 변환 시만 처리 |
| R10 | 미션 레벨 Quiz/Answer 필드 — TR=700 페이로드 포함이지만 UI 입력 없음 | 빈 문자열로 전송 | 신규 API 에서도 동일 처리 (또는 필드 제거 협의) |

---

## 10. 작업 체크리스트

### P0 — 서버 측 (블로커)
- [ ] POST `/api/v1/missions` 엔드포인트 추가 + 401/403/400 응답 정의
- [ ] PATCH `/api/v1/missions/{id}` 추가 (Designer == JWT userId 검증)
- [ ] DELETE `/api/v1/missions/{id}` 추가 (CASCADE 검증)
- [ ] PATCH `/api/v1/missions/{id}/status` 선택 추가
- [ ] OpenAPI `/api-docs` 에 반영
- [ ] R2 (MissionID 발급) / R3 (Designer 자동) 합의

### P1 — 클라이언트 DTO + ViewModel
- [ ] `BuilderMissionReq` / `BuilderMissionFields` / `BuilderItemFields` / `BuilderQuizFields` / `BuilderMissionCreatedRes` 추가 ([RestAPIDTO.swift](PlaySpot/Network/RestAPIDTO.swift))
- [ ] `MissionDataSource` 확장 — `createMission/updateMission/deleteMission/uploadBadgeImage`
- [ ] 기존 `uploadMission(missionJSON:itemsJSON:quizzesJSON:)` 폐기
- [ ] `MissionBuilderViewModel` 신규 ([Game/MissionBuilderViewModel.swift](PlaySpot/Game/))
- [ ] `LocalDataSource` mock 구현
- [ ] `LegacyRemoteDataSource` 의 createMission 내부에서 `}}` 페이로드 변환 후 TR=700 호출

### P2 — SwiftUI 화면
- [ ] `MissionSetupView` 확장 — RunLimitTime (DatePicker) / Lang Picker / Badge PhotosPicker / CLGeocoder 자동 Place
- [ ] `MissionBuilderMapView` 신규 — MapKit + longTap + drag + Save/Cancel
- [ ] `ItemDetailView` 11개 subform 분리 (CommonHeader + StartItemForm/EndItemForm/HintItemForm/QuizItemForm/RunStartItemForm/RunEndItemForm/MineItemForm/BlackItemForm/DefenseItemForm/GambleItemForm/SolutionItemForm/RadarForm×3/CouponItemForm/StoreItemForm)
- [ ] `QuizVariantsView` 신규 — ItemQuiz 리스트 + Add + Delete
- [ ] `MissionBuilderListView` 확장 — status badge / swipe delete / Upload 액션
- [ ] dataCheck 통합 — `MissionValidator` 헬퍼 신규
- [ ] Run Start 배치 시 자동 Run End 페어링 로직
- [ ] Run End 의 effectiveRange 자동 계산
- [ ] Localizable.xcstrings — `data_check_message_0~13` 추가

### P3 — 신규 API 호출
- [ ] `RestRemoteDataSource.createMission` 구현 (POST `/missions`)
- [ ] `RestRemoteDataSource.updateMission` 구현 (PATCH `/missions/{id}`)
- [ ] `RestRemoteDataSource.deleteMission` 구현 (DELETE `/missions/{id}`)
- [ ] `RestRemoteDataSource.uploadBadgeImage` 구현 (POST `/badges` multipart)
- [ ] `AuthBootstrap.ensureAuthenticated()` 호출로 토큰 보장

### P4 — Legacy 폴백
- [ ] backend=.legacy 토글 시 `LegacyRemoteDataSource.createMission` 이 TR=700 `}}` 페이로드로 정상 동작 확인
- [ ] 뱃지 업로드 → legacy `/playspot/image_save.php` (multipart `userfile`)

### P5 — E2E 검증
- [ ] tutorial001 빌더로 신규 작성 → 시드 동일 데이터 → POST → 201 + missionId
- [ ] mine002 / run003 / dark004 / gambling005 / standard006 동일 시나리오
- [ ] `/api/v1/missions?page=0` 응답에서 신규 미션 노출 확인
- [ ] 편집 → PATCH 동작 확인
- [ ] 삭제 → DELETE + 목록에서 제거 확인
- [ ] backend=.legacy 토글 회귀 동작 1회

### P6 — UX 보강
- [ ] dataCheck 실패 시 인라인 에러 메시지 + 첫 실패 항목으로 스크롤
- [ ] auto-save (Status=DESIGNING) — 백그라운드 진입 또는 dismiss 시
- [ ] 뒤로가기 시 isDirty 면 confirm dialog
- [ ] Save 진행 중 ProgressView / 실패 시 retry

---

## 11. 참고 자료

### 11.1 서버

- Swagger UI: <http://43.201.188.35:8080/swagger-ui/index.html>
- OpenAPI JSON: <http://43.201.188.35:8080/api-docs> (24 paths / 10 tags)
- 빌더 관련 태그: **v1 — Mission** (읽기), **v1 — Badge** (뱃지), **Legacy API** (TR=700 폴백)

### 11.2 레거시 (참조)

- 레거시 스크린샷: [`old_img/design_img/`](old_img/design_img/) 19장
- 레거시 컨트롤러:
  - [`Classes/MissionBuilder.{h,m}`](Classes/) (1196 라인)
  - [`Classes/MissionBuilderInfo.{h,m}`](Classes/) (1019 라인)
  - [`Classes/MissionBuilderDetail.{h,m}`](Classes/) (1394 라인)
  - [`Classes/MissionBuilderList.{h,m}`](Classes/) (494 라인)
- 게임플레이 분석: [`research.md`](research.md) §4 아이템 시스템 / [`research2.md`](research2.md) §4 itemType 별 가이드

### 11.3 신규 클라이언트

- 신규 API 사양: [`api_client.md`](api_client.md)
- 신규 API 마이그레이션 진행: [`api_plan_new.md`](api_plan_new.md)
- 레거시 17 TR 클라이언트 분석 (별개 문서, 신규 서버 사양 아님): [`new_api.md`](new_api.md)
- DB 스키마: [`db.sql`](db.sql) (Mission/MissionItem/ItemQuiz)
- 현재 빌더 (stub): [`PlaySpot/Views/MissionBuilder/`](PlaySpot/Views/MissionBuilder/) 4 파일 251 라인
- 신규 데이터 모델: [`PlaySpot/Models/Mission.swift`](PlaySpot/Models/Mission.swift) / [`MissionItem.swift`](PlaySpot/Models/MissionItem.swift) / [`ItemQuiz.swift`](PlaySpot/Models/ItemQuiz.swift)
- 신규 데이터 소스: [`PlaySpot/Network/RestRemoteDataSource.swift`](PlaySpot/Network/RestRemoteDataSource.swift)

