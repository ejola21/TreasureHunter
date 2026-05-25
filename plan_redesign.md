# PlaySpot Redesign — 실행 계획 (plan_redesign.md)

**Source of truth (디자인)**: [design_handoff_playspot_redesign/README.md](design_handoff_playspot_redesign/README.md)
**Source of truth (토큰)**: [design_handoff_playspot_redesign/swiftui_starter/DuoTokens.swift](design_handoff_playspot_redesign/swiftui_starter/DuoTokens.swift)
**대상 코드베이스**: 신규 `PlaySpot.xcodeproj` (`PlaySpot/`) — SwiftUI / Swift 5.10+ / iOS 16+
**작성일**: 2026-05-25
**기여 규칙**: [CLAUDE.md](CLAUDE.md) §"Build & Modification Rules" 준수 (특히 `project.yml` SOT, assets namespace, ATS, Personal Team)

---

## 0. 목적과 범위

Play Spot 의 25개 화면을 Duolingo-스타일 candy UI 로 전면 재디자인한다. 이 문서는 **무엇을 만들지·어디에 둘지·어떤 순서로 만들지·어떻게 검증할지** 를 명시한 실행 계획이다. 코드 자체는 단계별로 PR 로 분리해 머지한다.

**범위**:
- 5탭 메타 네비게이션 (Missions / Design / My Info / Badge / Settings)
- 플레이 플로우 (Mission Info → Map Play → AR Search → AR Mini-game → Hint)
- 디자인 플로우 (Design List → Action Sheet → Map Edit → Picker → Item Detail → Mission Edit)
- 도움말/온보딩 플로우 (Help Items / How to Play / Mission Design / Tutorial)

**범위 외** (이 문서가 다루지 않는 것):
- 백엔드 변경 — `/api/v1/**` REST 는 유지. 자세한 내용은 [api_plan_new.md](api_plan_new.md).
- 가상모드 정확도 버그 수정 — 별도 트랙 ([memory/project_virtual_mode_bug.md])
- StoreKit 결제 흐름 — Personal Team 제약 유지

---

## 1. 디자인 시스템 정리

### 1.1 토큰 SOT — `DuoTokens.swift`

스타터 파일이 다음을 이미 제공한다:
- **Colors** — `Color.duoGreen500`, `duoMacaw`, `duoCardinal`, `duoBee`, `duoFox`, `duoBeetle`, `duoSwan*`, `duoEel*` 등 ~30개
- **Fonts** — `Font.duoDisplay(size:)` (Jalnan2), `Font.duoBody(size:weight:)` (Nunito)
- **Spacing/Radius** — `DuoSpace.s1…s12`, `DuoRadius.xs…pill`
- **Components** — `CandyButtonStyle` (5 variants × 3 sizes), `DuoCard`, `DuoChip`, `DuoKicker`

### 1.2 DuoTokens 확장 필요 항목

핸드오프 `tokens.css` 와 `app.css` 를 비교해 추가해야 할 토큰:

| 누락 토큰 | 값 | 용도 |
|---|---|---|
| `duoMacawNavBg` | `#E1F4FF` | BottomNav active tile bg |
| `duoMacawNavBorder` | `#91D7F6` | BottomNav active tile border |
| `duoGreen400` | `#8EE000` | section pill highlight |
| `duoPolar` | `#F0F0F0` | card hover bg |
| `duoCardinalBg` | `#FFDFE0` | danger chip bg (이미 있음 ✓) |
| `hudTealStart/End` | `#2A8794`, `#1A5E69` | In-game top HUD gradient |
| `hudDarkStart/End` | `#1A5E69`, `#0E3A42` | AR Hint/Found dark HUD |
| `radarGreenLight/Dark` | `#6CD87F`, `#1A5223` | AR Radar widget gradient |
| `duoFoxBg` | `#FFE7CE` (이미 있음 ✓) | warning chip |
| `ghostButton` shadow | `#EBEBEB` | `--ghost` CandyButton variant |

→ Phase 0 에서 `DuoTokens.swift` 에 추가 후 PlaySpot 프로젝트로 이동.

### 1.3 신규 컴포넌트 (DuoTokens.swift 에 없는 것)

| 컴포넌트 | 설명 | 우선순위 |
|---|---|---|
| `PSToggle` | 56×32 알약형 토글 (ON/OFF 라벨 + 26 knob) | P0 |
| `Stepper` | 30px 알약 (−/+ 36×24, snow bg, swan border) | P0 |
| `FormGroup` | kicker + DuoCard + footer hint 묶음 | P0 |
| `FormRow` / `FieldRow` | 폼 내부 1줄 (label + value + chevron + divider) | P0 |
| `SegBtn` / `SegmentedTabs` | 흰 배경 + 활성 액센트 (3-탭 POPULAR/NEW/NEAR ME) | P0 |
| `BottomNav5` | 5탭 커스텀 바 (TabView 의 기본 탭바 교체) | P0 |
| `PSStatusBar` | 시뮬용 — 실제로는 시스템 status bar 사용. 디자인 핸드오프 검증용 placeholder | P3 |
| `FoxMascot` | 4 pose (wave/sit/think/cheer) — SVG 대신 PNG 5장 추가 또는 SF Symbols placeholder | P1 |
| `ItemPin` | i_*.png 17개 → namespace `Items/` 에 imageset + size/active/glow modifier | P0 |
| `ARRadar` | 64×64 컴퍼스 (그라데이션 + sweep + needle + blip) | P1 |
| `SparkleBurst` | 14 particle Canvas / TimelineView | P2 |
| `WordmarkPlaySpot` | playspot_logo.png 외곽선 + filter (brightness/saturate) | P2 |
| `DigitClock` | `00:09:00` 7-세그먼트 스타일 디지트 6~8개 | P1 |
| `PSChip` 확장 | `DuoChip` 색상 변형 — orange/red/blue/purple/yellow 프리셋 | P0 |

