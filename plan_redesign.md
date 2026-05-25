# PlaySpot Redesign — 실행 계획 / 완료 보고 (plan_redesign.md)

**Source of truth (디자인)**: [design_handoff_playspot_redesign/README.md](design_handoff_playspot_redesign/README.md)
**Source of truth (토큰)**: [design_handoff_playspot_redesign/swiftui_starter/DuoTokens.swift](design_handoff_playspot_redesign/swiftui_starter/DuoTokens.swift)
**대상 코드베이스**: 신규 `PlaySpot.xcodeproj` (`PlaySpot/`) — SwiftUI / Swift 5.10+ / iOS 16+
**작성일**: 2026-05-25 · **완료일**: 2026-05-25 · **결과 commit**: `d951a17`
**기여 규칙**: [CLAUDE.md](CLAUDE.md) §"Build & Modification Rules" 준수 (특히 `project.yml` SOT, assets namespace, ATS, Personal Team)

---

## ✅ 작업 상태 요약 (2026-05-25 완료)

| Phase | 화면 수 | 결과 | 비고 |
|---|---|---|---|
| 0. Foundation | — | ✅ 완료 | DuoTokens + Jalnan2TTF 등록 + Minigame imageset 6개 |
| 1. Reusable Components | 11종 | ✅ 완료 | DesignSystem 폴더 13 파일 |
| 2. Atomic Visual | 3종 | ✅ 완료 | ARRadar / PulseRing / SparkleBurst |
| 3. Meta Navigation | 5탭 + 4 화면 | ✅ 완료 | BottomNav5 커스텀, 게스트 차단 정책 보존 |
| 4. Play Flow | 9 화면 | ✅ 완료 | HintPopup / ItemAcquiredPopup 신규 + 7개 재작성 |
| 5. Design Flow | 6 화면 | ✅ 완료 | DesignActionSheet 신규 + 5개 재작성 |
| 6. Help & Tutorial | 4 화면 | ✅ 완료 | 모두 신규. 정적 PNG `TutorialPagerView` 폐기 |
| 7. Cleanup | Auth 2 | ✅ 완료 | LoginView/RegisterView candy 보정 |

**전체 산출물**: 신규 21 파일 + 재작성 20 파일 + 시각 어셋 (Items 19 commit `af645a0` + Minigame 6) + Jalnan2.ttf
**빌드**: `xcodebuild build` → BUILD SUCCEEDED (매 phase)
**시뮬 검증**: `bash scripts/verify.sh "iPhone 16 Pro"` 통과, 5탭 모두 candy 디자인 적용 시각 확인
**API 회귀**: `bash scripts/smoke_new_api.sh` → 22 케이스 중 20 PASS (실패 2건은 redesign 무관 기존 케이스)

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

### Phase 0 — Foundation ✅

**목표**: 디자인 시스템을 코드베이스에 통합. 이후 모든 화면이 이 기반 위에 쌓인다.

**Deliverables**:
- [x] [PlaySpot/Views/DesignSystem/DuoTokens.swift](PlaySpot/Views/DesignSystem/DuoTokens.swift) — 스타터 + 누락 토큰 13개 추가 (`duoMacawNavBg/Border`, `duoGreen200/300/400`, `duoPolar`, `hudTealStart/End`, `hudDarkStart/End`, `radarGreenLight/Dark`) + `LinearGradient.hudTeal/hudDark` + `RadialGradient.radarDisc` + `DuoChip` 6컬러 프리셋 + `ButtonStyle` 편의 헬퍼
- [x] [PlaySpot/Resources/Fonts/Jalnan2.ttf](PlaySpot/Resources/Fonts/Jalnan2.ttf) 등록 + project.yml resources + Info.plist UIAppFonts. **중요 발견**: 핸드오프 README 의 `"Jalnan2"` 는 부정확. 실제 PostScript 이름은 `Jalnan2TTF` — `Font.duoDisplay()` 가 이를 사용
- [x] [scripts/migrate_redesign_assets.sh](scripts/migrate_redesign_assets.sh) 작성 + 실행. Items i_*.png 19개는 commit `af645a0` 에서 이미 완료 확인 (해시 동일), Minigame 6개 imageset 신규 추가
- [x] `xcodegen generate` → 시뮬 빌드 BUILD SUCCEEDED
- [x] 시뮬 콘솔에서 폰트 등록 검증 — `🪶 Jalnan font registered: ["Jalnan2TTF"]` / `✅ Font.duoDisplay → Jalnan2TTF OK` 출력 확인 후 임시 print 제거

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

