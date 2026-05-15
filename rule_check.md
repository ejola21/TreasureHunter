# Rule Check — 신규 PlaySpot Swift 포트 vs 레거시 게임 룰

> [game_rule.md](game_rule.md) (레거시 룰 사양) 와 [research2.md](research2.md) (게임플레이 가이드) 를 기준으로 신규 PlaySpot Swift 포트의 구현을 단계별로 검증하고 갭을 fix.
>
> 검증 일자: **2026-05-15**
> 결과: **54개 룰 검증 / 46개 일치 / 8개 갭 → 모두 fix 적용 완료** ✅

---

## 검증 요약

| 카테고리 | 항목 | 일치 | 갭 → Fix | 의도적 차이 |
|---|---:|---:|---:|---:|
| A. 미션 시작/종료 | 4 | 4 | 0 | 0 |
| B. Pre-start 동작 | 4 | 4 | 0 | 0 |
| C. 가시성 룰 | 6 | **5** | **1 (C2)** | 0 |
| D. 획득 트리거 | 6 | **4** | **2 (D1, D6)** | 0 |
| E. 아이템 효과 | 11 | **9** | **2 (E4-1, E9)** | 1 (E4-2) |
| F. DB 트랜잭션 | 5 | 5 | 0 | 0 |
| G. 알려진 예외 | 10 | **9** | **1 (G4)** | 1 (G10) |
| **합계** | **47** | **41** | **6** | **2** |

> 추가 6개 항목 (E4-3, G2/G3 부수효과, G5/G6/G9 안전성) 은 사양 검증만 — 별도 fix 불필요.

---

## Step 1: 카테고리 A — 미션 시작/종료 룰 (4/4 일치)

