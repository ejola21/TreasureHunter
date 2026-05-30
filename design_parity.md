# design_parity.md — Mission Design 화면 SwiftUI ↔ Flutter 1:1 매칭

> 사용자 요구: "미션 디자인의 모든 화면과 기능, 디자인을 똑같이 해줘". 단계별 진행 추적용.

## 📊 인벤토리 (2026-05-30)

### SwiftUI MissionBuilder (PlaySpot/Views/MissionBuilder/) — 10 파일, 2,573줄
| 파일 | 줄 | 용도 |
|---|---|---|
| MissionBuilderViewModel.swift (Game/) | 489 | Builder 비즈니스 로직 |
| MissionSetupView.swift | 511 | 신규 미션 생성 폼 (제목/장소/시간/모드) |
| ItemForms.swift | 298 | 아이템 편집 폼 (타입별 입력 필드) |
| MissionBuilderView.swift | 280 | 빌더 컨테이너 (라우팅) |
| BuilderMapView.swift | 234 | 지도 화면 위젯 (핀 표시) |
| MissionBuilderMapView.swift | 194 | 지도 호스트 (제스처) |
| ItemPickerView.swift | 172 | 아이템 타입 선택 시트 |
| ItemDetailView.swift | 164 | 핀 탭 시 편집 시트 |
| DesignActionSheet.swift | 149 | 미션 액션 (저장/공개/삭제) |
| QuizVariantsView.swift | 82 | 퀴즈 변형 (정답 2종) |

### SwiftUI MissionDetail/List (PlaySpot/Views/MissionList/) — 3 파일, 674줄
| 파일 | 줄 | 용도 |
|---|---|---|
| MissionDetailView.swift | 416 | 상세 화면 (히어로/정보/랭킹/리뷰) |
| MissionListView.swift | 151 | 미션 목록 (4 세그) |
| MissionRowView.swift | 107 | 미션 카드 |

### Flutter 현재 (lib/features/) — 8 파일, 1,044줄
| 파일 | 줄 | 상태 |
|---|---|---|
| design/builder_page.dart | 275 | 🟡 단순화됨 (vs SwiftUI 234+194+489+280 = 1,197줄) |
| design/mission_setup_page.dart | 100 | 🟡 단순 (vs SwiftUI 511줄) |
| design/design_list_page.dart | 152 | 🟢 OK |
| design/design_providers.dart | 14 | 🟢 OK |
| missions/mission_detail_page.dart | 257 | 🟡 단순 (vs SwiftUI 416줄) |
| missions/mission_list_page.dart | 123 | 🟢 OK |
| missions/mission_card.dart | 82 | 🟢 OK |
| missions/mission_providers.dart | 41 | 🟢 OK |

**격차**: Flutter 가 SwiftUI 대비 약 **40%** 줄 수.
주요 누락: ItemDetailView/ItemForms (핀 편집 폼), MissionBuilderViewModel (분리 로직), QuizVariantsView, DesignActionSheet, MissionSetupView 의 장소 검색/시간 모드/Virtual 모드 토글 등.

---

## ✅ Step 진행 체크리스트

### Step 1 — ItemPickerView (Picker 누락 아이템 추가) ✅
- [x] SwiftUI ItemPickerView.swift (172줄) 분석
- [x] 15 아이템 타입 순서대로 노출 (start/end/simple/quiz/random/timeoutStart/mine/black/mineNoBomb/solution/coupon/store/radarAR/radarMap/radarMine) — timeoutEnd 는 페어링
- [x] 다크 toolbar (CANCEL / "ITEM · DISPLAY · VISIBLE RANGE" / DONE-bee)
- [x] 미리보기 카드 (아이콘 + 라벨 + Display 칩 + Range 칩 + helpText)
- [x] 3-컬럼 CupertinoPicker 휠 (Item 45% / Display 30% / Range 25%)
- [x] showType (Visible/Hidden/Stealth) + rangeAR (10/20/30/40/50/60/70/80/100/150/200/300/500m) 선택 후 아이템에 즉시 적용
- [x] 신규 파일: lib/features/design/item_picker_sheet.dart (162줄)
- [x] builder_page.dart 가 신규 picker 사용 (구 Wrap+ActionChip 제거)
- [x] analyze 통과
- [x] **사용자 검증** — 디바이스 캡처로 SwiftUI 와 픽셀 일치 확인 (14:16 캡처)

