# Play Spot (TreasureHunter) — 레거시 게임 메커닉 완전 가이드

> 본 문서는 [research.md](research.md) 의 내용을 **레거시 Objective-C 시스템 (`TreasureHunter.xcodeproj` / `Classes/`) 관점**에서 게임플레이 중심으로 재구성한 가이드다. iOS 4 시대에 만들어진 원본 시스템이 실제로 어떻게 동작하는지, 각 MissionItem 컬럼이 Map / AR 화면에서 어떻게 표시되고 어떤 효과를 일으키는지 설명한다.
>
> 모든 코드 라인 인용은 레거시 `Classes/*.m` / `*.h` 기준. 신규 PlaySpot Swift 포트와의 차이점은 **부록 C** 에 모음.

---

## 목차

1. [게임 한눈에 보기](#1-게임-한눈에-보기)
2. [두 화면의 역할 — Map vs AR](#2-두-화면의-역할--map-vs-ar)
3. [게임 상태 흐름](#3-게임-상태-흐름)
4. [아이템 타입별 가이드 (핵심)](#4-아이템-타입별-가이드-핵심)
5. [MissionItem 컬럼이 게임플레이에 미치는 영향](#5-missionitem-컬럼이-게임플레이에-미치는-영향)
6. [가시성 매트릭스](#6-가시성-매트릭스)
7. [획득 방법 매트릭스](#7-획득-방법-매트릭스)
8. [사운드 / 햅틱 / 애니메이션](#8-사운드--햅틱--애니메이션)
9. [빌더 → DB 저장값 매핑](#9-빌더--db-저장값-매핑)
10. [부록 A: 모든 코드값 사전](#부록-a-모든-코드값-사전)
11. [부록 B: 레거시 클래스 / 파일 참조 지도](#부록-b-레거시-클래스--파일-참조-지도)
12. [부록 C: 신규 Swift 포트와의 차이점](#부록-c-신규-swift-포트와의-차이점)

---

## 1. 게임 한눈에 보기

**Play Spot** (Bundle ID `com.mking.trasurehunter`, Objective-C/iOS 4 시대) 은 GPS 기반 보물찾기 게임이다. 한 미션은 다음 흐름으로 진행된다:

```
미션 선택 → [Start 아이템 획득] → 필수 아이템 수집 → [End 아이템 획득] → Clear!
```

플레이어는 두 가지 화면을 자유롭게 전환:
- **Map 화면** ([`MissionPlay.m`](Classes/MissionPlay.m), `MKMapView` 기반): 지도 위에서 아이템 위치/거리 파악
- **AR 화면** ([`ARGeoViewController.m`](Classes/ARGeoViewController.m) + [`ARViewController.m`](Classes/ARViewController.m)): 카메라 화면에 아이템 오버레이 + 폰 흔들기로 즉석 획득

플레이 모드 (`pch` enum):
- **`REAL_MODE`**: 실제 미션 좌표로 이동
- **`VIRTUAL_MODE`**: 플레이어 현재 위치 기준으로 좌표 평행이동 ([`MissionPlay.m`](Classes/MissionPlay.m) 의 `virtualMode:items:`)

---

## 2. 두 화면의 역할 — Map vs AR

| 측면 | Map 화면 (`MKMapView`) | AR 화면 (`ARGeoViewController`) |
|---|---|---|
| **시각화 범위** | 지도 전체 (zoom out 가능) | 카메라 시야 (수평 ~28.6°, 수직 ~42.4°) — `VIEWPORT_*_RADIANS` 매크로 |
| **아이템 표시 수** | 가시성 통과한 모든 핀 | **단 1개** — `minDistItem.annoItem` 하나만 [`addSubview`](Classes/ARViewController.m#L1597-L1600) |
| **표시 형태** | `MKAnnotation` 핀 + `MKCircle` 오버레이 | `viewToDraw` (150×100px UIView) — 타이틀 라벨 + 아이콘 |
| **거리 정보** | 시각적 위치 + 핀 callout | 화면 하단 `ar_infoView` ("`{itemTypeObjects[i]}`:XXm") + `ar_infoView1` ("Visible range:XXm") |
| **방향 정보** | 위치만 | 방위각 기반 화면 좌우 + 하단 레이더 패널 |
| **획득 방법** | 핀 탭 → callout / 알림 | **흔들기 1.4G** ([`getItemAnimation`](Classes/ARViewController.m#L440)) 또는 화면 탭 |
| **자동 트리거** | 진입 시 mine 폭발 ([`MissionPlay.m:1469`](Classes/MissionPlay.m#L1469)) | 진입 시 mine 폭발 ([`viewportContainsCoordinate:1232-1240`](Classes/ARViewController.m#L1232-L1240)) |
| **퀴즈/미니게임 진입** | 탭 → `QuizPlayAlert` / `GamePlayAlert` | 탭 → AR 닫고 alert 진입 |
| **레이더 표시** | mine 영역 빨간 원, dark 영역 검은 원 | 하단 레이더 패널 (`radianPanel/Center/Phone/Item`) |
| **사용 시나리오** | 전체 전략 짜기, 멀리서 위치 확인 | 근접 후 즉석 획득 |

> **핵심**: AR 은 `minDistItem` 하나만 그리는 "근접 발견" UI. Map 은 전략적 위치 파악용. 두 화면을 오가며 플레이.

---

## 3. 게임 상태 흐름

### 3.1 상태 전이도

```
                    [START 아이템 획득]
[미시작]──────────────────────────────────→[진행중]
caller.missionStarted=NO                  caller.missionStarted=YES
                                                  │
                                                  ├─[Run Start 획득]→[타임어택]→[Run End 획득]→[진행중]
                                                  │     timeOutS>0          │
                                                  │                         └→ 시간 초과 → finishRunTimeAlert
                                                  │
                                                  ├─[Mine 진입]──→ mineBlast: → 최근 아이템 상실
                                                  │                (Defense 있으면 dicRnPTaken 차감 후 방어)
                                                  │
                                                  └─[모든 필수 수집]→[END 등장]→[END 획득]→[완료]
                                                                                              │
                                                                                              ↓
                                                                                       missionCompleted=YES
                                                                                       c_mission_play_finish 전송
```

상태 변수는 모두 [`MissionPlay`](Classes/MissionPlay.h) 인스턴스 소유 (`caller.*` 로 [`ARGeoViewController`](Classes/ARGeoViewController.m) 에서 접근).

### 3.2 Pre-start (`caller.missionStarted == NO`)

**플레이어가 보는 것**:
- **Map**: START 아이템 1개만 ([`MissionPlay.m:2092-2096`](Classes/MissionPlay.m#L2092-L2096) — START 외엔 `imgFile = nil`)
- **AR**: START 아이템 1개만
  - outer filter ([`ARViewController.m:1498-1502`](Classes/ARViewController.m#L1498-L1502)): START/END 만 통과
  - inner branch ([`ARViewController.m:1538-1544`](Classes/ARViewController.m#L1538-L1544)): `else if I_START` 만 minDistItem 등록 → END 가 더 가까워도 minDistItem 으로 안 잡힘 → 두 번째 그리기 루프에서 제외

**불가능한 것**:
- START 외 다른 아이템 획득 시도: 흔들기 핸들러 [`getItemAnimation`](Classes/ARViewController.m#L492-L496) 가 직접 가드:
  ```objc
  if([outstandingItem.itemType isEqualToString:I_START] == NO) {
      if(caller.missionStarted == NO) { return; }
  }
  ```

**가능한 것**:
- Mine 영역 진입 → `mineBlast:` 자동 호출 ([`viewportContainsCoordinate:1232-1240`](Classes/ARViewController.m#L1232-L1240)) — mine 화면엔 안 보이지만 폭발은 발생

### 3.3 Post-start (`caller.missionStarted == YES`)

**플레이어가 보는 것**:
- 모든 아이템 (showType + 레이더 보유 조건 통과한 것)
- END 는 `[caller.mandatory.text intValue] > 1` 이면 숨김 (마지막 1개 = end 자신)
- Run Start 는 이미 `caller.isTimeOutS > 0` 이면 다른 Run Start 숨김

### 3.4 미션 완료

조건: [`MissionItemInPlayDao missionCompleted`](Classes/Dao/MissionItemInPlayDao.m) 쿼리 — `WHERE mandatory=1 AND endYN='N'` 0건

발생 사건:
- 게임 타이머 정지
- `MissionInPlay.endYN = "Y"`, `endTime = [NSDate date]` DB 저장
- 서버에 `c_mission_play_finish` 전송 ([`uploadMissionPlay:tran:`](Classes/MissionPlay.m))
- `caller.missionCompleted = YES`
- `mapInfoUpdate:TRUE` 로 화면 갱신

---

## 4. 아이템 타입별 가이드 (핵심)

각 아이템마다 다음 항목으로 정리:

- **🎯 식별**: 코드 / 매크로 / [`AppDelegate.itemTypeObjects`](Classes/TreasureHunterAppDelegate.m#L302) 라벨 / [`itemTypeFiles`](Classes/TreasureHunterAppDelegate.m#L303) prefix
- **🗺 Map**: 지도 표시 규칙 (어떤 아이콘, 어떤 조건)
- **📷 AR**: AR 표시 규칙
- **👋 획득**: 획득 트리거 (흔들기/탭/자동/퀴즈/미니게임)
- **⚡ 효과**: 획득 시 일어나는 일 ([`getItem:`](Classes/ARViewController.m#L543) 또는 [`MissionPlay`](Classes/MissionPlay.m) 분기)
- **📊 의미 있는 컬럼**: 이 타입에 영향 주는 다른 컬럼

---

### 4.1 Start (시작)

- **🎯 식별**: 코드 `"49"` / `I_START` / "Start" / `start.png` (지도) / `ar_start.png` (AR)
- **🗺 Map**: 항상 보임. pre-start 에서도 유일하게 표시 ([`MissionPlay.m:2092-2096`](Classes/MissionPlay.m#L2092-L2096))
- **📷 AR**: 항상 보임. pre-start 에선 **유일한 minDistItem 후보**
- **👋 획득**: `rangeAR` 안에서 흔들기/탭. 인터랙션 진입은 [`getItem:557`](Classes/ARViewController.m#L557)
- **⚡ 효과** ([`getItem:`](Classes/ARViewController.m#L557-L580)):
  - `MissionItemInPlay.endYN = "Y"`, `endTime = [NSDate date]` DB 저장
  - `caller.dicItemEnd[itemID] = "Y"` (메모리 갱신)
  - `MissionInPlay.startYN = "Y"`, `startTime = [NSDate date]` DB 저장
  - `caller.missionStarted = YES`
  - `caller.missionStartTime = missionInPlay.startTime`
  - 서버에 `c_mission_play_start` 전송
  - 사운드: `s_yougotit.mp3` + 진동
- **📊 의미 있는 컬럼**: `info` (시작 안내문), `latitude/longitude` (Virtual 모드 오프셋 기준점)

---

### 4.2 End (종료)

- **🎯 식별**: 코드 `"48"` / `I_END` / "End" / `end.png` / `ar_end.png`
- **🗺 Map**: `[caller.mandatory.text intValue] > 1` 이면 숨김 ([`MissionPlay.m:2123-2127`](Classes/MissionPlay.m#L2123-L2127))
- **📷 AR**: 위와 동일. pre-start 에선 START 만 후보로 들어가므로 END 도 자동 제외
- **👋 획득**: `rangeAR` 안에서 흔들기/탭
- **⚡ 효과** ([`missionSuccess:`](Classes/ARViewController.m#L503)):
  - `dicItemEnd[itemID] = "Y"`
  - `MissionInPlay.endYN = "Y"`, `endTime = 현재` DB 저장
  - `caller.missionCompleted = YES`
  - 서버에 `c_mission_play_finish` 전송
  - `mission.mStatus` 가 `DESIGNING` 이면 `TESTED` 로 승격 (빌더 테스트 플로)
  - 사운드: `s_applause.mp3`
- **📊 의미 있는 컬럼**: `info` (종료 안내문), `mandatory` (항상 Y)

---

### 4.3 Hint / Simple (힌트)

- **🎯 식별**: 코드 `"51"` / `I_SIMPLE` / "Hint" / `simple.png` / `ar_simple.png`
- **🗺 Map**: `showType` 에 따름
- **📷 AR**: `showType` 에 따름. minDistItem 후보 진입 가능
- **👋 획득** ([`getItem:712-743`](Classes/ARViewController.m#L712-L743)):
  - `aItem.itemGame == 0` (디폴트) → 즉시 획득
  - `aItem.itemGame != 0` → `[self playGame:aItem]` → `GamePlayAlert` 진입
- **⚡ 효과**:
  - `MissionItemInPlay.endYN = "Y"`, `endTime = 현재` DB 저장
  - `dicItemEnd[itemID] = "Y"`
  - `info` 가 비어 있으면 `obtain_no_hint` 로컬라이즈드 메시지, 아니면 `info` 자체를 표시
  - `[caller.hints addObject:msg]` (히스토리)
  - `[self itemGetAlert:6 Title:nil Message:msg]` (알림 6번 = Hint)
- **📊 의미 있는 컬럼**: `info` (힌트 텍스트), `itemGame` (0~3 미니게임 레벨)

---

### 4.4 Quiz (퀴즈)

- **🎯 식별**: 코드 `"40"` / `I_QUIZ` / "Quiz" / `quiz.png` / `ar_quiz.png`
- **🗺 Map**: `showType` 에 따름
- **📷 AR**: `showType` 에 따름
- **👋 획득** ([`getItem:709-711`](Classes/ARViewController.m#L709-L711)): `[self playQuiz:aItem]` → `QuizPlayAlert` 진입
  - 정답 → 획득
  - 오답 1회 → 정답 글자 수 힌트
  - 오답 2회 → 첫 글자 공개
  - Solution 보유 시 "Solution" 버튼으로 정답 즉시 공개 (1회 소비)
- **⚡ 효과**: 정답 시 `MissionItemInPlay` 갱신 + `dicItemEnd` 갱신, `quiz_rightanswer.mp3`
- **📊 의미 있는 컬럼**: `itemQuizzes` (별도 [`ItemQuiz`](Classes/ItemQuiz.h) 테이블 1:N), `quizSeq` (빌더 카운터)

---

### 4.5 Quiz20 (확장 퀴즈) — 빌더 미노출

- **🎯 식별**: 코드 `"41"` / `I_QUIZ20` / (라벨 없음) / `quiz.png`
- **🗺 Map / 📷 AR**: Quiz 와 동일
- **👋 획득**: Quiz 와 동일 (출제 풀이 더 큼)
- **⚡ 효과**: `MissionItemInPlay.quizSeq` 로 다음 회차 추적
- **📊 의미 있는 컬럼**: `itemQuizzes`
- **⚠ 주의**: [`AppDelegate.itemTypeKeys`](Classes/TreasureHunterAppDelegate.m#L300) 에 미포함 → 빌더 picker 에서 선택 불가. 서버 다운로드 데이터에서만 등장

---

### 4.6 Run Start (타임어택 시작)

- **🎯 식별**: 코드 `"42"` / `I_TIMEOUT_S` / "Run Start" / `time_start.png` / `ar_time_start.png`
- **🗺 Map**: `showType` 에 따름. 이미 타임어택 진행 중 (`caller.isTimeOutS > 0`) 이면 다른 Run Start 숨김 ([`ARViewController.m:1522-1526`](Classes/ARViewController.m#L1522-L1526))
- **📷 AR**: 위와 동일
- **👋 획득**: 흔들기/탭
- **⚡ 효과** ([`MissionPlay.m:870-885`](Classes/MissionPlay.m#L870-L885)):
  - `caller.timeOutStartTime = [NSDate date]`
  - 같은 `relationItemID` 를 가진 Run End 검색 → `endItem.effectiveTime` 으로 카운트다운 시작
  - `caller.isTimeOutS > 0` 플래그
  - 화면 하단 `timeOutView` (SBTickerView 6자리) 카운트다운 표시
  - 알림: `obtain_run_start_info` ("Acquire Run End Item in time limit")
- **📊 의미 있는 컬럼**: `relationItemID` (짝 Run End ID), `info`

---

### 4.7 Run End (타임어택 종료)

- **🎯 식별**: 코드 `"43"` / `I_TIMEOUT_E` / "Run End" / `time_end.png` / `ar_time_end.png`
- **🗺 Map**: `showType` 에 따름. **맥동 애니메이션** (`CABasicAnimation` scale 1.5x↔1.0x, 0.35초 무한 반복)
- **📷 AR**: `showType` 에 따름
- **👋 획득**: 흔들기/탭 (제한 시간 안에)
- **⚡ 효과** ([`MissionPlay.m`](Classes/MissionPlay.m)):
  - `caller.isTimeOutS = 0`
  - 시간 안에 도달 → 정상 획득, sound: `s_yougotit.mp3`, 알림: `obtain_run_record` (기록 시간 표시)
  - 시간 초과 → `finishRunTimeAlert`, sound: `s_timeover.mp3`, 페널티
- **📊 의미 있는 컬럼**: `relationItemID` (짝 Run Start ID), `effectiveTime` (제한 시간 초), `info`

---

### 4.8 Mine (지뢰)

- **🎯 식별**: 코드 `"55"` / `I_MINE` / "Mine" / `mine.png` / (AR 아이콘 없음 — 표시 안 됨)
- **🗺 Map**:
  - **Mine Radar 보유 시에만 표시** ([`MissionPlay.m:2097-2110`](Classes/MissionPlay.m#L2097-L2110))
  - `dicRnPTaken[I_RADAR_MINE] != nil` → 빨간 40% 투명 `MKCircle` 으로 영역 표시
  - 미보유 → `imgFile = nil`, 핀도 원도 안 보임
  - 폭발 후: 갈색 원 (영구 표시)
- **📷 AR**: **절대 그려지지 않음** ([`viewportContainsCoordinate:1228-1230`](Classes/ARViewController.m#L1228-L1230)):
  ```objc
  if([item.itemType isEqualToString:I_BLACK]){ return NO; }
  if([item.itemType isEqualToString:I_MINE]){ /* 폭발 트리거 후 return */ }
  ```
  최근접 후보 선정 루프 ([`ARViewController.m:1506`](Classes/ARViewController.m#L1506)) 에서도 `I_MINE` 명시 제외
- **👋 획득**: **불가능**. 흔들기/탭으로 못 얻음
- **⚡ 효과** (`mineBlast:` 자동 호출):
  - 플레이어가 mine 의 `rangeAR` 안에 진입 → `viewportContainsCoordinate:` 가 `[caller mineBlast:item]` 호출 ([`ARViewController.m:1235`](Classes/ARViewController.m#L1235))
  - 또는 Map 화면에서도 ([`MissionPlay.m:1469`](Classes/MissionPlay.m#L1469))
  - **방어 처리** ([`mineBlast:`](Classes/MissionPlay.m#L1263)):
    - `dicRnPTaken[I_MINE_NOBOMB]` 의 `ableCnt > 0` 면 방어 사용, ableCnt -1
    - 미보유 시 정상 폭발
  - **폭발 효과**:
    - `selectLastAcquiredItem` ([`MissionItemInPlayDao`](Classes/Dao/MissionItemInPlayDao.m)) 로 가장 최근 획득 아이템 1개 조회 (mine/random/timeoutStart/mineNoBomb 제외)
    - 그 아이템 `endYN = "N"` 으로 복원 → 상실
    - 진동 + sound: `s_explosion.mp3`, `s_timer.mp3`
    - 타임어택 진행 중이면 취소
    - 알림: "A mine has exploded!" + 상실 아이템 이름
- **📊 의미 있는 컬럼**: `rangeAR` (폭발 반경), `blackCnt`/`blackTime` (저장만, 미사용)

---

### 4.9 Defense / mineNoBomb (방어)

- **🎯 식별**: 코드 `"61"` / `I_MINE_NOBOMB` / "Defense" / `mine_nobomb.png` / `ar_mine_nobomb.png`
- **🗺 Map**: `showType` 에 따름 (mine 과 다름! 일반 핀처럼 표시)
- **📷 AR**: `showType` 에 따름. minDistItem 후보 진입 가능
  - [`ARViewController.m:1506`](Classes/ARViewController.m#L1506) 의 명시 제외 목록은 `I_MINE` 단독 — `I_MINE_NOBOMB` 는 후보 포함됨
- **👋 획득** ([`getItem:745-789`](Classes/ARViewController.m#L745-L789)):
  - `aItem.itemGame == 0` → 즉시
  - `aItem.itemGame != 0` → `playGame:` (미니게임)
- **⚡ 효과**:
  - `MissionItemInPlay.endYN = "Y"` DB 저장
  - `ItemRnPInPlay.ableCnt = 1` 추가 ([`ItemRnPInPlayDao`](Classes/Dao/ItemRnPInPlayDao.m))
  - `dicRnPTaken[I_MINE_NOBOMB] = ableCnt`
  - 다음 mine 폭발 시 자동 사용 (위 4.8 참고)
  - 알림: "Defense Item acquired!"
- **📊 의미 있는 컬럼**: `info`, `itemGame`

---

### 4.10 Dark / Black (다크존)

- **🎯 식별**: 코드 `"56"` / `I_BLACK` / "Dark" / `black.png` / (AR 아이콘 없음)
- **🗺 Map**:
  - 검은색 30% 투명 `MKCircle` 으로 영역 표시
  - 핀 아이콘은 안 보임
  - **미획득 black 의 `rangeAR` 안에 들어간 다른 아이템들은 지도에서 사라짐** ([`MissionPlay.m:2128-2157`](Classes/MissionPlay.m#L2128-L2157)):
    ```objc
    for (CircleItem *circleItem in self.mapOverlays) {
        if([circleItem.missionItem.itemType isEqualToString:I_BLACK] && /* 미획득 */) {
            if (distance <= circleItem.missionItem.rangeAR && ![item.itemType isEqualToString:I_START]) {
                if ([item.itemType isEqualToString:I_BLACK]) { break; }
                else { imgFile = nil; /* 가림 */ }
            }
        }
    }
    ```
    예외: START 와 black 자신
- **📷 AR**: **절대 그려지지 않음** ([`viewportContainsCoordinate:1228`](Classes/ARViewController.m#L1228) `return NO`)
- **👋 획득**: **AR 에서 불가능**. Map 에서도 직접 탭으로 획득하는 동작은 정의되지 않음 (사실상 자동/부수효과 아이템)
- **⚡ 효과**: black 자체가 획득되면 가렸던 아이템들 다시 표시
- **📊 의미 있는 컬럼**: `rangeAR` (영향 반경)

---

### 4.11 Gambling / Random (랜덤)

- **🎯 식별**: 코드 `"50"` / `I_RANDOM` / "Gambling" / `random_box.png` / `ar_random_box.png`
- **🗺 Map**: `showType` 에 따름 (보통 `arOnly=2` — Map Radar 보유 시 표시)
- **📷 AR**: `showType` 에 따름
- **👋 획득**: 흔들기/탭 즉시
- **⚡ 효과**:
  - [`MissionItemInPlayDao selectRand`](Classes/Dao/MissionItemInPlayDao.m) — 미보유 아이템 중 랜덤 1개 조회
  - 쿼리: `WHERE endYN='N' AND itemType NOT IN ('48','50','56')` (End/Random/Black 제외)
  - 추가 획득된 아이템도 정상 효과 발동 (재귀 `getItem:`)
  - 알림: "Gambling acquired!"
  - 시각 효과: `randAni` (180°/2초 회전 + 페이드아웃, 4초 후 자동 제거)
- **📊 의미 있는 컬럼**: 없음

---

### 4.12 Solution (솔루션)

- **🎯 식별**: 코드 `"52"` / `I_SOLUTION` / "Solution" / `genius.png` / `ar_genius.png`
- **🗺 Map**: `showType` 에 따름
- **📷 AR**: `showType` 에 따름
- **👋 획득**:
  - `itemGame == 0` → 즉시
  - `itemGame != 0` → 미니게임
- **⚡ 효과**:
  - `ItemRnPInPlay.ableCnt = 1` 추가
  - 퀴즈 화면 (`QuizPlayAlert`) 에서 "Solution" 버튼으로 정답 즉시 공개 가능 (1회 소비)
  - IAP `solution_add_10` 으로 10개 추가 구매 가능 ([`MyInfo.m`](Classes/MyInfo.m))
  - 알림: "Solution Item acquired!"
- **📊 의미 있는 컬럼**: `info`, `itemGame`

---

### 4.13 Map Radar (맵 레이더)

- **🎯 식별**: 코드 `"66"` / `I_RADAR_MAP` / "Map Radar" / `radar_map.png` / `ar_radar_map.png`
- **🗺 Map / 📷 AR**: `showType` 에 따름
- **👋 획득**: 흔들기/탭 (또는 미니게임)
- **⚡ 효과**:
  - `dicRnPTaken[I_RADAR_MAP]` 등록 → **영구 효과**
  - **Hidden(`SHOW_AR=2`) / Transparent(`SHOW_TRANSPARENT=1`) ShowType 아이템이 지도에 표시되기 시작** ([`MissionPlay.m:2112-2122`](Classes/MissionPlay.m#L2112-L2122))
  - sound: `s_radar.mp3`
  - 알림: "Map Radar Item acquired!"
- **📊 의미 있는 컬럼**: `info`, `itemGame`

---

### 4.14 Stealth Radar / radarAR (스텔스 레이더)

- **🎯 식별**: 코드 `"65"` / `I_RADAR_AR` / "Stealth Radar" / `radar_ar.png` / `ar_radar_ar.png`
- **🗺 Map / 📷 AR**: `showType` 에 따름
- **👋 획득**: 흔들기/탭 (또는 미니게임)
- **⚡ 효과**:
  - `dicRnPTaken[I_RADAR_AR]` 등록 → **영구 효과**
  - **Stealth(`SHOW_MAP=3`) / Transparent(`SHOW_TRANSPARENT=1`) ShowType 아이템이 AR 에 정상 정보로 표시되기 시작**
  - 미보유 시: AR 화면에 minDistItem 으로 잡혀도 [`ARViewController.m:1622-1638`](Classes/ARViewController.m#L1622-L1638) 분기로 하단 라벨이 `ar_clear1`/`ar_clear2` 로 대체되고 `radianItem`/`radianPhone` 화살표 둘 다 `removeFromSuperview`:
    ```objc
    if ((SHOW_TRANSPARENT || SHOW_MAP) && (radarAR 없음 && radarAll 없음)) {
        ar_infoView.title = ar_clear1;
        ar_infoView1.title = ar_clear2;
        [radianItem removeFromSuperview];
        [radianPhone removeFromSuperview];
    }
    ```
    > **참고**: 레거시는 아이콘 (`viewToDraw`) 자체는 그대로 그린다. 즉 위치는 보이지만 거리/방향 정보가 차단되는 형태.
  - 알림: "Stealth Radar Item acquired!"
- **📊 의미 있는 컬럼**: `info`, `itemGame`

---

### 4.15 All Radar — 빌더 미노출

- **🎯 식별**: 코드 `"67"` / `I_RADAR_ALL` / (라벨 없음) / `radar_all.png` / `ar_radar_all.png`
- **🗺 Map / 📷 AR**: `showType` 에 따름
- **👋 획득**: 흔들기/탭 (또는 미니게임)
- **⚡ 효과**:
  - `dicRnPTaken[I_RADAR_ALL]` 등록
  - **Map Radar + Stealth Radar 효과 동시 적용** (`MissionPlay.m` 모든 가시성 분기에서 OR 검사로 처리됨)
  - 알림: "All Radar Item acquired!"
- **📊 의미 있는 컬럼**: `info`, `itemGame`
- **⚠ 주의**: [`itemTypeKeys`](Classes/TreasureHunterAppDelegate.m#L300) 에 미포함 → 빌더 picker 에서 선택 불가

---

### 4.16 Mine Radar (지뢰 레이더)

- **🎯 식별**: 코드 `"68"` / `I_RADAR_MINE` / "Mine Radar" / `radar_mine.png` / `ar_radar_mine.png`
- **🗺 Map / 📷 AR**: `showType` 에 따름
- **👋 획득**: 흔들기/탭 (또는 미니게임)
- **⚡ 효과**:
  - `dicRnPTaken[I_RADAR_MINE]` 등록 → **영구 효과**
  - **Mine 의 폭발 반경(`rangeAR`)이 빨간 `MKCircle` 으로 지도에 표시되기 시작** ([`MissionPlay.m:906`](Classes/MissionPlay.m#L906))
  - 미보유 시: mine 위치 알 수 없음
  - 알림: "Mine Radar Item acquired!"
- **📊 의미 있는 컬럼**: `info`, `itemGame`

---

### 4.17 Coupon (쿠폰)

- **🎯 식별**: 코드 `"59"` / `I_COUPON` / "쿠폰" / `coupon.png` / `ar_coupon.png`
- **🗺 Map / 📷 AR**: `showType` 에 따름
- **👋 획득**: 흔들기/탭 즉시
- **⚡ 효과**:
  - 일반 획득 처리
  - `info` 가 쿠폰 코드/내용으로 표시
- **📊 의미 있는 컬럼**: `info`

---

### 4.18 Store (상점)

- **🎯 식별**: 코드 `"91"` / `I_STORE` / "Store" / `store.png` / `ar_store.png`
- **🗺 Map / 📷 AR**: `showType` 에 따름
- **👋 획득**: 흔들기/탭 (또는 미니게임)
- **⚡ 효과**:
  - 일반 획득 처리
  - `info` 가 상품 정보로 표시
- **📊 의미 있는 컬럼**: `info`

---

### 4.19 미사용/미구현 타입

| 코드 | 매크로 | 라벨 | 상태 |
|:---:|---|---|---|
| `"00"~"09"` | `I_NUM00`~`I_NUM09` | (Number 0~9) | [`MissionItem.h:31-40`](Classes/MissionItem.h#L31-L40) 정의만. 빌더/런타임 미사용 |
| `"10"` | `I_ALPHABET` | (Alphabet) | 정의만 |
| `"54"` | `I_PENALTY_REMOVE` | (Penalty Remove) | 정의만. 퀴즈 페널티 초기화 의도 |
| `"69"` | `I_RADAR_BLACK` | (Radar Black) | 빌더에 분기 코드만 있고 [`MissionBuilderDetail.m:523`](Classes/MissionBuilderDetail.m#L523) 에 "현재 구현 안됨" 주석 |

> 11개 타입이 정의되어 있으나 실제 게임플레이에서 등장하지 않는다. 서버 데이터에 들어 있더라도 효과를 일으키지 않거나 시각적으로만 표시될 수 있다.

---

## 5. MissionItem 컬럼이 게임플레이에 미치는 영향

각 컬럼별로 "이 컬럼이 무엇을 결정하는가, 게임 중 언제 작용하는가, Map/AR 화면에 어떤 영향을 주는가" 정리.

---

### 5.1 `itemType` (TEXT) — 가장 결정적인 컬럼

**용도**: 아이템의 종류 결정 (위 §4 의 어느 카테고리에 속하는지)

**게임 중 작용**:
- 아이콘 결정: [`AppDelegate.itemTypeFiles[index]`](Classes/TreasureHunterAppDelegate.m#L303) → `i_X.png` / `in_X.png` / `ar_X.png` / `arn_X.png`
- 획득 인터랙션 분기: [`getItem:`](Classes/ARViewController.m#L543) 의 거대한 `if/else if` 체인
- 가시성 분기: mine, black 은 영구 제외; start, end 는 특수 룰
- 획득 후 alert 분기: [`itemGetAlert:Title:Message:`](Classes/ARViewController.m) 의 alert 종류 (1~7)

**Map 영향**: 아이콘 PNG 결정. mine, black 은 핀 대신 원 오버레이. 필수면 별표 prefix `in_X.png`

**AR 영향**: 아이콘 PNG 결정 (`ar_X.png`/`arn_X.png`). mine, black 은 후보 영구 제외

**코드값**: 27개 (§4 와 §부록 A 참고)

---

### 5.2 `showType` (TEXT) — 가시성의 핵심

**용도**: 아이템이 Map / AR 에 기본적으로 보이는지 결정

**게임 중 작용** (보유 레이더와 조합):

| `showType` | 매크로 | Map 기본 | Map (radarMap/All 보유) | AR 기본 | AR (radarAR/All 보유) |
|:---:|---|:---:|:---:|:---:|:---:|
| `"4"` | `SHOW_ALL` | ✓ | ✓ | ✓ | ✓ |
| `"2"` | `SHOW_AR` | ✗ | ✓ | ✓ | ✓ |
| `"3"` | `SHOW_MAP` | ✓ | ✓ | (정보 가림) | ✓ |
| `"1"` | `SHOW_TRANSPARENT` | ✗ | ✓ | (정보 가림) | ✓ |

**Map 영향**: [`MissionPlay.m:2112-2122`](Classes/MissionPlay.m#L2112-L2122) 에서 `showType == TRANSPARENT/AR && !radarMap && !radarAll` 면 `imgFile = nil`

**AR 영향**:
- 후보 자체는 제외하지 않음
- 그릴 때 [`ARViewController.m:1622-1638`](Classes/ARViewController.m#L1622-L1638) 분기:
  - `showType == TRANSPARENT/MAP && !radarAR && !radarAll` → 하단 정보 라벨 "Hidden" 텍스트로 대체, 레이더 화살표 둘 다 제거 (단 아이콘 자체는 그대로 그림)

**빌더 노출**: 3개만 (Normal, Hidden, Stealth) — [`AppDelegate.m:305-306`](Classes/TreasureHunterAppDelegate.m#L305-L306). `SHOW_TRANSPARENT` 는 서버 다운로드 데이터에만 등장 가능

---

### 5.3 `mandatory` (INT, 0/1)

**용도**: 미션 완료 필수 여부

**게임 중 작용**:
- 화면 하단 "남은필수" 카운터 (`caller.mandatory.text`)
- 미션 완료 판정 ([`MissionItemInPlayDao missionCompleted`](Classes/Dao/MissionItemInPlayDao.m) SQL: `WHERE mandatory=1 AND endYN='N'` 0건)
- END 등장 조건 (`[caller.mandatory.text intValue] > 1` 이면 숨김)

**Map 영향**:
- 필수면 별표 아이콘 (`in_X.png`), 선택이면 일반 아이콘 (`i_X.png`) — [`AppDelegate itemMandatoryMapFile:` / `itemMapFile:`](Classes/TreasureHunterAppDelegate.m#L490-L505)
- 필수만 레이더 화살표 (`radianItem`) 의 nearest 후보가 됨

**AR 영향**: 별표 prefix (`arn_X.png`)

**코드값**: `MANDATORY_N=0`, `MANDATORY_Y=1` ([`pch:32-35`](TreasureHunter_Prefix.pch#L32-L35))

---

### 5.4 `rangeAR` (INT, 미터, 30~100)

**용도**: AR 가시 거리 + 인터랙션 거리 + 영역 효과 반경 (3중 의미)

**게임 중 작용**:

| 아이템 타입 | rangeAR 의미 | 코드 위치 |
|---|---|---|
| 일반 (start, end, hint, quiz, ...) | AR 화면에 표시되는 최대 거리 | [`viewportContainsCoordinate:1219`](Classes/ARViewController.m#L1219) `radialDistance > rangeAR → return NO` |
| `mine` (55) | 자동 폭발 반경 | [`MissionPlay.m:1469`](Classes/MissionPlay.m#L1469) `[playerLoc distanceFromLocation:itemLoc] <= rangeAR` |
| `black` (56) | 다크존 영향 반경 (이 안의 다른 아이템 가림) | [`MissionPlay.m:2138`](Classes/MissionPlay.m#L2138) |
| (지도 그리기) | mine/black 의 `MKCircle` 반경 | [`MissionPlay.m:906`](Classes/MissionPlay.m#L906) |

**기본값**: 30 ([`MissionItem.m:62`](Classes/MissionItem.m#L62))
**빌더 picker**: 30, 40, 50, 60, 70, 80, 90, 100 ([`AppDelegate.m:314`](Classes/TreasureHunterAppDelegate.m#L314))

---

### 5.5 `itemGame` (INT, 0~3) — 미니게임 토글

**용도**: 획득 시 미니게임 발동 여부 + 난이도

**게임 중 작용**:
- `0` → 즉시 획득 (디폴트)
- `1~3` → 미니게임 시트 표시
- 적용 가능 타입: `simple`(Hint), 모든 radar (`radarAR/Map/All/Mine`), `solution`, `mineNoBomb`, `store` — [`ARViewController.m:715, 753`](Classes/ARViewController.m#L715) 의 `if(aItem.itemGame != 0) { [self playGame:aItem]; }` 체크

**미니게임 메커니즘** ([`GamePlayAlert.m`](Classes/GamePlayAlert.m)):
- `type` 은 매번 [`arc4random()%2`](Classes/GamePlayAlert.m#L31-L34) 로 랜덤: 0=터치 (`game_touch.png`), 1=흔들기 (`game_shake.png`)
- 100점 채우면 클리어, 1초마다 -1, 0 도달 시 실패
- 흔들기 임계: 1.4G ([`GamePlayAlert.m:112`](Classes/GamePlayAlert.m#L112))

**레벨별 가산값** ([`GamePlayAlert.m:114-141`](Classes/GamePlayAlert.m#L114-L141)):

| `itemGame` 값 | 라벨 (en/ko) | 터치 +/클릭 | 흔들기 +/흔들기 |
|:---:|---|---:|---:|
| 0 | None / 없음 | (미니게임 없음) | (미니게임 없음) |
| 1 | Beginer Level / 난이도 하 | +6 | +7 |
| 2 | Normal Level / 난이도 중 | +5 | +6 |
| 3 | Senior Level / 난이도 상 | +4 | +5 |
| (그 외) | (디폴트) | +7 | +8 |

**Map 영향**: 없음
**AR 영향**: 없음 (탭 시 alert 진입만)

---

### 5.6 `effectiveTime` (INT, 초)

**용도**: Run Start ~ Run End 제한 시간

**게임 중 작용** ([`MissionPlay.m:880, 1394`](Classes/MissionPlay.m#L880)):
- Run Start 획득 시 `caller.timeOutLimitTime = item.effectiveTime` 설정 후 카운트다운 시작
- 화면 하단 `timeOutView` (SBTickerView 빨간 배경) 에 남은 시간 표시
- 0 도달 시 sound `s_timeover.mp3` + `finishRunTimeAlert`

**적용 타입**: `timeoutStart`(42), `timeoutEnd`(43) — 빌더에서 두 아이템에 동일 값 자동 저장 ([`MissionBuilder.m:551-552`](Classes/MissionBuilder.m#L551-L552))

**Map/AR 영향**: 시각적으로 없음 (UI 는 화면 상단 타이머에 반영)

---

### 5.7 `effectiveRange` (INT, 미터, 2~60)

**용도**: 의도상 Run Start ↔ Run End 사이 거리

**게임 중 작용**: **현재 런타임 검사 코드 없음**. 빌더에서 거리 자동 측정 ([`MissionBuilderDetail.m:553`](Classes/MissionBuilderDetail.m#L553)) 후 저장만. [`MissionBuilder.m:651`](Classes/MissionBuilder.m#L651) 에서 Run End 생성 시 `effectiveRange = 42` 하드코딩

**Map/AR 영향**: 없음

---

### 5.8 `relationItemID` (INT)

**용도**: Run Start ↔ Run End 짝맞춤

**게임 중 작용**:
- 빌더에서 Run End 추가 시 가장 최근 Run Start 의 `itemID` 를 양쪽에 자동 set ([`MissionBuilder.m:649-657`](Classes/MissionBuilder.m#L649-L657))
- 런타임 Run Start 획득 시 같은 `relationItemID` 를 가진 Run End 검색 → `effectiveTime` 추출
- Run End 획득 시 매칭 Run Start 가 활성 상태인지 검증

**Map 영향**: 시각적으로 없음 (논리적 연결만)
**AR 영향**: 없음

---

### 5.9 `info` (TEXT, 자유 입력)

**용도**: 아이템별 메시지 / 데이터

**게임 중 작용**: 획득 alert 메시지로 표시. 비어 있으면 타입별 디폴트 (`obtain_*` localizable strings) 사용

**적용 타입별 의미**:

| 타입 | `info` 내용 | 디폴트 (en) |
|---|---|---|
| Start | 시작 안내 | "If you touch OK, the item will be released Mission." |
| Hint | 힌트 텍스트 | `obtain_no_hint` ("Lose the draw!! No hint.") |
| Run Start | 타임어택 안내 | `obtain_run_start_info` |
| Run End | 종료 안내 | `obtain_run_record` (시간 표시) |
| Solution | 사용 안내 | "You can get an answer if you win mission quiz or quiz item." |
| Stealth Radar | 효과 설명 | "Stealth items are now visible in AR." |
| Map Radar | 효과 설명 | "Hidden items are now visible on the map." |
| Mine Radar | 효과 설명 | "Mine explosion radius is now shown on the map." |
| All Radar | 효과 설명 | "All hidden items are now revealed." |
| Defense | 효과 설명 | "Mine damage can be avoided using this Defence item." |
| Coupon | 쿠폰 코드 | (코드 자체) |
| Store | 상품 정보 | (정보 자체) |

빌더 입력: [`MissionBuilderDetail.m:258, 277, 308`](Classes/MissionBuilderDetail.m#L258) — UITextView/UITextField 텍스트 입력

**Map/AR 영향**: 시각적으로는 없음. 획득 alert 에만 사용

---

### 5.10 `latitude`, `longitude` (REAL)

**용도**: GPS 좌표 (WGS84)

**게임 중 작용**:
- 거리 계산: `CLLocation.distanceFromLocation:` (Haversine, 고도 무시)
- 방위각 계산 ([`ARGeoCoordinate calibrateUsingOrigin:`](Classes/ARGeoCoordinate.m)): AR 화면 X 위치 결정
- Virtual 모드 오프셋 기준점 ([`MissionPlay.m virtualMode:`](Classes/MissionPlay.m)): start 아이템 좌표 → 플레이어 위치 오프셋

**Map 영향**: `MKAnnotation.coordinate` (핀 위치)
**AR 영향**: `pointInView:forCoordinate:` 의 X (방위각) + Y (수직각) 위치

---

### 5.11 `blackCnt`, `blackTime` (INT)

**용도**: 의도상 dark/mine 영역의 카운트 / 시간 페널티

**게임 중 작용**: **현재 런타임 사용처 없음** ([`MissionItemDao`](Classes/Dao/MissionItemDao.m) 저장만, 빌더 picker 만 존재)

**Map/AR 영향**: 없음

**기본값**: blackCnt=5, blackTime=300(5분) ([`MissionItem.m:64-65`](Classes/MissionItem.m#L64-L65))

**빌더 picker** ([`AppDelegate.m:315-317`](Classes/TreasureHunterAppDelegate.m#L315-L317)):
- blackCnt: 1~10
- blackTime: "5분"~"10분" → `(인덱스+1)×300` 초로 저장 ([`MissionBuilderDetail.m:752`](Classes/MissionBuilderDetail.m#L752))

---

### 5.12 `quizSeq`, `rnpSeq` (INT)

- **`quizSeq`**: [`MissionItem.m:79`](Classes/MissionItem.m#L79) `addItemQuiz` 가 사용하는 메모리 카운터. ItemQuiz 추가 시 자동 증가. DB 저장 안 됨. 기본값 1
- **`rnpSeq`**: 완전 미사용. [`MissionItemDao`](Classes/Dao/MissionItemDao.m) 의 select/insert 컬럼에도 없음

---

## 6. 가시성 매트릭스

### 6.1 Map 가시성 (Post-start, mine/black 제외)

| `showType` | 레이더 없음 | Map Radar | All Radar |
|:---:|:---:|:---:|:---:|
| `4` Normal | ✓ | ✓ | ✓ |
| `2` Hidden | ✗ | ✓ | ✓ |
| `3` Stealth | ✓ | ✓ | ✓ |
| `1` Transparent | ✗ | ✓ | ✓ |

**예외**:
- mine: Mine Radar 필요 ([`MissionPlay.m:2105-2109`](Classes/MissionPlay.m#L2105-L2109))
- end: `[mandatory.text intValue] > 1` 이면 숨김 ([`MissionPlay.m:2123-2127`](Classes/MissionPlay.m#L2123-L2127))
- 다크존 안의 아이템 (start, black 제외): black 미획득 동안 숨김 ([`MissionPlay.m:2128-2157`](Classes/MissionPlay.m#L2128-L2157))

### 6.2 AR 가시성 (Post-start)

레거시 AR 은 후보 자체는 ShowType 에 무관하게 잡고 (선정 루프 [1497-1547](Classes/ARViewController.m#L1497-L1547) 의 ShowType 검사가 [1512-1521](Classes/ARViewController.m#L1512-L1521) 에 주석 처리됨), 그릴 때 정보 라벨/화살표만 차단:

| `showType` | 레이더 없음 | Stealth Radar | All Radar |
|:---:|:---:|:---:|:---:|
| `4` Normal | ✓ 아이콘 + 정보 | ✓ 아이콘 + 정보 | ✓ 아이콘 + 정보 |
| `2` Hidden (arOnly) | ✓ 아이콘 + 정보 | ✓ 아이콘 + 정보 | ✓ 아이콘 + 정보 |
| `3` Stealth (mapOnly) | **아이콘 보임 / 정보·화살표 차단** | ✓ 아이콘 + 정보 | ✓ 아이콘 + 정보 |
| `1` Transparent | **아이콘 보임 / 정보·화살표 차단** | ✓ 아이콘 + 정보 | ✓ 아이콘 + 정보 |

**Swift 포트 viewport 검사 차이** (F-10): 신규 포트는 pitch(수직 inclination) 검사를 생략. `ARCoordinate.from` 이 inclination=0 (지면 평면) 으로 고정하기 때문에 pitch 검사가 의미가 없고, 시뮬레이터에서 CMDeviceMotion 데이터가 없어 모든 아이템이 viewport 밖으로 판정되는 버그를 회피하기 위함. 거리(rangeAR) 와 (heading 있을 때) azimuth 만 검사. y 좌표는 화면 중앙 고정.

> 레거시 특이점: Stealth/Transparent + radar 없음 인 경우에도 **아이콘 자체는 그려진다** ([`viewportContainsCoordinate:`](Classes/ARViewController.m#L1216) 와 두 번째 그리기 루프 [1549-1613](Classes/ARViewController.m#L1549-L1613) 에 ShowType 차단 없음). 차단되는 것은 하단 라벨 (`ar_clear1`/`ar_clear2`) 과 레이더 화살표뿐 — "근처에 뭔가 있다는 것은 보이지만 거리/방향 정보는 막는" 형태.

**예외**:
- mine, black: 항상 안 보임 ([`viewportContainsCoordinate:1228-1230`](Classes/ARViewController.m#L1228-L1230))
- end: `[mandatory.text intValue] > 1` 이면 후보에서 제외 ([`ARViewController.m:1527-1530`](Classes/ARViewController.m#L1527-L1530))
- timeoutStart: `caller.isTimeOutS > 0` 면 후보 제외 ([`ARViewController.m:1522-1526`](Classes/ARViewController.m#L1522-L1526))

### 6.3 Pre-start 가시성 (`caller.missionStarted == NO`)

| 화면 | 보이는 아이템 | 코드 |
|---|---|---|
| Map | START 아이템 1개만 | [`MissionPlay.m:2092-2096`](Classes/MissionPlay.m#L2092-L2096) `imgFile = nil` |
| AR | START 아이템 1개만 (END 가 더 가까워도 숨김) | outer [1498-1502](Classes/ARViewController.m#L1498-L1502) + inner [1538](Classes/ARViewController.m#L1538) |

mine 은 Pre-start 에서도 자동 폭발 트리거됨 (단, 화면엔 안 보임)

---

## 7. 획득 방법 매트릭스

> **핵심**: Map 화면에서는 **어떤 아이템도 핀 탭으로 획득되지 않는다**. 레거시 [`MissionPlay.m:1979-1981`](Classes/MissionPlay.m#L1979-L1981) 의 `didSelectAnnotationView:` 는 빈 함수 — Map 핀 탭은 callout 표시 전용. 모든 획득은 **AR 화면**에서만.

| 아이템 타입 | Map 탭 | AR 탭 | AR 흔들기 | 자동 트리거 | 퀴즈 통과 | 미니게임 통과 |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| Start | ✗ | ✓ | ✓ | ✗ | ✗ | ✗ |
| End | ✗ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Hint (itemGame=0) | ✗ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Hint (itemGame>0) | ✗ | alert | alert | ✗ | ✗ | ✓ |
| Quiz | ✗ | alert | alert | ✗ | ✓ | ✗ |
| Run Start | ✗ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Run End | ✗ | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Mine** | **✗** | **✗** | **✗** | **✓ (`mineBlast:`)** | **✗** | **✗** |
| Defense (itemGame=0) | ✗ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Defense (itemGame>0) | ✗ | alert | alert | ✗ | ✗ | ✓ |
| **Dark** | **✗** | **✗** | **✗** | (간접) | ✗ | ✗ |
| Gambling | ✗ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Solution (itemGame=0) | ✗ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Solution (itemGame>0) | ✗ | alert | alert | ✗ | ✗ | ✓ |
| Map Radar | ✗ | ✓ | ✓ | ✗ | ✗ | (조건부) |
| Stealth Radar | ✗ | ✓ | ✓ | ✗ | ✗ | (조건부) |
| Mine Radar | ✗ | ✓ | ✓ | ✗ | ✗ | (조건부) |
| Coupon | ✗ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Store | ✗ | ✓ | ✓ | ✗ | ✗ | (조건부) |

> **alert** = AR 화면에서 아이콘 탭/흔들기 시 즉시 획득 안 되고 `QuizPlayAlert` / `GamePlayAlert` 진입 → 통과 후 획득

> **(조건부)** = `itemGame > 0` 인 경우만 미니게임 발동

> Map 화면의 역할은 **탐색 가이드** — 아이템 위치를 시각적으로 확인하고 그 좌표로 이동한 뒤 AR 화면을 켜서 획득.

---

## 8. 사운드 / 햅틱 / 애니메이션

### 8.1 사운드 매핑

[`AppDelegate playSystemSound:fileType:`](Classes/TreasureHunterAppDelegate.m) 로 재생.

| 사운드 | 트리거 |
|---|---|
| `s_gogogo.mp3` | 미션 시작 |
| `s_yougotit.mp3` | 일반 아이템 획득 |
| `s_explosion.mp3` | Mine 폭발 |
| `s_timer.mp3` | 카운트다운 경고 |
| `s_timeover.mp3` | 타임어택 시간 초과 |
| `quiz_rightanswer.mp3` | 퀴즈 정답 |
| `quiz_wronganswer.mp3` | 퀴즈 오답 |
| `s_quiz_fail.mp3` | 퀴즈 최종 실패 |
| `s_radar.mp3` | 레이더 획득 |
| `s_applause.mp3` | 미션 완료 환호 |
| `game_finish.mp3` | 게임 종료 |
| `s_game_touch.mp3` | 미니게임 터치 |
| `s_winsomething.wav` | 보상 획득 |

### 8.2 햅틱

- Mine 폭발: `AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)` ([`MissionPlay.m`](Classes/MissionPlay.m) `mineBlast:`)

### 8.3 애니메이션

- **타이머 자릿수**: SBTickerView 6자리 flip (HH:MM:SS) — [`Classes/flip/SBTickerView.m`](Classes/flip/SBTickerView.m)
- **Run End 핀**: `CABasicAnimation` scale 1.5x ↔ 1.0x, 0.35초 무한 반복
- **AR 아이템 획득**: 1.5배 확대 → 원래 크기 (각 0.3초 EaseOut/EaseIn) — [`getItemAnimation`](Classes/ARViewController.m#L440)
- **Gambling 이펙트**: `randAni` — 180°/2초 회전 + 페이드아웃, 4초 후 자동 제거

---

## 9. 빌더 → DB 저장값 매핑

### 9.1 Picker 옵션

[`AppDelegate.m:300-317`](Classes/TreasureHunterAppDelegate.m#L300-L317).

| 컬럼 | Picker | 노출 옵션 수 | 저장 변환 |
|---|---|---:|---|
| `itemType` | 16 타입 라벨 (`itemTypeKeys`/`Objects`) | 16 | 라벨 → I_* 코드 |
| `mandatory` | "선택" / "필수" (`mandatory` 배열) | 2 | 인덱스 (0/1) |
| `showType` | "Normal" / "Hidden" / "Stealth" (`showTypeKeys`) | 3 | SHOW_ALL/AR/MAP |
| `rangeAR` | 30~100 (10 단위) | 8 | intValue |
| `effectiveRange` | 2~10, 20, 30, 40, 50, 60 | 14 | intValue |
| `effectiveTime` | (`UITextField` MM:SS) | — | `[APPDEL timeFormat2sec:]` 변환 |
| `itemGame` | "없음"/"하"/"중"/"상" (NSLocalizedString) | 4 | 인덱스 (0~3) |
| `blackCnt` | 1~10 | 10 | intValue |
| `blackTime` | "5분"~"10분" | 6 | (인덱스+1)×300 |
| `info` | (UITextView) | — | 그대로 |
| `relationItemID` | (자동, Run End 추가 시) | — | 자동 산출 ([`MissionBuilder.m:649-657`](Classes/MissionBuilder.m#L649-L657)) |

### 9.2 빌더 유효성 검사 ([`MissionBuilder.m dataCheck`](Classes/MissionBuilder.m))

| 규칙 | 비고 |
|---|---|
| 미션 제목/설명/장소 비어 있으면 안 됨 | — |
| 아이템 최소 3개 | — |
| START 정확히 1개 | 중복/누락 불가 |
| END 정확히 1개 | 중복/누락 불가 |
| Quiz 타입은 모두 question + answer 필수 | — |
| Run Start 수 = Run End 수 | 짝맞춤 검증 |
| Stealth(showType=3) 아이템 있으면 Stealth Radar 1개 이상 필수 | 사용자가 못 풀게 되는 미션 방지 |

---

## 부록 A: 모든 코드값 사전

### A.1 itemType (전 27개)

[`MissionItem.h:18-59`](Classes/MissionItem.h#L18-L59).

| 코드 | 매크로 | 라벨 (en) | 라벨 (ko) | 빌더 노출 | 카테고리 |
|:---:|---|---|---|:---:|---|
| `"00"` | `I_NUM00` | (Number 0) | — | ✗ | 수집 (미사용) |
| `"01"` | `I_NUM01` | (Number 1) | — | ✗ | 수집 (미사용) |
| `"02"` | `I_NUM02` | (Number 2) | — | ✗ | 수집 (미사용) |
| `"03"` | `I_NUM03` | (Number 3) | — | ✗ | 수집 (미사용) |
| `"04"` | `I_NUM04` | (Number 4) | — | ✗ | 수집 (미사용) |
| `"05"` | `I_NUM05` | (Number 5) | — | ✗ | 수집 (미사용) |
| `"06"` | `I_NUM06` | (Number 6) | — | ✗ | 수집 (미사용) |
| `"07"` | `I_NUM07` | (Number 7) | — | ✗ | 수집 (미사용) |
| `"08"` | `I_NUM08` | (Number 8) | — | ✗ | 수집 (미사용) |
| `"09"` | `I_NUM09` | (Number 9) | — | ✗ | 수집 (미사용) |
| `"10"` | `I_ALPHABET` | (Alphabet) | — | ✗ | 수집 (미사용) |
| `"40"` | `I_QUIZ` | Quiz | Quiz | ✓ | 퀴즈 |
| `"41"` | `I_QUIZ20` | (Quiz20) | — | ✗ | 퀴즈 (확장) |
| `"42"` | `I_TIMEOUT_S` | Run Start | Run Start | ✓ | 타임어택 |
| `"43"` | `I_TIMEOUT_E` | Run End | Run End | ✓ | 타임어택 |
| `"48"` | `I_END` | End | End | ✓ | 미션 |
| `"49"` | `I_START` | Start | Start | ✓ | 미션 |
| `"50"` | `I_RANDOM` | Gambling | Gambling | ✓ | 특수 |
| `"51"` | `I_SIMPLE` | Hint | Hint | ✓ | 수집 / 미니게임 |
| `"52"` | `I_SOLUTION` | Solution | Solution | ✓ | 파워업 |
| `"54"` | `I_PENALTY_REMOVE` | (Penalty Remove) | — | ✗ | 파워업 (미구현) |
| `"55"` | `I_MINE` | Mine | Mine | ✓ | 위험 |
| `"56"` | `I_BLACK` | Dark | Dark | ✓ | 위험 |
| `"59"` | `I_COUPON` | 쿠폰 | 쿠폰 | ✓ | 보상 |
| `"61"` | `I_MINE_NOBOMB` | Defense | Defense | ✓ | 파워업 |
| `"65"` | `I_RADAR_AR` | Stealth Radar | Stealth Radar | ✓ | 레이더 |
| `"66"` | `I_RADAR_MAP` | Map Radar | Map Radar | ✓ | 레이더 |
| `"67"` | `I_RADAR_ALL` | (All Radar) | — | ✗ | 레이더 |
| `"68"` | `I_RADAR_MINE` | Mine Radar | Mine Radar | ✓ | 레이더 |
| `"69"` | `I_RADAR_BLACK` | (Radar Black) | — | ✗ | 레이더 (미구현) |
| `"91"` | `I_STORE` | Store | Store | ✓ | 보상 |

> 빌더 노출 16개 / 헤더만 11개 (총 27개).

### A.2 showType (전 4개)

[`MissionItem.h:65-68`](Classes/MissionItem.h#L65-L68).

| 코드 | 매크로 | 빌더 라벨 | Map 기본 | AR 기본 |
|:---:|---|---|:---:|:---:|
| `"1"` | `SHOW_TRANSPARENT` | (빌더 미노출) | ✗ | ✗ (정보 가림) |
| `"2"` | `SHOW_AR` | Hidden | ✗ | ✓ |
| `"3"` | `SHOW_MAP` | Stealth | ✓ | ✗ (정보 가림) |
| `"4"` | `SHOW_ALL` | Normal | ✓ | ✓ |

### A.3 mandatory (전 2개) — `pch:32-35`

| 코드 | 매크로 | 라벨 (en/ko) |
|:---:|---|---|
| `0` | `MANDATORY_N` | Option / 선택 |
| `1` | `MANDATORY_Y` | Mandatory / 필수 |

### A.4 itemGame (전 4개) — `AppDelegate.m:311`

| 코드 | 라벨 (en) | 라벨 (ko) | 미니게임 발동 |
|:---:|---|---|:---:|
| `0` | None | 없음 | ✗ |
| `1` | Beginer Level | 난이도 하 | ✓ |
| `2` | Normal Level | 난이도 중 | ✓ |
| `3` | Senior Level | 난이도 상 | ✓ |

### A.5 미션 상태 enum — `pch:25-30`

| 코드 | enum | 의미 |
|:---:|---|---|
| `0` | `DESIGNING` | 편집 중 |
| `1` | `TESTED` | 테스트 완료 |
| `2` | `SERVER_UPLOAD` | 서버 업로드 (수정 불가) |
| `3` | `FIRST_DESIGN` | 최초 디자인 (취소 시 삭제) |

### A.6 플레이 모드 enum — `pch:36-39`

| 코드 | enum | 의미 |
|:---:|---|---|
| `0` | `REAL_MODE` | 실제 GPS |
| `1` | `VIRTUAL_MODE` | 가상 GPS (오프셋) |

---

## 부록 B: 레거시 클래스 / 파일 참조 지도

```
TreasureHunterAppDelegate (싱글턴 — 전역 상태, APPDEL 매크로로 접근)
├── itemTypeKeys/Objects/Files (16종 picker)
├── showTypeKeys/Objects (3종 picker)
├── itemGame, mandatory, rangeAR, blackCnt, blackTime, effectiveRange (picker 배열)
├── locationManager (CoreLocation)
├── soundIDDic (사운드 캐시)
└── playMission / playingDic (현재 게임 상태)

MissionPlay (메인 게임 컨트롤러, ~85KB)
├── MKMapView (지도)
├── SBTickerView ×12 (메인 타이머 6 + 타임어택 6)
├── statusView (mine/mandatory/invisibleMap/invisibleAR 4개 카운터)
├── ARGeoViewController (AR 진입 시)
│   └── ARViewController (AR 렌더링)
│       ├── UIImagePickerController (카메라)
│       ├── UIAccelerometer (1.4G 흔들기 감지)
│       └── ARGeoCoordinate[] (GPS → 극좌표)
├── QuizPlayAlert (퀴즈 UI)
├── GamePlayAlert (미니게임 UI)
└── DAO 호출:
    ├── MissionDao
    ├── MissionItemDao
    ├── ItemQuizDao
    ├── MissionInPlayDao
    ├── MissionItemInPlayDao
    └── ItemRnPInPlayDao
```

핵심 파일과 줄번호 빠른 참조:

| 동작 | 파일 | 라인 |
|---|---|---|
| 아이템 타입 27 코드 정의 | `Classes/MissionItem.h` | 18-59 |
| ShowType 4 코드 정의 | `Classes/MissionItem.h` | 65-68 |
| 모든 picker 배열 | `Classes/TreasureHunterAppDelegate.m` | 300-317 |
| AR 뷰포트 가시성 | `Classes/ARViewController.m` | 1216-1271 |
| AR minDistItem 선정 | `Classes/ARViewController.m` | 1487-1547 |
| AR 그리기 (icon vs Hidden) | `Classes/ARViewController.m` | 1549-1638 |
| 흔들기 → 획득 | `Classes/ARViewController.m` | 440-500 |
| getItem 분기 (타입별) | `Classes/ARViewController.m` | 543-940 |
| Map 핀 가시성 | `Classes/MissionPlay.m` | 2080-2160 |
| Map mine 폭발 | `Classes/MissionPlay.m` | 1469 |
| mineBlast: 처리 | `Classes/MissionPlay.m` | 1263+ |
| 미니게임 메커닉 | `Classes/GamePlayAlert.m` | 31-141 |
| 미션 완료 SQL | `Classes/Dao/MissionItemInPlayDao.m` | (missionCompleted) |

---

## 부록 C: 신규 Swift 포트와의 차이점

신규 PlaySpot Swift 포트 ([`PlaySpot.xcodeproj`](PlaySpot.xcodeproj)) 작업 중 발견된 레거시 동작과의 갭. 모두 적용 완료. 자세한 내용은 [research.md §G](research.md) 참고.

| # | 항목 | 레거시 동작 | Swift 포트 (수정 후) |
|---|---|---|---|
| F-1 | Pre-start AR 표시 | START 만 (END 도 후보 제외) | START 만 ([`ARGameView.swift:222`](PlaySpot/AR/ARGameView.swift#L222)) |
| F-2 | mine 자동 폭발 (AR 화면) | `viewportContainsCoordinate:` 안에서 자동 트리거 | `.onChange(currentLocation)` → `detectMineBlast()` |
| F-3 | mineNoBomb AR 흔들기 획득 | 후보 포함 (I_MINE 단독 제외) | `item.itemType == .mine` 으로 좁힘 |
| F-4 | Stealth/Hidden + radar 없음 | 아이콘 그대로 + 정보·화살표 차단 | "Hidden — Stealth Radar required" 플레이스홀더 + 화살표 숨김 (Swift 는 더 명확) |
| F-7 | 다크존 내 아이템 지도 가리기 | `MissionPlay.m:2128-2157` | `GameEngine.shouldShowOnMap` 에 `isInsideUnacquiredDarkZone` 추가 |
| F-8 | AR 좌하단 라벨 | nearest 후보의 `displayLabel:거리m` (또는 stealth 안내) | 초기 포트는 항상 "Hint:Xm" 만 표시 → `nearestItemInfoText` 로 교체하여 `{타입}:{거리}m` 또는 `ar_clear1` 안내. 우하단도 nearest 의 rangeAR 표시로 교체 |
| F-9 | 하단 라벨 viewport 무관성 | `minDistItem` 은 viewport 검사 없이 잡히고 라벨은 항상 표시 (없으면 "mission_completed") | `nearestCandidateItem` (viewport X) 와 `nearestVisibleItem` (viewport O) 분리. 라벨은 candidate, 아이콘은 visible |
| F-10 | AR 가시성 viewport 검사 | rangeAR + azimuth + inclination 3중 검사 | **inclination(pitch) 검사 제거**. 이유: `ARCoordinate.from` 이 inclination=0 (지면 평면) 으로 고정 → pitch 검사 자체가 무의미. 또 시뮬레이터엔 CMDeviceMotion 데이터 없어 `pitch=0 → relativePitch=π/2 > viewport` 로 모든 아이템이 viewport 밖이 되는 버그. 거리 + (heading 있을 때) azimuth 만 검사. screenPosition 의 y 도 화면 중앙 고정 |
| F-11 | mine vs mineNoBomb 분리 | `I_MINE` 단독 검사 ([MissionPlay.m:2097](Classes/MissionPlay.m#L2097)) → mine 만 Mine Radar 필요, mineNoBomb 은 일반 showType 분기 | 초기 포트는 `ItemType.isMine` (mine OR mineNoBomb 둘 다) 으로 검사 → mineNoBomb(Defense) 가 Mine Radar 없으면 지도에서 안 보이고, mine 의 빨간 원이 항상 표시되는 두 버그 동시 발생. `shouldShowOnMap` / `updateCounters` / `shouldShowCircle` 모두 `== .mine` 으로 좁힘. mine 빨간 원은 `dicRnPTaken[radarMine] != nil` 일 때만 |

> **F-4 의 미세한 차이**: 레거시는 "근처에 뭔가 있다는 것은 보이지만 거리/방향 정보를 막는" 형태로 아이콘 자체는 그렸다. Swift 포트는 더 명확하게 아이콘을 "Hidden — Stealth Radar required" 플레이스홀더로 대체. 게임 의도(레이더 필요)는 둘 다 충족.

---

## 변경 이력

- **v2 (2026-05-15)**: 레거시 ObjC 시스템 관점으로 전면 재작성. Swift 포트 언급은 부록 C 로 분리. 모든 코드 인용을 `Classes/*.m` 로 통일.
- **v1**: 게임 메커닉 가이드 초안 (Swift 포트와 혼재)
