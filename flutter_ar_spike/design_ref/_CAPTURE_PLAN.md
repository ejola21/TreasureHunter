# SwiftUI 자동 캡쳐 — 사용자 네비게이션 체크리스트

⚠️ **macOS Sequoia 가 외부 프로세스의 합성 click 을 차단**하여 cliclick / AppleScript 자동 클릭은 시뮬레이터로 전달되지 않습니다.
대신 **watch 모드가 5초마다 자동 캡쳐** 중입니다 → 시뮬레이터에서 아래 순서대로 화면만 전환해주시면 됩니다.

## 진행 방법

1. 시뮬레이터를 보면서 아래 화면을 **천천히** (각 화면당 ≥ 6초 머무르기) 순서대로 이동
2. 다 끝나면 Terminal 에서 `Ctrl+C` 로 watch 중지 (또는 저에게 "끝났어" 라고 알려주세요 — 백그라운드 작업 중지)
3. 제가 모든 `sequential_NNN.png` 를 분석해서 올바른 이름으로 재명명 + design_ref 정리

## 📋 캡쳐 순서 (위에서 아래로)

### Missions 탭 (현재 위치)
- [ ] `mission_list_all` ← 지금 화면, 이미 저장됨
- [ ] **POPULAR** 탭 클릭 → 6초 대기
- [ ] **NEW** 탭 클릭 → 6초 대기
- [ ] **NEAR ME** 탭 클릭 → 6초 대기
- [ ] **ALL** 다시 클릭 → 6초 대기

### Mission Detail 진입
- [ ] **첫 번째 카드** ("튜토리얼: 기본 미션") 클릭 → 6초 대기 (hero 영역)
- [ ] **스크롤 다운** 천천히 → 6초 대기 (info rows / rankings / reviews 보이게)
- [ ] **Play 버튼** 클릭 → 6초 대기 (모드 시트 = play_mode_sheet)
- [ ] 시트 닫고 **← 백** → Missions 복귀

### DESIGN 탭
- [ ] **DESIGN** 탭 클릭 → 6초 대기 (design_list)
- [ ] **우상단 + 버튼** → 6초 대기 (mission_setup_new)
- [ ] 백 (← 또는 Cancel) → design_list 복귀
- [ ] **첫 번째 디자인 행** 클릭 → 6초 대기 (design_action_sheet)
- [ ] 시트 안에서 **"Modify · 수정"** → 6초 대기 (builder_map)
- [ ] 빌더에서 핀 1개 탭 → 6초 대기 (item_picker_start)
- [ ] 휠 회전 (Quiz/Start/End 등 1-2개 변형) → 각 6초
- [ ] Done 으로 item_detail 진입 → 6초 (item_detail_quiz / start)
- [ ] Cancel 로 빌더 복귀, ← 백 → design_list

### MY INFO / BADGE
- [ ] **MY INFO** 탭 → 6초 (my_info)
- [ ] **BADGE** 탭 → 6초 (badge_list)

### SETTINGS + Login + Help
- [ ] **SETTINGS** 탭 → 6초 (settings)
- [ ] **로그인 행** 클릭 → 6초 (settings_login_sheet)
- [ ] 시트 닫기
- [ ] **GUIDE → 튜토리얼** → 6초 × 3 step (tutorial_step1/2/3)
- [ ] 백
- [ ] **GUIDE → 도움말** → 6초 (help_items)
- [ ] 도움말 안에서 다음 탭 → 6초 (help_howto, help_design)

### 끝
- Terminal `Ctrl+C` 또는 저에게 알려주세요

## 캡쳐 위치
`flutter_ar_spike/design_ref/swiftui_simulator/sequential_NNN.png`