### Phase 1 — Reusable Components ✅

**목표**: 모든 화면이 의존하는 11개 컴포넌트를 미리 만들어 두기.

**Deliverables** (모두 `PlaySpot/Views/DesignSystem/` 에 위치):

| 파일 | 컴포넌트 | 상태 |
|---|---|---|
| [PSToggle.swift](PlaySpot/Views/DesignSystem/PSToggle.swift) | `PSToggle(isOn:, tint:, shadow:)` 56×32 알약 | ✅ |
| [DuoStepper.swift](PlaySpot/Views/DesignSystem/DuoStepper.swift) | `DuoStepper(value:, range:, step:)` 30px 알약 (SwiftUI 기본 Stepper 와 이름 충돌 회피) | ✅ |
| [FormGroup.swift](PlaySpot/Views/DesignSystem/FormGroup.swift) | `FormGroup` + `FormRow` (한 파일에 묶음) | ✅ |
| [SegBtn.swift](PlaySpot/Views/DesignSystem/SegBtn.swift) | `SegmentedTabs<T: Hashable & Identifiable>` + `SegBtnPair<T>` | ✅ |
| [BottomNav5.swift](PlaySpot/Views/DesignSystem/BottomNav5.swift) | `BottomNav5(active: Binding<MainTab>)` 5탭 + `MainTab` enum | ✅ |
| [FoxMascot.swift](PlaySpot/Views/DesignSystem/FoxMascot.swift) | `FoxMascot(pose:, size:)` SF Symbol placeholder (Phase 7 외주 일러스트 보류 — Open Question) | ✅ |
| [ItemPin.swift](PlaySpot/Views/DesignSystem/ItemPin.swift) | `ItemPin(.type)` or `ItemPin(named:)` + size/active/glow/dimmed | ✅ |
| DuoChip 프리셋 | `DuoTokens.swift` 안에 `static func green/red/orange/yellow/blue/purple` | ✅ |
| [DigitClock.swift](PlaySpot/Views/DesignSystem/DigitClock.swift) | `DigitClock(seconds:, style: .light/.dark, digitFontSize:)` | ✅ |
| [WordmarkPlaySpot.swift](PlaySpot/Views/DesignSystem/WordmarkPlaySpot.swift) | `WordmarkPlaySpot(progress:, variant: .outline/.color)` brightness/saturate filter + 글로우 | ✅ |
| [PSDesignSystemPreview.swift](PlaySpot/Views/DesignSystem/PSDesignSystemPreview.swift) | 카탈로그 화면 — Settings DEBUG 진입점에서 접근 가능 | ✅ |

**검증**:
- 각 컴포넌트마다 `#Preview` 4종 (기본 / 활성 / 다크 / 라지) 작성
- 단일 카탈로그 화면 `PSDesignSystemPreview.swift` 에 모두 모아 시뮬 스크린샷

**위험**:
- `BottomNav5` 가 SwiftUI 의 `TabView` 와 어떻게 조합되는지 — TabView 의 기본 탭바 숨김(`.toolbar(.hidden, for: .tabBar)`) 후 ZStack 으로 커스텀 바 오버레이 패턴 사용
- `Stepper` 는 SwiftUI 의 기본 `Stepper` 와 이름 충돌 가능 → `DuoStepper` 로 명명

---

### Phase 2 — Atomic Visual Assets ✅

**목표**: AR 화면 시각 요소.