---

## 2. 화면 인벤토리 (디자인 ↔ 현재 코드)

| # | 디자인 ID | 디자인 화면 | 현재 SwiftUI | 작업 유형 | Phase |
|---|---|---|---|---|---|
| 1 | `list` | Mission List | [MissionListView.swift](PlaySpot/Views/MissionList/MissionListView.swift) | 전면 재작성 | 3 |
| 2 | `mission-info` | Mission Info | [MissionDetailView.swift](PlaySpot/Views/MissionList/MissionDetailView.swift) | 재디자인 | 4 |
| 3 | `map-play` | Map Play | [MissionPlayView.swift](PlaySpot/Views/MissionPlay/MissionPlayView.swift) (522줄) | HUD/도크 재디자인 (게임 로직 보존) | 4 |
| 4 | `ar-search` | AR Searching | [ARGameView.swift](PlaySpot/AR/ARGameView.swift) | 톱바/하단 HUD + ARRadar | 4 |
| 5 | `ar-touch` / `ar-party` | AR Mini-game | [MiniGameView.swift](PlaySpot/Views/MissionPlay/MiniGameView.swift) | 흔들기/터치 + 파티클 | 4 |
| 6 | `hint` | Hint Acquired Popup | (신규) | 모달 컴포넌트 | 4 |
| 7 | `map-edit` | Map Edit | [BuilderMapView.swift](PlaySpot/Views/MissionBuilder/BuilderMapView.swift) | HUD/도크/팔레트 재디자인 | 5 |
| 8 | `map-edit-picker` | Map Edit + Picker | [ItemPickerView.swift](PlaySpot/Views/MissionBuilder/ItemPickerView.swift) | 3-column 드럼 신규 | 5 |
| 9 | `item-detail-v2` | Item Detail (모든 kind 통합) | [ItemDetailView.swift](PlaySpot/Views/MissionBuilder/ItemDetailView.swift) + [ItemForms.swift](PlaySpot/Views/MissionBuilder/ItemForms.swift) | 재디자인 + 통합 | 5 |
| 10 | `design-list-v2` | Design List | [MissionBuilderView.swift](PlaySpot/Views/MissionBuilder/MissionBuilderView.swift) | 신규 + 공개/비공개 섹션 | 5 |
| 11 | `mission-edit-v2` | Mission Edit | [MissionSetupView.swift](PlaySpot/Views/MissionBuilder/MissionSetupView.swift) | 폼 그룹 재디자인 | 5 |
| 12 | `design-action` | Design Action Sheet | (신규) | confirmationDialog 또는 커스텀 시트 | 5 |
| 13 | `badges-v2` | Badge List | [BadgeListView.swift](PlaySpot/Views/MyInfo/BadgeListView.swift) | 티얼 헤더 + 그리드 재디자인 | 3 |
| 14 | `my-info` | My Info | [MyInfoView.swift](PlaySpot/Views/MyInfo/MyInfoView.swift) | 카드형 재디자인 | 3 |
| 15 | `settings` | Settings | [SettingsView.swift](PlaySpot/Views/Settings/SettingsView.swift) | 폼 그룹 + SegBtn 재디자인 | 3 |
| 16 | `help-items` | Help · Item Glossary | (신규) | Help 플로우 진입 화면 | 6 |
| 17 | `help-howto` | Help · How to Play | (신규) | Marketing 스타일 | 6 |
| 18 | `help-design` | Help · Mission Design | (신규) | 5-step 가이드 | 6 |
| 19 | `tutorial` | Onboarding Tutorial | `TutorialPagerView` (in [SettingsView.swift](PlaySpot/Views/Settings/SettingsView.swift)) | 3-step 인터랙티브 재작성 | 6 |
| 20 | `item-acquired` | Item Acquired Popup | (신규) | Modal | 4 |
| 21 | `mission-info-mode-sheet` | Virtual/Real 모드 선택 | [StartGameView.swift](PlaySpot/Views/MissionPlay/StartGameView.swift) 부분 | Mission Info 오버레이 | 4 |
| 22 | `quiz` | Quiz Modal | [QuizView.swift](PlaySpot/Views/MissionPlay/QuizView.swift) | candy 스타일 보정 | 4 |
| 23 | `mission-complete` | Clear 화면 | [MissionCompletePopup.swift](PlaySpot/Views/MissionPlay/MissionCompletePopup.swift) | candy 보정 | 4 |
| 24 | `mission-timeout` | 타임아웃 | [MissionTimeoutPopup.swift](PlaySpot/Views/MissionPlay/MissionTimeoutPopup.swift) | candy 보정 | 4 |
| 25 | `auth` | Login/Register | [LoginView.swift](PlaySpot/Views/Auth/LoginView.swift), [RegisterView.swift](PlaySpot/Views/Auth/RegisterView.swift) | candy 보정 (디자인 핸드오프 외 — 자체 추가) | 7 |

**총계**: 25화면 (디자인 핸드오프 24 + Auth 1 자체 보정). 모달 6개 (Hint, Action Sheet, Mode Sheet, Item Acquired, Quiz, Complete/Timeout) 포함.

---

## 3. 어셋 인벤토리

### 3.1 신규로 추가할 PNG

**`design_handoff_playspot_redesign/source/assets/items/` → `PlaySpot/Assets.xcassets/Items/`** (이미 일부 있음, 교체/추가):

