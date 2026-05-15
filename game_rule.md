# Play Spot — 레거시 게임 룰 정밀 사양

> 본 문서는 [research.md](research.md) / [research2.md](research2.md) 를 보완하여 **레거시 ObjC 시스템 (`Classes/`) 의 게임 룰과 예외**를 아이템별 / 시스템별로 정밀하게 정리한다. 모든 규칙은 레거시 소스 코드의 정확한 라인 인용으로 백킹된다. 신규 PlaySpot Swift 포트가 따라야 할 사양 문서로 활용 가능.
>
> 우선순위: **레거시 코드의 실제 동작 > 빌더 UI 의 의도 > 데이터 시트의 명세**. 셋이 충돌할 경우 코드가 진실.

---

## 목차

1. [전역 상태와 변수](#1-전역-상태와-변수)
2. [미션 시작 / 종료 글로벌 룰](#2-미션-시작--종료-글로벌-룰)
3. [아이템별 상세 룰 / 예외](#3-아이템별-상세-룰--예외)
   1. [Start (49)](#31-start-49)
   2. [End (48)](#32-end-48)
   3. [Hint / Simple (51)](#33-hint--simple-51)
   4. [Quiz (40)](#34-quiz-40)
   5. [Quiz20 (41)](#35-quiz20-41)
   6. [Run Start (42)](#36-run-start-42)
   7. [Run End (43)](#37-run-end-43)
   8. [Mine (55)](#38-mine-55)
   9. [Defense / mineNoBomb (61)](#39-defense--minenobomb-61)
   10. [Dark / Black (56)](#310-dark--black-56)
   11. [Gambling / Random (50)](#311-gambling--random-50)
   12. [Solution (52)](#312-solution-52)
   13. [Map Radar (66)](#313-map-radar-66)
   14. [Stealth Radar / radarAR (65)](#314-stealth-radar--radarar-65)
   15. [All Radar (67)](#315-all-radar-67)
   16. [Mine Radar (68)](#316-mine-radar-68)
   17. [Coupon (59)](#317-coupon-59)
   18. [Store (91)](#318-store-91)
   19. [기타 미사용 (00~10, 54, 69)](#319-기타-미사용-00~10-54-69)
4. [퀴즈 / 미니게임 룰](#4-퀴즈--미니게임-룰)
5. [타임어택 (Run) 룰](#5-타임어택-run-룰)
6. [지뢰 폭발 / 방어 룰](#6-지뢰-폭발--방어-룰)
7. [가시성 룰 (Map / AR / 레이더)](#7-가시성-룰-map--ar--레이더)
8. [DB 트랜잭션 룰](#8-db-트랜잭션-룰)
9. [알려진 예외 / 엣지 케이스](#9-알려진-예외--엣지-케이스)
10. [Swift 포트 동기화 체크리스트](#10-swift-포트-동기화-체크리스트)

---

## 1. 전역 상태와 변수

[`MissionPlay.h`](Classes/MissionPlay.h) / [`MissionPlay.m`](Classes/MissionPlay.m) 인스턴스가 보유하는 핵심 상태. AR 화면 ([`ARGeoViewController`](Classes/ARGeoViewController.m)) 은 `caller.*` 로 접근.

| 변수 | 타입 | 의미 | 변경 트리거 |
|---|---|---|---|
| `missionStarted` | BOOL | 미션 시작 여부 | START 획득 시 YES |
| `missionCompleted` | BOOL | 미션 완료 여부 | END 획득 + 모든 필수 완료 시 YES |
| `isMissionEnd` | BOOL | END 획득 후 마무리 단계 | END 획득 시 |
| `isVirtualMode` | BOOL | 가상 모드 여부 | setupPlay 인자 |
| `isNewStart` | BOOL | 새 플레이 시작 (DB 초기화 여부) | 사용자가 "Real/Virtual Play" 탭 시 YES |
| `isTimeOutS` | int | 활성 Run Start ID (0 이면 비활성) | Run Start 획득 / Run End 획득 / mine 폭발 |
| `isTimeOutE` | int | 활성 Run End ID | 동일 |
| `timeOutLimitTime` | int | 활성 타임어택 제한 시간 (초) | Run Start 획득 시 endItem.effectiveTime |
| `timeOutStartTime` | NSDate | 타임어택 시작 시각 | Run Start 획득 시 [NSDate date] |
| `missionStartTime` | NSDate | 미션 전체 시작 시각 | START 획득 시 |
| `dicItemEnd` | NSMutableDictionary | itemID(string) → "Y"/"N" | 모든 획득/취소 |
| `dicRnPTaken` | NSMutableDictionary | itemType(string) → ableCnt(int) | radar/solution/mineNoBomb 획득/소비 |
| `RunPassTime` | NSString | 마지막 Run 통과 시간 표시용 | Run End 획득 시 |
| `hints` | NSMutableArray | 획득한 힌트 메시지 누적 | Hint 획득 시 |

전역 (`APPDEL` 매크로):
- `APPDEL.gUserID`: 현재 플레이어 ID (`Guest@<timestamp>` 또는 로그인 ID)
- `APPDEL.locationManager`: CoreLocation 매니저
- `APPDEL.startPoint`: 마지막 GPS 위치 (앱 시작 시 초기화)
- `APPDEL.itemTypeKeys` / `itemTypeObjects` / `itemTypeFiles`: 16종 picker 매핑
- `APPDEL.solutionCount`: IAP 잔고 (NSUserDefaults 백업)

---

## 2. 미션 시작 / 종료 글로벌 룰

### 2.1 미션 진입 (`setupPlay`)

[`MissionPlay.m setupPlay`](Classes/MissionPlay.m) 흐름:

1. DB 에서 미션 / 아이템 / 퀴즈 로드 (`MissionDao`, `MissionItemDao`, `ItemQuizDao`)
2. `isNewStart == 1` 이면 이전 진행 데이터 모두 삭제:
   - `MissionItemInPlay` for this missionID/playerID
   - `MissionInPlay` for this missionID/playerID
   - `ItemRnPInPlay` for this missionID/playerID
3. **START 아이템 존재 여부 검사**:
   - 있으면 `MissionInPlay.startYN = "N"`, `missionStarted = NO` (대기)
   - 없으면 `MissionInPlay.startYN = "Y"`, `startTime = 현재`, `missionStarted = YES` (즉시 시작)
4. `dicItemEnd` 와 `dicRnPTaken` 을 DB 에서 로드 (이어하기 지원)
5. 활성 타임어택 복원: `selectLastStartedTimeOut` 으로 활성 Run Start 찾고 `timeOutLimitTime` 복원
6. **Virtual Mode 좌표 오프셋** (`virtualMode:items:`):
   - `isNewStart == 1` → START 아이템 좌표를 플레이어 위치로, 나머지를 동일 오프셋
   - `isNewStart == 0` → 마지막 획득 아이템 (`loadLastAcquiredItem`) 위치 기준으로 재계산
7. 지도에 핀과 오버레이 배치
8. AR 좌표 (ARGeoCoordinate) 생성

### 2.2 미션 종료 조건

| 조건 | SQL | 트리거 |
|---|---|---|
| **미션 완료** | `WHERE mandatory=1 AND endYN='N'` 가 0건 ([`MissionItemInPlayDao.m:376-389`](Classes/Dao/MissionItemInPlayDao.m#L376-L389)) | END 획득 시 검사 |
| **End 표시 가능** | `WHERE mandatory=1 AND itemType <> '48' AND endYN='N'` 가 0건 ([`MissionItemInPlayDao.m:392-405`](Classes/Dao/MissionItemInPlayDao.m#L392-L405)) | 매 카운터 갱신 시 |

> **End 등장 = 다른 모든 필수 아이템 완료 후**. End 자체가 mandatory 라 mandatory remaining 카운트에 포함되지만, 등장 조건 검사 시엔 End 만 제외.

### 2.3 미션 완료 후 흐름

1. `missionCompleted = YES`
2. `isMissionEnd = YES`
3. `MissionInPlay.endYN = "Y"`, `endTime = [NSDate date]` DB 저장
4. 게임 타이머 정지
5. 사운드 `s_applause.mp3` + `game_finish.mp3`
6. 빌더 테스트 플로 (`mission.mStatus == DESIGNING`) 면 `TESTED` 로 승격
7. 일반 플레이면 `c_mission_play_finish` 서버 전송
8. 평점/리뷰 입력 화면 표시

### 2.4 미션 실패

조건 (수동):
- 사용자가 "Exit" 버튼 → 진행 데이터 모두 삭제 (옵션) → `c_mission_play_fail` 전송

조건 (자동):
- Run 타임아웃 만료 시 (구체 동작은 [§5.4](#54-시간-초과-처리) 참고)

---

## 3. 아이템별 상세 룰 / 예외

각 아이템마다 다음 5단계 룰을 정밀하게:
- **빌더 시 자동 설정 룰** (Builder 가 강제하는 값)
- **Map 표시 룰** (정확한 분기 조건)
- **AR 표시 룰** (정확한 분기 조건)
- **획득 트리거 룰** (어떻게 획득되는가)
- **획득 후 효과 / 부수효과 룰**
- **이 아이템 관련 알려진 예외**

---

### 3.1 Start (49)

#### 빌더 룰 ([`MissionBuilder.m:684`](Classes/MissionBuilder.m#L684))
- `showType` 자동 강제: `SHOW_ALL` (= "4")
- `mandatory` 자동: `MANDATORY_Y` (1)
- `rangeAR` 디폴트: 30
- 미션 당 정확히 1개 ([`dataCheck`](Classes/MissionBuilder.m))

#### Map 표시 룰
- **항상 보임** — pre-start 든 post-start 든 무조건 표시
- pre-start 에서는 START 외 모든 아이템 `imgFile = nil` 처리됨 ([`MissionPlay.m:2092-2096`](Classes/MissionPlay.m#L2092-L2096))
- 획득 후: 흑백 처리 (`convertImageBW:`)

#### AR 표시 룰
- **항상 후보** ([`viewportContainsCoordinate:1216-1226`](Classes/ARViewController.m#L1216-L1226))
- pre-start 에서 **유일한 minDistItem 후보** ([`ARViewController.m:1538`](Classes/ARViewController.m#L1538) `else if I_START`)
- post-start 후 dicItemEnd[startID]="Y" 로 후보에서 영구 제외

#### 획득 트리거
- **AR 화면에서만** — 흔들기 (1.4G) 또는 AR 아이콘 탭 → [`getItem:`](Classes/ARViewController.m#L543)
- Map 핀 탭은 callout 표시만 — 레거시 [`MissionPlay.m:1979-1981`](Classes/MissionPlay.m#L1979-L1981) `didSelectAnnotationView:` 가 빈 함수

#### 획득 효과 ([`getItem:557-580`](Classes/ARViewController.m#L557-L580))
1. `MissionItemInPlay.endYN = "Y"`, `endTime = [NSDate date]` DB 저장
2. `caller.dicItemEnd[startID] = "Y"` (메모리)
3. `MissionInPlay.startYN = "Y"`, `startTime = [NSDate date]` DB 저장
4. `caller.missionStarted = YES`
5. `caller.missionStartTime = missionInPlay.startTime`
6. 서버에 `c_mission_play_start` POST 전송 (`uploadMissionPlay:tran:`)
7. 사운드 `s_yougotit.mp3` + 진동 (`AudioServicesPlaySystemSound`)
8. itemGetAlert 1번 (Start) 표시
9. 화면 갱신: 모든 아이템 표시 권한 활성화

#### 알려진 예외
- **mine 이 START 보다 가까울 때**: pre-start 라도 mine 의 rangeAR 안에 진입하면 [`viewportContainsCoordinate:1232-1240`](Classes/ARViewController.m#L1232-L1240) 에서 mineBlast 자동 호출. 그러나 `selectLastAcquiredItem` 이 nil 반환 → 실제 데미지 없음 (상실할 아이템 없음)
- START 의 `info` 가 비어있으면 디폴트 안내문 사용

---

### 3.2 End (48)

#### 빌더 룰
- `mandatory` 자동: `MANDATORY_Y` ([`MissionBuilder.m:677-680`](Classes/MissionBuilder.m#L677-L680))
- 미션 당 정확히 1개 ([`dataCheck`](Classes/MissionBuilder.m))
- `showType` 사용자 선택 (Normal/Hidden/Stealth)
- 퀴즈 첨부 가능 (`missionQuiz`/`missionAnswer` 가 미션 레벨 퀴즈) — End 획득 시 `QuizPlayAlert` 진입

#### Map 표시 룰
- `[caller.mandatory.text intValue] > 1` 이면 `imgFile = nil` ([`MissionPlay.m:2123-2127`](Classes/MissionPlay.m#L2123-L2127))
- 마지막 1개 (= End 자신) 일 때만 표시
- showType 에 따른 가시성도 적용
- **Run End 와 다른 점**: End 는 맥동 애니메이션 없음

#### AR 표시 료
- pre-start 에서 outer filter ([`ARViewController.m:1498-1502`](Classes/ARViewController.m#L1498-L1502)) 통과하지만 inner branch 가 START 만 잡으므로 사실상 제외
- post-start: `[caller.mandatory.text intValue] > 1` 이면 후보 제외 ([`ARViewController.m:1527-1530`](Classes/ARViewController.m#L1527-L1530))

#### 획득 트리거
- 퀴즈 없으면 흔들기/탭 즉시 획득
- 미션 퀴즈 (`missionQuiz` 비어있지 않음) 있으면 → `QuizPlayAlert` 진입 → 정답 통과 후 획득

#### 획득 효과 ([`missionSuccess:`](Classes/ARViewController.m#L503-L541))
1. `dicItemEnd[endID] = "Y"`
2. `MissionInPlay.endYN = "Y"`, `endTime = 현재` DB 저장
3. `caller.missionCompleted = YES`
4. `mission.mStatus == DESIGNING` → `TESTED` 승격 + DB 저장
5. 일반 플레이면 `c_mission_play_finish` 서버 전송
6. 사운드 `s_applause.mp3`
7. `mapInfoUpdate:TRUE` 호출 → 화면 갱신

#### 알려진 예외
- **End 획득 후 미션이 완료 안 될 수 있나?** 가능하다. `missionCompleted` SQL 은 `mandatory=1 AND endYN='N'` 검사인데, End 만 획득되고 다른 mandatory 가 미완료면 `missionCompleted = NO`. 하지만 End 표시 조건 (`missionCompletedExceptEndItem`) 이 이미 다른 mandatory 완료 후에만 End 를 보이게 하므로, End 가 보이는 시점엔 항상 완료 가능.
- **End 퀴즈 실패 페널티**: 퀴즈 실패 시 `failCnt++`, 다음에 다시 시도하면 글자수 힌트 (1회) → 첫 글자 (2회) 공개 ([`QuizPlayAlert.m:113-124`](Classes/QuizPlayAlert.m#L113-L124))

---

### 3.3 Hint / Simple (51)

#### 빌더 룰
- `mandatory` 사용자 선택 (대다수 미션은 N)
- `showType` 사용자 선택
- `info` 텍스트 입력 (힌트 내용)
- `itemGame` 사용자 선택 (None/하/중/상)

#### Map 표시 룰
- 일반 showType 분기 ([§7](#7-가시성-룰-map--ar--레이더))
- pre-start 시 숨김

#### AR 표시 룰
- 일반 후보. minDistItem 으로 선정될 수 있음

#### 획득 트리거 ([`getItem:712-743`](Classes/ARViewController.m#L712-L743))
```objc
else if([aItem.itemType isEqualToString:I_SIMPLE]) {
    if(aItem.itemGame != 0) { [self playGame:aItem]; }
    else { /* 즉시 획득 */ }
}
```
- `itemGame == 0` → 흔들기/탭 즉시
- `itemGame > 0` → `playGame:` → `GamePlayAlert` 미니게임 시트

#### 획득 효과
- `MissionItemInPlay.endYN = "Y"` DB 저장
- `dicItemEnd[itemID] = "Y"`
- `info` 가 빈 문자열이면 `obtain_no_hint` ("Lose the draw!! No hint."), 아니면 `info` 그대로 표시
- `[caller.hints addObject:msg]` (히스토리 누적)
- `itemGetAlert:6` (Hint 알림)

#### 알려진 예외
- Hint 도 mandatory 일 수 있음 (빌더에서 선택 가능). mandatory Hint 면 미션 완료 위해 반드시 획득
- `itemGame` 이 0 이 아닌데 `info` 가 비면 미니게임 통과 후에도 "Lose the draw!! No hint." 표시 (혼란 가능 — 빌더 의도 오류)

---

### 3.4 Quiz (40)

#### 빌더 룰
- `mandatory` 자동: `MANDATORY_Y` ([`MissionBuilder.m:677`](Classes/MissionBuilder.m#L677))
- `showType` 사용자 선택
- ItemQuiz 1:N 관계 — 빌더에서 `[itemQuiz quiz/answer/probability]` 복수 입력 가능
- 빌더 검증: 모든 Quiz 아이템에 question + answer 필수

#### Map 표시 룰
- 일반 showType 분기
- pre-start 시 숨김

#### AR 표시 룰
- 일반 후보 — minDistItem 으로 선정될 수 있음

#### 획득 트리거 ([`getItem:709-711`](Classes/ARViewController.m#L709-L711))
- **AR 흔들기 / AR 아이콘 탭** → `playQuiz:` → `QuizPlayAlert` 진입 (Map 탭은 무동작)

#### Quiz 출제 룰 ([`QuizPlayAlert.m:127-128`](Classes/QuizPlayAlert.m#L127-L128))
```objc
quizSeq = arc4random() % [missionItem.itemQuizzes count];
quizItem = [missionItem.itemQuizzes objectAtIndex:quizSeq];
```
- 매 진입마다 `arc4random()` 으로 랜덤 출제
- `probability` 필드는 정의되어 있으나 현재 출제 가중치로 사용 안 됨 (단순 랜덤)

#### 정답 비교 ([`QuizPlayAlert.m:202`](Classes/QuizPlayAlert.m#L202))
```objc
if([[answerField.text lowercaseString] isEqualToString:[answer lowercaseString]])
```
- **case-insensitive 비교** (소문자 변환 후 비교)
- 공백 trim 등 정규화 없음
- 정답: `MissionItemInPlay.endYN = "Y"`, `quizSeq = 사용한 seq` 저장
- 오답: `failCnt++`, `endYN = "N"`, `quizSeq = 사용한 seq` 저장

#### 오답 페널티 진행 ([`QuizPlayAlert.m:113-124`](Classes/QuizPlayAlert.m#L113-L124))
- 1회 실패 후 재진입: `quiz_0` 힌트 (정답 글자 수 표시)
- 2회 실패 후 재진입: `quiz_1` 힌트 (정답 글자 수 + 첫 글자 공개)
- failCnt 는 누적 (재플레이마다)

#### Solution 사용 ([`QuizPlayAlert.m:156-184`](Classes/QuizPlayAlert.m#L156-L184))
1. **우선순위**: `dicRnPTaken[I_SOLUTION].ableCnt > 0` 먼저 사용
2. 없으면 `APPDEL.solutionCount` (IAP 잔고) 사용
3. 둘 다 0 이면 IAP 구매 (`solution_add_10`) 유도
4. 사용 시 정답이 자동 입력되고 `solutionButton.hidden = TRUE`

#### 알려진 예외
- **answerField 의 trim 없음** → 사용자가 앞뒤 공백 입력하면 오답 처리
- **다국어 미고려** → 한글/영문 혼합 답안에서 lowercase 변환은 한글에 무영향이지만 영문 대소문자만 무관
- **arc4random 분포**: 매번 균등 랜덤 → 같은 quiz 가 연속 출제될 수 있음 (의도된 동작)

---

### 3.5 Quiz20 (41) — 빌더 미노출

#### 일반 Quiz 와의 차이
- **빌더 노출 X** (`itemTypeKeys` 미포함)
- 20개 이상의 퀴즈 변형 의도
- `MissionItemInPlay.quizSeq` 로 플레이어가 마지막으로 푼 seq 추적
- 같은 아이템을 여러 번 풀 수 있는 구조 (failCnt 별도 처리)

#### 특수 SQL ([`MissionItemInPlayDao.m selectLastFailedQuiz`](Classes/Dao/MissionItemInPlayDao.m#L153-L196))
- `B.itemType='41' AND A.endTime is NULL` 검사로 미완료 Quiz20 우선 처리
- 이후 Quiz/Quiz20 통합 검색
- failCnt > 2 면 페널티 활성화

#### 알려진 예외
- 서버 데이터에서만 등장 가능 (빌더 미노출). 실제 사용 사례 거의 없음

---

### 3.6 Run Start (42)

#### 빌더 룰
- `mandatory` 자동: `MANDATORY_Y` ([`MissionBuilder.m:677-680`](Classes/MissionBuilder.m#L677-L680))
- Run Start 추가 시 자동으로 Run End 도 함께 추가 ([`MissionBuilder.m:637-664`](Classes/MissionBuilder.m#L637-L664))
- 두 아이템에 동일 `effectiveTime`, `effectiveRange = 42` (m), 자동으로 양방향 `relationItemID` set

#### Map 표시 룰
- 일반 showType 분기
- pre-start 시 숨김
- `caller.isTimeOutS > 0` 이면 다른 Run Start 도 표시되긴 함 (Map 에선 별도 차단 X)

#### AR 표시 룰 ([`ARViewController.m:1522-1526`](Classes/ARViewController.m#L1522-L1526))
```objc
if ([itemType isEqualToString:I_TIMEOUT_S] && caller.isTimeOutS > 0) { continue; }
```
- 이미 타임어택 진행 중이면 다른 Run Start 후보 제외

#### 획득 효과 ([`MissionPlay.m:870-885`](Classes/MissionPlay.m#L870-L885))
1. `MissionItemInPlay.endYN = "Y"`, `endTime = 현재` DB 저장
2. `dicItemEnd[itemID] = "Y"`
3. `caller.timeOutStartTime = [NSDate date]`
4. 같은 `relationItemID` 를 가진 Run End 검색하여 `endItem.effectiveTime` 으로 카운트다운 시작
5. `caller.timeOutLimitTime = endItem.effectiveTime`
6. `caller.isTimeOutS = item.itemID` (활성 표식)
7. `[timeOutView setHidden:FALSE]` (빨간 SBTickerView 표시)
8. itemGetAlert 4 ("Run Start Item acquired!")
9. info 비면 `obtain_run_start_info` 디폴트

#### 알려진 예외
- **이어하기 시 복원**: setupPlay 의 `selectLastStartedTimeOut` 으로 활성 Run Start 가 있으면 자동 복원 ([`MissionPlay.m:1394-1398`](Classes/MissionPlay.m#L1394-L1398))
- **mine 진입 시 강제 취소**: mineBlast 시 [`MissionPlay.m:1328-1342`](Classes/MissionPlay.m#L1328-L1342) 에서 `isTimeOutS = 0` 으로 강제 취소 + `blastAlert:1 key:I_TIMEOUT_S`

---

### 3.7 Run End (43)

#### 빌더 룰
- `mandatory` 자동: Y
- `relationItemID` 자동: 짝 Run Start ID
- `effectiveTime` 자동: 짝 Run Start 와 동일

#### Map 표시 룰
- 일반 showType 분기
- pre-start 시 숨김
- **맥동 애니메이션** (`CABasicAnimation`, scale 1.5x↔1.0x, 0.35초 무한 반복)

#### AR 표시 룰
- 일반 후보. 맥동 애니메이션 없음 (Map 전용)

#### 획득 트리거 / 효과
- 흔들기/탭 → 즉시 획득
- 시간 안에 도달 → 정상 획득:
  - `dicItemEnd[itemID] = "Y"`
  - `isTimeOutS = 0`, `isTimeOutE = 0`, `timeOutLimitTime = 0`
  - `[timeOutView setHidden:TRUE]` + `[playTimeView setHidden:FALSE]`
  - `RunPassTime = [APPDEL sec2timeFormat:interval]` (기록 시간)
  - itemGetAlert 7 ("Run End Item acquired!" + "obtain_run_record" 시간)
  - sound: `s_yougotit.mp3`
- 시간 초과 후 도달 → finishRunTimeAlert 처리 ([§5.4](#54-시간-초과-처리))

#### 알려진 예외
- **`relationItemID` 짝 안 맞음**: 빌더 검증에서 Run Start 수 = Run End 수 검사하지만, 서버 데이터에서 깨질 수 있음. 짝 못 찾으면 timeOutLimitTime 미설정 → 카운트다운 안 시작
- **활성 Run Start 없을 때 Run End 획득 시도**: `isTimeOutS == 0` 인데 Run End 탭 시 정의되지 않은 동작 (현재 코드는 그냥 획득 처리)

---

### 3.8 Mine (55)

#### 빌더 룰
- `mandatory` 자동: `MANDATORY_N` ([`MissionBuilderDetail.m:444-447`](Classes/MissionBuilderDetail.m#L444-L447))
- 빌더 detail 화면에서 itemType + rangeAR 만 노출. **showType 행 주석 처리** ([`MissionBuilderDetail.m:462`](Classes/MissionBuilderDetail.m#L462))
- 첫 추가 시 사용자가 선택한 showType 저장되지만 가시성에 영향 없음 (dead column)

#### Map 표시 룰 ([`MissionPlay.m:2097-2110`](Classes/MissionPlay.m#L2097-L2110))
```objc
if([itemType isEqualToString:I_MINE] && endYN == "N") {
    if (dicRnPTaken[I_RADAR_MINE] == nil) {
        imgFile = nil;          // 핀 숨김
        canShowCallout = NO;
    }
}
```
- **Mine Radar 보유 시에만 표시**:
  - 핀: 보임
  - `MKCircle` 빨간 40% 투명 원 (rangeAR 반경) ([`MissionPlay.m:906`](Classes/MissionPlay.m#L906))
- 미보유: 완전 숨김
- 폭발 후: 갈색 원 영구 표시

#### AR 표시 룰 ([`ARViewController.m:1228-1240`](Classes/ARViewController.m#L1228-L1240))
- `viewportContainsCoordinate:` 가 mine 분기에서 별도 처리:
  ```objc
  if([itemType isEqualToString:I_MINE]) {
      if (radialDistance <= rangeAR) {
          [caller mineBlast:item];   // 자동 폭발 트리거
          [self mapInfoUpdate:false];
      }
  }
  ```
  → mine 은 **AR 화면에 절대 그려지지 않음**. 단지 폭발 트리거 사이드 이펙트만
- minDistItem 후보 선정 ([`ARViewController.m:1506`](Classes/ARViewController.m#L1506)): `I_MINE` 명시 제외

#### 획득 트리거: **불가능**
- 사용자가 의도적으로 획득 못함 — 진입 시 자동 폭발이 곧 "처리"

#### 폭발 효과 ([`mineBlast:`](Classes/MissionPlay.m#L1263-L1480))
[§6](#6-지뢰-폭발--방어-룰) 참고

#### 알려진 예외
- **Pre-start 에서도 폭발**: `viewportContainsCoordinate:` 의 mine 분기는 missionStarted 검사 없음 → START 안 했어도 mine 진입 시 폭발 ([§9](#9-알려진-예외--엣지-케이스) 참고)
- **빌더에서 showType 변경 불가**: detail 화면 행 주석 처리. 첫 추가 시 picker 값만 저장됨
- **mineNoBomb (Defense, 61) 와 혼동 금지**: 둘 다 폭탄 모양 아이콘이지만 mineNoBomb 는 일반 아이템처럼 동작. SQL 에서도 `I_MINE` 단독 검사 — Swift 포트는 `ItemType.isMine` 로 둘 다 잡는 버그 있었음 (F-11)

---

### 3.9 Defense / mineNoBomb (61)

#### 빌더 룰
- `mandatory` 자동: `MANDATORY_N` ([`MissionBuilderDetail.m:444-447`](Classes/MissionBuilderDetail.m#L444-L447))
- `showType` 사용자 선택 (mine 과 다름)
- 일반 아이템처럼 detail 편집 가능

#### Map 표시 룰
- **일반 showType 분기** (mine 과 다름)
- mine 처럼 Mine Radar 검사 안 함

#### AR 표시 룰
- **일반 후보** — minDistItem 으로 선정 가능 ([`ARViewController.m:1506`](Classes/ARViewController.m#L1506) 의 명시 제외 목록에 `I_MINE_NOBOMB` 없음)

#### 획득 트리거 ([`getItem:745-789`](Classes/ARViewController.m#L745-L789))
- `itemGame == 0` → 흔들기/탭 즉시
- `itemGame > 0` → `playGame:` (미니게임)

#### 획득 효과
1. `MissionItemInPlay.endYN = "Y"` DB 저장
2. `dicRnPTaken[I_MINE_NOBOMB] = ableCnt` 갱신
3. `ItemRnPInPlay` insert/update — `ableCnt = 기존 + 1`
4. **누적 가능**: 여러 개 획득 시 ableCnt 가 누적
5. itemGetAlert 5 ("Defense Item acquired!")

#### 사용 룰 ([`mineBlast:1289-1320`](Classes/MissionPlay.m#L1289-L1320))
- mine 폭발 시 자동 사용
- `dicRnPTaken[I_MINE_NOBOMB].ableCnt > 0` 이면:
  1. ableCnt -= 1
  2. `ItemRnPInPlay.update`
  3. `dicRnPTaken` 다시 로드
  4. `blastAlert:0` ("Mine did not damage using Defense item")
  5. **mineBlast 함수 종료** (NO 반환 — 폭발 효과 적용 안 됨)
- ableCnt == 0 이면 정상 폭발 진행

#### 알려진 예외
- **mine 자신의 ableCnt 차감 후 mine 은?** mine 자체는 항상 `endYN = "Y"` 처리됨 ([`MissionPlay.m:1281-1283`](Classes/MissionPlay.m#L1281-L1283)) — Defense 사용 여부와 무관하게 mine 은 "처리됨"
- **selectLastAcquiredItem 에서 제외**: NOT IN ('55','61','50','42') — Defense 는 mine 폭발의 "최근 아이템" 후보 아님 (즉 Defense 가 가장 최근에 획득됐어도 mine 폭발 시 다른 아이템이 상실 대상)

---

### 3.10 Dark / Black (56)

#### 빌더 룰
- `mandatory` 자동: `MANDATORY_N`
- 빌더 detail 화면에서 itemType + rangeAR 만 노출 (mine 과 동일) ([`MissionBuilderDetail.m:469-485`](Classes/MissionBuilderDetail.m#L469-L485))
- showType 변경 불가 (행 주석 처리)

#### Map 표시 룰
- 검은색 30% 투명 `MKCircle` 으로 영역 표시
- 핀 아이콘은 **안 보임** (mine 과 비슷)
- **다크존 효과** ([`MissionPlay.m:2128-2157`](Classes/MissionPlay.m#L2128-L2157)):
  - 미획득 black 의 `rangeAR` 안에 있는 다른 아이템들 → `imgFile = nil` (지도에서 가려짐)
  - 예외: START 와 black 자신
  - black 획득 후 효과 해제 (가렸던 아이템 다시 표시)

#### AR 표시 룰
- **절대 그려지지 않음** ([`viewportContainsCoordinate:1228-1230`](Classes/ARViewController.m#L1228-L1230) `return NO`)
- minDistItem 후보 선정에서도 명시 제외 ([`ARViewController.m:1507`](Classes/ARViewController.m#L1507))

#### 획득 트리거: 사실상 부수효과
- AR 에서 획득 불가 (그려지지 않으니 흔들기/탭 대상 아님)
- Map 에서도 핀 없음 → 직접 탭 불가
- **실제로는** 다른 아이템 획득의 사이드 이펙트로 black 자신도 처리되거나 (구체 트리거 코드 없음 — 사실상 영구 존재)

#### 알려진 예외
- **black 자신은 다른 black 의 다크존 안에 있어도 안 가려짐**: [`MissionPlay.m:2141-2145`](Classes/MissionPlay.m#L2141-L2145) `if (itemType == I_BLACK) break;` — 즉 다크존 영역 안의 다른 다크존은 그대로 표시
- **다크존 안의 mine**: 마찬가지로 `imgFile = nil` 처리되지만 mine 은 어차피 Mine Radar 없으면 안 보이므로 영향 미미
- **end 가 다크존 안에 있을 경우**: end 의 `mandatoryRemaining > 1` 검사가 먼저 → end 안 보임. 다크존 검사는 적용되지만 결과 동일
- 빌더에서 black 의 효과 / 획득 방법이 명확히 정의되지 않음 (디자인 미완성 의심)

---

### 3.11 Gambling / Random (50)

#### 빌더 룰
- `mandatory` 사용자 선택 (대다수 N)
- `showType` 사용자 선택

#### Map / AR 표시 룰
- 일반 showType 분기

#### 획득 트리거
- 흔들기/탭 즉시 획득

#### 획득 효과 ([`getItem:`](Classes/ARViewController.m#L543) 내 random 분기)
1. `MissionItemInPlay.endYN = "Y"` DB 저장
2. `dicItemEnd[itemID] = "Y"`
3. `selectRand:` 로 미보유 아이템 풀 조회 ([`MissionItemInPlayDao.m:289-328`](Classes/Dao/MissionItemInPlayDao.m#L289-L328)):
   ```sql
   SELECT B.* FROM MISSIONITEMINPLAY A, MISSIONITEM B
   WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID
     AND A.itemID = B.itemID AND A.EndYN = 'N'
     AND B.itemType NOT IN ('48','50','56')
   ```
   → End / Random / Black 제외, 미보유만
4. `arc4random_uniform(count)` 으로 랜덤 1개 선택
5. **재귀 acquireItem**: 선택된 아이템도 정상 획득 효과 발동 (Quiz 면 자동 정답 처리?)
6. 시각 효과 `randAni` (180°/2초 회전 + 페이드아웃, 4초 후 자동 제거)
7. 사운드: `s_winsomething.wav`

#### 알려진 예외
- **재귀 호출**: 만약 랜덤으로 선택된 게 또 Random 이면? SQL 의 NOT IN 으로 제외됐으니 절대 일어나지 않음
- **미보유 풀이 비면**: `selectRand:` 가 nil 반환 → 추가 획득 없음 (Random 자신만 획득)
- **Random 으로 Quiz 가 선택되면?** 자동 정답 처리 (퀴즈 시트 안 띄우고 endYN = "Y" 직접 set) — 사실상 무료 정답
- **Random 으로 Run Start 가 선택되면?** 타임어택이 자동 시작됨 (의외의 사이드 이펙트)
- **Random 의 randomItem 이 또 Random 효과를 일으킬 수 있나?** 위 NOT IN 절로 차단

---

### 3.12 Solution (52)

#### 빌더 룰 / Map / AR 표시: 일반 분기

#### 획득 효과
1. `MissionItemInPlay.endYN = "Y"` DB 저장
2. `ItemRnPInPlay` insert/update — `ableCnt = 기존 + 1` (누적)
3. `dicRnPTaken[I_SOLUTION] = ableCnt` 갱신
4. itemGetAlert ("Solution Item acquired!")

#### 사용 룰 ([`QuizPlayAlert.m:156-184`](Classes/QuizPlayAlert.m#L156-L184))
- **우선순위**: `dicRnPTaken[I_SOLUTION].ableCnt > 0` 먼저 사용
- 없으면 `APPDEL.solutionCount` (IAP 잔고)
- 둘 다 0 이면 IAP `solution_add_10` 구매 유도
- 사용 시:
  - `ableCnt -= 1` 또는 `solutionCount -= 1`
  - 정답 자동 입력
  - `solutionButton.hidden = TRUE` (재사용 차단)

#### 알려진 예외
- **누적 가능** (Solution 여러 개 획득 시 합산)
- **End 의 미션 퀴즈에도 사용 가능**: Quiz 와 End (퀴즈 있음) 둘 다 적용
- IAP 잔고는 NSUserDefaults `solution` 키에 영구 저장 (앱 재설치 외엔 유지)

---

### 3.13 Map Radar (66)

#### 빌더 룰 / Map / AR 표시: 일반 분기

#### 획득 효과
1. `dicRnPTaken[I_RADAR_MAP] = ableCnt` (사실상 boolean — 누적 의미 없음, 1번만 영향)
2. `ItemRnPInPlay` 저장
3. **즉시 효과**: Hidden(`SHOW_AR=2`) / Transparent(`SHOW_TRANSPARENT=1`) 아이템이 지도에 표시
4. 사운드: `s_radar.mp3`
5. itemGetAlert ("Map Radar Item acquired!")

#### 알려진 예외
- 한 번 획득하면 영구 효과
- 빌더 검증: Stealth 아이템 있을 때 Stealth Radar 1개 이상 필수 (Map Radar 와는 별개)

---

### 3.14 Stealth Radar / radarAR (65)

#### 획득 효과
1. `dicRnPTaken[I_RADAR_AR] = ableCnt` (boolean)
2. **즉시 효과**: Stealth(`SHOW_MAP=3`) / Transparent(`SHOW_TRANSPARENT=1`) 아이템이 AR 정보 (라벨 + 화살표) 정상 표시
3. AR 의 ar_clear1/ar_clear2 안내 문구 → 정상 정보 라벨로 전환
4. radianItem/radianPhone 화살표 다시 추가

#### 표시 변화 (radar 미보유 → 보유) ([`ARViewController.m:1639-1651`](Classes/ARViewController.m#L1639-L1651))
```objc
[ar_infoView setTitle:[NSString stringWithFormat:@"%@:%.0fm", typeLabel, radialDistance]];
[ar_infoView1 setTitle:[NSString stringWithFormat:@"%@:%dm", "Visible range", rangeAR]];
[ar_overlayView addSubview:radianPhone];
[ar_overlayView addSubview:radianItem];
```

#### 알려진 예외
- **레거시 특이점**: Stealth 아이템의 AR 아이콘 자체는 radar 없어도 그려짐. 차단되는 건 **하단 정보 라벨과 레이더 화살표만**. "근처에 뭔가 있다" 는 보이지만 "정확히 무엇/어디" 는 막는 디자인

---

### 3.15 All Radar (67) — 빌더 미노출

#### 효과
- `dicRnPTaken[I_RADAR_ALL]` 등록 시 Map Radar + Stealth Radar 동시 효과
- 모든 가시성 분기에서 `radarMap || radarAll` / `radarAR || radarAll` OR 검사로 처리

#### 알려진 예외
- 빌더에서 선택 불가 (`itemTypeKeys` 미포함)
- 서버 데이터에서만 등장 가능

---

### 3.16 Mine Radar (68)

#### 획득 효과
1. `dicRnPTaken[I_RADAR_MINE] = ableCnt`
2. **즉시 효과**: 모든 미획득 mine 의 `MKCircle` 빨간 원 + 핀이 지도에 표시
3. 사운드: `s_radar.mp3`
4. itemGetAlert ("Mine Radar Item acquired!")

#### 알려진 예외
- mineNoBomb (Defense) 의 가시성에는 영향 없음 (애초에 일반 분기로 처리)

---

### 3.17 Coupon (59)

#### Map / AR / 획득: 일반 분기
- `info` 가 쿠폰 코드/내용
- 별도 효과 없음 (단순 획득 + info 표시)

---

### 3.18 Store (91)

#### Map / AR / 획득: 일반 분기
- `info` 가 상품 정보
- 향후 IAP 연동 가능 구조 (현재 미구현)

---

### 3.19 기타 미사용 (00~10, 54, 69)

| 코드 | 매크로 | 상태 |
|---|---|---|
| `00`~`09` | `I_NUM00`~`I_NUM09` | 정의만, 미사용 |
| `10` | `I_ALPHABET` | 정의만, 미사용 |
| `54` | `I_PENALTY_REMOVE` | 정의만, "퀴즈 페널티 초기화" 의도 추정 |
| `69` | `I_RADAR_BLACK` | [`MissionBuilderDetail.m:523`](Classes/MissionBuilderDetail.m#L523) 에 분기만 있고 "현재 구현 안됨" 주석 |

---

## 4. 퀴즈 / 미니게임 룰

### 4.1 퀴즈 알림 시퀀스 ([`QuizPlayAlert`](Classes/QuizPlayAlert.m))

```
playQuiz: → QuizPlayAlert init
  → questionView 에 quiz 표시
  → failCnt > 0 이면 hintLabel 에 글자수 / 첫 글자 힌트
  → solutionButton 표시
사용자 정답 입력:
  → submitClick → answerField vs answer (lowercase 비교)
  → 정답: ALERT_SUCCESS → endYN = "Y" + 사운드 + dismiss
  → 오답: ALERT_FAIL → failCnt++ + 사운드 + 두 가지 옵션 alert
    → 옵션 0 (취소): dismiss (다시 시도 가능)
    → 옵션 1 (재시도): failQuiz → 새 quizSeq 다시 출제
사용자 Solution 사용:
  → solutionSelect → ALERT_SOLUTION 또는 ALERT_SOLUTION_ITEM
  → ableCnt 또는 solutionCount 차감 + 정답 자동 입력
```

### 4.2 미니게임 알림 시퀀스 ([`GamePlayAlert`](Classes/GamePlayAlert.m))

```
playGame: → GamePlayAlert init
  → type = arc4random()%2 (0=터치, 1=흔들기)
  → level = aItem.itemGame
  → progressView 표시 (300x300)
  → timeCount = 0
  → 1초마다 timeCount-- (decay)

if type == 0 (터치):
  → 사용자 터치마다: timeCount += 가산값 (level 별)
if type == 1 (흔들기):
  → 가속도 1.4G 초과 시: timeCount += 가산값

if timeCount >= 100: 클리어 → endYN = "Y"
if timeCount <= 0: 실패 → 재시도 또는 dismiss
```

### 4.3 미니게임 가산값 매트릭스

| `itemGame` | 라벨 (en) | 터치 +/click | 흔들기 +/shake |
|:---:|---|---:|---:|
| 0 | None (미니게임 없음) | — | — |
| 1 | Beginer Level | +6 | +7 |
| 2 | Normal Level | +5 | +6 |
| 3 | Senior Level | +4 | +5 |
| (그 외) | (디폴트) | +7 | +8 |

### 4.4 알려진 예외

- **type 이 매번 랜덤** → 같은 아이템 재시도 시 터치/흔들기 모드가 바뀔 수 있음 (사용자 혼란)
- **failCnt 무제한 누적** — 영구 페널티 아님, 재시도 가능
- **답안 trim 안 함** — 공백 입력 시 오답
- **case-insensitive 만 적용** — 한글 정규화 없음

---

## 5. 타임어택 (Run) 룰

### 5.1 타이머 시작 ([`MissionPlay.m:870-885`](Classes/MissionPlay.m#L870-L885))

Run Start 획득 시:
```
caller.timeOutStartTime = [NSDate date]
caller.isTimeOutS = item.itemID
caller.timeOutLimitTime = endItem.effectiveTime  // 짝 Run End 의 effectiveTime
[timeOutView setHidden:FALSE]
```

### 5.2 카운트다운 ([`MissionPlay.m:742-787`](Classes/MissionPlay.m#L742-L787))

`updatePassedTime:` 가 1초마다 호출. `isTimeOutS > 0` 이면:
- `interval = [NSDate date - timeOutStartTime]`
- `seconds = round(timeOutLimitTime - interval)`
- `timeOutView` (SBTickerView 6자리) 갱신:
  - HH:MM:SS 분리하여 각 자리 flip
  - 일반: 빨간 배경 (RGBA 200,0,0,1)
  - 100초 미만: 더 진한 빨강
  - 10초 미만: sound `s_timer.mp3` 경고

### 5.3 Run End 정상 도달

- `isTimeOutS = 0`, `isTimeOutE = 0`
- `timeOutLimitTime = 0`
- `timeOutStartTime = nil`
- `[timeOutView setHidden:TRUE]`
- `RunPassTime = sec2timeFormat(interval)` (기록 시간)

### 5.4 시간 초과 처리 ([`MissionPlay.m:764-787`](Classes/MissionPlay.m#L764-L787))

```objc
if(self.timeOutLimitTime < interval) {
    self.isTimeOutS = 0;
    [self finishRunTimeAlert];
}
```

`finishRunTimeAlert` ([`MissionPlay.m:1513`](Classes/MissionPlay.m#L1513)):
- sound: `s_timeover.mp3`
- alert "Run Time Out" + `obtain_run_record_fail` (시간 표시)
- **자동 페널티는 없음** — 사용자가 다시 Run Start 획득 가능 (재시작)

### 5.5 mine 폭발 시 강제 취소 ([`MissionPlay.m:1328-1342`](Classes/MissionPlay.m#L1328-L1342))

mine 폭발이 일어나고 활성 타임어택이 있으면:
```objc
if (isTimeOutS > 0) {
    self.timeOutStartTime = nil;
    self.isTimeOutS = 0;
    self.isTimeOutE = 0;
    [timeOutView setHidden:TRUE];
    [self.playTimeView setHidden:FALSE];
    [self blastAlert:1 key:I_TIMEOUT_S];   // "타임어택 취소" 알림
}
```

### 5.6 알려진 예외

- **이어하기 시 시간 보정 없음**: setupPlay 가 `timeOutStartTime = lastSavedTime` 으로 복원하면 앱 종료 시간만큼 이미 흘러간 것으로 계산됨 → 시간 초과 즉시 finishRunTimeAlert 가능
- **여러 Run Start 가 있는 미션**: 동시에 2개 활성 불가 (`isTimeOutS > 0` 일 때 추가 Run Start 후보 제외)

---

## 6. 지뢰 폭발 / 방어 룰

### 6.1 폭발 트리거 조건

플레이어 위치가 미획득 mine 의 `rangeAR` 안에 진입 시 자동 발동:
- **AR 화면**: [`viewportContainsCoordinate:1232-1240`](Classes/ARViewController.m#L1232-L1240) 의 mine 분기
- **Map 화면**: [`MissionPlay.m:1469`](Classes/MissionPlay.m#L1469) 의 `[newLocation distanceFromLocation:itemLoc] <= rangeAR`

### 6.2 폭발 처리 흐름 ([`mineBlast:`](Classes/MissionPlay.m#L1263-L1480))

```
1. missionCompleted 면 NO 반환 (이미 종료된 미션)
2. mine 의 endYN 이 이미 "Y" 면 NO 반환 (중복 방지)
3. 진동 + sound s_explosion.mp3
4. mine.endYN = "Y", endTime = 현재 DB 저장
5. dicItemEnd[mineID] = "Y"
6. Defense 검사:
   if dicRnPTaken[I_MINE_NOBOMB].ableCnt > 0:
     → ableCnt -= 1
     → ItemRnPInPlay update
     → dicRnPTaken 다시 로드
     → blastAlert:0 ("Defense 사용")
     → return NO   ← 폭발 효과 적용 안 됨
7. selectLastAcquiredItem 로 최근 획득 아이템 1개 조회 (조건: NOT IN ('55','61','50','42'))
8. 활성 타임어택 있으면 강제 취소 + blastAlert:1 (key:I_TIMEOUT_S)
9. 최근 획득 아이템 있으면:
   - lastItem.endYN = "N", endTime = nil DB 저장
   - dicItemEnd[lastItemID] = "N"
   - lastItem 이 START 면 MissionInPlay.startYN = "N", startTime = nil 도 복원
     → caller.missionStarted = NO 로 복귀
   - blastAlert:2 (lastItem 이름 표시)
10. 지도/오버레이 강제 갱신
```

### 6.3 selectLastAcquiredItem 룰 ([`MissionItemInPlayDao.m:85-115`](Classes/Dao/MissionItemInPlayDao.m#L85-L115))

```sql
SELECT itemplay.* FROM MissionItemInPlay itemplay
INNER JOIN MissionItem I 
  ON itemplay.missionID = I.missionID AND itemplay.itemID = I.itemID
WHERE itemplay.missionID=? AND itemplay.playerID=?
  AND I.itemType NOT IN ('55','61','50','42')   -- Mine, Defense, Random, RunStart 제외
  AND itemplay.endYN = 'Y'
  AND itemplay.itemID <> ?                       -- 폭발한 mine 자신 제외
ORDER BY itemplay.endTime DESC
LIMIT 1
```

→ "최근에 먹은 아이템" 후보:
- ✓ Start, End, Hint, Quiz, Solution, Defense ← 잠깐 Defense 는 NOT IN 에 있음 ('61'). 즉 Defense 는 제외
- ✗ Mine (자기), Defense, Random, Run Start

> 의도: 자동 발동 / 자동 획득 / 위험 카테고리는 "사용자가 의식적으로 획득한" 게 아니므로 상실 후보에서 제외

### 6.4 폭발 알림 종류 (`blastAlert:`)

| key | 의미 |
|:---:|---|
| 0 | "Defense 로 방어됨" |
| 1, key=I_TIMEOUT_S | "타임어택 취소됨" |
| 2 | "최근 획득 X 상실됨" |
| 기본 | "지뢰 폭발!" (상실 아이템 없을 때) |

### 6.5 알려진 예외

- **상실 아이템 없을 때**: `selectLastAcquiredItem` 이 nil 반환 (예: pre-start 에서 mine 폭발) → 단순 "지뢰 폭발!" 알림만, 데미지 없음
- **START 가 상실되면**: `missionStarted = NO` 로 복귀 → 다시 START 부터 획득해야 함 (사실상 미션 재시작)
- **연쇄 폭발 가능**: 하나의 mine 폭발 후 사용자 위치 변동 없이 다른 mine 의 rangeAR 안에 있으면 연속 폭발 (각각 처리)
- **Defense 가 0 인데 dicRnPTaken[I_MINE_NOBOMB] 키는 존재**: `valueForKey:` 가 NSNumber(0) 반환 → `intValue == 0` → 정상 폭발 진행

---

## 7. 가시성 룰 (Map / AR / 레이더)

### 7.1 ShowType × Radar 매트릭스 (Post-start, mine/black 제외)

#### Map

| `showType` | 레이더 없음 | radarMap | radarAll |
|:---:|:---:|:---:|:---:|
| `4` Normal | ✓ | ✓ | ✓ |
| `2` Hidden (arOnly) | ✗ | ✓ | ✓ |
| `3` Stealth (mapOnly) | ✓ | ✓ | ✓ |
| `1` Transparent | ✗ | ✓ | ✓ |

#### AR (아이콘 그려짐 / 정보 라벨 차단)

| `showType` | 레이더 없음 | radarAR | radarAll |
|:---:|---|---|---|
| `4` Normal | ✓ 아이콘 + 정보 | ✓ | ✓ |
| `2` Hidden (arOnly) | ✓ 아이콘 + 정보 | ✓ | ✓ |
| `3` Stealth (mapOnly) | 아이콘 보임 / 정보·화살표 차단 | ✓ | ✓ |
| `1` Transparent | 아이콘 보임 / 정보·화살표 차단 | ✓ | ✓ |

### 7.2 우선순위 (먼저 검사되는 조건이 나중을 덮어씀)

#### Map ([`MissionPlay.m updateMap` / 핀 그리기 분기](Classes/MissionPlay.m))

```
1. !missionStarted && itemType != I_START → imgFile = nil (가림)
2. itemType == I_END && mandatory.text > 1 → imgFile = nil
3. itemType == I_MINE && !radarMine → imgFile = nil
4. (transparent || arOnly) && !radarMap && !radarAll → imgFile = nil
5. 다크존 안에 있고 itemType != I_START && itemType != I_BLACK → imgFile = nil
```

#### AR (minDistItem 후보 선정)

```
1. !missionStarted → only I_START 후보 (else if 분기)
2. dicItemEnd[id] == "Y" → 후보 제외
3. itemType == I_MINE → 후보 제외 (단 폭발 트리거)
4. itemType == I_BLACK → 후보 제외
5. itemType == I_TIMEOUT_S && isTimeOutS > 0 → 후보 제외
6. itemType == I_END && mandatory.text > 1 → 후보 제외
   (showType 검사는 후보 단계엔 없음 — 그리기 단계에서 정보 라벨만 차단)
```

#### AR (그리기 단계, viewport 검사)

```
viewportContainsCoordinate:
  1. radialDistance > rangeAR → NO (거리 밖)
  2. dicItemEnd[id] == "Y" → NO
  3. !missionStarted && itemType != I_START && itemType != I_END → NO
  4. itemType == I_BLACK → NO
  5. itemType == I_MINE → 자동 mineBlast 트리거 후 (drawing은 NO)
  6. azimuth 가 viewport 내인가
  7. inclination 이 viewport 내인가
```

### 7.3 알려진 예외

- **viewport 검사 vs 후보 선정 분리**: minDistItem 은 viewport 검사 없이 잡힘 → 1km 떨어진 아이템도 minDistItem 가능. 화면에 안 그려질 뿐 하단 정보 라벨은 표시됨 (탐색 가이드)
- **showType 검사가 minDistItem 단계에 없음**: 코드에 주석 처리 ([`ARViewController.m:1512-1521`](Classes/ARViewController.m#L1512-L1521)). 의도된 디자인 — Stealth 도 후보로 잡되 그릴 때 정보만 차단

---

## 8. DB 트랜잭션 룰

### 8.1 setupPlay (`isNewStart == 1`) 시 삭제 순서

```
1. MissionItemInPlay DELETE WHERE missionID=? AND playerID=?
2. MissionInPlay DELETE WHERE missionID=? AND playerID=?
3. ItemRnPInPlay DELETE WHERE missionID=? AND playerID=?
```

### 8.2 새 MissionInPlay 생성

```
INSERT INTO MissionInPlay (missionID, playerID, startYN, startTime, endYN, endTime)
VALUES (?, ?, 'N' or 'Y', current or NULL, 'N', NULL)
```

`startYN = "Y"` 인 경우는 START 아이템이 미션에 없는 경우 (즉시 시작).

### 8.3 새 MissionItemInPlay (모든 아이템에 대해)

```
INSERT INTO MissionItemInPlay (missionID, playerID, itemID, endYN, failCnt, startTime, endTime, quizSeq)
VALUES (?, ?, ?, 'N', 0, NULL, NULL, 0)
```

### 8.4 획득 시 update

```
UPDATE MissionItemInPlay
SET endYN='Y', endTime=current, quizSeq=? (퀴즈인 경우)
WHERE missionID=? AND playerID=? AND itemID=?
```

### 8.5 mine 폭발 시 update (상실 아이템)

```
UPDATE MissionItemInPlay
SET endYN='N', endTime=NULL
WHERE missionID=? AND playerID=? AND itemID=?
```

### 8.6 ItemRnPInPlay 누적 / 차감

```
-- 누적 (radar/solution/defense 획득)
INSERT OR UPDATE ItemRnPInPlay (missionID, playerID, itemType, ableCnt, ableTime, acquiredTime)

-- 차감 (defense 사용, solution 사용)
UPDATE ItemRnPInPlay SET ableCnt = ableCnt - 1
WHERE missionID=? AND playerID=? AND itemType=?
```

### 8.7 알려진 예외

- **DELETE 순서**: 외래키 없으므로 순서 무관하지만 시각적 일관성 위해 위 순서 권장
- **Concurrent access**: SQLite + FMDB 는 단일 connection 시리얼 처리. 별도 lock 없음
- **트랜잭션 안 씀**: 각 INSERT/UPDATE 가 auto-commit. 중간 크래시 시 일부 커밋된 상태 가능

---

## 9. 알려진 예외 / 엣지 케이스

### 9.1 Pre-start 에서도 mine 폭발

`viewportContainsCoordinate:1232-1240` 의 mine 분기는 `missionStarted` 검사 없음. 따라서 START 안 했어도 mine 의 rangeAR 안에 진입하면 폭발. 단 `selectLastAcquiredItem` 이 nil 이라 데미지는 없음.

### 9.2 Random 으로 Quiz 획득

Random 효과로 Quiz 가 선택되면 `getItem:` 의 재귀 호출이 발동되며 **자동 정답 처리** 됨 (퀴즈 시트 안 띄움). `endYN = "Y"` 직접 set. 사실상 "무료 정답" 효과.

### 9.3 Random 으로 Run Start 획득

`getItem:` 의 Run Start 분기로 자동 진입 → 타임어택 즉시 시작. 의도치 않은 사이드 이펙트 가능.

### 9.4 START 가 mine 으로 상실

START 가 `selectLastAcquiredItem` 후보에 포함됨. mine 폭발 시 START 가 가장 최근 획득이면 상실 → `missionStarted = NO` 로 복귀. 사용자는 다시 START 부터 획득해야 하지만 모든 다른 진행도는 보존됨 (혼란 가능).

### 9.5 빌더에서 Quiz 의 itemQuizzes 가 비어있는 채로 저장

빌더 검증이 통과되었어도 (또는 검증 우회 시) Quiz 의 `itemQuizzes` 가 빈 배열이면 `arc4random() % 0` → undefined behavior (modulo by zero 크래시 가능).

### 9.6 Run Start 의 짝 Run End 가 없음

서버 데이터에서 `relationItemID` 짝이 깨질 수 있음. Run Start 획득 시 짝 Run End 못 찾으면 `endItem.effectiveTime` 가져올 수 없어 `timeOutLimitTime = 0` → 카운트다운 즉시 종료 → finishRunTimeAlert 즉시 발동.

### 9.7 Defense ableCnt 가 누적 후 폭발

Defense 를 3개 획득하면 `ableCnt = 3`. 3번의 mine 폭발까지 방어. 4번째 폭발 시 정상 데미지.

### 9.8 다크존 내 START

다크존 효과 코드에 `if itemType == I_START → break` 예외 분기 있음 ([`MissionPlay.m:2139`](Classes/MissionPlay.m#L2139)). 따라서 START 는 다크존 안에 있어도 항상 보임.

### 9.9 빌더 미노출 itemType 이 서버 데이터로 들어옴

`itemType` 이 `I_QUIZ20`, `I_RADAR_ALL`, `I_RADAR_BLACK`, `I_PENALTY_REMOVE`, `I_NUM*` 등 빌더 미노출 코드일 때:
- AR 의 `itemTypeFiles` lookup 시 `indexOfObject` 가 `NSNotFound` 반환 → `objectAtIndex:NSNotFound` 크래시 가능
- ar_infoView 의 라벨 lookup 도 동일 위험

### 9.10 시간대 / 날짜 처리

`endTime` 등은 `[NSDate date]` 로컬 시간. 서버 전송 시 timezone 처리 없음. 사용자가 비행기로 시간대 이동 시 통계 왜곡 가능.

### 9.11 Solution 사용 후 Quiz 재시도

`solutionButton.hidden = TRUE` 로 한 세션 내에서만 차단. Quiz 시트 닫고 다시 열면 다시 사용 가능 (의도된 동작인지 불명).

### 9.12 mine 의 mandatory == Y 인 경우

빌더는 mine 의 mandatory 를 N 으로 강제하지만 ([`MissionBuilderDetail.m:444-447`](Classes/MissionBuilderDetail.m#L444-L447)), 서버 데이터로 들어오면 mandatory=Y 일 수 있음. 이 경우 mine 은 사용자가 못 획득하니 미션 완료 불가능 (영구 데드락).

---

## 10. Swift 포트 동기화 체크리스트

신규 PlaySpot Swift 포트가 위 룰을 정확히 구현하는지 검증용 체크리스트.

### 10.1 게임 룰 구현 확인

- [x] START / END 미션 시작/종료 트리거
- [x] missionStarted 게이트 — pre-start 시 START 만 후보
- [x] END 등장 조건 — mandatoryRemaining > 1 검사
- [x] mine 자동 폭발 (AR 화면) — F-2
- [x] Defense 자동 사용 — `engine.handleMineBlast` 내부 분기
- [x] Defense AR 흔들기 획득 — F-3 (ItemType.isMine → == .mine)
- [x] Stealth/Hidden + radar 없음 → AR 안내 — F-4 (b)
- [x] 다크존 내 아이템 가리기 — F-7
- [x] AR 좌하단 라벨 — nearest 후보 정보 표시 — F-8
- [x] AR 라벨 viewport 무관성 — F-9
- [x] AR pitch 검사 제거 (평면 가정) — F-10
- [x] mine 빨간 원은 Mine Radar 보유 시에만 — F-11
- [x] SwiftUI Map Annotation filter 패턴 — F-12

### 10.2 미구현 / 의도적 생략

- [ ] Quiz failCnt 누적 페널티 (글자수 / 첫 글자 힌트)
- [ ] Solution 자동 정답 입력
- [ ] Run End 맥동 애니메이션
- [ ] Random 으로 획득한 아이템의 재귀 효과
- [ ] mine 폭발 후 갈색 원 영구 표시
- [ ] 빌더 (`MissionBuilder`) 전체
- [ ] StoreKit IAP (solution_add_10, time_add_10)
- [ ] 서버 통신 (RemoteDataSource 부분 구현, c_mission_play_* 미구현)

### 10.3 검증 시나리오

#### tutorial001 (튜토리얼 4 아이템)
- pre-start: Start 만 보임 ✓
- Start 획득 후: Quiz, Hint, End 표시
- Quiz 획득 후: Hint, End 표시
- Hint 획득 후: End 표시 (mandatoryRemaining ≤ 1)
- End 획득: 미션 완료

#### mine002 (지뢰 미션)
- pre-start: Start 만 보임
- Start 획득 후: Defense ✓ Map Radar ✓ Mine Radar ✓ Hint ✓ End — 모두 표시. **mine 빨간 원은 안 보임** ✓
- Mine Radar 획득: mine 빨간 원 등장
- Defense 획득: 다음 mine 폭발 시 자동 방어
- 모든 mandatory 획득 후 End 등장

#### dark004 (다크존 미션)
- Start 획득 후: black 검은 원 표시. 다크존 내 Stealth Hint 가려짐
- 사용자 black 영역 진입: AR 에 아무것도 안 보임 (black 후보 제외)
- Stealth Radar 획득: Hint AR 정보 정상 표시 + 화살표 복원
- 모든 mandatory 획득 후 End 등장

---

## 변경 이력

- **v1 (2026-05-15)**: 레거시 ObjC 시스템의 게임 룰을 아이템별 / 시스템별로 정밀 정리. mineBlast / Quiz / Run / 가시성 / DB 룰 + 12개 알려진 예외 + Swift 포트 동기화 체크리스트 포함.