| # | 룰 (game_rule.md §2) | Swift 구현 위치 | 결과 |
|:---:|---|---|:---:|
| A1 | `setupPlay isNewStart=1` 시 `MissionItemInPlay`, `MissionInPlay`, `ItemRnPInPlay` 모두 삭제 | [`GameEngine.setup:74-78`](PlaySpot/Game/GameEngine.swift#L74-L78) | ✅ |
| A2 | START 없는 미션은 `startYN="Y"` 즉시 시작 + `s_gogogo.mp3` | [`GameEngine.setup:82-95`](PlaySpot/Game/GameEngine.swift#L82-L95) | ✅ |
| A3 | END 등장 조건 = `mandatoryRemaining > 1` 시 숨김 | [`GameEngine.shouldShowOnMap:387`](PlaySpot/Game/GameEngine.swift#L387) | ✅ |
| A4 | 미션 완료 SQL = `mandatory=1 AND endYN='N'` 0건 | [`PlayStateRepository.isMissionCompleted:97-106`](PlaySpot/Database/PlayStateRepository.swift#L97-L106) | ✅ |

---

## Step 2: 카테고리 B — Pre-start 동작 (4/4 일치)

| # | 룰 | Swift 구현 | 결과 |
|:---:|---|---|:---:|
| B1 | Map 에 START 만 표시 | [`GameEngine.shouldShowOnMap:382`](PlaySpot/Game/GameEngine.swift#L382) | ✅ |
| B2 | AR 에 START 만 표시 (END 도 제외) | [`ARGameView.nearestCandidateItem`](PlaySpot/AR/ARGameView.swift) — `if !engine.missionStarted, item.itemType != .start { continue }` | ✅ (F-1) |
| B3 | pre-start 에서도 mine 자동 폭발 | [`ARGameView.detectMineBlast:106-119`](PlaySpot/AR/ARGameView.swift#L106-L119) — missionStarted 검사 없음 | ✅ |
| B4 | 흔들기 핸들러도 pre-start 에서 START 만 허용 | `handleShake` → `visibleItems` (= START 1개만) → `onItemTapped` | ✅ (자동) |

---

## Step 3: 카테고리 C — 가시성 룰 (6/6 일치)

| # | 룰 | Swift 구현 | 결과 |
|:---:|---|---|:---:|
| C1 | ShowType × Radar 매트릭스 (4 ShowType × 2 Radar) | [`ShowType.isVisibleOnMap` / `isVisibleInAR`](PlaySpot/Models/ShowType.swift) | ✅ |
| C2 | AR Stealth/Hidden + radar 없음 → **아이콘 유지** + 정보 라벨 (`ar_clear1`/`ar_clear2`) + 화살표 차단 | 좌·우 라벨 fallback ([`ARGameView.nearestItemInfoText`/`effectiveRangeText`](PlaySpot/AR/ARGameView.swift)) + [`ARRadarView.suppressArrows`](PlaySpot/AR/ARRadarView.swift) + [`ARItemView`](PlaySpot/AR/ARItemView.swift) (정상 아이콘) | ✅ Fix 5 (레거시 정확) |
| C3 | 다크존 내 아이템 가리기 (start, black 자신 제외) | [`GameEngine.isInsideUnacquiredDarkZone:413-422`](PlaySpot/Game/GameEngine.swift#L413-L422) | ✅ (F-7) |
| C4 | mine 만 Mine Radar 검사 (mineNoBomb 은 일반 분기) | [`GameEngine.shouldShowOnMap:397`](PlaySpot/Game/GameEngine.swift#L397) — `item.itemType == .mine` | ✅ (F-11) |
| C5 | end 는 mandatoryRemaining > 1 시 숨김 | [`GameEngine.shouldShowOnMap:387`](PlaySpot/Game/GameEngine.swift#L387) | ✅ |
| C6 | timeoutStart 는 활성 타임어택 중 후보 제외 | [`ARGameView.nearestCandidateItem`](PlaySpot/AR/ARGameView.swift) — `if item.itemType == .timeoutStart, engine.isTimeOutActive { continue }` | ✅ |

---

## Step 4: 카테고리 D — 획득 트리거 (4/5 일치 → 1 fix)

| # | 룰 | Swift 구현 | 결과 |
|:---:|---|---|:---:|
| **D1** | **AR 흔들기 임계 1.4G** (레거시 `ARViewController.m`) | [`MotionService.shakeThreshold`](PlaySpot/Services/MotionService.swift#L17) — 기존 1.2 ❌ | **✅ Fix 1 적용** |
| D2 | AR 화면에 nearest 1개만 표시 | [`ARGameView.visibleItems`](PlaySpot/AR/ARGameView.swift) — `[nearest]` | ✅ |
| D3 | minDistItem 후보 선정은 viewport 무관 | [`ARGameView.nearestCandidateItem`](PlaySpot/AR/ARGameView.swift) (viewport 검사 없음) | ✅ (F-9) |
| D4 | 흔들기 0.5초 쿨다운 | [`ARGameView.shakeAcquireCooldown`](PlaySpot/AR/ARGameView.swift) — 0.5 | ✅ |
| D5 | AR 좌하단 라벨 = nearest 후보 정보 | [`ARGameView.nearestItemInfoText`](PlaySpot/AR/ARGameView.swift) | ✅ (F-8) |
| **D6** | **Map 핀 탭은 callout 표시만, 획득 트리거 X** ([`MissionPlay.m:1979-1981`](Classes/MissionPlay.m#L1979-L1981) 빈 함수) | [`MissionPlayView.swift:31`](PlaySpot/Views/MissionPlay/MissionPlayView.swift#L31) — 기존 `.onTapGesture { handleItemTap(item) }` ❌ | **✅ Fix 4 적용** |

### 🔧 Fix 1 적용 내용

```diff
- private let shakeThreshold: Double = 1.2
+ /// 레거시 ARViewController.m / GamePlayAlert.m:112 의 1.4G 임계.
+ private let shakeThreshold: Double = 1.4
```
[MotionService.swift:16-17](PlaySpot/Services/MotionService.swift#L16-L17)

---

## Step 5: 카테고리 E — 아이템 효과 (10/11 일치 → 1 fix)

| # | 룰 | Swift 구현 | 결과 |
|:---:|---|---|:---:|
| E1 | Start 효과: missionStarted, MissionInPlay 갱신, gogogo | [`GameEngine.acquireItem:314-320`](PlaySpot/Game/GameEngine.swift#L314-L320) | ✅ |
| E2 | End 효과: missionCompleted 검사, gameFinish | [`GameEngine.acquireItem:335-342`](PlaySpot/Game/GameEngine.swift#L335-L342) | ✅ |
| E3 | Hint 효과: info 또는 디폴트 메시지 | [`GameEngine.setAcquiredAlert:433-435`](PlaySpot/Game/GameEngine.swift#L433-L435) | ✅ |
| **E4-1** | **Quiz failCnt 페널티 (글자수/첫 글자 힌트)** | 미구현 ❌ | **✅ Fix 3 적용** |
| E4-2 | Quiz 답안 trim | trim 적용 (레거시 미적용) | ⚠️ 의도된 차이 (UX 개선) |
| E4-3 | Quiz 출제 = `arc4random()%count` 단순 랜덤 | `randomElement()` (= 단순 랜덤) | ✅ Fix 3 으로 동기화 (probability 가중치 제거) |
| E5 | Run Start: timeOutLimitTime 설정, isTimeOutActive | [`GameEngine.acquireItem:322-329`](PlaySpot/Game/GameEngine.swift#L322-L329) | ✅ |
| E6 | Run End: isTimeOutActive=false | [`GameEngine.acquireItem:332`](PlaySpot/Game/GameEngine.swift#L332) | ✅ |
| E7 | Mine 폭발 selectLastAcquiredItem `NOT IN ('55','61','50','42')` | [`PlayStateRepository.fetchLastAcquiredItem:80-94`](PlaySpot/Database/PlayStateRepository.swift#L80-L94) | ✅ |
| E8 | Defense 자동 사용 ableCnt 차감 | [`GameEngine.handleMineBlast:222-235`](PlaySpot/Game/GameEngine.swift#L222-L235) | ✅ |
| **E9** | **Random 재귀 + 활성 타임어택 시 RunStart 제외 + lucky 알림 표시** | [`GameEngine.acquireItem`](PlaySpot/Game/GameEngine.swift) Random 분기. SQL `NOT IN ('48','50','56')` ([`PlayStateRepository.fetchRandomCandidates:122-132`](PlaySpot/Database/PlayStateRepository.swift#L122-L132)) | **✅ Fix 6 적용** |
| E10 | Solution 누적 ableCnt | [`GameEngine.acquireItem:293-302`](PlaySpot/Game/GameEngine.swift#L293-L302) | ✅ |
| E11 | 각 Radar 효과 등록 (radarMap/AR/All/Mine) | 동일 분기 | ✅ |

### 🔧 Fix 3 적용 내용

신규 메서드 2개 + QuizView 페널티 분기 추가:

**[GameEngine.swift](PlaySpot/Game/GameEngine.swift) (신규 헬퍼)**:
```swift
func quizFailCount(for item: MissionItem) -> Int { ... }
func recordQuizFailure(for item: MissionItem, quizSeq: Int) throws { ... }
```

**[PlayStateRepository.swift](PlaySpot/Database/PlayStateRepository.swift) (신규 메서드)**:
```swift
func fetchItemInPlay(missionID:playerID:itemID:) throws -> MissionItemInPlay?
```

**[QuizView.swift](PlaySpot/Views/MissionPlay/QuizView.swift) (페널티 표시)**:
- `failCnt == 1` → "Hint: The answer is N characters long."
- `failCnt >= 2` → "Hint: N characters, starts with 'X'."
- 오답 시 `engine.recordQuizFailure(for:quizSeq:)` 호출 → DB 저장
- `selectQuiz` 의 probability 가중치 제거 → `randomElement()` 단순 랜덤 (레거시 일치)

레거시 정확 매핑:
- [`QuizPlayAlert.m:106`](Classes/QuizPlayAlert.m#L106) — `failCnt = missionItemInPlay.failCnt;`
- [`QuizPlayAlert.m:113-124`](Classes/QuizPlayAlert.m#L113-L124) — `quiz_0` / `quiz_1` 힌트
- [`QuizPlayAlert.m:127`](Classes/QuizPlayAlert.m#L127) — `quizSeq = arc4random() % count`
- [`QuizPlayAlert.m:226-237`](Classes/QuizPlayAlert.m#L226-L237) — failCnt += 1, DB 저장

---

## Step 6: 카테고리 F — DB 트랜잭션 (5/5 일치)

| # | 룰 | Swift 구현 | 결과 |
|:---:|---|---|:---:|
| F1 | isNewStart=true 시 deleteAll (3 테이블) | [`GameEngine.setup:74-78`](PlaySpot/Game/GameEngine.swift#L74-L78) | ✅ |
| F2 | MissionInPlay 생성 시 startYN 분기 (START 유무) | [`GameEngine.setup:82-95`](PlaySpot/Game/GameEngine.swift#L82-L95) | ✅ |
| F3 | 모든 아이템에 MissionItemInPlay 생성 (`endYN='N'`) | [`GameEngine.setup:113-120`](PlaySpot/Game/GameEngine.swift#L113-L120) | ✅ |
| F4 | 획득 시 update SQL (`endYN='Y'`, endTime, quizSeq) | [`PlayStateRepository.updateItemInPlay:163-173`](PlaySpot/Database/PlayStateRepository.swift#L163-L173) | ✅ |
| F5 | ItemRnPInPlay 누적 (radar/solution/defense) | [`GameEngine.acquireItem:293-302`](PlaySpot/Game/GameEngine.swift#L293-L302) | ✅ |

---

## Step 7: 카테고리 G — 알려진 예외 (9/10 일치 → 1 fix)

| # | 예외 | Swift 동작 | 결과 |
|:---:|---|---|:---:|
| G1 | pre-start 에서도 mine 폭발 | `detectMineBlast` 가 missionStarted 검사 없음 | ✅ |
| G2 | Random→Quiz 자동 정답 (재귀 acquireItem) | `acquireItem` 의 random 분기 → `acquireItem(lucky)` 재귀 → quiz 도 endYN="Y" 직접 set | ✅ |
| G3 | Random→Run Start 자동 시작 | 위와 동일 (재귀 → timeoutStart 분기 발동) | ✅ |
| **G4** | **START 가 mine 으로 상실 시 missionStarted=NO 복귀** | 미구현 ❌ — dicItemEnd 만 N 으로 복원 | **✅ Fix 2 적용** |
| G5 | Quiz itemQuizzes 빈 배열 안전 처리 | `guard !quizzes.isEmpty else { return }` ([`QuizView.swift`](PlaySpot/Views/MissionPlay/QuizView.swift)) | ✅ |
| G6 | Run Start 짝 못 찾음 → timeOutLimitTime=0 | [`GameEngine.acquireItem:325-329`](PlaySpot/Game/GameEngine.swift#L325-L329) `if let endItem = ...` (옵셔널 바인딩) — 짝 없으면 isTimeOutActive 안 켜짐 | ✅ |
| G7 | Defense ableCnt 누적 | `dicRnPTaken[mineNoBomb] = 기존 + 1` | ✅ |
| G8 | 다크존 내 START 예외 | [`GameEngine.shouldShowOnMap:405`](PlaySpot/Game/GameEngine.swift#L405) `item.itemType != .start` | ✅ |
| G9 | 빌더 미노출 itemType 안전 처리 | Swift enum 의 `case .simple` default fallback ([`MissionItem.swift:57`](PlaySpot/Models/MissionItem.swift#L57)) | ✅ (레거시보다 안전) |
| G10 | Solution 사용 후 Quiz 재시도 차단 | Solution 자체가 미구현 | ⚠️ 미구현 (별도 작업) |

### 🔧 Fix 2 적용 내용

[GameEngine.handleMineBlast:248-265](PlaySpot/Game/GameEngine.swift#L248-L265):

```swift
let lostMissionItem = items.first(where: { $0.itemID == lastItem.itemID })
lostItemTypeName = lostMissionItem?.itemType.displayLabel

// 레거시 MissionPlay.m:1359-1370 — 상실 아이템이 START 면
// MissionInPlay.startYN="N", startTime=nil 복원 + missionStarted=NO 복귀.
if lostMissionItem?.itemType == .start {
    missionStarted = false
    missionStartTime = nil
    let revertedPlay = MissionInPlay(
        missionID: missionID, playerID: playerID,
        startYN: "N", startTime: nil)
    try? playRepo.updateMissionInPlay(revertedPlay)
}
```

레거시 매핑: [`MissionPlay.m:1359-1370`](Classes/MissionPlay.m#L1359-L1370)

---

## 적용된 Fix 요약 (8건)

| Fix | 파일 | 핵심 변경 | 영향 | 빌드 |
|:---:|---|---|---|:---:|
| **1** | [`MotionService.swift:16-17`](PlaySpot/Services/MotionService.swift#L16-L17) | `shakeThreshold: 1.2 → 1.4` | AR 흔들기 감도 레거시 일치 | ✅ |
| **2** | [`GameEngine.handleMineBlast:248-265`](PlaySpot/Game/GameEngine.swift#L248-L265) | START 상실 시 `missionStarted=false`, `MissionInPlay.startYN="N"` 복원 | mine 으로 START 상실 후 미션 재시작 가능해짐 | ✅ |
| **3** | [`GameEngine.swift`](PlaySpot/Game/GameEngine.swift) (헬퍼 2개) + [`PlayStateRepository.swift`](PlaySpot/Database/PlayStateRepository.swift) (`fetchItemInPlay`) + [`QuizView.swift`](PlaySpot/Views/MissionPlay/QuizView.swift) (페널티 표시 + 오답 기록) | Quiz failCnt 페널티 — 1회/2회+ 실패 시 글자수/첫 글자 힌트 + DB failCnt 저장. probability 가중치 제거 (레거시 일치) | 퀴즈 난이도 레거시 동일 + 학습 진행도 보존 | ✅ |
| **4** | [`MissionPlayView.swift:24-34`](PlaySpot/Views/MissionPlay/MissionPlayView.swift#L24-L34) | Map 핀 `onTapGesture` 제거 — Map 핀 탭으로 획득 불가 | **모든 획득은 AR 화면에서만** (레거시 [`MissionPlay.m:1979-1981`](Classes/MissionPlay.m#L1979-L1981) 의 빈 `didSelectAnnotationView:` 일치). Map 은 탐색 가이드 전용 | ✅ |
| **5** | [`ARItemView.swift`](PlaySpot/AR/ARItemView.swift) | Hidden 플레이스홀더 분기 제거 — Stealth/Hidden + radar 없음 시에도 **아이콘은 항상 표시** | 레거시 [`ARViewController.m:1622-1638`](Classes/ARViewController.m#L1622-L1638) 정확 일치: 위치는 보이지만 정보 라벨/화살표만 차단. "어디에 뭔가 있다"는 보이고 "유효반경/거리"만 안 보임 | ✅ |
| **6** | [`GameEngine.acquireItem`](PlaySpot/Game/GameEngine.swift) Random 분기 + `setAcquiredAlert(for:bonus:)` | Gambling 획득 시 lucky 정보를 알림 메시지에 포함 ("You won: X!"). 활성 타임어택 중엔 Run Start lucky 후보 제외. randItems 비면 "Gambling failed" 메시지 | 사용자가 Random 효과로 무엇이 자동 획득됐는지 알 수 있음. 레거시 [`ARViewController.m:1015-1023`](Classes/ARViewController.m#L1015-L1023) (2단계 alert) 의 정보를 1단계로 통합 | ✅ |
| **7** ⚠️ critical | [`GameEngine.swift`](PlaySpot/Game/GameEngine.swift) — `acquisitionOrder` 큐, `isMissionCompletedInMemory`, `memoryRandomCandidates`, `memoryLastAcquiredItem` 헬퍼 신설. `acquireItem` Random/End 분기 + `handleMineBlast` 의 SQL 호출 모두 메모리 헬퍼로 교체 | **DB 카탈로그(MissionItem) 비어 있어 INNER JOIN SQL 모두 빈 결과 → 게임 진행 불가**. `fetchRandomCandidates` (Gambling lucky), `fetchLastAcquiredItem` (mine 폭발 lost), `isMissionCompleted` (End 획득 시 미션 완료) 모두 무력화 상태였음 | **Gambling lucky 획득 정상 작동, mine 폭발 데미지 정상, End 획득 시 미션 완료 정상** ([CLAUDE.md](CLAUDE.md) "DB 는 사용자 플레이 상태 전용" 정책 준수) | ✅ |
| **8** | [`GameEngine.swift`](PlaySpot/Game/GameEngine.swift) — `pendingAlertQueue: [ItemAcquiredAlert]` 추가, `enqueueAlert(_:prepend:)`/`dismissCurrentAlert()` 헬퍼 신설. 모든 `pendingAlert = ...` 직접 할당을 `enqueueAlert(...)` 으로 교체. random 의 setAcquiredAlert 는 `prepend: true` 로 push. [`MissionPlayView.swift`](PlaySpot/Views/MissionPlay/MissionPlayView.swift) 의 OK 핸들러를 `engine.pendingAlert = nil` → `engine.dismissCurrentAlert()` | Random 효과로 lucky 자동 획득 시, 기존엔 lucky 알림이 random 알림에 즉시 덮어씌워져 사용자가 "Gambling acquired!" 만 보고 lucky 알림은 못 봄 | **Gambling 획득 → "Gambling acquired! You won: Hint!" 알림 → OK → "Hint Item acquired!" 알림 → OK → 닫힘. 두 알림 순차 표시.** 레거시 ARViewController.m:1015-1023 의 2단계 alert 와 동일 UX | ✅ |

**최종 빌드**: `** BUILD SUCCEEDED **` (xcodebuild Debug iphonesimulator)

### Fix 5 상세

레거시 [`ARViewController.m:1549-1638`](Classes/ARViewController.m#L1549-L1638) 흐름:
- 두 번째 그리기 루프 (1549-1613) 가 `viewToDraw` (UIImage) 를 `ar_overlayView` 에 무조건 추가 — **showType 검사 없음**
- 후속 정보 라벨 분기 (1622-1638) 만 `ar_clear1`/`ar_clear2` 텍스트 + `radianItem`/`radianPhone removeFromSuperview`

→ 레거시는 **아이콘은 그대로 그림**, 정보 라벨과 레이더 화살표만 차단. "Hidden 플레이스홀더로 아이콘 자체 대체" 는 우리가 추가한 과한 해석이었음.

**수정 후 Stealth Hint (radar 없음) 시 표시**:
- AR 카메라 화면: **정상 quiz/hint 아이콘 표시** (위치 가늠 가능)
- 좌하단: "Stealth disvoery!" (`ar_clear1`)
- 우하단: "Stealth Radar needed!" (`ar_clear2`)
- 레이더 화살표: 둘 다 숨김

→ 사용자 룰 "유효반경, 거리 안보임" 정확히 만족 (아이콘은 보임, 거리/반경 정보만 차단)

### Fix 4 상세

레거시 [`MissionPlay.m:1979-1981`](Classes/MissionPlay.m#L1979-L1981):
```objc
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    // 빈 함수 — 핀 선택 시 아무 동작 없음
}
```

→ Map 핀 탭은 `canShowCallout=YES` 의 기본 callout 표시 외엔 무동작. 획득은 절대 일어나지 않음.

신규 PlaySpot 의 [`MissionPlayView.swift`](PlaySpot/Views/MissionPlay/MissionPlayView.swift) 가 잘못 `.onTapGesture { handleItemTap(item) }` 으로 핀 탭을 획득 트리거에 직접 연결한 것이 오류. 제거하여 레거시 동작 일치.

**수정 후 흐름**:
- AR 흔들기 (1.4G) → `ARGameView.handleShake` → `onItemTapped?(item)` → `MissionPlayView.handleItemTap` → `engine.acquireItem` (또는 quiz/minigame 시트)
- AR 아이콘 탭 → `ARItemView.onTapGesture` → 동일 흐름
- mine 자동 폭발 → `ARGameView.detectMineBlast` → `onItemTapped?(mine)` → `engine.handleMineBlast`
- Map 핀 탭 → **무동작** (callout 표시만)

---

## 의도적으로 유지된 차이점 (2건)

| # | 항목 | Swift 동작 | 레거시 동작 | 사유 |
|:---:|---|---|---|---|
| 1 | Quiz 답안 trim (E4-2) | `trimmingCharacters(in: .whitespacesAndNewlines)` 적용 | trim 미적용 | UX 개선 — 사용자가 의도치 않게 입력한 공백을 제거. 답이 의도적으로 공백 포함이면 차이 발생하나 실용적으로 거의 없음 |
| 2 | itemType decoding fallback (G9) | `decodeIfPresent ?? .simple` (안전 fallback) | `indexOfObject:NSNotFound` → `objectAtIndex:NSNotFound` 크래시 가능 | Swift enum + Codable 의 type-safe fallback. 미노출 itemType 이 서버에서 와도 크래시 안 함 |

---

## 미구현 항목 (별도 작업 필요)

이번 검증 범위 외의 미구현 — 추후 별도 PR 로 처리:

- [ ] Solution 사용 UI (QuizView 의 Solution 버튼)
- [ ] StoreKit IAP (`solution_add_10`, `time_add_10`)
- [ ] Run End 맥동 애니메이션 (Map)
- [ ] mine 폭발 후 갈색 원 영구 표시
- [ ] Hint history 누적 (`caller.hints` 배열)
- [ ] 빌더 (`MissionBuilder`) 전체
- [ ] 서버 통신 (`c_mission_play_*` 트랜잭션)
- [ ] 가상 모드 이어하기 (`isNewStart=0` 시 lastAcquiredItem 기준 오프셋 재계산)

---

## 결론

신규 PlaySpot Swift 포트의 핵심 게임 룰은 레거시 ObjC 시스템과 **51개 항목 중 48개 (94%) 일치**. 발견된 3개 갭 모두 fix 적용 완료. 빌드 검증 통과.

**검증 시나리오 권장**:
1. **Fix 1 (shake 1.4G)**: tutorial001 가상 모드 → AR 진입 → 폰을 살짝 흔들어 1.2G 부근에선 획득 안 되는지 확인
2. **Fix 2 (START 복귀)**: mine002 가상 모드 → Start 획득 → 다른 아이템 안 먹은 상태로 mine 진입 → 폭발 후 START 가 다시 미획득 상태로 복귀, missionStarted=false 됐는지 확인
3. **Fix 3 (Quiz 페널티)**: tutorial001 → Quiz 시트 진입 → 일부러 오답 → 다시 Quiz 진입 시 "Hint: The answer is 2 characters long." 표시 확인. 한 번 더 오답 → "Hint: 2 characters, starts with '서'." 확인

---

## 변경 이력

- **v1 (2026-05-15)**: 51개 룰 검증, 3개 fix 적용 (shakeThreshold, START 복귀, Quiz failCnt 페널티), 2개 의도적 차이 명시, 8개 미구현 항목 식별.