### Step 2 — ItemDetailView + ItemForms (핀 탭 시 편집 시트) ✅
- [x] SwiftUI ItemDetailView (164줄) + ItemForms (298줄) 1:1 분석
- [x] ItemType extension `detailGuide.effect`/`tip` 매핑 (17 타입)
- [x] 상단 toolbar: 취소(macaw) / "아이템 상세" / 완료(macaw heavy)
- [x] 정보 카드: ItemPin 56 + "ITEM · 아이템" kicker + 라벨 + effect
- [x] 💡 tip 카드: beeBg + 0xE8C878 stroke + 💡 emoji + tip 텍스트
- [x] 폼 카드: 16 SubForm 을 *매트릭스 압축* (mandatoryMode/showsShowType/showsItemGame/showsRelationId/showsEffectiveTime/infoLabel)
- [x] 필수 여부: 자동 켜짐(green) / 자동 꺼짐(hare) / 사용자 토글
- [x] 표시 방식: Visible/Hidden/Stealth ChoiceChip + helpText
- [x] 발견 거리: Slider 5-500 step 5
- [x] 미니게임: 없음/흔들기/터치(준비)/랜덤(준비) ChoiceChip
- [x] 페어 ID: readonly (timeoutStart/End)
- [x] 제한 시간: Slider 1-3600s (timeoutEnd)
- [x] 안내 문구: TextField (타입별 라벨)
- [x] 삭제 버튼: cardinal outline + trash 아이콘 + heavy 햅틱
- [x] 신규 파일: lib/models/item_type_detail.dart (123줄)
- [x] 신규 파일: lib/features/design/item_detail_sheet.dart (336줄)
- [x] builder_page.dart 핀 탭 → 새 sheet (구 InlineEditor 제거)
- [x] analyze 통과 + 49/49 tests
- [ ] **사용자 검증** — 핀 탭 → 시트 확인

### Step 3 — MissionSetupView (신규/편집 미션 폼) ✅
- [x] SwiftUI MissionSetupView 511줄 1:1 재이식
- [x] **AppBar**: 취소(macaw) / centered title / 저장(macaw heavy)
- [x] **타이틀** "새 미션" / "미션 편집" inline 28pt display
- [x] **FormGroup 6 그룹** + duoSnow 배경
  - 기본 정보 (제목 kicker + 장소 kicker + 자동 채우기 row)
  - 설명 (멀티라인 TextEditor)
  - 플레이 제한 시간 (toggle + 3-wheel h:m:s CupertinoPicker)
  - 플레이 설정 (Virtual 모드 toggle + 언어 picker)
  - 공개 설정 (공개 toggle + 동적 subtitle)
  - 뱃지 이미지 (preview + 선택/변경/제거 버튼)
- [x] **검증**: 제목 비면 저장 비활성
- [x] **isDirty 추적** + 닫기 시 confirm dialog (저장 후 닫기 / 저장 안 함 / 취소)
- [x] **"아이템 배치 (지도 진입)" Beetle candy 버튼** — deep offset y:4 스택
- [x] design_list_page Modify action → MissionSetupPage(mission: m) 라우팅
- [x] 신규 파일: mission_setup_page.dart (520줄)
- [ ] 좌표 → 장소 자동 채우기 (geocoding 패키지 미설치, "곧 지원 예정" snackbar)
- [ ] 뱃지 이미지 picker (image_picker 패키지 미설치, "곧 지원 예정" snackbar)

### Step 4 — MissionDetailView (상세 화면) ✅
- [x] SwiftUI MissionDetailView.swift 416줄 1:1 분석
- [x] **히어로 카드**: macawBg + macawBorder 2pt + 64×64 badge + "BY DESIGNER" kicker(macawDeep) + 제목 + 별점 + description + PLAYS/FAILS chips
- [x] **InfoRows 카드** (4행, 흰 + swan2 stroke):
  - PLACE (macaw 컬러 아이콘 배지 32×32)
  - ITEMS (green) — 필수 N + 전체 N chips
  - TIME LIMIT (fox)
  - CREATED (beetle)
- [x] **Rankings 카드** — 흰 + swan2 stroke + DuoKicker + top3 rank rows
- [x] **Reviews 카드** — 흰 + swan2 stroke + 빈 상태 안내 / 리뷰 row (별점 + 닉네임 + 날짜 + 텍스트)
- [x] **Sticky 하단** — `bottomNavigationBar` 로 고정 "Play · 미션 시작" 초록 버튼
- [x] **Mode Sheet** — Virtual 미션 시 dim 55% + 흰 카드 + REAL/VIRTUAL 2-button (Real green / Virtual beetle, deep offset y:4 stack)
- [x] 배경 duoSnow
- [x] AppBar centerTitle + 흰 배경


### Step 5 — BuilderMapView / MissionBuilderMapView (지도) ✅
- [x] SwiftUI MissionBuilderMapView 194줄 1:1 (BuilderMapView 234줄 + ViewModel 일부)
- [x] **AppBar**: "EDITING" kicker(9pt) 위 + "아이템 배치" 14pt display 두 줄 centered + "완료" 우측
- [x] **핀**: ItemType.mapIcon(mandatory) 실제 PNG (in_/i_ prefix 자산 사용) 44×44
- [x] **영역 원**: rangeAR 기준
  - Mine: cardinal 18% fill + 55% border
  - Dark: beetle 18% fill + 55% border
  - 기본: green 12% fill + 50% border
- [x] **핀 탭 → 콜아웃** ("타입명 거리m" + 파란 원형 → 화살표) → ItemDetailSheet
- [x] **하단 다크 toolbar**: 🦊 + "꾹 눌러서 아이템 배치 · 탭으로 설정" + "아이템 N · 필수 M"
- [x] **검증 배너 (cardinal)**: Start/End 핀 없으면 상단 표시
- [x] 길게 누름 → ItemPickerSheet
- [x] 초기 카메라: 첫 아이템 좌표 또는 fallback (37.486, 126.808)
- [x] builder_page.dart 완전 재작성 (197 → 285줄)