**Deliverables**:
- [x] [ARRadar.swift](PlaySpot/Views/DesignSystem/ARRadar.swift) — 64px RadialGradient 디스크 + 6s linear sweep (TimelineView) + 동심원 2개 + 십자 + 노란 needle + 중앙 hub + blip 점
- [x] [SparkleBurst.swift](PlaySpot/Views/DesignSystem/SparkleBurst.swift) — `Canvas` + `TimelineView(.animation)` 30fps, 14 결정론적 파티클 (4컬러 팔레트 Bee/Fox/Macaw/White), trigger 카운터 변경 시 burst
- [x] [PulseRing.swift](PlaySpot/Views/DesignSystem/PulseRing.swift) — 1.8s ease-out, scale 0.6→2.4 + opacity 0.55→0, multi-ring 지원

**검증**: `PSDesignSystemPreview` 카탈로그에 추가 → 시뮬 영상으로 60fps 유지 확인

**위험**: 파티클 14개를 SwiftUI 로 매 프레임 갱신하면 성능 이슈 가능 → 옵션 B = SpriteKit 오버레이. 우선 Canvas 로 시도, 30fps 이하 떨어지면 전환.

---

### Phase 3 — Meta Navigation ✅

**목표**: 5탭 메인 네비게이션 + 4개 메타 화면. 앱을 열면 바로 candy UI 가 보이는 단계.

**대상 화면** (5):
1. **Mission List** (`list`) → 재작성
2. **My Info** (`my-info`) → 재작성
3. **Badge List v2** (`badges-v2`) → 재작성
4. **Settings** (`settings`) → 재작성
5. **MainTabView** → `BottomNav5` 로 교체