```
i_start.png         i_end.png           i_simple.png        (hint)
i_mine.png          i_mine_nobomb.png   (defence)
i_random_box.png    (gambling)
i_quiz.png          i_genius.png        (solution)
i_ox_o.png          i_ox_x.png          (quiz variants)
i_radar_map.png     i_radar_mine.png    i_radar_ar.png      (stealth)
i_radar_all.png
i_time_start.png    i_time_end.png
i_black.png         i_store.png         i_coupon.png        i_hospital.png
```

19개. 모두 162×162 3x PNG. 각 imageset Contents.json 에 `"scale": "3x"` 만 넣고 1x/2x 는 비워둠.

기존 [Items/](PlaySpot/Assets.xcassets/Items/) 에 같은 이름 imageset 이 있으면 **PNG 만 교체** (Contents.json 보존). 없으면 imageset 생성.

→ Phase 0 의 일회성 스크립트 `scripts/migrate_redesign_assets.sh` 로 처리 권장.

### 3.2 미니게임 어셋

**`design_handoff/source/assets/minigame/` → `PlaySpot/Assets.xcassets/Minigame/`** (신규 namespace):

```
playspot_logo.png         (외곽선 워드마크)
playspot_logo_color.png   (컬러 워드마크 — Item Acquired 모달용)
shake_0.png  shake_1.png  (흔들기 미니게임 2프레임)
touch_0.png  touch_1.png  (터치 미니게임 2프레임)
```

코드 호출: `Image("Minigame/playspot_logo")` (namespace 사용 — group `provides-namespace: true` 설정).

### 3.3 폰트

**`design_handoff/source/styles/fonts/Jalnan2.ttf` → `PlaySpot/Resources/Fonts/Jalnan2.ttf`**

추가 작업:
1. `project.yml` 의 `resources:` 블록에 `PlaySpot/Resources/Fonts/Jalnan2.ttf` 추가
2. `PlaySpot/Info.plist` 에 `UIAppFonts = ["Jalnan2.ttf"]` 추가
3. `xcodegen generate` 실행 후 시뮬에서 `UIFont.familyNames` 로 등록 확인

Nunito 는 시스템 폴백 사용 (별도 번들 불필요).

### 3.4 Fox Mascot (선택)

README §"Fox Mascot" 는 SVG placeholder 다. 실제 일러스트 없으면 옵션 두 가지:
- **Option A**: PNG 4장 (`fox_wave`, `fox_sit`, `fox_think`, `fox_cheer`) 외주 또는 임시 일러스트 사용
- **Option B**: SF Symbols `face.smiling.fill` + 표정별 색상 변형 (임시)

Phase 1 에서 Option B 로 시작, Phase 7 직전 외주 일러스트로 교체.

---

## 4. Phase 0–7 실행 계획

### Phase 0 — Foundation (1일)

**목표**: 디자인 시스템을 코드베이스에 통합. 이후 모든 화면이 이 기반 위에 쌓인다.

**Deliverables**:
- [ ] `PlaySpot/Views/DesignSystem/DuoTokens.swift` — 스타터 파일을 복사 + §1.2 의 누락 토큰 13개 추가
- [ ] `PlaySpot/Resources/Fonts/Jalnan2.ttf` 추가 + `project.yml` resources 등록 + `Info.plist` UIAppFonts
- [ ] `scripts/migrate_redesign_assets.sh` 작성 + 실행 (i_*.png 19개 + minigame 6개 imageset 등록)
- [ ] `xcodegen generate` → 시뮬 빌드 성공
- [ ] `DuoTokens_Previews` 가 Jalnan2 폰트로 렌더되는지 확인

**검증**:
```bash
xcodebuild -project PlaySpot.xcodeproj -scheme PlaySpot \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  build CODE_SIGNING_ALLOWED=NO
# DuoTokens_Previews 가 표시되는 single-view 테스트 앱 또는 #Preview
```

**위험**:
- Jalnan2 PostScript name 이 `"Jalnan2"` 가 아닐 수 있음 → `UIFont(name:size:)` 로 실제 등록명 확인 필요
- 기존 `Items/i_*.imageset` 과 충돌 — 마이그레이션 스크립트는 dry-run 모드로 먼저 확인

---

### Phase 1 — Reusable Components (2일)

**목표**: 모든 화면이 의존하는 11개 컴포넌트를 미리 만들어 두기.

**Deliverables** (모두 `PlaySpot/Views/DesignSystem/` 에 위치):

| 파일 | 컴포넌트 |
|---|---|
| `PSToggle.swift` | `PSToggle(isOn: Binding<Bool>, tint:)` |
| `Stepper.swift` | `DuoStepper(value: Binding<Int>, range:, step:)` |
| `FormGroup.swift` | `FormGroup<C: View>(title:, subtitle:, @ViewBuilder content)` |
| `FormRow.swift` | `FormRow(label:, value:, link:, action:, isLast:)` |
| `SegBtn.swift` | `SegmentedTabs<T: Hashable>(selection:, options:, theme:)` |
| `BottomNav5.swift` | `BottomNav5(active: Binding<MainTab>)` 5탭 커스텀 바 |
| `FoxMascot.swift` | `FoxMascot(pose:, size:)` — Phase 1 은 SF Symbol placeholder |
| `ItemPin.swift` | `ItemPin(kind: ItemType, size:, active:, glow:, dimmed:)` |
| `DuoChip+Presets.swift` | `.green`, `.red`, `.orange`, `.blue`, `.purple`, `.yellow` static helpers |
| `DigitClock.swift` | `DigitClock(seconds: Int, style:)` |
| `WordmarkPlaySpot.swift` | `WordmarkPlaySpot(progress: Double)` brightness/saturate filter |

**검증**:
- 각 컴포넌트마다 `#Preview` 4종 (기본 / 활성 / 다크 / 라지) 작성
- 단일 카탈로그 화면 `PSDesignSystemPreview.swift` 에 모두 모아 시뮬 스크린샷

