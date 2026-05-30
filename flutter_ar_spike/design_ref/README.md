# design_ref — SwiftUI PlaySpot 원본 디자인 참조

Flutter 측 화면을 SwiftUI PlaySpot 과 1:1 매칭하기 위한 시각 참조 폴더.

## 📂 폴더 구조

```
design_ref/
├── README.md                     # 이 파일 (사용법 + 매핑 표)
├── _CAPTURE_PLAN.md              # 수동 캡쳐 워크플로 가이드
├── legacy/                       # ⚠️ 옛 디자인 (참고만, 현재 SwiftUI 와 다름)
└── swiftui_simulator/            # ✅ 최신 SwiftUI 캡쳐 47장 (2026-05-30, 빌드 com.ejola.playspot)
```

## 🎯 자동 캡쳐가 macOS Sequoia 보안에 막혀 있을 때

cliclick / AppleScript 의 합성 click 이벤트는 iOS Simulator 18+ 에 전달되지 않습니다.
유일한 자동 우회는 XCTest UI 테스트 타겟이며, 그게 부담스러우면 **수동 캡쳐 워크플로**:

1. 시뮬레이터에서 `Cmd+S` 로 화면 캡쳐 → Desktop 저장 (`Simulator Screenshot - iPhone 16 Pro - …`)
2. 모든 화면을 한 번에 찍거나, 부분 캡쳐 후 Claude 에게 "확인해줘"
3. Claude 가 각 PNG 시각 식별 → 적절한 이름으로 `swiftui_simulator/` 에 일괄 분류

## 🗺 분류된 47장 (2026-05-30 캡쳐)

### Tab 1: Missions
| 파일 | 설명 | Flutter 대응 |
|---|---|---|
| [mission_list_all.png](swiftui_simulator/mission_list_all.png) | ALL 필터 선택, 8개 미션 카드 | [mission_list_page.dart](../lib/features/missions/mission_list_page.dart) |
| [mission_detail_hero.png](swiftui_simulator/mission_detail_hero.png) | 튜토리얼: 기본 미션 상세 (BY TEST@GMAIL.COM, ★4(5), 0 PLAYS, info rows) | [mission_detail_page.dart](../lib/features/missions/mission_detail_page.dart) |
| [mission_detail_play_mode_sheet.png](swiftui_simulator/mission_detail_play_mode_sheet.png) | "어떻게 플레이할까요?" REAL/VIRTUAL 모드 카드 | (동상) |

### Tab 2: Design
| 파일 | 설명 | Flutter 대응 |
|---|---|---|
| [design_list.png](swiftui_simulator/design_list.png) | 내 디자인 (비공개 2 / 공개 6) | [design_list_page.dart](../lib/features/design/design_list_page.dart) |
| [design_action_sheet.png](swiftui_simulator/design_action_sheet.png) | DESIGN 작업 시트 (Modify/Test/Unpublish/Delete) | [design_action_sheet.dart](../lib/features/design/design_action_sheet.dart) |
| [mission_setup_edit_top.png](swiftui_simulator/mission_setup_edit_top.png) | 미션 편집 상단 (제목·장소·자동채우기·설명·시간 휠) | [mission_setup_page.dart](../lib/features/design/mission_setup_page.dart) |
| [mission_setup_edit_bottom.png](swiftui_simulator/mission_setup_edit_bottom.png) | 하단 (Virtual 허용·언어·공개·뱃지 이미지·아이템 배치) | (동상) |

### Builder Map (아이템 배치)
| 파일 | 설명 | Flutter 대응 |
|---|---|---|
| [builder_map.png](swiftui_simulator/builder_map.png) | 아이템 배치 지도 (밀집된 핀들) | [builder_page.dart](../lib/features/design/builder_page.dart) |
| [builder_map_callout_stealth_radar.png](swiftui_simulator/builder_map_callout_stealth_radar.png) | 핀 탭 → "Stealth Radar 40m" 콜아웃 | (동상) |
| [builder_map_callout_quiz.png](swiftui_simulator/builder_map_callout_quiz.png) | "Quiz 50m" 콜아웃 | (동상) |
| [builder_map_dense_defense_callout.png](swiftui_simulator/builder_map_dense_defense_callout.png) | 밀집 17개 아이템 + Defense 반경 원 | (동상) |