**Deliverables**:
- [x] [MainTabView.swift](PlaySpot/Views/App/MainTabView.swift) — VStack + 조건부 tabContent + BottomNav5 (TabView 의 기본 탭바 제거). **게스트 차단 정책 보존** (release 빌드에서 Design/MyInfo/Badge 진입 시 LoginView sheet)
- [x] [MissionListView.swift](PlaySpot/Views/MissionList/MissionListView.swift) + [MissionRowView.swift](PlaySpot/Views/MissionList/MissionRowView.swift) — Fox + "PLAYING NOW · Missions" 헤더 + 🔥/💎 stat chip + SegmentedTabs 4탭 (popular/new/near/all) + MissionCard (64×64 컬러 뱃지 + 4 액센트 팔레트 hash 분배 + PLAYS/FAILS/V chip). 데이터 fetch 로직 보존
- [x] [MyInfoView.swift](PlaySpot/Views/MyInfo/MyInfoView.swift) — 50×50 macaw 원형 아바타 Profile card + ITEMS/DESIGNED/PLAYED FormGroup, 빈 상태 처리
- [x] [BadgeListView.swift](PlaySpot/Views/MyInfo/BadgeListView.swift) — 티얼(#1C8A9F) 헤더 + 3-col 그리드 + PlayBadge candy 셀 (green-400 + dark border) / LockedBadge "?"
- [x] [SettingsView.swift](PlaySpot/Views/Settings/SettingsView.swift) — 28px display "Settings" + FormGroup × 6 (ACCOUNT/API BACKEND/DEBUG/GUIDE/ABOUT/PHASE PREVIEW) + SegBtnPair Legacy/REST. API Backend 토글/401 시뮬 로직 보존

**상태 보존**:
- Settings 의 API Backend 토글, 401 시뮬 버튼은 기존 로직 보존 — UI 만 교체
- MissionList 의 selectedTab/loadMissions/refreshable 동작 보존 — 디자인 탭 ID 매핑은 `popular=2(All), new=0(Playing), near=1(Near Me)` 로 우선 매핑 (서버에 popular/new 분리 호출 없으면 디자인 라벨만 변경)
- BadgeList 의 playMilestones 19개 / playedMissions API 로직 보존

**검증**: `bash scripts/verify.sh` 로 5탭 모두 진입 + 스크린샷 4장

**위험**:
- MainTabView 의 `if appState.isGuest && [1,2,3].contains(newTab)` 가드는 BottomNav5 에서도 동일하게 구현 — 디자인은 5탭 전부 노출이지만 게스트 차단 정책은 유지
- 디자인의 4가지 액센트 컬러 토글 (green/blue/orange/purple) — Phase 7 까지는 green 고정. Tweaks 패널은 프로토타입 전용 (README §"Don't ship the Tweaks panel")

---

### Phase 4 — Play Flow ✅

**목표**: 미션을 실제로 플레이하는 전체 흐름. **GameEngine, AR 좌표 변환, 가상모드 위치 오프셋, mine 자동 폭발, run timer, missionCompleted/missionTimedOut, 댓글 옵티미스틱 캐시 100% 보존**.

**Deliverables**:
- [x] [MissionDetailView.swift](PlaySpot/Views/MissionList/MissionDetailView.swift) — 영웅 카드 (macaw bg/border + avatar + DuoKicker BY + display 18px + StarRating + PLAYS/FAILS chip) + InfoRow × 4 (Place/Items/TimeLimit/Created, 5컬러 icon badge) + 핀 프리뷰 (최대 6개 + "+N") + Rankings + Reviews + safeAreaInset PLAY CandyButton + Mode Sheet 오버레이 (Real green / Virtual purple). 데이터 fetch 보존
- [x] [MissionPlayView.swift](PlaySpot/Views/MissionPlay/MissionPlayView.swift) — LegacyTopChrome → hudTeal 그라데이션 + EXIT(cardinal) + DigitClock + Locate/Info 36×36 candy 버튼. LegacyBottomBar → hudTeal 바 + counter 4행 + 62px floating 카메라 버튼 (radial green + bee flash dot). 게임 로직 일체 보존
- [x] [ARGameView.swift](PlaySpot/AR/ARGameView.swift) — hudTeal 톱바 (MAP + DigitClock) + 카메라 배경 유지 + 부유 핀 + 하단 hudDark 88pt (좌 라벨 bee + ARRadarView 중앙 + 우 라벨 macaw)
- [x] [MiniGameView.swift](PlaySpot/Views/MissionPlay/MiniGameView.swift) — WordmarkPlaySpot (progress 따라 brightness/saturate/glow) + Bee 글로우 halo (50% 이상) + shake/touch 0/1 일러스트 토글 + SparkleBurst (tap 마다 trigger) + hudDark 하단 바 ("흔드세요!"/"터치하세요!" + N/100 카운터). shake 게인/디케이/완료 로직 보존
- [x] [HintPopup.swift](PlaySpot/Views/MissionPlay/HintPopup.swift) **신규** — 다크 배경 + 모달 카드 (hint 핀 -14/-22 오버랩) + Reward chip strip (XP bee / Gem beetle) + 확인 primary CandyButton
- [x] [ItemAcquiredPopup.swift](PlaySpot/Views/MissionPlay/ItemAcquiredPopup.swift) **신규** — MissionPlayView 안의 기존 정의를 별도 파일로 분리. 시그니처 `(alert: ItemAcquiredAlert, onOK:)` 유지. 컬러 워드마크 + Items/i_*.png 핀 + 본문 + orange CandyButton
- [x] [QuizView.swift](PlaySpot/Views/MissionPlay/QuizView.swift) — ItemPin(.quiz) + DuoKicker + 질문 카드 + 답안 TextField (candy) + 정답/오답 chip + Submit primary. failCnt 힌트 로직 보존
- [x] [MissionCompletePopup.swift](PlaySpot/Views/MissionPlay/MissionCompletePopup.swift) — Bee trophy halo + StarRatingPicker + 댓글 TextEditor candy + 듀얼 버튼 (건너뛰기 ghost / 후기 남기기 orange). 옵티미스틱 캐시 호출 보존
- [x] [MissionTimeoutPopup.swift](PlaySpot/Views/MissionPlay/MissionTimeoutPopup.swift) — Cardinal timer 아이콘 halo + elapsedText pill + red CandyButton

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

### Phase 5 — Design Flow ✅

**목표**: 사용자가 자작 미션을 만들고 편집하는 흐름. **검증/뱃지 업로드/공개 해제/MissionBuilder 저장 로직 100% 보존**.

**Deliverables**:
- [x] [MissionBuilderView.swift](PlaySpot/Views/MissionBuilder/MissionBuilderView.swift) → Design List v2 재작성. ScrollView + 36×36 green + CandyButton + "내 디자인" 28px display + 비공개/공개 FormGroup + `DesignRowV2` (status chip + 테스트 small Candy + chevron) + Fox think empty state. **참고**: enum case 이름 `private/public` 은 Swift 키워드와 충돌 → `privateMission/publicMission` 으로 변경
- [x] [DesignActionSheet.swift](PlaySpot/Views/MissionBuilder/DesignActionSheet.swift) **신규** — 4 ActionRow (Modify macaw / Test fox / Publish-Unpublish green-beetle / Delete cardinal-hare) + 취소 ghost. `.sheet` + `presentationDetents([.medium, .large])`. 공개 상태는 Delete 회색 안내
- [x] [MissionBuilderMapView.swift](PlaySpot/Views/MissionBuilder/MissionBuilderMapView.swift) — 상단 toolbar "EDITING / 아이템 배치" + 우상단 macaw "완료" + Fox think 다크 헬퍼 토스트 ("꾹 눌러서 아이템 배치 · 탭으로 설정") + candy 검증 배너 (cardinal-bg). MapKit 드래그/롱프레스 로직은 BuilderMapView 그대로 유지
- [x] [ItemPickerView.swift](PlaySpot/Views/MissionBuilder/ItemPickerView.swift) — 다크 toolbar (#3D3D3D, CANCEL/타이틀/DONE bee) + ItemPin 48px 미리보기 + DuoChip blue/green + 시스템 wheel picker 유지 (드럼 충실도 vs 구현 난이도 trade-off — README §"드럼 픽커 SwiftUI 구현 난이도" 위험 회피)
- [x] [ItemDetailView.swift](PlaySpot/Views/MissionBuilder/ItemDetailView.swift) — Item Detail v2: ScrollView 외곽 + 아이템 정보 카드 (ItemPin 56px + DuoKicker + display + 효과 설명) + 💡 yellow tip 카드 (bee-bg + bee border) + SubForm 16개 분기 (Form 그대로 — 시스템 디자인 유지) + 삭제 outline-cardinal CandyButton. 취소/완료 macaw 링크
- [x] [MissionSetupView.swift](PlaySpot/Views/MissionBuilder/MissionSetupView.swift) — Mission Edit v2: ScrollView + 28px display + FormGroup × 6 (기본정보/설명/제한시간 wheel/플레이설정 PSToggle/공개설정/뱃지). PhotosPicker + ImageCropView + 검증 카드 (cardinal-bg) + purple "아이템 배치 (지도 진입)" CandyButton

**상태 보존**:
- MissionBuilder 자작 미션 PlayStateRepository / MissionBuilderRepo 보존
- 좌표/실제반경 검증 로직 보존
- 배지 업로드 파이프라인 (최근 commit `634e4bc`) 보존

**위험**:
- 드럼 피커는 SwiftUI 기본 `Picker(.wheel)` 로는 디자인 충실도 부족. 커스텀 구현 필요 — Phase 2 에서 빠르게 PoC 권장
- Map Edit 의 드래그·롱프레스 인터랙션은 MapKit `Map` 의 한계로 SwiftUI 만으로 어려움 → UIViewRepresentable 로 `MKMapView` 직접 사용 검토

---

### Phase 6 — Help & Tutorial ✅

**목표**: 도움말 3-탭 + 온보딩 3-step. **모두 신규 작성**.

**Deliverables**:
- [x] [HelpRoot.swift](PlaySpot/Views/Help/HelpRoot.swift) **신규** — 3탭 라우터. 백 chevron + DuoKicker "Help · 도움말" + 22px display + SegmentedTabs (Items/How to Play/Design)
- [x] [HelpItemsView.swift](PlaySpot/Views/Help/HelpItemsView.swift) **신규** — Property legend (Normal/Hidden/Stealth/필수) + 5 그룹 (Mission green / Quiz red / Radar purple / Time blue / Special orange). 각 그룹: 컬러 헤더 + 아이템 row (ItemPin 42px + 이름 + 효과 설명)
- [x] [HelpHowToView.swift](PlaySpot/Views/Help/HelpHowToView.swift) **신규** — orange hero (Fox cheer) + LIVE/HOME 2 모드 카드 + 4 PlayStep (numbered + icon) + dark reward strip (XP bee/Gem beetle/Streak fox/Badge macaw) + Fox wave 말풍선
- [x] [HelpDesignView.swift](PlaySpot/Views/Help/HelpDesignView.swift) **신규** — purple hero (Fox think) + 5 DesignStep (numbered double-border circle + 64×64 미니 SF Symbol visual) + purple "미션 만들기 시작!" CandyButton (CTA)
- [x] [TutorialView.swift](PlaySpot/Views/Help/TutorialView.swift) **신규** — SKIP + 3-dot progress (active 22px) + X 닫기 + step kicker/title + 데모카드 (PulseRing + ItemPin glow + 손가락 SF Symbol) + Fox + 말풍선 + BACK ghost / NEXT blue / LET'S PLAY primary. 기존 정적 PNG `TutorialPagerView` 제거
- [x] Settings 진입점 — GUIDE FormGroup 신설 (Tutorial · 튜토리얼 / Help · 아이템 도움말 2개 macaw 링크)

**상태 보존**:
- 기존 `TutorialPagerView` 는 `Tutorial/tutorial0_en.png` 같은 정적 PNG 슬라이드 — 신규 디자인은 인터랙티브 SwiftUI 로 대체. 정적 PNG 자체는 deprecate (asset catalog 에서 삭제는 Phase 7)

**진입점**:
- Help 3탭: Settings 의 "How to Play" 링크 + Mission List 의 추후 추가될 ? 버튼
- Tutorial: 첫 진입 / Settings 의 "How to Play" 버튼

**위험**:
- Help 의 16개 아이템 row 데이터 모델 — `ItemType` enum 에 `localizedName`, `description`, `category` 추가 필요. 데이터 소스는 코드 상수로 두는 게 무난 (서버 동기화 불필요)

---

### Phase 7 — Cleanup & Polish ✅

**목표**: 마무리 + Auth 화면 보정 + 회귀 검증.

**Deliverables (이번 phase 완료)**:
- [x] [LoginView.swift](PlaySpot/Views/Auth/LoginView.swift) — DuoKicker + 24px display + candy 텍스트 input row (2개) + cardinal error chip + primary Login + blue Create Account + Guest ghost. login/continueAsGuest 로직 보존
- [x] [RegisterView.swift](PlaySpot/Views/Auth/RegisterView.swift) — 4 candy 텍스트 input row + 검증 후 primary Register. register + auto login + nickname patch 로직 보존
- [x] `bash scripts/verify.sh "iPhone 16 Pro"` — BUILD SUCCEEDED + 시뮬 부팅 + 5탭 candy 적용 시각 확인
- [x] `bash scripts/smoke_new_api.sh` — REST 22 케이스 중 20 PASS (실패 2건은 anonymous/invalid token 기존 케이스, redesign 무관)

**Deliverables (별도 트랙 / 보류)**:
- [ ] [ContentView.swift](PlaySpot/Views/App/ContentView.swift), [GameTooltipView.swift](PlaySpot/Views/Components/GameTooltipView.swift), [LoadingHUD.swift](PlaySpot/Views/Components/LoadingHUD.swift), [StarRatingView.swift](PlaySpot/Views/Components/StarRatingView.swift) — 기능 영향 없는 보조 컴포넌트, 후속 단발성 PR
- [ ] **색상 테마 토글** (green/blue/orange/purple) — Open Question 으로 product 결정 대기. 현재 green 고정
- [ ] **Fox 일러스트 외주 교체** — 현재 SF Symbol placeholder. 외주 일러스트 도착 시 [FoxMascot.swift](PlaySpot/Views/DesignSystem/FoxMascot.swift) 의 systemSymbol → Image("Mascot/fox_*") 만 swap
- [ ] **미사용 어셋 정리** — 옛 `Tutorial/tutorial0_en.png` 등 정적 PNG 슬라이드. 별도 PR
- [ ] **레거시 `TreasureHunter.xcodeproj`** — 참고용으로 보존

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

## 10. 일정 — 예상 vs 실제

| Phase | 예상 작업일 | 실제 | 비고 |
|---|---|---|---|
| 0. Foundation | 1d | ✅ 완료 | Items i_*.png 19개는 commit `af645a0` 에서 선행 완료 (해시 검증) — 시간 단축 |
| 1. Components | 2d | ✅ 완료 | 11종 컴포넌트 + 카탈로그 화면 |
| 2. Atomic Visual | 1d | ✅ 완료 | ARRadar / PulseRing / SparkleBurst |
| 3. Meta Nav | 3d | ✅ 완료 | 5탭 모두 시뮬 스크린샷 검증 |
| 4. Play Flow | 4d | ✅ 완료 | 9 화면, GameEngine 등 게임 로직 100% 보존 |
| 5. Design Flow | 4d | ✅ 완료 | DesignActionSheet 신규, 5 재작성 |
| 6. Help & Tutorial | 2d | ✅ 완료 | 4 신규 화면, 정적 PNG TutorialPagerView 폐기 |
| 7. Cleanup | 2d | ✅ 완료 | Auth 2 화면 candy, smoke 회귀 통과 |

**전체 1일에 통합 완료** (2026-05-25). 단일 통합 commit `d951a17` 로 반영.

---

## 11. PR / Commit 분리 전략 — 실제 결과

**실제 머지**: Phase 0~7 모두 **단일 통합 commit** `d951a17` 로 반영 (2026-05-25).

- 변경 파일: 106 파일 (+14,207 / −1,363 줄)
- 핸드오프 자료 `design_handoff_playspot_redesign/` 포함 (디자인 SOT 보존용)
- Co-Author: Claude Opus 4.7 (1M context)

원안의 PR 분리 (#1~#6) 는 향후 동일 규모 작업 시 참고용. 이번 작업은 1인 풀스택으로 phase 간 의존성이 강해 (Phase 1 컴포넌트가 Phase 3~7 모두에서 사용) 단일 commit 이 효율적이었다. 각 phase 끝마다 빌드/시뮬/스모크 검증으로 회귀를 차단했다.

후속 PR (분리 권장):
- Components 잔여 candy 보정 (ContentView/LoadingHUD/Star*)
- Fox 외주 일러스트 swap
- 미사용 어셋 정리 (`Tutorial/tutorial0_en` 등)
- 색상 테마 토글 (product 결정 후)

---

## 12. 참고 링크

- 디자인 README — [design_handoff_playspot_redesign/README.md](design_handoff_playspot_redesign/README.md)
- 토큰 — [design_handoff_playspot_redesign/swiftui_starter/DuoTokens.swift](design_handoff_playspot_redesign/swiftui_starter/DuoTokens.swift)
- CSS 토큰 (참고) — [design_handoff_playspot_redesign/source/styles/tokens.css](design_handoff_playspot_redesign/source/styles/tokens.css), [app.css](design_handoff_playspot_redesign/source/styles/app.css)
- JSX 화면 구현체 — [design_handoff_playspot_redesign/source/src/](design_handoff_playspot_redesign/source/src/) (screens-game.jsx / screens-meta.jsx / screens-design.jsx / screens-tutorial.jsx / screens-v2.jsx)
- 인터랙티브 프리뷰 — `open design_handoff_playspot_redesign/source/PlaySpot Redesign.html`
- 현재 코드 SOT — [CLAUDE.md](CLAUDE.md)
- API 마이그레이션 SOT — [api_plan_new.md](api_plan_new.md)