**위험**:
- `BottomNav5` 가 SwiftUI 의 `TabView` 와 어떻게 조합되는지 — TabView 의 기본 탭바 숨김(`.toolbar(.hidden, for: .tabBar)`) 후 ZStack 으로 커스텀 바 오버레이 패턴 사용
- `Stepper` 는 SwiftUI 의 기본 `Stepper` 와 이름 충돌 가능 → `DuoStepper` 로 명명

---

### Phase 2 — Atomic Visual Assets (1일)

**목표**: AR 화면 시각 요소.

**Deliverables**:
- [ ] `PlaySpot/Views/DesignSystem/ARRadar.swift` — 64px 그라데이션 + sweep (`TimelineView(.animation)`) + needle + blip
- [ ] `PlaySpot/Views/DesignSystem/SparkleBurst.swift` — Canvas 또는 14× `@State Particle` 배열 + `withAnimation` 트리거
- [ ] `PlaySpot/Views/DesignSystem/PulseRing.swift` — 플레이어 위치/AR 핀 펄스 (scale 0.6→2.4, opacity 0.55→0)

**검증**: `PSDesignSystemPreview` 카탈로그에 추가 → 시뮬 영상으로 60fps 유지 확인

**위험**: 파티클 14개를 SwiftUI 로 매 프레임 갱신하면 성능 이슈 가능 → 옵션 B = SpriteKit 오버레이. 우선 Canvas 로 시도, 30fps 이하 떨어지면 전환.

---

### Phase 3 — Meta Navigation (2~3일)

**목표**: 5탭 메인 네비게이션 + 4개 메타 화면. 앱을 열면 바로 candy UI 가 보이는 단계.

**대상 화면** (5):
1. **Mission List** (`list`) → 재작성
2. **My Info** (`my-info`) → 재작성
3. **Badge List v2** (`badges-v2`) → 재작성
4. **Settings** (`settings`) → 재작성
5. **MainTabView** → `BottomNav5` 로 교체

**Deliverables**:
- [ ] [MainTabView.swift](PlaySpot/Views/App/MainTabView.swift) — 시스템 탭바 제거 + `BottomNav5` 오버레이
- [ ] [MissionListView.swift](PlaySpot/Views/MissionList/MissionListView.swift) + [MissionRowView.swift](PlaySpot/Views/MissionList/MissionRowView.swift) — 헤더(Fox + Streak/Gem chip) + SegmentedTabs(POPULAR/NEW/NEAR ME) + MissionCard 64×64 avatar + level circle + plays/fails chips
- [ ] [MyInfoView.swift](PlaySpot/Views/MyInfo/MyInfoView.swift) — Profile card + ITEMS/DESIGNED/PLAYED FormGroup
- [ ] [BadgeListView.swift](PlaySpot/Views/MyInfo/BadgeListView.swift) — 티얼 헤더 (`#1C8A9F`) + 3-col 그리드 + 잠금 셀 (grayscale)
- [ ] [SettingsView.swift](PlaySpot/Views/Settings/SettingsView.swift) — FormGroup × 5 (ACCOUNT / API BACKEND / DEBUG / TUTORIAL / ABOUT) + SegBtn (Legacy/REST)

**상태 보존**:
- Settings 의 API Backend 토글, 401 시뮬 버튼은 기존 로직 보존 — UI 만 교체
- MissionList 의 selectedTab/loadMissions/refreshable 동작 보존 — 디자인 탭 ID 매핑은 `popular=2(All), new=0(Playing), near=1(Near Me)` 로 우선 매핑 (서버에 popular/new 분리 호출 없으면 디자인 라벨만 변경)
- BadgeList 의 playMilestones 19개 / playedMissions API 로직 보존

**검증**: `bash scripts/verify.sh` 로 5탭 모두 진입 + 스크린샷 4장

**위험**:
- MainTabView 의 `if appState.isGuest && [1,2,3].contains(newTab)` 가드는 BottomNav5 에서도 동일하게 구현 — 디자인은 5탭 전부 노출이지만 게스트 차단 정책은 유지
- 디자인의 4가지 액센트 컬러 토글 (green/blue/orange/purple) — Phase 7 까지는 green 고정. Tweaks 패널은 프로토타입 전용 (README §"Don't ship the Tweaks panel")

---

### Phase 4 — Play Flow (3~4일)

**목표**: 미션을 실제로 플레이하는 전체 흐름.

**대상 화면** (9):
1. **Mission Info** (`mission-info`)
2. **Mode Sheet** (Virtual/Real 오버레이)
3. **Map Play** (`map-play`)
4. **AR Search** (`ar-search`)
5. **AR Mini-game** (`ar-touch`, `ar-party`)
6. **Hint Popup** (`hint`)
7. **Item Acquired Popup** (`item-acquired`)
8. **Quiz Modal** (`quiz`)
9. **Mission Complete / Timeout**

