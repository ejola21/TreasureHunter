# test_flutter_playspot.md — flutter_ar_spike ↔ SwiftUI PlaySpot 동등성 검증 매트릭스

이 문서의 검증 기준은 **단 하나**: *기존 SwiftUI PlaySpot 과 디자인·기능이 똑같은가*.
모든 케이스는 SwiftUI 소스 `file:line` 을 권위 있는 정답(ground truth)으로 인용한다.
헷갈리면 추측하지 말고 그 파일을 다시 읽는다.

---

## §0. 검증 인프라

### 0-1. 단계별 자동화 레이어 (강한 → 약한 ROI 순)

| 레이어 | 도구 | 잡는 것 | 안 잡는 것 |
|---|---|---|---|
| **A. 단위 테스트** | `flutter test test/game_engine_test.dart` | GameEngine 상태 머신 (완료 게이트, 마인 손실, Defense, dark zone, run 타임아웃) | UI, 사운드, 센서 |
| **B. Golden 테스트** | `flutter test test/golden/` | 위젯 픽셀 회귀 (HUD, painter, 팝업, 오버레이 레이아웃) | 인터랙션 |
| **C. 위젯 테스트** | `flutter test test/widget/` | 인터랙션 + 상태 변화 (탭 → 팝업, 핫스팟, 미니게임 진행) | 카메라/센서/사운드 |
| **D. 웹 헤드리스 스크린샷** | `scripts/screenshot_web.sh` | 전체 앱 컴포지션, 라우팅, 폰트 로딩 | 모바일 전용(카메라/나침반/센서) |
| **E. 실기기** | iOS 시뮬레이터 + Android 실기기 | 사운드, 햅틱, 카메라 피드, 흔들기, 나침반, GPS | — |

### 0-2. 실행 명령

```bash
cd flutter_ar_spike

# A. 단위 (현재 7케이스 → 미션 완료/지뢰/Defense/dark/timeout)
flutter test test/game_engine_test.dart

# B. Golden (첫 생성)
flutter test --update-goldens test/golden/
# B. Golden (회귀 검증)
flutter test test/golden/

# C. 위젯 + 인터랙션
flutter test test/widget/

# A + B + C 한 번에
flutter test

# D. 웹 스크린샷 (Playwright 필요: npm i -g playwright && playwright install chromium)
bash scripts/screenshot_web.sh
```

### 0-3. pre-push 후크 (선택)

`lefthook.yml`:
```yaml
pre-push:
  parallel: true
  commands:
    analyze: { run: cd flutter_ar_spike && flutter analyze }
    test:    { run: cd flutter_ar_spike && flutter test }
```
설치: `brew install lefthook && lefthook install`.

---

## §1. GameEngine 상태 머신 (이미 단위 테스트 7케이스로 고정됨)

**Ground truth**: [`PlaySpot/Game/GameEngine.swift`](PlaySpot/Game/GameEngine.swift)

이미 [`flutter_ar_spike/test/game_engine_test.dart`](flutter_ar_spike/test/game_engine_test.dart) 에 7케이스 고정.
회귀 시 `flutter test test/game_engine_test.dart` 가 빨개지면 GameEngine 이식 직전 커밋과 비교.

| # | 케이스 | SwiftUI 근거 |
|---|---|---|
| 1 | 완료는 모든 필수 아이템 획득 후 성립 | GameEngine.swift:493-499 |
| 2 | End 핀은 필수>1 남으면 지도 숨김 | GameEngine.swift `shouldShowOnMap` (mandatoryRemaining 분기) |
| 3 | 지뢰 폭발 → 최근 획득 1개 손실 | GameEngine.swift:358-380 |
| 4 | Defense(mineNoBomb) → 손실 흡수, count -1 | GameEngine.swift:343-355 |
| 5 | dark zone 내부 미획득은 지도 숨김 | GameEngine.swift `_isInsideUnacquiredDarkZone` |
| 6 | Run End는 Run Start 없으면 거부 | GameEngine.swift `acquireItem` timeoutEnd pre-check |
| 7 | Run Start → 타임아웃 활성, 짝 Run End 로 종료 | GameEngine.swift:475-487 |

**추가 권장 케이스 (작성 안 됨)**:
- [ ] Gambling(random) → 후보 중 1개 자동 획득, 알림 큐 prepend 순서 (GameEngine.swift:453-461, 774-776)
- [ ] 미션 제한 시간 만료 → `missionTimedOut=true`, `.timeOver` 사운드, fail 기록 (GameEngine.swift:274-280)
- [ ] Run 만료 시 Run Start 가 'N' 으로 되돌려져 재획득 가능 (GameEngine.swift:294-320)
- [ ] 시작 아이템이 mine 으로 손실되면 missionStarted=false (GameEngine.swift:382-387)

---

## §2. 화면별 Golden + Widget 테스트

### 2-1. 맵 화면 (`MissionPlayView` 의 Map 영역)