### Item Picker (휠)
| 파일 | 설명 | Flutter 대응 |
|---|---|---|
| [item_picker_start.png](swiftui_simulator/item_picker_start.png) | Start/Visible/30M 휠 | [item_picker_sheet.dart](../lib/features/design/item_picker_sheet.dart) |
| [item_picker_solution.png](swiftui_simulator/item_picker_solution.png) | Solution/Visible/30M 휠 | (동상) |

### Item Detail (16 type 폼)
| 파일 | 아이템 타입 | Flutter 대응 |
|---|---|---|
| [item_detail_start.png](swiftui_simulator/item_detail_start.png) | Start (필수자동, Visible, 30m, 시작안내문) | [item_detail_sheet.dart](../lib/features/design/item_detail_sheet.dart) |
| [item_detail_end.png](swiftui_simulator/item_detail_end.png) | End (필수자동, 30m, 종료안내문) | (동상) |
| [item_detail_hint.png](swiftui_simulator/item_detail_hint.png) | Hint (Visible, 미니게임 없음) | (동상) |
| [item_detail_hint_with_minigame.png](swiftui_simulator/item_detail_hint_with_minigame.png) | Hint (Stealth, 흔들기 게임, 힌트 텍스트) | (동상) |
| [item_detail_mine.png](swiftui_simulator/item_detail_mine.png) | Mine (45m, 폭발 반경 표시) | (동상) |
| [item_detail_defense.png](swiftui_simulator/item_detail_defense.png) | Defense (Visible, 미니게임 옵션) | (동상) |
| [item_detail_quiz.png](swiftui_simulator/item_detail_quiz.png) | Quiz (필수자동, 50m, 변형 1개) | (동상) |
| [item_detail_quiz_two_variants.png](swiftui_simulator/item_detail_quiz_two_variants.png) | Quiz (변형 2개, ADD 버튼) | (동상) |
| [item_detail_solution.png](swiftui_simulator/item_detail_solution.png) | Solution (미니게임 옵션) | (동상) |
| [item_detail_map_radar.png](swiftui_simulator/item_detail_map_radar.png) | Map Radar (필수 ON, Hidden 짝꿍) | (동상) |
| [item_detail_stealth_radar.png](swiftui_simulator/item_detail_stealth_radar.png) | Stealth Radar (40m, Stealth 짝꿍) | (동상) |
| [item_detail_mine_radar.png](swiftui_simulator/item_detail_mine_radar.png) | Mine Radar (지뢰 위치·반경 표시) | (동상) |
| [item_detail_dark.png](swiftui_simulator/item_detail_dark.png) | Dark (90m, 다크존 반경) | (동상) |
| [item_detail_gambling.png](swiftui_simulator/item_detail_gambling.png) | Gambling (Hidden, 랜덤 게임) | (동상) |
| [item_detail_coupon.png](swiftui_simulator/item_detail_coupon.png) | Coupon (쿠폰 코드/안내문) | (동상) |
| [item_detail_store.png](swiftui_simulator/item_detail_store.png) | Store (효과 없음, 예정) | (동상) |
| [item_detail_run_start.png](swiftui_simulator/item_detail_run_start.png) | Run Start (페어 ID #8) | (동상) |
| [item_detail_run_end.png](swiftui_simulator/item_detail_run_end.png) | Run End (60초, 거리 79m, 페어 ID #7) | (동상) |

### Play (게임 진행)
| 파일 | 설명 | Flutter 대응 |
|---|---|---|
| [play_map.png](swiftui_simulator/play_map.png) | 지도 모드 (EXIT/타이머/카메라/지뢰004/HIDDEN/STEALTH 카운터) | [mission_play_page.dart](../lib/features/play/mission_play_page.dart) |
| [play_ar_general.png](swiftui_simulator/play_ar_general.png) | AR 모드 (지도 토글/타이머/도움말 + 레이더 START 0m/유효50m) | [ar_play.dart](../lib/features/play/ar_play.dart) |
| [play_ar_help.png](swiftui_simulator/play_ar_help.png) | AR 도움말 오버레이 (Shake it!! + 거리/반경 라벨/레이더 설명) | (동상) |
| [popup_acquired_start.png](swiftui_simulator/popup_acquired_start.png) | "Start Item acquired!" 팝업 | [popups.dart](../lib/features/play/popups.dart) |

### Tab 3-5: My Info / Badge / Settings
| 파일 | 설명 | Flutter 대응 |
|---|---|---|
| [my_info.png](swiftui_simulator/my_info.png) | test@gmail.com Member, DESIGNED(10), PLAYED | [my_info_page.dart](../lib/features/myinfo/my_info_page.dart) |
| [badge_list.png](swiftui_simulator/badge_list.png) | Mission Badge 6 / Play Badge 12 (모두 ? 잠금) | [badge_list_page.dart](../lib/features/badge/badge_list_page.dart) |
| [settings_login_sheet.png](swiftui_simulator/settings_login_sheet.png) | PLAYSPOT 로고 / SIGN IN / EMAIL/PASSWORD / LOGIN / 회원가입 / 게스트 | [settings_page.dart](../lib/features/settings/settings_page.dart) (_LoginSheet) |
| [settings_signup_sheet.png](swiftui_simulator/settings_signup_sheet.png) | SIGN UP · 회원가입 (Email/Nickname/Password/Confirm) | (동상) |
| [settings_login_filled.png](swiftui_simulator/settings_login_filled.png) | Login 폼 — test@gmail.com 자동 채워짐 | (동상) |

### Guide (Settings → Guide)
| 파일 | 설명 | Flutter 대응 |
|---|---|---|
| [tutorial_step1.png](swiftui_simulator/tutorial_step1.png) | STEP 1: 지도에서 아이템 찾기 | [tutorial_view.dart](../lib/features/tutorial/tutorial_view.dart) |
| [tutorial_step2.png](swiftui_simulator/tutorial_step2.png) | STEP 2: AR로 흔들고 터치하기 | (동상) |
| [tutorial_step3.png](swiftui_simulator/tutorial_step3.png) | STEP 3: 퀴즈 풀고 클리어! | (동상) |
| [help_items_top.png](swiftui_simulator/help_items_top.png) | Items 탭 — Properties / Mission(Start/End/Hint/Mine/Defense/Gambling…) | [help_root.dart](../lib/features/help/help_root.dart) |
| [help_items_bottom.png](swiftui_simulator/help_items_bottom.png) | 스크롤 하단 — All Radar / Time / Special | (동상) |
| [help_howto.png](swiftui_simulator/help_howto.png) | How to Play — LIVE/HOME 모드 / 4 STEPS / REWARDS | (동상) |
| [help_design.png](swiftui_simulator/help_design.png) | Design — 5단계 (배치/설정/메타/테스트/업로드) + "미션 만들기 시작!" CTA | (동상) |

## 💡 작업 워크플로

Flutter 화면 1:1 매칭 시:
1. 위 표에서 대상 SwiftUI 캡쳐 열기 (cmd+클릭)
2. Flutter 디바이스에서 해당 화면 띄우고 `bash scripts/verify.sh` 또는 `flutter run` 후 스크린샷
3. 두 PNG 를 좌우로 놓고 차이점 한 줄씩 수정
4. [design_parity.md](../design_parity.md) 의 해당 Step 체크박스 진행

## ⚠️ 주의
- `legacy/` 안의 PNG 는 *이전 디자인* — 참고만 (현재 SwiftUI 와 다름)
- 시뮬레이터 화면이 디바이스 화면과 약간 다를 수 있음 (Dynamic Island/홈 인디케이터). 컨텐츠 영역만 비교
- 새 화면 추가 시 위 표에 행 추가 + 캡쳐는 snake_case + 상태 suffix