**Deliverables**:
- [ ] [MissionDetailView.swift](PlaySpot/Views/MissionList/MissionDetailView.swift) — 영웅 카드 (avatar+stars+plays/fails) + 6 InfoRow + 핀 프리뷰 + "PLAY" CandyButton + Mode Sheet 오버레이
- [ ] [MissionPlayView.swift](PlaySpot/Views/MissionPlay/MissionPlayView.swift) — 게임 로직 (GameEngine) 보존 + UI 만 분리해 재작성: 상단 HUD (`hudTealStart/End` 그라데이션) + EXIT (red Candy) + DigitClock + Locate/Info 36×36 + 하단 HUD (남은지형/남은필수/카메라/Hidden/Stealth segments + 62px floating Camera 버튼)
- [ ] [ARGameView.swift](PlaySpot/AR/ARGameView.swift) — 톱바 (MAP 버튼 + DigitClock) + 카메라 배경 (`ARCameraView` 유지) + 부유 핀 (PulseRing + ItemPin glow) + 하단 ARBottomHud (방향 화살표 + ARRadar 중앙 + 유효반경 m 표시)
- [ ] [MiniGameView.swift](PlaySpot/Views/MissionPlay/MiniGameView.swift) — 외곽선 워드마크 (filter 진행도 반영) + 흔들기/터치 phone PNG (0.7s 토글 + tap 마다 progress 4–8 증가) + SparkleBurst + glow halo + 하단 안내문구 ("흔드세요!"/"터치하세요!") + N/100 카운터
- [ ] `HintPopup.swift` (신규) — Blurred AR 배경 + 모달 카드 (hint 핀 -16/-22 오버랩) + Reward chip strip (+15 XP / +1 Gem) + 확인 CandyButton + 하단 dark 바 + 미션종료 red Candy
- [ ] `ItemAcquiredPopup.swift` (신규) — 컬러 워드마크 + 아이템 핀 48px + 본문 + 주황 OK 버튼 (inset shadow)
- [ ] [QuizView.swift](PlaySpot/Views/MissionPlay/QuizView.swift) — DuoCard 안 질문 + 답안 입력 + 정답/오답 피드백 + Candy 확인 버튼
- [ ] [MissionCompletePopup.swift](PlaySpot/Views/MissionPlay/MissionCompletePopup.swift), [MissionTimeoutPopup.swift](PlaySpot/Views/MissionPlay/MissionTimeoutPopup.swift) — DuoCard + CandyButton 보정

**상태 보존**:
- GameEngine (setup async / dataSource.fetchMissionDetail) 완전 보존
- AR 좌표 변환 ([ARCoordinate.swift](PlaySpot/AR/ARCoordinate.swift)) 보존
- 가상모드 위치 오프셋 처리 보존 ([memory/project_virtual_mode_bug.md] 참고)

**검증**:
- 가상모드 미션 플레이 풀 흐름 시뮬 테스트
- 스크린샷: mission-info / map-play / ar-search / mini-game / hint / item-acquired / quiz / complete

**위험**:
- MapPlay 의 MapKit annotation 커스터마이즈가 SwiftUI `Map` 에서 가능한지 — iOS 17 의 `Map(content:)` + `Annotation` 사용 필수
- AR 카메라 배경 위에 SwiftUI overlay 합성 시 frame timing — `ARCameraView` 는 UIViewRepresentable, 그 위에 SwiftUI ZStack 으로 HUD 올림
- MiniGame 의 SparkleBurst 60fps — Phase 2 에서 미리 검증

---

### Phase 5 — Design Flow (3~4일)

**목표**: 사용자가 자작 미션을 만들고 편집하는 흐름.

**대상 화면** (6):
1. **Design List v2** (`design-list-v2`)
2. **Design Action Sheet** (`design-action`)
3. **Map Edit** (`map-edit`)
4. **Map Edit Picker** (`map-edit-picker`)
5. **Item Detail v2** (`item-detail-v2`)
6. **Mission Edit v2** (`mission-edit-v2`)

**Deliverables**:
- [ ] [MissionBuilderView.swift](PlaySpot/Views/MissionBuilder/MissionBuilderView.swift) → Design List 로 재작성. + 버튼 (36×36 green) / "내 디자인" 28px display / 비공개 FormGroup (orange chip) / 공개 FormGroup (green chip) / 헬퍼 텍스트 / 행 우측 "테스트" 플레이 버튼 + chevron
- [ ] `DesignActionSheet.swift` (신규) — Modify/Test/Upload 3행 (icon badge + text + chevron) + CANCEL ghost. iOS `.confirmationDialog` 으로는 디자인 충실도 부족 → 커스텀 `.sheet(...)` 또는 ZStack 오버레이
- [ ] [BuilderMapView.swift](PlaySpot/Views/MissionBuilder/BuilderMapView.swift), [MissionBuilderMapView.swift](PlaySpot/Views/MissionBuilder/MissionBuilderMapView.swift) — Map Edit 재디자인: 상단 (CANCEL ghost / "EDITING" 타이틀 / SAVE primary) + Map 영역 (MapKit + 미션 라디우스 dashed + 지뢰 blast red circle + 아이템 핀 + 타겟 reticle + 체커 깃발) + 헬퍼 토스트 (dark eel-2 + Fox think + 안내문) + 하단 팔레트 (44px white 타일 14개)
- [ ] [ItemPickerView.swift](PlaySpot/Views/MissionBuilder/ItemPickerView.swift) — Map Edit + Picker: 상단 map 프리뷰 (240pt) + 3-column 드럼 (ITEM / DISPLAY / VISIBLE RANGE). 드럼은 `ScrollViewReader` + `GeometryReader` + scroll-snap (옵션: `.scrollTargetBehavior(.viewAligned)` iOS 17+)
- [ ] [ItemDetailView.swift](PlaySpot/Views/MissionBuilder/ItemDetailView.swift) + [ItemForms.swift](PlaySpot/Views/MissionBuilder/ItemForms.swift) — Item Detail v2: 취소/완료 텍스트 링크 (macaw 블루) + 아이템 정보 카드 (56px 핀 + 이름 + 설명) + Tip 카드 (yellow bee-bg) + per-item 섹션 (필수 토글 / 발견 거리 Stepper / 폭발 반경 fox 컬러 / Hint mini-game dropdown / Quiz 질문답 textarea / Run End 시간제한 등) + 삭제 버튼 (cardinal red, trash icon)
- [ ] [MissionSetupView.swift](PlaySpot/Views/MissionBuilder/MissionSetupView.swift) — Mission Edit v2: < 내 디자인 취소 / 저장 / "미션 편집" 28px + 4 FormGroup (기본정보 / 설명 / 플레이 제한 시간 / 플레이 설정)