**Ground truth**: [`PlaySpot/Views/MissionPlay/MissionPlayView.swift:21-67`](PlaySpot/Views/MissionPlay/MissionPlayView.swift#L21-L67)

#### Golden — `test/golden/map_screen_test.dart`

- [ ] **상단 크롬**: Exit(X) · WhitePillTimer · scope · info(?) — `LegacyTopChrome` (MissionPlayView.swift:276-325)
  - X 버튼: 좌측, `CandyExitButton`
  - 타이머: 가운데 흰 pill, 디지트 빨강(Run 활성 시)
  - 오른쪽 2개: `CandyIconButton` scope(회색) + info(파랑 macaw)
- [ ] **하단 HUD**: 4 stat chip + 가운데 부유 카메라 — `LegacyBottomBar` (MissionPlayView.swift:330-374)
  - 좌: `StatChip(label: "지형", value: mineCount, style: .blue)` · `StatChip(label: "필수", value: mandatoryRemaining, style: .orange)`
  - 가운데: 72px 공간 + 76×76 `Color.duoGreen500` 부유 카메라(흰 stroke 3, offset y:-8)
  - 우: `StatChip(label: "HIDDEN", style: .neutral)` · `StatChip(label: "STEALTH", style: .purple)`
- [ ] **PulseMapPin** 획득/미획득
  - 미획득: 컬러 + scale 1.0
  - 획득: `.grayscale(1.0)` (PulseMapPin.swift:403-406 — opacity 그대로, 컬러만 desaturate)
  - timeoutEnd + isTimeOutActive: scale 1.0↔1.5 easeInOut 0.35s autoreverse forever (MissionPlayView.swift:393-424)
- [ ] **지형 원**: 미획득 mine(빨강 0.3 + Mine Radar 보유 시) / black(검정 0.3 영구) (MissionPlayView.swift:261-273)

#### Widget — `test/widget/map_callout_test.dart`

- [ ] 핀 탭 → **callout 정보 표시 (획득 불가)** (MissionPlayView.swift:26-31 의 주석: "Map 핀 탭은 callout 표시 전용이고 획득은 절대 일어나지 않는다")
- [ ] 카메라 버튼 탭 → ArPlay 풀스크린 라우트 push
- [ ] info(?) 탭 → "Mission Info" 다이얼로그 (Items: done/total, Mode: Real/Virtual) (MissionPlayView.swift:199-203)

---

### 2-2. AR 화면 (`ARGameView`)

**Ground truth**: [`PlaySpot/AR/ARGameView.swift`](PlaySpot/AR/ARGameView.swift)

#### Golden — `test/golden/ar_screen_test.dart`

- [ ] **상단 바**: 좌측 `map.fill`(초록 candy) · 가운데 WhitePillTimer · 우측 `questionmark`(파랑 macaw) (ARGameView.swift:58-87)
- [ ] **BearingRadarDisc (76×76, north-up)** — [`PlaySpot/AR/ARRadarView.swift`](PlaySpot/AR/ARRadarView.swift)
  - 그라데이션 디스크 (`RadialGradient.radarDisc` — duoGreen 계열) + 흰 outer stroke 2pt + 안쪽 dark stroke 1.5pt 0.35 (ARRadarView.swift:21-25)
  - 동심원 2개: inset 18%/32%, 흰색 0.35/0.30
  - 십자선: 흰색 0.4, 1pt
  - **폰 부채꼴**: 50° pie sector, radiusRatio 0.86, fill 흰색 0.65, stroke duoEel2 0.45, **헤딩(절대) 으로 회전** (ARRadarView.swift:38-50)
  - **아이템 바늘**: `Image("Radar/radar_item")` PNG 9:21, 높이 = discSize × 0.45, **아이템 절대 베어링으로 회전** (ARRadarView.swift:54-62)
  - 중앙 허브: 7px duoBee + dark stroke 1.2 + 노란 glow (ARRadarView.swift:65-69)
- [ ] **하단 RadarPillHUD** (ARGameView.swift:189-211, stealth 외)
  - 좌: 아이템 타입 라벨(대문자) + 거리 "732m"
  - 가운데: 76×76 BearingRadarDisc (offset y:-8)
  - 우: "Visible range" + rangeAR(예 "50m")
- [ ] **stealth 전용 HUD** (ARGameView.swift:215-246)
  - 화살표 숨김 레이더 58×58
  - 아이템 이름 + 보라 "STEALTH" chip
  - 2.5초마다 두 문구 토글: 녹색 "스텔스 레이더 ..." ↔ 주황 "지금도 폰을 움직여 ..."

#### Widget — `test/widget/ar_acquire_test.dart`

- [ ] viewport 안(상대 azimuth ≤ ±0.25 rad)에 있을 때만 ARItemBillboard 표시 (ARGameView.swift:356-378 `nearestVisibleItem`)
- [ ] 화면 X 좌표 = `width/2 + (rel/0.5rad) × width/2` (ARGameView.swift:392-408)
- [ ] 거리 스케일 = `max(0.3, 1.0 - min(d, 500)/500 × 0.7)` (ARGameView.swift:411-415)
- [ ] 탭 → range 안일 때만 `onItemTapped` 발화
- [ ] **흔들기** 감지 (가속도 ≥ 14 m/s², 500ms 쿨다운) → 범위 내 가장 가까운 미획득 자동 획득 (ARGameView.swift:143-156)
- [ ] **mine 자동 폭발**: 범위 진입 시 `detectMineBlast` (ARGameView.swift:128-141)

---

### 2-3. AR 아이템 빌보드 6 애니메이션 (`ARItemView`)

**Ground truth**: [`PlaySpot/AR/ARItemView.swift`](PlaySpot/AR/ARItemView.swift)

Golden 으로 정적 스냅샷은 잡지만 *애니메이션 자체*는 위젯 테스트에서 `AnimationController.value` 를 특정 phase 로 고정 후 골든 검증.

- [ ] (a) **float** ±12pt, spring(response:2.2, dampingFraction:0.55), autoreverse forever (ARItemView.swift 각 controller)
- [ ] (b) **sway** ±5°, easeInOut 2.8s, autoreverse forever
- [ ] (c) **pop** 1.0→1.08, easeInOut 2.2s, autoreverse forever
- [ ] (d) **pulse rings** — 2개, 0.7→2.0 스케일, base 70px, stroke 2.5pt, duoBee × 0.7, opacity 1→0, 1.6s, stagger duration/2 (ARItemView.swift:44-72)
- [ ] (e) **conic glow** — AngularGradient 3 stops [0% 투명, 18% duoBee 0.55, 40% 투명], 14pt stroke 140×140, 3.6s linear 회전, blur 2 (ARItemView.swift:24-42)
- [ ] (f) **sparkles** — 3 stars at (-22,4)/(0,-8)/(22,6), rise 60pt, 1.4s, stagger duration/3, 8각 별 8pt, duoBee, fade+scale (ARItemView.swift:76-109)
- [ ] **필수 별 배지**: 26×26 duoBee 원 + 흰 stroke 2 + 흰 별 13pt (ARItemView.swift:120-123)
- [ ] **획득 상태**: opacity 0.4 + 모든 애니메이션 정지 (ARItemView.swift:42, 47, 79, 117, 134)
- [ ] **isHiddenByShowType**: 자체 렌더링 없음 (부모 stealthHUD 가 안내; ARGameView.swift:45)

#### 흔들기 외부 트리거

- [ ] `MotionService` 가속도 δ > 1.4G (MotionService.swift:17, 50)
- [ ] AR 쿨다운 500ms (ARGameView.swift:24)
- [ ] 미니게임 쿨다운 120ms (MiniGameView.swift:25)

---

### 2-4. AR 도움말 오버레이 (`ARHelpOverlay`)

**Ground truth**: [`PlaySpot/AR/ARGameView.swift:420-587`](PlaySpot/AR/ARGameView.swift#L420-L587)

#### Golden — `test/golden/ar_help_overlay_test.dart`

- [ ] **외곽 dim**: `Color.black.opacity(0.5)` 전체 (line 431)
- [ ] **우상단 X 닫기** (line 434-446)
  - `padding(.top, 36)` + `padding(.horizontal, 14)`
  - `Image(systemName: "xmark") font(.system(size: 16, weight: .heavy))`
  - 44×44 흰 라운드 12, foregroundColor duoEel2
- [ ] **"화면 설명" capsule** (line 450-456)
  - `Capsule().fill(Color.duoMacaw)`
  - `font(.duoDisplay(size: 16))`, white
  - `.padding(.horizontal, 22).padding(.vertical, 10)`
  - VStack top padding 92pt
- [ ] **Shake 안내 말풍선** — 좌측, intrinsic width, 우측 Spacer (line 459-471)
  - VStack spacing 2: "아이템이 나오면" (duoDisplay 17 / duoEel2) → "Shake it!!" (duoDisplay 28 / duoCardinal)
- [ ] **거리 말풍선 2개** — `HStack(alignment: .top, spacing: 12)` + `Spacer(minLength: 16)` 사이 (line 477-489)
  - 좌: kicker(duoFoxDeep) + "아이템과 사용자\n간의 거리" (duoDisplay 15)
  - 우: kicker(duoGreen800) + "아이템 화면\n표시 거리"
- [ ] **레이더 범례 말풍선** (line 491-498)
  - DuoKicker "레이더" (duoHare)
  - row1: `Image("arrow.up") .black weight 22pt duoBee` + "노란 바늘 · 아이템 방향" + sub "ITEM"
  - row2: `PhoneDisc` (초록 원 + 흰 부채꼴 halfWidth × 0.34) + "흰색 반경 · 폰 방향" + sub "PHONE"
- [ ] **bubble 공통**
  - `RoundedRectangle(cornerRadius: 16).fill(.white)`
  - `.padding(.horizontal, 16).padding(.vertical, 13)`
  - 아래꼬리: `DownTriangle 20×11`, VStack spacing -0.5
  - `shadow(color: .black.opacity(0.22), radius: 7, x: 0, y: 3)`
- [ ] 마지막 `.padding(.bottom, 120)` (line 499)
- [ ] **어디든 탭하면 닫힘** + 우상단 X 도 닫힘

---

### 2-5. 미니게임 (`MiniGameView`)

**Ground truth**: [`PlaySpot/Views/MissionPlay/MiniGameView.swift`](PlaySpot/Views/MissionPlay/MiniGameView.swift)

#### Golden — `test/golden/minigame_test.dart`

- [ ] **배경**: 검정 풀스크린, statusBarHidden (line 32, 51)
- [ ] **모드**: `item.itemGame == 1` → 흔들기, `== 2` → 터치 (line 28)
- [ ] **PLAY SPOT wordmark** — `WordmarkPlaySpot(.outline)` 좌→우 노란 채움 (line 78)
  - width = `min(screenW × 1.05, illustrationH × 1.45)`, height = width × 0.75
  - 진행도 `progress / 100` 비율
  - 컬러: duoBee
- [ ] **일러스트**: shake_0/shake_1 또는 touch_0/touch_1 토글 (3 tick = 0.3s, easeInOut 0.18s, line 98-107, 217)
  - 흔들기 모드 ±6° 회전 (line 105)
- [ ] **halo**: 진행도 > 50% 시 duoBee 0.4 blendMode .screen, radius = illustrationSide × 0.85 (line 82-92)
- [ ] **하단 HUD**
  - 라벨: 흔들기 모드 "흔드세요!" / 터치 모드 "터치하세요!" (line 142-143)
  - "X / 100": 좌 duoBee 26pt + 우 duoSwan 22pt 0.55 opacity (line 147-152)
  - `RadarPillHUD`: HINT · 0m | ARRadar 76 | 유효 반경 · 100m (line 158-163)
- [ ] **상단**: 좌측 candy map 버튼(duoGreen500 + 흰 아이콘 + duoGreen700 shadow, 44×44)만 (line 122-130), `padding(.horizontal 14, .top 36)`
- [ ] **WhitePillTimer** 위치 (line 118)

#### Widget — `test/widget/minigame_progress_test.dart`

- [ ] 탭 또는 흔들기 → +15 (line 24)
- [ ] 100ms 마다 -0.4 decay (line 26)
- [ ] 흔들기 쿨다운 120ms (line 25)
- [ ] 100 도달 → `.gameFinish` 사운드 + `success` 햅틱 + 힌트 모달 + 600ms 후 pop(true) (line 223-226)
- [ ] 일러스트 opacity 페이드: 진행도 가까울수록 사라짐 (`(100-progress)/20`, line 230-234)
- [ ] 흔들기마다 `s_game_touch` 사운드 + SparkleBurst trigger 증가 (line 207-208)

---

### 2-6. 팝업들

#### 2-6-a. `ItemAcquiredPopup` (쇼케이스 V2)

**Ground truth**: [`PlaySpot/Views/MissionPlay/ItemAcquiredPopup.swift`](PlaySpot/Views/MissionPlay/ItemAcquiredPopup.swift)

- [ ] **onAppear → `HapticService.shared.success()`** (line 79)
- [ ] **OK 버튼 → `HapticService.shared.vibrate()` (heavy) → onOK** (line 54)
- [ ] **헤더 쇼케이스**: 130pt 높이, `eel2` 바탕, 회전 SweepGradient(4s), 펄스 링, 아이템 아이콘 72×72, "ITEM ACQUIRED · 아이템 획득" 키커
- [ ] **본문**: 타이틀 + 메시지 + 캔디 OK 버튼 (`DuoColors.fox` + foxDeep shadow)

#### 2-6-b. `MissionCompletePopup` / `MissionTimeoutPopup`

- 별점 + 후기 입력 (`MissionCompletePopup` only)
- 닫기 → 부모 dismiss
- 시각 디자인은 해당 SwiftUI 파일 자체를 ground truth 로 골든 작성

#### 2-6-c. `HintPopup` (`PlaySpot/Views/MissionPlay/HintPopup.swift`)

- 미니게임 완료 시 또는 Solution 사용 시 표시 — SwiftUI 파일 정확히 읽고 디자인 매칭

---

### 2-7. 시작 게임 / 미션 정보 / 퀴즈

| 화면 | SwiftUI 파일 | 핵심 검증 |
|---|---|---|
| **StartGameView** | `PlaySpot/Views/MissionPlay/StartGameView.swift` | Real/Virtual 모드 선택, "플레이 시작" 후 MissionPlayView push |
| **MissionInfoSheet** | `PlaySpot/Views/MissionPlay/MissionInfoSheet.swift` | 시트 디자인, 닫기 동작 |
| **QuizView** | `PlaySpot/Views/MissionPlay/QuizView.swift` | 정답 → `.quizCorrect` + pop(true). 오답 → `.quizWrong` + failCnt 증가 → 글자수/첫글자 힌트 (GameEngine.swift:606-614 `recordQuizFailure`) |
| **ARSearchView** | `PlaySpot/Views/MissionPlay/ARSearchView.swift` | 사용 위치 확인 후 골든 |

---

## §3. 사운드 / 햅틱 매트릭스

**Ground truth**: [`PlaySpot/Services/SoundService.swift`](PlaySpot/Services/SoundService.swift) + [`PlaySpot/Services/HapticService.swift`](PlaySpot/Services/HapticService.swift) + GameEngine.swift 호출부

자동 검증 한계: 실제 오디오 출력은 단위 테스트에서 mock 만 가능. **이 표 자체가 회귀 체크리스트**로 동작.

| 이벤트 | 사운드 | 햅틱 | SwiftUI 근거 |
|---|---|---|---|
| 미션 setup (start 없음, 자동 시작) | `.gogogo` | — | GameEngine.swift:151 |
| Start 획득 | `.gogogo` | — | GameEngine.swift:470 |
| 일반 아이템 획득 | `.itemGet` | — | GameEngine.swift:508 |
| 알림 큐 pop | `.itemGet` (한 번 더) | — | GameEngine.swift:560 |
| Radar 류 5종 획득 | `.radar` | — | GameEngine.swift:445 |
| 미션 완료 (End + 모든 필수) | `.gameFinish` | — | GameEngine.swift:498 |
| 미션 제한시간 초과 | `.timeOver` | — | GameEngine.swift:278 |
| Run 타임아웃 만료 | `.timeOver` | — | GameEngine.swift:315 |
| 지뢰 폭발 (defense 유무 무관) | `.explosion` | `.vibrate()` heavy | GameEngine.swift:332, 341 |
| 퀴즈 정답 | `.quizCorrect` | — | QuizView |
| 퀴즈 오답 | `.quizWrong` | — | QuizView |
| 퀴즈 힌트(failCnt 페널티) | `.quizFail` | — | QuizView/GameEngine |
| 미니게임 흔들기/탭 | `.gameTouch` | — | MiniGameView.swift:208 |
| 미니게임 완료 | `.gameFinish` | `.success()` | MiniGameView.swift:225-226 |
| ItemAcquiredPopup onAppear | — | `.success()` | ItemAcquiredPopup.swift:79 |
| ItemAcquiredPopup OK | — | `.vibrate()` heavy | ItemAcquiredPopup.swift:54 |

자동화 권장: Flutter 측 `SoundService` 와 `HapticService` 를 **interface + fake** 로 리팩토링한 뒤, 위 트리거 케이스에서 fake 의 `recordedCalls` 가 기대 시퀀스인지 검증.

---

## §4. 아이템 타입별 기능 + 디자인 정밀 매트릭스 (★ 가장 중요)

**Ground truth (절대 추측 금지)**:
- [`PlaySpot/Game/GameEngine.swift`](PlaySpot/Game/GameEngine.swift) — `acquireItem`, `handleMineBlast`, `_setAcquiredAlert`
- [`PlaySpot/Game/ItemInteraction.swift`](PlaySpot/Game/ItemInteraction.swift) — 라우팅 (`interactionType`)
- [`PlaySpot/Models/ItemType.swift`](PlaySpot/Models/ItemType.swift) — 아이콘 이름 규칙
- [`PlaySpot/Views/MissionPlay/ItemAcquiredPopup.swift`](PlaySpot/Views/MissionPlay/ItemAcquiredPopup.swift) — 팝업 디자인
- [`PlaySpot/Resources/Localizable.xcstrings`](PlaySpot/Resources/Localizable.xcstrings) — 한국어 문구

### §4-0. 공통 검증 흐름 (모든 아이템 공통)

획득 1회마다 SwiftUI 가 무엇을 하는지 (`acquireItem` 호출 순서):

1. `dicItemEnd[itemID] = "Y"` 마킹 + DB `MissionItemInPlay` upsert (endYN=Y, endTime=now) (GameEngine.swift:425-431)
2. **타입별 효과** (radar 보유 카운트 증가, timeout 활성/해제, mission completed 체크 등)
3. `acquisitionOrder.append(itemID)` — 후속 mine 폭발 시 lost 후보가 됨 (GameEngine.swift:506)
4. `updateCounters()` — mineCount/mandatoryRemaining/hiddenOnMapCount/stealthOnARCount 재계산 (GameEngine.swift:507)
5. `_setAcquiredAlert(item, bonus)` — ItemAcquiredAlert 큐에 enqueue (GameEngine.swift:514)
6. **사운드 재생** (`.itemGet` 또는 타입별 `.radar` / `.gogogo` / `.gameFinish`)
7. `notifyListeners()` (Flutter), SwiftUI 는 `@Observable` 자동 갱신

#### 각 아이템 공통 검증 항목

| # | 검증 | 테스트 종류 |
|---|---|---|
| C1 | `dicItemEnd[id]` 가 'N' → 'Y' 로 전이 | 단위 |
| C2 | `acquisitionOrder` 끝에 itemID 추가 | 단위 |
| C3 | `updateCounters` 후 mandatoryRemaining 감소 (필수일 때) | 단위 |
| C4 | `ItemAcquiredAlert` 큐에 enqueue | 단위 (alert 검증) |
| C5 | 해당 사운드 1회 호출 (SoundService fake) | 단위 |
| C6 | 맵 핀이 grayscale 로 전환 | 골든 |
| C7 | AR 빌보드가 isAcquired=true → opacity 0.4 + 애니메이션 정지 | 골든 |
| C8 | ItemAcquiredPopup 헤더에 해당 아이콘 표시 | 골든 |
| C9 | ItemAcquiredPopup OK → onOK 호출 + heavy 햅틱 | 위젯 |

---

### §4-1. Start (49) — 미션 시작

- **SwiftUI ref**: GameEngine.swift:715-717, ItemInteraction.swift:20
- **라우팅**: `interactionType = .startGame` → 직접 acquire
- **에셋**:
  - mapIcon: `Items/i_start` 또는 `Items/in_start` (필수일 때)
  - arIcon: `AR/ar_start` / `AR/arn_start`
  - **Flutter**: `assets/items/i_start.png` / `assets/ar/ar_start.png`
- **사운드**: `.gogogo` (GameEngine.swift:470)
- **게임 상태 효과**:
  - `missionStarted = true`
  - `missionStartTime = Date()`
  - `MissionInPlay.startYN = "Y"`, `startTime = now` (DB upsert)
  - `recordPlay(.start, time)` — 서버 기록
- **팝업** (ItemAcquiredPopup):
  - title: `"Start Item acquired!"`
  - message: `item.info.isEmpty ? "If you touch OK, the item will be released Mission." : item.info` (GameEngine.swift:716)
- **테스트 케이스**:
  - [ ] 단위: setup 시 start 가 있으면 startYN='N' (acquire 전), 없으면 자동 start (GameEngine.swift:95-103)
  - [ ] 단위: acquire 후 missionStarted=true + sound .gogogo 1회
  - [ ] 위젯: 미션 시작 전 다른 아이템 acquire 시도 → AR 후보에서 `start` 만 보임 (ARGameView.swift:321)
  - [ ] 골든: start 핀 디자인 (mapIcon i_start), AR 빌보드 디자인 (arIcon ar_start)
  - [ ] 골든: 획득 후 핀 grayscale

---

### §4-2. End (48) — 미션 종료

- **SwiftUI ref**: GameEngine.swift:493-500, ItemInteraction.swift:22
- **라우팅**: `interactionType = .endGame` → 직접 acquire
- **에셋**: `Items/i_end` / `Items/in_end`, `AR/ar_end` / `AR/arn_end`
- **사운드**: `.gameFinish` (모든 필수 완료 시), 미완료 시 사운드 없음 (GameEngine.swift:493-499)
- **게임 상태 효과**:
  - `stopTimer()` 호출 (GameEngine.swift:494)
  - 모든 필수 acquired 시 → `missionCompleted=true`, `isMissionEnd=true`, `recordPlay(.finish, now)` (GameEngine.swift:495-500)
  - 필수 남음 시 → end 만 'Y' 처리, completed 안 됨
- **팝업**: 전용 ItemAcquiredAlert 없음. 완료 시 `MissionCompletePopup` 표시 (MissionPlayView.swift:94-132)
- **HUD 가시성**: `mandatoryRemaining > 1` 일 때 지도/AR 모두에서 핀 숨김 (GameEngine.swift `shouldShowOnMap`, ARGameView.swift:324)
- **테스트 케이스**:
  - [ ] 단위: 필수 1개 남은 상태에서 end acquire → completed=false (이미 §1#1 케이스)
  - [ ] 단위: 모든 필수 + end → completed=true, isMissionEnd=true, sound .gameFinish
  - [ ] 단위: shouldShowOnMap(end) — mandatoryRemaining 2 → false, 1 → true (이미 §1#2)
  - [ ] 위젯: 완료 → MissionCompletePopup 표시
  - [ ] 골든: end 핀 디자인, AR 빌보드, MissionCompletePopup

---

### §4-3. Simple (51) — Hint (탭/미니게임)

- **SwiftUI ref**: GameEngine.swift:719-721, ItemInteraction.swift:36-37
- **라우팅**: `item.itemGame > 0 ? .miniGame : .simplePickup`
- **에셋**: `Items/i_simple` / `Items/in_simple`, `AR/ar_simple` / `AR/arn_simple`
- **사운드**: `.itemGet` (GameEngine.swift:508)
- **팝업** (itemGame == 0 만, GameEngine.swift:719):
  - title: `"Hint Item acquired!"`
  - message: `item.info.isEmpty ? "Lose the draw!! No hint." : item.info`
- **itemGame > 0**: MiniGameView 라우팅 (§2-5 참고). 미니게임 100 도달 시에만 `engine.acquireItem(it)` 호출 → 사운드 + 팝업
- **테스트 케이스**:
  - [ ] 단위: itemGame=0 → 직접 acquire, sound .itemGet, 팝업 "Hint Item acquired!"
  - [ ] 위젯: itemGame=1 (shake) → MiniGameView push → 흔들기 누적 → 100 → pop(true) → acquire
  - [ ] 위젯: itemGame=2 (touch) → 같은 흐름 (탭 누적)
  - [ ] 골든: simple 핀, AR 빌보드, 팝업 (itemGame=0 케이스)

---

### §4-4. Quiz (40) / Quiz20 (41) — 퀴즈

- **SwiftUI ref**: ItemInteraction.swift:18-19, [`QuizView.swift`](PlaySpot/Views/MissionPlay/QuizView.swift)
- **라우팅**: `interactionType = .quiz` → QuizView 시트 push (MissionPlayView.swift:83-85)
- **에셋**: `Items/i_quiz` / `Items/in_quiz`, `AR/ar_quiz` / `AR/arn_quiz` (quiz/quiz20 동일)
- **사운드**:
  - 정답: `.quizCorrect` (QuizView 내부)
  - 오답: `.quizWrong` (QuizView 내부) + `recordQuizFailure` → failCnt 증가 (GameEngine.swift:606-614)
  - 정답 후 acquire: `.itemGet`
- **퀴즈 데이터**: setup 시 `dataSource.fetchMissionDetail` 반환 quizzes → itemID 별 그룹핑 → `item.quizzes` (GameEngine.swift:121-125)
- **힌트 단계** (failCnt 별, QuizView.swift 확인 필요):
  - failCnt=0: 힌트 없음
  - failCnt=1: 글자수 표시
  - failCnt≥2: 첫글자 표시
- **팝업**: SwiftUI 의 `_setAcquiredAlert` 에 quiz 분기는 *없음* (default → 팝업 enqueue 없음). 사용자가 보는 것은 QuizView 자체에서의 정답 피드백.
- **테스트 케이스**:
  - [ ] 단위: setup 시 quiz/quiz20 아이템에 quizzes 가 itemID 매칭으로 묶여 있음
  - [ ] 단위: recordQuizFailure → failCnt 증가, endYN='N' 유지 (퀴즈 미완료)
  - [ ] 위젯: QuizView 오답 → 오답 사운드 + 글자수/첫글자 힌트 표시
  - [ ] 위젯: QuizView 정답 → pop(true) → acquireItem → sound .itemGet
  - [ ] 골든: quiz 핀, AR 빌보드, QuizView 디자인 (3 상태: 초기/오답 1회/오답 2회)

---

### §4-5. TimeoutStart (42) — Run Start

- **SwiftUI ref**: GameEngine.swift:475-481, 723-728, ItemInteraction.swift:30
- **라우팅**: `interactionType = .runStart` → 직접 acquire
- **에셋**: `Items/i_time_start` / `Items/in_time_start`, `AR/ar_time_start` / `AR/arn_time_start`
- **사운드**: `.itemGet`
- **게임 상태 효과**:
  - `timeOutStartTime = Date()`
  - 페어 `timeoutEnd` (`relationItemID == item.itemID`) 의 `effectiveTime` 을 `timeOutLimitTime` 으로 설정
  - `isTimeOutActive = true`, `activeTimeoutStartID = item.itemID`
- **팝업**:
  - title: `"Run Start Item acquired!"`
  - message: `"제한 시간 \(MM:SS) 안에 Run End 아이템을 획득하세요."` ← *반드시* 페어 Run End 의 `effectiveTime` 으로 계산 (GameEngine.swift:726, item.info 사용 금지 — stale 가능)
- **HUD 효과**:
  - WhitePillTimer 가 `remainingRunTime` 카운트다운 (GameEngine.swift:176-180)
  - 디지트 컬러 빨강 전환 (Run 활성 또는 < 10초 경고)
  - 페어 Run End 핀이 펄스 1.0↔1.5 (PulseMapPin)
- **만료** (`_handleRunTimeExpired`, GameEngine.swift:294-320):
  - sound `.timeOver`
  - Run Start 를 'N' 으로 복귀 (재획득 가능)
  - alert: "mission_play_9" / "mission_play_10" 키
- **테스트 케이스**:
  - [ ] 단위 (이미 §1#7): timeoutStart acquire → isTimeOutActive=true, activeTimeoutStartID=id, timeOutLimitTime=페어 effectiveTime
  - [ ] 단위 (권장 추가): 만료 → Run Start 'Y' → 'N' 되돌림, dicItemEnd 갱신, acquisitionOrder 에서 제거
  - [ ] 위젯: 획득 후 WhitePillTimer 가 remainingRunTime 카운트다운, < 10초 시 빨강
  - [ ] 골든: timeoutStart 핀, 페어 Run End 펄스 상태 핀, AR 빌보드, 팝업 ("제한 시간 ...")

---

### §4-6. TimeoutEnd (43) — Run End

- **SwiftUI ref**: GameEngine.swift:483-491, 730-732, ItemInteraction.swift:32
- **사전 검사** (`acquireItem` 진입 시):
  - `!isTimeOutActive` → 거부 + 알림 `"획득 실패: Run Start 아이템을 먼저 획득하세요"` (Flutter 만; SwiftUI 코드 확인 — Flutter 가 보강)
  - `activeTimeoutStartID != relationItemID` → 거부 + `"Run Start 와 Run End 가 짝이 맞아야 합니다"`
- **에셋**: `Items/i_time_end` / `Items/in_time_end`, `AR/ar_time_end` / `AR/arn_time_end`
- **사운드**: `.itemGet`
- **게임 상태 효과**:
  - `isTimeOutActive = false`
  - `activeTimeoutStartID = nil`
  - 페어 timeoutStart 의 `endYN='Y'` (이미 acquired 상태 유지)
- **팝업**:
  - title: `"Run End Item acquired!"`
  - message: `item.info.isEmpty ? "Run time ended successfully." : item.info`
- **테스트 케이스**:
  - [ ] 단위 (이미 §1#6, §1#7): 비활성 → 거부 / 활성 + 짝 → 종료
  - [ ] 단위 (권장): activeTimeoutStartID 있는데 relationItemID 다르면 거부
  - [ ] 골든: timeoutEnd 핀 (펄스 활성 시 / 비활성 시), AR 빌보드, 팝업

---

### §4-7. Mine (55) — 지뢰

- **SwiftUI ref**: GameEngine.swift:325-405, ItemInteraction.swift:24
- **AR 비표시**: AR 빌보드에 아이콘 그리지 않음 (자동 폭발만, ARGameView.swift:128-141)
- **에셋**: `Items/i_mine` / `Items/in_mine` (지도 핀; Mine Radar 보유 시에만 표시), `AR/ar_mine` (사실상 미사용)
- **사운드**: `.explosion` (defense 유무 무관, GameEngine.swift:341)
- **햅틱**: `vibrate()` heavy (GameEngine.swift:332)
- **게임 상태 효과 (Defense 있을 때)**:
  - `dicRnPTaken[mineNoBomb] -= 1`
  - PowerUpRepository upsert (`ableCnt = 새 값`)
  - 팝업: `"지뢰 폭발!" + "Defense 아이템으로 피해를 막았습니다"`
- **게임 상태 효과 (Defense 없을 때, `_memoryLastAcquiredItem`)**:
  - 최근 획득 아이템 중 mine/mineNoBomb/random/timeoutStart **제외** (GameEngine.swift `_memoryLastAcquiredItem`)
  - 그 아이템을 'Y' → 'N' 으로 복귀
  - `acquisitionOrder` 에서 제거
  - lost 가 `start` 면 missionStarted=false, startTime=nil, MissionInPlay.startYN='N' (GameEngine.swift:382-387)
  - 진행 중인 timeout 도 취소 (lostName = "Run Start")
  - 팝업: `"지뢰 폭발! 최근 획득한 [lostName] 아이템을 잃었습니다"` 또는 lost 없으면 `"지뢰가 폭발했습니다!"`
- **지도 표시**:
  - Mine Radar 보유: 핀 + 반경 원 (빨강 0.3 alpha) (MissionPlayView.swift:261-264)
  - 미보유: 핀/원 모두 숨김
- **HUD 카운터**: `mineCount` 는 Mine Radar 보유 시에만 미획득 지뢰 카운트, 미보유 시 0 (GameEngine.swift `updateCounters`)
- **자동 폭발**:
  - 맵에서: `detectMineProximity` (GameEngine.swift:523-533) — 위치 갱신 시 범위 진입 검사
  - AR 진입 시: `detectMineBlast()` 즉시 호출 (ARGameView.swift:112-141)
- **테스트 케이스**:
  - [ ] 단위 (이미 §1#3): mine 폭발 → 최근 획득 1개 손실
  - [ ] 단위 (이미 §1#4): Defense 있으면 흡수 + count 감소
  - [ ] 단위 (권장): Defense 없고 최근 acquired 가 start 면 missionStarted=false 로 되돌림
  - [ ] 단위 (권장): Run 활성 중 mine 폭발 → isTimeOutActive=false + lostName="Run Start"
  - [ ] 위젯: 위치 스트림 mock → mine 범위 진입 → handleMineBlast 1회 호출
  - [ ] 골든: mine 핀 (radar 있/없 두 상태), 반경 원, 폭발 팝업 (defense 있/없)

---

### §4-8. MineNoBomb (61) — Defense

- **SwiftUI ref**: GameEngine.swift:438-446 (취득), 343-355 (소비), 754-756 (팝업), ItemInteraction.swift:26
- **에셋**: `Items/i_mine_nobomb` / `Items/in_mine_nobomb`, `AR/ar_mine_nobomb` / `AR/arn_mine_nobomb`
- **사운드**: `.itemGet`
- **게임 상태 효과 (취득)**:
  - `dicRnPTaken[mineNoBomb] += 1`
  - PowerUpRepository upsert (`ableCnt = 누적`)
- **팝업**:
  - title: `"Defence Item acquired!"`
  - message: `item.info.isEmpty ? "Mine damage can be avoided using this Defence item." : item.info`
- **소비**: 다음 mine 폭발 시 자동 (위 §4-7 참조)
- **테스트 케이스**:
  - [ ] 단위 (이미 §1#4): Defense 1 → 폭발 흡수 → Defense 0
  - [ ] 단위 (권장): Defense 2 누적 → 2번까지 흡수
  - [ ] 골든: defense 핀, AR 빌보드, 팝업

---

### §4-9. Random (50) — Gambling

- **SwiftUI ref**: GameEngine.swift:453-461, 764-776, ItemInteraction.swift:28
- **에셋**: `Items/i_random_box` / `Items/in_random_box`, `AR/ar_random_box` / `AR/arn_random_box`
- **사운드**: `.itemGet` (보너스 자체 사운드는 보너스 acquire 시 별도 재생)
- **흐름** (GameEngine.swift:453-461):
  1. 후보 = `_memoryRandomCandidates(item.itemID)` (전체 items 중 미획득 + end/random/black 제외)
  2. 진행 중 timeout 이면 timeoutStart 도 제외
  3. 후보 중 1개 랜덤 추첨 → **그 보너스를 다시 `acquireItem(lucky)` 재귀 호출**
  4. 그 결과 보너스 알림이 먼저 enqueue 됨
  5. 그 다음 random 자신의 `_setAcquiredAlert` 가 **prepend=true** 로 큐 맨 앞에 삽입
  6. → 유저는 **Gambling 팝업을 먼저 본 뒤 OK → 보너스 팝업 표시**
- **팝업**:
  - title: `"Gambling acquired!"`
  - message (보너스 있음): `"You won: [boss type displayLabel]!"`
  - message (후보 없음): `"Gambling failed — no items left to win."`
- **테스트 케이스**:
  - [ ] 단위 (권장 추가): random acquire 시 후보 중 1개가 보너스로 acquire 됨 + 알림 순서 = [gambling 먼저, 보너스 두번째]
  - [ ] 단위 (권장): 후보 없는 경우 → 보너스 없음, message "Gambling failed"
  - [ ] 단위 (권장): timeout 활성 중 후보에서 timeoutStart 제외
  - [ ] 위젯: gambling 팝업 OK → 두번째 팝업 표시
  - [ ] 골든: random_box 핀, AR 빌보드, gambling 팝업, "You won: ..." 팝업

---

### §4-10. Black (56) — Dark Zone

- **SwiftUI ref**: GameEngine.swift `shouldShowOnMap` + `_isInsideUnacquiredDarkZone`, ItemInteraction.swift:34 (`.darkEffect`)
- **에셋**: 핀 그리지 않음 (`shouldShowOnMap` 분기에서 항상 false). 검정 원 오버레이만 (MissionPlayView.swift:266)
- **사운드**: 없음 (획득 불가)
- **게임 상태 효과**:
  - 미획득 black 의 rangeAR 범위 내 *다른* 미획득 아이템들이 지도에서 숨김 (start/black 자신 제외)
- **HUD 카운터**: `hiddenOnMapCount` 에 영향 (간접)
- **테스트 케이스**:
  - [ ] 단위 (이미 §1#5): black 범위 내 simple → shouldShowOnMap=false
  - [ ] 단위: black 자체는 핀 안 그림 (shouldShowOnMap=false 영구)
  - [ ] 골든: 지도에 검정 원 오버레이(0.3 alpha), 내부 아이템 숨겨진 상태

---

### §4-11. Solution (52)

- **SwiftUI ref**: GameEngine.swift:438-446, 734-736
- **에셋**: `Items/i_genius` / `Items/in_genius`, `AR/ar_genius` / `AR/arn_genius` (filename = "genius")
- **사운드**: `.itemGet`
- **게임 상태 효과**:
  - `dicRnPTaken[solution] += 1`
  - PowerUpRepository upsert
- **팝업**:
  - title: `"Solution Item acquired!"`
  - message: `item.info.isEmpty ? "You can get an answer if you win mission quiz or quiz item." : item.info`
- **소비**: 퀴즈에서 사용자가 "솔루션 사용" 버튼으로 활용 (QuizView 확인 필요)
- **테스트 케이스**:
  - [ ] 단위: acquire → dicRnPTaken[solution]++ + sound .itemGet
  - [ ] 위젯: QuizView 에서 solution 카운트 표시 + 사용 시 정답 자동 표시 (QuizView.swift 확인)
  - [ ] 골든: genius 핀, AR 빌보드, 팝업

---

### §4-12. RadarAR (65) — Stealth Radar

- **SwiftUI ref**: GameEngine.swift:438-446, 738-740
- **에셋**: `Items/i_radar_ar` / `Items/in_radar_ar`, `AR/ar_radar_ar` / `AR/arn_radar_ar`
- **사운드**: `.radar` (GameEngine.swift:445 — `item.itemType.isRadar` 시 별도 분기)
- **게임 상태 효과**:
  - `dicRnPTaken[radarAR] += 1`
  - **이후** AR 에서 stealth 아이템들이 일반처럼 보임 (ShowType.isVisibleInAR 분기, ItemType / ShowType 참조)
  - `updateCounters` 후 stealthOnARCount 감소
- **팝업**:
  - title: `"Stealth Radar Item acquired!"`
  - message: `item.info.isEmpty ? "Stealth items are now visible in AR." : item.info`
- **테스트 케이스**:
  - [ ] 단위: acquire → dicRnPTaken[radarAR]++ + sound **.radar (not .itemGet)**
  - [ ] 단위: 획득 전 stealth 아이템 → ARGameView `nearestItemIsHiddenByShowType=true`, 획득 후 false
  - [ ] 골든: radar_ar 핀, AR 빌보드, 팝업

---

### §4-13. RadarMap (66)

- **SwiftUI ref**: GameEngine.swift:438-446, 742-744
- **에셋**: `Items/i_radar_map` / `Items/in_radar_map`, `AR/ar_radar_map` / `AR/arn_radar_map`
- **사운드**: `.radar`
- **효과**: `dicRnPTaken[radarMap]++`. 이후 ShowType.isVisibleOnMap 분기에서 hidden 아이템이 지도에 표시 → hiddenOnMapCount 감소
- **팝업**: `"Map Radar Item acquired!"` + `"Hidden items are now visible on the map."`
- **테스트 케이스**:
  - [ ] 단위: 획득 전 hidden 아이템 → shouldShowOnMap=false, 획득 후 true
  - [ ] 골든: 핀/빌보드/팝업

---

### §4-14. RadarMine (68)

- **SwiftUI ref**: GameEngine.swift:438-446, 746-748
- **에셋**: `Items/i_radar_mine` / `Items/in_radar_mine`, `AR/ar_radar_mine` / `AR/arn_radar_mine`
- **사운드**: `.radar`
- **효과**: `dicRnPTaken[radarMine]++`. 이후 mine 핀 + 빨간 반경 원이 지도에 표시 (MissionPlayView.swift:263-264). mineCount HUD 도 업데이트
- **팝업**: `"Mine Radar Item acquired!"` + `"Mine explosion radius is now shown on the map."`
- **테스트 케이스**:
  - [ ] 단위: 획득 전 mineCount=0 (radar 없음), 획득 후 mineCount=미획득 지뢰 수
  - [ ] 골든: 지도에 mine 핀 + 빨간 원 출현

---

### §4-15. RadarAll (67)

- **SwiftUI ref**: GameEngine.swift:438-446, 750-752
- **에셋**: `Items/i_radar_all` / `Items/in_radar_all`, `AR/ar_radar_all` / `AR/arn_radar_all`
- **사운드**: `.radar`
- **효과**: `dicRnPTaken[radarAll]++`. **모든 종류** (map hidden + AR stealth) 가 표시됨 (ShowType.isVisibleOnMap/isVisibleInAR 의 hasRadarAll 분기)
- **팝업**: `"All Radar Item acquired!"` + `"All hidden items are now revealed."`
- **테스트 케이스**:
  - [ ] 단위: RadarAll 획득 → hiddenOnMapCount=0, stealthOnARCount=0
  - [ ] 골든: 모든 hidden/stealth 핀 표시 상태

---

### §4-16. RadarBlack (69)

- **SwiftUI ref**: GameEngine.swift 의 `_setAcquiredAlert` switch 에 **명시 case 없음** → default 분기 → ItemAcquiredAlert 미발생
- **에셋**: 확인 필요 (filename 폴백). `Items/i_original` 가 디폴트 (ItemType.swift:78-90 의 imageFileName default)
- **사운드**: `.radar` (isRadar 분기)
- **효과**: `dicRnPTaken[radarBlack]++` — black zone 가시화/무력화? (ShowType / GameEngine 추가 분기 확인 필요)
- **팝업**: 없음 (default 분기)
- **테스트 케이스**:
  - [ ] 단위: 획득 → 카운트 증가 + sound .radar, 팝업 없음 확인 (Flutter 도 동일하게 default 분기)
  - [ ] 추가 검증 필요: SwiftUI 에서 black 핀이 RadarBlack 보유 시 다르게 그려지는지 (`shouldShowCircle` / `shouldShowOnMap` 의 `radarBlack` 분기)
  - **헷갈리면** `grep -rn "radarBlack" PlaySpot/` 으로 모든 사용처 확인 후 정확히 매칭

---

### §4-17. Coupon (59)

- **SwiftUI ref**: GameEngine.swift:758-762
- **에셋**: `Items/i_coupon` / `Items/in_coupon`, `AR/ar_coupon` / `AR/arn_coupon`
- **사운드**: `.itemGet`
- **효과**: 게임 상태 변경 없음 — 단순 표시
- **팝업**:
  - title: `"Coupon acquired!"`
  - message: `item.info.isEmpty ? "Coupon acquired. Check details with the designer." : item.info` (info 필드에 쿠폰 코드)
- **테스트 케이스**:
  - [ ] 단위: acquire → 사운드 + 팝업, dicRnPTaken/카운터 변화 없음
  - [ ] 골든: coupon 핀, AR 빌보드, 팝업 (info 비어있을 때 / 채워졌을 때 2종)

---

### §4-18. PenaltyRemove (54), Store (91), Num/Alphabet (00-10)

- **SwiftUI ref**: `_setAcquiredAlert` switch 의 default 분기 (GameEngine.swift:778-779)
- **사운드**: `.itemGet`
- **효과**: 게임 상태 변화 없음, 팝업 없음
- **현재 PlaySpot 구현**: placeholder/예약 — 미사용 가능
- **테스트 케이스**:
  - [ ] 단위: 획득 → 사운드만, 팝업 없음
  - [ ] *주의*: SwiftUI 미사용 타입이라도 Flutter 가 동일하게 noop 동작이어야 함 (UI 표시는 default 핀)

---

### §4-19. 매트릭스 요약 (테스트 자동화 골격)

각 아이템 = `test/widget/items/<item>_test.dart` 1개 파일. 골격:

```dart
// test/widget/items/start_test.dart
void main() {
  group('start (49)', () {
    test('함수: acquire → missionStarted=true + gogogo 사운드 + Start 팝업', () async {
      final fake = FakeSoundService();
      final engine = await _engineWith([_start, _m1], soundService: fake);
      engine.acquireItem(_start);
      expect(engine.missionStarted, isTrue);
      expect(engine.dicItemEnd[_start.itemID], 'Y');
      expect(fake.played, contains(SoundEffect.gogogo));
      expect(engine.pendingAlert?.title, 'Start Item acquired!');
    });

    testGoldens('디자인: 맵 핀(미획득/획득), AR 빌보드, 팝업', (tester) async {
      // …
      await expectLater(find.byType(PulseMapPin), matchesGoldenFile('start_pin_unacquired.png'));
    });
  });
}
```

### §4-20. SwiftUI 와의 1:1 회귀 체크리스트

각 아이템마다 *반드시* 동일해야 할 5가지:

| # | 검증 | SwiftUI 어디서 확인 |
|---|---|---|
| 1 | 사운드 enum 값 | `GameEngine.swift _setAcquiredAlert` / `acquireItem` 의 `play(.<x>)` |
| 2 | 팝업 title 문자열 | `GameEngine.swift _setAcquiredAlert` switch |
| 3 | 팝업 message 분기 (info 비어있을 때 vs 채워졌을 때) | 같은 곳 |
| 4 | 게임 상태 변화 (dicItemEnd, dicRnPTaken, missionStarted, isTimeOutActive) | `acquireItem` / `handleMineBlast` |
| 5 | 맵/AR 핀 에셋 파일명 | `ItemType.swift imageFileName` + 필수 prefix `in_`/`arn_` |

Flutter 가 1번 항목이라도 다르면 곧 회귀.

---

## §5. 기타 화면 (Phase 2-4, 9 — 디자인 화면들)

**SwiftUI 파일 위치**:
- 미션 목록: `PlaySpot/Views/Missions/`
- 미션 상세: `PlaySpot/Views/MissionDetail/`
- 디자인: `PlaySpot/Views/Design/`
- 빌더: `PlaySpot/Views/Builder/`
- My Info: `PlaySpot/Views/MyInfo/`
- Badge: `PlaySpot/Views/Badge/`
- Settings: `PlaySpot/Views/Settings/`

이들 각 폴더의 SwiftUI 파일을 ground truth 로, Flutter `lib/features/<area>/` 의 화면과 1:1 골든 비교.

권장 골든 1개씩 (총 ~10개):
- [ ] MissionListPage 4 세그(인기/신규/내주변/전체)
- [ ] MissionCard 컴포넌트
- [ ] MissionDetailPage (hero + 정보/랭킹/리뷰)
- [ ] DesignListPage
- [ ] MissionSetupPage
- [ ] BuilderPage (지도+편집 패널)
- [ ] MyInfoPage (프로필 + ITEMS + DESIGNED + PLAYED)
- [ ] BadgeListPage
- [ ] SettingsPage
- [ ] MainTab 5탭 (미션/디자인/내정보/뱃지/설정)

---

## §6. 웹 헤드리스 스크린샷

### 6-1. 스크립트 (작성 예정)

`scripts/screenshot_web.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../flutter_ar_spike"

# 릴리즈 빌드 (web)
flutter build web

# 정적 서빙
(cd build/web && python3 -m http.server 8080 --bind 127.0.0.1) &
SERVER=$!
trap "kill $SERVER 2>/dev/null || true" EXIT
sleep 2

# Playwright 로 라우트별 캡처 (iPhone 14 Pro viewport)
mkdir -p ../screenshots/web
for route in '/' '#/missions' '#/design' '#/info' '#/badge' '#/settings'; do
  fname=$(echo "$route" | sed 's|[/#]|_|g')
  npx playwright screenshot \
    --viewport-size=393,852 \
    --device-scale-factor=3 \
    --wait-for-timeout=3000 \
    "http://127.0.0.1:8080/$route" \
    "../screenshots/web/${fname:-home}.png"
done

echo "✓ screenshots → screenshots/web/"
```

사전 준비:
```bash
npm i -g playwright && playwright install chromium
chmod +x scripts/screenshot_web.sh
```

### 6-2. 검증 흐름

1. `bash scripts/screenshot_web.sh` → `screenshots/web/*.png` 6장
2. 같은 디자인의 iOS 시뮬레이터 스크린샷과 옆에 두고 비교
3. 변경 후 재실행 → `git diff --stat screenshots/web/` 로 영향 받은 라우트 확인

웹 한계: 카메라 피드 없음, 나침반/센서 mock, AR 화면은 카메라 누락 상태로 캡처됨 — *지도/디자인/리스트* 회귀에 한정.

---

## §7. 자동화로 잡을 수 없는 것 (실기기 잔여)

| 항목 | 검증 방법 |
|---|---|
| 실제 사운드 출력 | 이어폰/스피커 청취 |
| 햅틱 (heavy/success) | 손에 든 채로 |
| 카메라 피드 | iOS/Android 실기기 |
| 흔들기 (1.4G threshold) | 손으로 흔들어보기 |
| 나침반/방위각 | 폰을 돌리며 north-up 동작 |
| GPS 정확도 / virtual offset | 실외에서 걸어다니며 |
| AR 화면 좌표 ↔ 화면 X 투영 정합성 | 카메라로 보며 |
| 실제 IAP (출시 후) | TestFlight |
| 멀티 디바이스 (iPad 가로 등) | 각 장치별 |

체크리스트:
- [ ] iOS 시뮬레이터 16 Pro
- [ ] iOS 실기기 (Personal Team 서명)
- [ ] Android 실기기 (USB 디버깅)
- [ ] 가상 모드 — 1회차 (실제 위치 ≠ 미션 좌표) → 오프셋 적용 후 캐릭터 = 미션 start
- [ ] 가상 모드 — 2회차 (재 setup 시 오프셋 초기화 확인)
- [ ] 실제 모드 — 미션 좌표 부근 실외 GPS

---

## §8. 핫리로드 흐름 (개발 중 빠른 시각 확인)

```bash
flutter run -d <device-id>      # debug, JIT — 핫리로드 가능
# r=hot reload, R=hot restart, q=quit
```

- 위젯/스타일 수정 → `r` 즉시 반영
- AnimationController 라이프사이클 변경, initState 수정 → `R`
- pubspec.yaml 변경, 에셋 추가, 네이티브 코드 → 풀 재빌드
- **릴리즈 모드는 핫리로드 불가** (AOT) — 출시 직전 회귀에만 사용

---

## §9. 권장 도입 순서

★ = 사용자가 명시한 *가장 중요* 영역(§4 아이템별 기능 + 디자인). 우선순위로 배치.

1. **★ §4 SoundService / HapticService 를 interface + fake 로 리팩토링** — 모든 아이템 테스트의 기반 (1시간)
2. **★ §4 아이템 타입별 함수 단위 테스트 19개** (§4-1 ~ §4-19 의 단위 케이스) — 사운드 enum / 팝업 title / 게임 상태 변화 검증. SwiftUI `_setAcquiredAlert` 와 1:1 매칭 (3시간)
3. **★ §4 아이템 타입별 골든 테스트** — 핀(미획득/획득) + AR 빌보드 + ItemAcquiredPopup 3종 × 19 타입 ≈ 57장. 작업 분량 크니 가장 자주 쓰는 5종(start/end/simple/quiz/mine) 먼저 (2시간)
4. **§1 단위 테스트 권장 4 케이스 추가** (gambling 순서, mission timeout, run expiry 재획득, start mine 손실) — 30분
5. **§2 화면 골든 12-15장** (맵/AR HUD/도움말 오버레이/미니게임) — 1-2시간
6. **§2 인터랙션 위젯 테스트 5-7개** (핀 탭 callout, 카메라 → AR push, 도움말 토글, ItemAcquiredPopup OK) — 1시간
7. **§5 기타 화면 골든** (List/Detail/Design/Builder/MyInfo/Badge/Settings) — 2시간
8. **§6 웹 헤드리스 스크린샷 스크립트** — 30분
9. **§0-3 pre-push 후크** — 5분

합계 ≈ 11-14시간 일회성 투자. 1-3번 (≈ 6시간) 만 해도 *아이템 회귀*는 자동 잡힘.

### 권장 디렉토리 구조

```
flutter_ar_spike/test/
├── game_engine_test.dart              # §1 (현재 7케이스)
├── unit/
│   ├── sound_service_test.dart        # 사운드 fake 검증
│   └── items/                         # §4 — 19개 아이템 단위
│       ├── start_test.dart
│       ├── end_test.dart
│       ├── simple_test.dart
│       ├── quiz_test.dart
│       ├── timeout_start_test.dart
│       ├── timeout_end_test.dart
│       ├── mine_test.dart
│       ├── mine_nobomb_test.dart
│       ├── random_test.dart
│       ├── black_test.dart
│       ├── solution_test.dart
│       ├── radar_ar_test.dart
│       ├── radar_map_test.dart
│       ├── radar_mine_test.dart
│       ├── radar_all_test.dart
│       ├── radar_black_test.dart
│       └── coupon_test.dart
├── widget/
│   ├── map_callout_test.dart          # §2-1 widget
│   ├── ar_acquire_test.dart           # §2-2 widget
│   ├── minigame_progress_test.dart    # §2-5 widget
│   ├── quiz_flow_test.dart            # §4-4 위젯
│   ├── gambling_alert_order_test.dart # §4-9 위젯
│   └── popup_callback_test.dart       # §2-6 widget
└── golden/
    ├── radar_disc_test.dart            # §2-2
    ├── map_screen_test.dart            # §2-1
    ├── ar_help_overlay_test.dart       # §2-4
    ├── minigame_test.dart              # §2-5
    ├── popups_test.dart                # §2-6
    └── items/                          # §4 — 19 × 3 = 57장
        ├── start_golden_test.dart
        ├── end_golden_test.dart
        └── ...
```

---

## §10. 헷갈릴 때 (절대 추측하지 말기)

| 의문 | 봐야 할 SwiftUI 파일 |
|---|---|
| 이 아이템 타입 사운드 뭐임? | `GameEngine.swift` `acquireItem` 내부 + `_setAcquiredAlert` |
| 이 위젯 패딩이 몇? | 해당 SwiftUI struct 의 `.padding(...)` 라인 |
| 이 색이 macaw 인지 macawDeep 인지? | `PlaySpot/DesignSystem/DuoTokens.swift` + 사용처 |
| 이 애니메이션 duration? | 해당 `withAnimation(.easeInOut(duration: ...))` 라인 |
| 이 한국어 문구가 정확한가? | `PlaySpot/Resources/Localizable.xcstrings` 키 검색 |
| viewport 안에 들어가는 조건? | `ARGameView.swift:356-378 nearestVisibleItem` |
| 지뢰 폭발 시 어떤 아이템이 사라지나? | `GameEngine.swift:358-380 memoryLastAcquiredItem` |
| 후보 선정 제외 조건? | `ARGameView.swift:313-333 nearestCandidateItem` |

**원칙**: Flutter 코드를 짤 때 SwiftUI 파일을 옆에 띄워두고 1:1 라인 단위로 옮긴다.
"비슷할 거야"는 곧 회귀. 골든 테스트가 실패하면 SwiftUI 와 다시 비교한다.

---

## §11. 실행 진행 상황 (2026-05-30 기준)

### 11-1. 최종 통계

| 항목 | 결과 |
|---|---|
| `flutter analyze` | **No issues found** |
| `flutter test` | **48 / 48 통과** (기존 7 + 신규 41) |
| `flutter build web` | ✓ Built `build/web` |
| 골든 PNG | 5장 `test/golden/goldens/` 저장 |
| **자동으로 잡은 SwiftUI 회귀** | **14건** (아래 11-4) |

### 11-2. §9 권장 순서 대비 진행률

| §9 # | 항목 | 상태 | 비고 |
|---|---|---|---|
| 1★ | SoundService/HapticService → interface + Fake | ✅ 완료 | factory 패턴으로 기존 호출부 무변경 |
| 2★ | 아이템별 함수 단위 19개 | ✅ 16개 완료 | quiz/quiz20/black 포함. radarBlack/penaltyRemove/store/num00-09 = SwiftUI default 분기(noop)라 생략 |
| 3★ | 아이템별 골든 (19 × 3 = 57장) | 🟡 부분 (5장) | 핵심 HUD/팝업 5장 우선. 나머지는 필요 시 추가 |
| 4 | §1 권장 추가 4 케이스 | 🟡 2/4 | Gambling prepend + start mine 손실 = ✅ / mission timeout + run 만료 재획득 = timer mock 필요해 deferred |
| 5 | §2 화면 골든 12-15장 | ⬜ 미착수 | Step 5에 5장만 |
| 6 | §2 인터랙션 위젯 테스트 | ⬜ 미착수 | 후속 |
| 7 | §5 기타 화면 골든 | ⬜ 미착수 | 후속 |
| 8 | §6 웹 헤드리스 스크립트 | ⬜ 미착수 | Playwright 설치 필요 |
| 9 | §0-3 pre-push 후크 | ✅ 파일 작성 | 활성화는 사용자 (11-6 참조) |

### 11-3. 생성된 산출물

#### 코드
- [`flutter_ar_spike/lib/services/sound_service.dart`](flutter_ar_spike/lib/services/sound_service.dart) — abstract `SoundService` + `RealSoundService` + **`FakeSoundService`**
- [`flutter_ar_spike/lib/services/haptic_service.dart`](flutter_ar_spike/lib/services/haptic_service.dart) — 같은 패턴, `HapticKind` enum + `FakeHapticService`
- [`flutter_ar_spike/lib/game/game_engine.dart`](flutter_ar_spike/lib/game/game_engine.dart) — `_setAcquiredAlert` 14개 문구 SwiftUI 1:1 / MM:SS 포맷 / Run End pre-check 제거

#### 테스트
- [`flutter_ar_spike/test/game_engine_test.dart`](flutter_ar_spike/test/game_engine_test.dart) — 기존 7 + Run End 거동 SwiftUI 동등 수정 (7/7)
- [`flutter_ar_spike/test/unit/items/_helpers.dart`](flutter_ar_spike/test/unit/items/_helpers.dart) — 공용 `FakeDataSource` + `buildEngine`
- [`flutter_ar_spike/test/unit/items_test.dart`](flutter_ar_spike/test/unit/items_test.dart) — 16 그룹 24 케이스
- [`flutter_ar_spike/test/unit/edge_cases_test.dart`](flutter_ar_spike/test/unit/edge_cases_test.dart) — §1 추가 4 케이스
- [`flutter_ar_spike/test/unit/sound_haptic_test.dart`](flutter_ar_spike/test/unit/sound_haptic_test.dart) — Fake 자체 + 시퀀스 8 케이스
- [`flutter_ar_spike/test/golden/hud_goldens_test.dart`](flutter_ar_spike/test/golden/hud_goldens_test.dart) + `goldens/` 5장

#### CI 게이트 (미활성)
- [`lefthook.yml`](lefthook.yml) — `analyze` + `test` 병렬 실행 설정
- [`scripts/pre_push_check.sh`](scripts/pre_push_check.sh) — lefthook 미사용 시 수동 게이트 (실행권한 부여됨)

### 11-4. 자동으로 잡힌 SwiftUI ↔ Flutter 회귀 (14건, 모두 수정)

[items_test.dart](flutter_ar_spike/test/unit/items_test.dart) 첫 실행에서 모두 빨개진 항목들. 이후 `game_engine.dart`의 `_setAcquiredAlert`를 SwiftUI 영문 그대로 교체해 모두 그린.

| # | 아이템 | Flutter (수정 전, 잘못됨) | SwiftUI (수정 후, 정답) |
|---|---|---|---|
| 1 | start title | `Start Item!` | `Start Item acquired!` |
| 2 | start msg | `미션을 시작합니다` | `If you touch OK, the item will be released Mission.` |
| 3 | simple title | `Hint!` | `Hint Item acquired!` |
| 4 | simple msg | `힌트` | `Lose the draw!! No hint.` |
| 5 | timeoutStart title | `Run Start!` | `Run Start Item acquired!` |
| 6 | timeoutStart msg | `제한 시간 60초 안에...` | `제한 시간 01:00 안에 Run End 아이템을 획득하세요.` (MM:SS 포맷) |
| 7 | timeoutEnd title | `Run End!` | `Run End Item acquired!` |
| 8 | timeoutEnd msg | `타임어택 성공!` | `Run time ended successfully.` |
| 9 | mineNoBomb title | `Defense!` | `Defence Item acquired!` (영국식 철자) |
| 10 | mineNoBomb msg | `지뢰 피해를 1번 막아줍니다` | `Mine damage can be avoided using this Defence item.` |
| 11 | random title | `Gambling!` | `Gambling acquired!` |
| 12 | random msg | `획득: Hint!` 또는 `꽝!...` | `You won: Hint!` 또는 `Gambling failed — no items left to win.` |
| 13 | solution title | `Solution!` | `Solution Item acquired!` |
| 14 | solution msg | `퀴즈 정답을 확인할 수 있어요` | `You can get an answer if you win mission quiz or quiz item.` |
| 15 | radarAR/Map/Mine/All title | `X Radar!` | `X Radar Item acquired!` |
| 16 | radarAR/... msg | (한국어 한 줄씩) | (영어 SwiftUI 그대로) |
| 17 | coupon title | `Coupon!` | `Coupon acquired!` |
| 18 | coupon msg | `쿠폰 획득` | `Coupon acquired. Check details with the designer.` |
| — | Run End pre-check | Flutter가 거부 알림 강제 | **제거** (SwiftUI는 pre-check 없음 — 그냥 acquire) |

### 11-5. 잔여 TODO

| 우선순위 | 작업 | 이유 |
|---|---|---|
| 중 | mission 제한시간 만료 + Run 만료 재획득 단위 테스트 | `_tick` 호출이 timer 의존이라 `fakeAsync` 또는 public 테스트 hook 필요 |
| 중 | ARHelpOverlay 골든 | `_ARHelpOverlay` 가 `ar_play.dart`의 private 클래스 — public 으로 노출 후 골든 |
| 중 | 미니게임 위젯 테스트 (탭 → 100 → pop(true)) | `MiniGameView` 자체 테스트 |
| 하 | 아이템별 핀/AR 빌보드 골든 (19 × 2 = 38장) | 시각 회귀 시 추가 |
| 하 | List/Detail/Design/Builder/MyInfo/Badge/Settings 골든 | 9 화면 골든 (§5) |
| 하 | 웹 헤드리스 스크린샷 스크립트 | Playwright 설치 후 6 라우트 |

### 11-6. **활성화 안내** (사용자 직접)

자동 검증 인프라는 다 만들었지만 *git push 동작 변경* 은 사용자 동의가 필요해 자동 활성화하지 않았습니다. 셋 중 하나 골라 활성화하세요:

```bash
# 옵션 A — lefthook (병렬, 가장 빠름)
brew install lefthook
lefthook install   # .git/hooks/pre-push 자동 생성

# 옵션 B — 단순 git hook 심볼릭 링크 (의존성 없음)
ln -sf ../../scripts/pre_push_check.sh .git/hooks/pre-push
chmod +x .git/hooks/pre-push

# 옵션 C — 활성화 없이 매번 수동 실행
bash scripts/pre_push_check.sh
```

활성화 후엔 `git push` 할 때마다 `flutter analyze` + 전체 48 테스트가 자동 실행, 하나라도 빨개지면 push 차단.

비활성화:
```bash
lefthook uninstall   # 옵션 A 사용 시
# 또는
rm .git/hooks/pre-push   # 옵션 A/B 공통
```

### 11-7. 다음 작업 시 시작점

후속 작업자는 §11-5 의 **잔여 TODO 중 우선순위 "중"** 부터 진행하면 됩니다.
새 SwiftUI 변경 사항이 생기면:

1. SwiftUI 소스 변경 라인 확인
2. 해당 §X 의 ground truth 줄 번호 갱신
3. 테스트 fail → Flutter 코드 수정 → 테스트 그린
4. (필요 시) 골든 `--update-goldens` 후 시각적으로 검토

이 사이클로 SwiftUI ↔ Flutter 의 1:1 동등성을 영구 유지.