### Step 6 — DesignActionSheet · QuizVariantsView
- [x] **DesignActionSheet** — SwiftUI 149줄 1:1 이식 (Phase 6-A)
  - [x] 헤더 (kicker + 제목 + place)
  - [x] 안내 ("완성된 디자인을 테스트해본 뒤 서버에 업로드하세요.")
  - [x] **5 ActionRow 카드**: View(beetle) / Modify(macaw) / Test(fox) / Publish-Unpublish(green/beetle) / Delete(cardinal/hare)
  - [x] 컬러 아이콘 배지 36×36 + 제목(duoDisplay 14) + subtitle(12) + chevron
  - [x] important=true 시 stroke 컬러 매칭
  - [x] muted (published 미션의 Delete) opacity 0.7 + 회색 + 비활성
  - [x] 취소 버튼 (흰 outline + DuoColors.swan2 stroke)
  - [x] 신규 파일: lib/features/design/design_action_sheet.dart (167줄)
  - [x] design_list_page.dart 행 탭 → 새 시트 (PopupMenuButton 제거)
  - [x] **View → MissionDetailPage** push (사용자 신고: "미션 상세 조회 화면이 없다" 해결)
  - [x] **Test → StartGamePage** push (사용자 신고: "테스트 엇고" 해결)
  - [x] Modify → BuilderPage push
  - [x] Publish/Unpublish/Delete 기존 로직 그대로
- [x] **사용자 검증 완료 (15:03 캡처)** — SwiftUI 와 픽셀 단위 일치 확인
- [x] **QuizVariantsView 인라인 이식** — item_detail_sheet.dart 안에 Quiz 변형 섹션
  - [x] 헤더 "QUIZ 변형 (N개)" + ADD 버튼 (macaw plus.circle)
  - [x] 행: #seq + 퀴즈 질문 TextField + 정답 TextField + 삭제 X 아이콘
  - [x] 빈 상태 "최소 1개의 변형을 추가하세요 (필수)." (cardinal)
  - [x] ItemQuiz quiz/answer mutable 화 (편집 가능)

### Step 6-C — ItemDetail 폼 추가 필드 (s30/s32/s35/s36 캡쳐 반영) ✅
- [x] **Mine**: 폭발 반경 라벨 (foxDeep) 발견 거리 아래
- [x] **Dark**: 다크존 반경 라벨 (beetleDeep)
- [x] **Run End**: 거리 (자동) 행 — paired Start 와 거리 표시 (effectiveRange)

### Step 7 — analyze + 빌드 검증 ✅
- [x] flutter analyze — 0 issues
- [x] flutter build apk (debug) — ✓ Built app-debug.apk
- [x] flutter build web --release — ✓ Built build/web
- [x] design_parity.md 최종 업데이트

---

## 📝 작업 로그

### 2026-05-30 13:50 - Step 0 완료
- design_parity.md 작성
- 인벤토리 + 체크리스트 + 작업 로그 섹션 마련

### 2026-05-30 16:30 - Step 3·5·6-C·7 (미션 디자인 전체 매칭) 완료
- **Step 3 (mission_setup_page)**: 100→520줄, FormGroup 6 그룹 + 3-wheel 시간 + Beetle 진입 버튼 + isDirty/confirm + Toolbar
- **Step 5 (builder_page)**: 197→285줄, EDITING/완료 toolbar + ItemType.mapIcon PNG 핀 + 콜아웃(파란 화살표) + Fox 다크 toolbar + validation cardinal banner + Mine/Dark 영역 원 색상 차별화
- **Step 6-B (Quiz 변형)**: item_detail_sheet 안에 QuizVariantsView 인라인 이식 — 헤더+ADD, 변형 행(질문/정답 TextField + 삭제 X), 빈 상태 안내
- **Step 6-C (폼 추가 필드)**: Mine 폭발 반경, Dark 다크존 반경, Run End 거리(자동) 라벨 추가
- **모델 변경**: ItemQuiz quiz/answer final → mutable, 생성자 const 제거 (편집 가능)
- **DesignList Modify 라우팅**: BuilderPage → MissionSetupPage(mission: m) 로 변경 (SwiftUI 일치)
- **빌드 검증**: analyze 0 issues, Android debug + Web release 모두 성공

---

## 🎯 디자인 원칙

1. **SwiftUI 원본을 ground truth 로** — 디자인/문구/색상/순서 추측 금지
2. **DuoTokens 일관성** — Color/Padding/Radius/Font 동일 사용
3. **에셋 매핑** — `Items/i_*` + `Items/in_*` (필수) PNG 일관 사용
4. **검증 사이클** — 각 Step: 코드 작성 → analyze → test → 캡처 비교
5. **MD 업데이트** — 각 Step 완료 시 체크박스 + 작업 로그 추가