**상태 보존**:
- MissionBuilder 자작 미션 PlayStateRepository / MissionBuilderRepo 보존
- 좌표/실제반경 검증 로직 보존
- 배지 업로드 파이프라인 (최근 commit `634e4bc`) 보존

**위험**:
- 드럼 피커는 SwiftUI 기본 `Picker(.wheel)` 로는 디자인 충실도 부족. 커스텀 구현 필요 — Phase 2 에서 빠르게 PoC 권장
- Map Edit 의 드래그·롱프레스 인터랙션은 MapKit `Map` 의 한계로 SwiftUI 만으로 어려움 → UIViewRepresentable 로 `MKMapView` 직접 사용 검토

---

### Phase 6 — Help & Tutorial (2일)

**목표**: 도움말 3-탭 + 온보딩 3-step.

**대상 화면** (4):
1. **Help · Item Glossary** (`help-items`)
2. **Help · How to Play** (`help-howto`)
3. **Help · Mission Design** (`help-design`)
4. **Tutorial Onboarding** (`tutorial`)

**Deliverables**:
- [ ] `HelpItemsView.swift` (신규) — 백버튼 + "HELP · 도움말" kicker + 탭 (ITEMS/HOW TO PLAY/DESIGN) + Property legend (4 row 미니 뱃지) + 5개 그룹 (Mission/Quiz/Radar/Time/Special) — 색상 헤더 + 아이템 row (42px 핀 + 영문/한글명 + 필수 chip + 설명)
- [ ] `HelpHowToView.swift` (신규) — orange 그라데이션 hero + 2-card 모드 비교 (LIVE green / HOME purple) + 4 PlayStep (numbered orange circle + 미니 visual) + 다크 reward strip (XP/Gems/Streak/Badge perk chip) + Fox + 말풍선
- [ ] `HelpDesignView.swift` (신규) — purple 그라데이션 hero + 5 DesignStep (numbered circle + 80×80 미니 visual) + "미션 만들기 시작!" purple CandyButton
- [ ] `TutorialView.swift` (신규, `TutorialPagerView` 대체) — SKIP + 3-dot progress (active 22px 바) + X close + Step kicker/title + faux demo device (펄스 핀 + 손가락/탭 ripple + 팁 버블) + Fox + 말풍선 + BACK/NEXT/"LET'S PLAY!" 버튼

**상태 보존**:
- 기존 `TutorialPagerView` 는 `Tutorial/tutorial0_en.png` 같은 정적 PNG 슬라이드 — 신규 디자인은 인터랙티브 SwiftUI 로 대체. 정적 PNG 자체는 deprecate (asset catalog 에서 삭제는 Phase 7)

**진입점**:
- Help 3탭: Settings 의 "How to Play" 링크 + Mission List 의 추후 추가될 ? 버튼
- Tutorial: 첫 진입 / Settings 의 "How to Play" 버튼

**위험**:
- Help 의 16개 아이템 row 데이터 모델 — `ItemType` enum 에 `localizedName`, `description`, `category` 추가 필요. 데이터 소스는 코드 상수로 두는 게 무난 (서버 동기화 불필요)

---

### Phase 7 — Cleanup & Polish (1~2일)

**목표**: 마무리 + Auth 화면 보정 + 회귀 검증.

**Deliverables**:
- [ ] [LoginView.swift](PlaySpot/Views/Auth/LoginView.swift), [RegisterView.swift](PlaySpot/Views/Auth/RegisterView.swift) — DuoCard + FormRow + Candy 보정
- [ ] [ContentView.swift](PlaySpot/Views/App/ContentView.swift) — splash/loading 보정 (필요시)
- [ ] [GameTooltipView.swift](PlaySpot/Views/Components/GameTooltipView.swift), [LoadingHUD.swift](PlaySpot/Views/Components/LoadingHUD.swift) — Candy 보정
- [ ] [StarRatingView.swift](PlaySpot/Views/Components/StarRatingView.swift), [StarRatingPicker.swift](PlaySpot/Views/Components/StarRatingPicker.swift) — bee 색상 + display font
- [ ] 색상 테마 토글 — Settings 에 액센트(green/blue/orange/purple) 선택 추가? (옵션, README §"Tweaks" 는 prod 비노출 원칙이지만 4 theme 자체는 살릴 수 있음) → **결정 보류, Open Question §"테마 토글" 로 기록**
- [ ] Fox 일러스트 외주 교체 (SF Symbol → PNG)
- [ ] 레거시 `TreasureHunter.xcodeproj` 는 그대로 둠 (참고용)
- [ ] 미사용 어셋 정리 — 옛 `Tutorial/tutorial0_en` 등은 별도 PR 에서 제거

**최종 검증**:
- [ ] `bash scripts/verify.sh "iPhone 16 Pro"` — 풀 흐름 스크린샷
- [ ] `bash scripts/smoke_new_api.sh` — REST 22 케이스 회귀 통과
- [ ] 가상모드 + 실모드 양쪽 풀 미션 1회씩 플레이
- [ ] new_screen/ 폴더에 phase 별 베이스라인 스크린샷 추가 (최근 commit `954efc0` 패턴)

---

## 5. 네비게이션 그래프 (SwiftUI 매핑)

```
PlaySpotApp.swift (root)
└─ ContentView
   └─ MainTabView          // BottomNav5 커스텀
      ├─ NavigationStack [tab=0]
      │  ├─ MissionListView (`list`)
      │  └─ MissionDetailView (`mission-info`)
      │     ├─ overlay: ModeSheet
      │     ├─ navigate: MissionPlayView (`map-play`)
      │     │  ├─ sheet:    ARGameView (`ar-search`)
      │     │  │  ├─ sheet: MiniGameView (`ar-touch`/`ar-party`)
      │     │  │  │  └─ HintPopup (`hint`) → ItemAcquiredPopup
      │     │  ├─ sheet:    QuizView (`quiz`)
      │     │  └─ sheet:    MissionCompletePopup / MissionTimeoutPopup
      ├─ NavigationStack [tab=1]
      │  ├─ MissionBuilderView (`design-list-v2`)
      │  ├─ DesignActionSheet (overlay)
      │  ├─ BuilderMapView (`map-edit`)
      │  │  ├─ sheet: ItemPickerView (`map-edit-picker`)
      │  │  └─ sheet: ItemDetailView (`item-detail-v2`)
      │  └─ MissionSetupView (`mission-edit-v2`)
      ├─ NavigationStack [tab=2]
      │  └─ MyInfoView (`my-info`)
      ├─ NavigationStack [tab=3]
      │  └─ BadgeListView (`badges-v2`)
      └─ NavigationStack [tab=4]
         └─ SettingsView (`settings`)
            ├─ sheet: TutorialView (`tutorial`)
            ├─ sheet: HelpItemsView (`help-items`)
            ├─ sheet: HelpHowToView (`help-howto`)
            └─ sheet: HelpDesignView (`help-design`)
```

**원칙**:
- 탭 간 이동은 `BottomNav5` 가 처리. 각 탭은 독립 `NavigationStack`.
- 모달성 화면 (Quiz, Hint, Item Acquired, Mode Sheet, Design Action Sheet, Tutorial, Help) 은 `.sheet(...)` 또는 ZStack 오버레이.
- AR Search → Mini-game → Hint 체인은 같은 sheet 내에서 `@State` 단계 전환 (sheet 중첩 X — iOS 의 sheet 중첩은 어색함).

---

## 6. 디자인 시스템 사용 예 (스니펫 가이드)

### 6.1 Candy Button

```swift
Button("Mission Start!") { onStart() }
    .buttonStyle(.primary)     // DuoTokens.swift 의 CandyButtonStyle.primary
```

### 6.2 FormGroup

```swift
FormGroup(title: "기본 정보") {
    FormRow(label: "제목", value: $title, link: false)
    FormRow(label: "장소", value: $place, link: false, isLast: false)
    FormRow(label: "좌표로 장소 자동 채우기", icon: "search", action: autoFillPlace)
}
```

### 6.3 Mission Card (List)

```swift
HStack(spacing: 12) {
    ItemPin(kind: .start, size: 56)
        .overlay(alignment: .topTrailing) { LevelCircle(level: 1) }
    VStack(alignment: .leading, spacing: 4) {
        Text(mission.title).font(.duoDisplay(size: 15)).foregroundColor(.duoEel2)
        Text(mission.description).font(.duoBody(size: 11)).foregroundColor(.duoWolf2)
        HStack(spacing: 6) {
            StarRatingView(rating: mission.recommendAvg, starSize: 12)
            Text(mission.place.uppercased()).font(.duoBody(size: 9, weight: .heavy)).foregroundColor(.duoMacaw)
        }
    }
    Spacer()
    VStack(spacing: 4) {
        DuoChip(label: "\(mission.playCnt) PLAYS", bg: .duoGreen100, fg: .duoGreen800)
        DuoChip(label: "\(mission.failCnt) FAILS", bg: .duoCardinalBg, fg: .duoCardinalDeep)
    }
}
.padding(12)
.background(RoundedRectangle(cornerRadius: DuoRadius.xl).fill(Color.white))
.overlay(RoundedRectangle(cornerRadius: DuoRadius.xl).stroke(Color.duoSwan2, lineWidth: 2))
```

---

## 7. 테마 / Localization 정책

**액센트 테마 (green/blue/orange/purple)**:
- Phase 7 까지는 **green 고정** (default).
- 사용자 노출 토글은 Open Question — 결정 전까지 노출 안 함.

**언어 표기**:
- 핸드오프의 패턴 "확인 · OK" 는 **동시 표기**로 해석.
- 본문 UI 는 동시 표기 (한국어 우선 · English 보조).
- Mission Info 등 사용자 입력 필드는 단일 언어 (`Locale.current.language.languageCode`).
- Localization 분리 (`Localizable.strings` 등) 는 **Phase 8 (별도 트랙)**.

**Dark mode**:
- README §"Tweaks" 의 dark 모드는 부분 지원 (AR 화면은 항상 dark, 그 외는 light).
- Phase 7 까지는 light only. 시스템 dark 모드는 무시 (`.preferredColorScheme(.light)` 강제).

---

## 8. 위험 & 오픈 질문

### 8.1 기술적 위험

| 위험 | 영향 | 완화 |
|---|---|---|
| Jalnan2 폰트가 시뮬에서 등록 안 됨 | 모든 헤딩이 시스템 폰트로 폴백 | Phase 0 첫 빌드에서 `UIFont.familyNames` 로그 확인. 안 되면 PostScript name 추출 |
| SparkleBurst 60fps 미만 | 미니게임 시각 충격 약화 | Phase 2 PoC. 30fps 미만이면 SpriteKit 오버레이로 전환 |
| 드럼 피커 SwiftUI 구현 난이도 | Map Edit + Picker 화면 지연 | iOS 17 `.scrollTargetBehavior(.viewAligned)` 우선. 안 되면 UIPickerView UIViewRepresentable |
| MapKit annotation 커스터마이즈 한계 | 핀 디자인 충실도 ↓ | iOS 17 `Map(content:) { Annotation }` 사용. 충실도 부족 시 MKMapView UIViewRepresentable |
| MissionPlayView 522줄 리팩토링 | 게임 로직 회귀 | UI 만 분리. GameEngine / Repository 호출은 그대로 |
| Personal Team 제약 | 일부 capability 차단 | 디자인이 paid entitlement 요구하지 않음 — 위험 낮음 |

### 8.2 Product Open Questions (README §16 + 추가)

- [ ] **언어 표기**: 한/영 동시 vs 단일 (Locale)? — 본 계획은 동시 표기 가정
- [ ] **백엔드**: Legacy vs REST 둘 다 유지? — 본 계획은 REST default 유지
- [ ] **테마 토글**: green/blue/orange/purple 노출 여부? — 본 계획은 green 고정
- [ ] **Fox 마스코트**: SVG placeholder vs 외주 일러스트? — Phase 7 결정
- [ ] **Animation budget**: 60fps 풀 vs 30fps 절약? — 배터리 측정 후 결정
- [ ] **AR 카메라 권한 거부 처리** UX — 디자인 핸드오프에 명시 없음

---

## 9. 산출물 / 디렉토리 구조 변경

**신규 폴더**:
```
PlaySpot/
├── Views/
│   ├── DesignSystem/                # 신규 (Phase 0~2)
│   │   ├── DuoTokens.swift          # 스타터에서 이동
│   │   ├── PSToggle.swift
│   │   ├── DuoStepper.swift
│   │   ├── FormGroup.swift
│   │   ├── FormRow.swift
│   │   ├── SegBtn.swift
│   │   ├── BottomNav5.swift
│   │   ├── FoxMascot.swift
│   │   ├── ItemPin.swift
│   │   ├── DigitClock.swift
│   │   ├── ARRadar.swift
│   │   ├── SparkleBurst.swift
│   │   ├── PulseRing.swift
│   │   └── WordmarkPlaySpot.swift
│   ├── Help/                        # 신규 (Phase 6)
│   │   ├── HelpItemsView.swift
│   │   ├── HelpHowToView.swift
│   │   ├── HelpDesignView.swift
│   │   └── TutorialView.swift
│   └── MissionPlay/
│       ├── HintPopup.swift          # 신규 (Phase 4)
│       └── ItemAcquiredPopup.swift  # 신규 (Phase 4)
└── Resources/
    └── Fonts/
        └── Jalnan2.ttf              # 신규 (Phase 0)
```

**project.yml 변경**:
- `sources:` — `PlaySpot/Views/DesignSystem` 추가 (와일드카드라면 자동)
- `resources:` — `PlaySpot/Resources/Fonts/Jalnan2.ttf` 추가
- `info:` 또는 별도 plist — `UIAppFonts: [Jalnan2.ttf]`

**Assets.xcassets 변경**:
- `Items/` — i_*.imageset 19개 추가/교체
- `Minigame/` — 신규 namespace (playspot_logo, shake_0/1, touch_0/1)
- `Mascot/` — fox_wave/sit/think/cheer (Phase 7 외주 후)

---

## 10. 일정 예상

| Phase | 작업일 | 누적 |
|---|---|---|
| 0. Foundation | 1d | 1d |
| 1. Components | 2d | 3d |
| 2. Atomic Visual | 1d | 4d |
| 3. Meta Nav | 3d | 7d |
| 4. Play Flow | 4d | 11d |
| 5. Design Flow | 4d | 15d |
| 6. Help & Tutorial | 2d | 17d |
| 7. Cleanup | 2d | 19d |

**~3.5주 (1인 풀타임 기준)**. 각 Phase 끝에 PR 1개 + 베이스라인 스크린샷 commit.

---

## 11. PR 분리 전략

각 phase 끝에 PR 을 끊되, 가능하면 **사용 가능한 상태로** 머지한다 (앱이 빌드되고 모든 탭이 동작):
- PR #1 (Phase 0+1+2) — 디자인 시스템 + 컴포넌트 + 시각 어셋. 메인 화면 변경 없음 (백워드 호환).
- PR #2 (Phase 3) — 5탭 메타 네비게이션 + 4 화면 재작성. 실제 사용자가 체감하는 첫 변화.
- PR #3 (Phase 4) — 플레이 플로우 9 화면.
- PR #4 (Phase 5) — 디자인 플로우 6 화면.
- PR #5 (Phase 6) — 도움말/온보딩 4 화면.
- PR #6 (Phase 7) — Auth + 잔여 + 외주 일러스트 + 미사용 어셋 정리.

각 PR 마다 README §"Build & Modification Rules" 의 검증 절차 (xcodebuild + verify.sh) 통과 필수.

---

## 12. 참고 링크

- 디자인 README — [design_handoff_playspot_redesign/README.md](design_handoff_playspot_redesign/README.md)
- 토큰 — [design_handoff_playspot_redesign/swiftui_starter/DuoTokens.swift](design_handoff_playspot_redesign/swiftui_starter/DuoTokens.swift)
- CSS 토큰 (참고) — [design_handoff_playspot_redesign/source/styles/tokens.css](design_handoff_playspot_redesign/source/styles/tokens.css), [app.css](design_handoff_playspot_redesign/source/styles/app.css)
- JSX 화면 구현체 — [design_handoff_playspot_redesign/source/src/](design_handoff_playspot_redesign/source/src/) (screens-game.jsx / screens-meta.jsx / screens-design.jsx / screens-tutorial.jsx / screens-v2.jsx)
- 인터랙티브 프리뷰 — `open design_handoff_playspot_redesign/source/PlaySpot Redesign.html`
- 현재 코드 SOT — [CLAUDE.md](CLAUDE.md)
- API 마이그레이션 SOT — [api_plan_new.md](api_plan_new.md)
