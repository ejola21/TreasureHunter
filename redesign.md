# redesign.md — 듀오링고 스타일 리디자인 작업 계획

> 목표: PlaySpot 의 디자인을 듀오링고 스타일로 전면 교체.
> 원칙: **소스 1-2 회 수정으로 끝낸다.** 화면별 반복 작업 X.

---

## 한 줄 요약

```
Claude Design 에서 시각 시안 + 토큰 확정  →  Claude Code 에서 한 번에 SwiftUI 구현
```

---

## 작업 흐름

### 1단계 — Claude Design (브라우저)

[claude.ai/design](https://claude.ai/design) 에서 진행. 소스 코드는 안 건드림.

**할 일:**
1. 듀오링고 스타일 시안을 5-10 개 핵심 화면에 적용
2. 디자인 토큰 명세서 추출
3. 핵심 컴포넌트 (버튼/카드/칩/뱃지) 의 정확한 수치 정리

**Claude Design 에 요청할 프롬프트 예시:**
```
이 디자인의 모든 화면에서 사용된 디자인 토큰을 정리해줘.
SwiftUI 로 옮기기 위해 필요한 명세서 형태로:
1) 모든 색 값 (hex) 와 용도
2) 모든 폰트 사이즈/굵기 와 용도
3) 모든 모서리 반경 값
4) 모든 그림자 값 (offset/blur/color)
5) 공통 컴포넌트 (버튼/카드/칩/뱃지) 의 정확한 수치
```

### 2단계 — Claude Code (이 세션) 에 가져올 것

| 항목 | 형태 | 분량 |
|---|---|---|
| **토큰 명세** | 텍스트 (hex / pt 값) | 1 페이지 |
| **컴포넌트 스펙** | 텍스트 (height / radius / padding / shadow) | 1 페이지 |
| **대표 화면 스크린샷** | PNG | 5-10 장 |
| **(선택) 특이 화면 캡쳐** | PNG — AR 오버레이, 지도 HUD 등 고유 레이아웃 | 1-2 장 |

→ **나머지 화면은 캡쳐 불필요.** 시스템이 자동 적용됨.

### 3단계 — Claude Code 가 한 번에 구현

단일 PR 로:
```
PlaySpot/Design/Theme.swift            ← 색·폰트·간격·반경·그림자 토큰
PlaySpot/Views/Components/DLButton.swift
PlaySpot/Views/Components/DLCard.swift
PlaySpot/Views/Components/DLBadge.swift
PlaySpot/Views/Components/DLProgressBar.swift
PlaySpot/Views/Components/DLChip.swift
+ 기존 모든 화면을 Theme/Components 사용하도록 일괄 변경
```

### 4단계 — 결과 확인 + 핀포인트 수정

- `bash scripts/verify.sh` 로 시뮬레이터 자동 스크린샷
- 어색한 화면만 추가 수정

---

## 왜 모든 화면을 캡쳐 안 해도 되는가

듀오링고 룩 = **토큰 10개 + 컴포넌트 5개** 의 일관된 사용.

이 시스템만 정확히 잡으면 **나머지 화면은 같은 primitives 로 재조립** → 자동으로 통일된 룩.

```
Claude Design 캡쳐 5-10 장  →  토큰/컴포넌트 추출  →  모든 화면 자동 적용
```

Claude Code 가 **모든 SwiftUI 소스를 직접 읽을 수 있음** → 시안 없는 화면도 같은 시스템으로 변환.

---

## 듀오링고 스타일 핵심 요소

| 요소 | 특징 | SwiftUI 매핑 |
|---|---|---|
| **컬러** | 채도 높은 초록 (#58CC02) primary + 진한 회색 텍스트 + 흰 배경 | `Color(hex:)` 토큰 |
| **버튼** | 둥근 + **아래쪽 4-6pt 진한 그림자** (3D 누름 효과) | `RoundedRectangle` 위·아래 다른 색 |
| **폰트** | 굵은 둥근 산세리프 | `.font(.system(.title, design: .rounded, weight: .black))` |
| **모서리** | 12-20pt 큰 라운드 | `cornerRadius: 16` |
| **카드** | 흰 배경 + 두꺼운 컬러 보더 + 큰 패딩 | `.padding(20)` + 3pt border |
| **CTA** | 화면당 1개의 큰 초록 버튼 | 명확한 primary action |
| **애니메이션** | bounce 스프링 | `.spring(response: 0.35, dampingFraction: 0.6)` |

---

## 체크리스트 — Claude Design 작업 완료 시점

진행하기 전 다음이 준비되어야 함:

- [ ] 핵심 화면 5-10 개 듀오링고 스타일 시안 확정
- [ ] 색 토큰 9-10 개 (hex 값)
- [ ] 폰트 스케일 4-5 단계 (size + weight)
- [ ] 모서리 반경 3-4 단계
- [ ] 그림자 명세 (button / card 각각)
- [ ] 컴포넌트 5 개 (button / card / chip / badge / progress) 정확한 수치
- [ ] 시안 화면 캡쳐 PNG 5-10 장
- [ ] (선택) 특이 화면 캡쳐 PNG 1-2 장

다 모이면 이 세션에서 한 번에 구현.

---

## 예상 작업 시간

| 단계 | 소요 |
|---|---|
| Claude Design 시안 + 토큰 확정 | 사용자가 진행 (병렬) |
| Claude Code 구현 (Theme + Components + 모든 화면) | 1-2 시간 (1 PR) |
| 결과 확인 + 핀포인트 수정 | 30 분 |
| **총** | **반나절** |

---

## 참고

- 현재 시스템 미사용 — 기본 SwiftUI 컬러/폰트 사용 중
- 이번 작업으로 디자인 시스템 도입 → 향후 화면 추가 시 자동으로 일관된 룩
- 듀오링고 스타일은 게임 도메인과 잘 맞음 (별점/배지/연속 진행도 등 요소 친화)


#
아이템 디자인 변경예정이다 신규 디자인을 playspot 리소스에 이름과 사이즈를 똑같이해서 업데이트 할예정이다
작업 방식에 문제가 있는지 확인해줘
./new_img/아이템섦영.png 를 읽어서 같은 폴더에 있는 아이템 이름을 변경해줘 현재 플레이스팟 프로젝트의 이름으로 변경해줘
변경후 그대로 복사해서 업데이트 할계획이다, 

./new_img/에 coupon, store, all_rader 추가했다
좀전 작업처럼  프로젝트의 이름으로 변경해줘
변경후 그대로 복사해서 업데이트 할계획이다 





# 클로드 디자인 개발자 핸드오프후 작업

README.md — 25+ 화면 풀스펙 + 디자인 토큰 + SwiftUI 구현 가이드
swiftui_starter/DuoTokens.swift — 색상/폰트/Candy Button/Card 즉시 사용 가능
source/ — HTML 프로토타입 + JSX 소스 + CSS 토큰 + 17개 PNG 핀 + 폰트

Claude Code에서 이 폴더를 열고 "Implement the screens described in README.md using DuoTokens.swift" 같은 식으로 시작하시면 됩니다.

# 
./design_handoff_playspot_redesign 폴더를 깊게 읽고 읽고
Implement the screens described in README.md using DuoTokens.swift


#
./design_handoff_playspot_redesign 폴더를 깊게 읽고 읽고


./design_handoff_playspot_redesign/README.md
./design_handoff_playspot_redesign/swiftui_starter/DuoTokens.swift

위 핸드오프 문서와 디자인 토큰을 참고해서 AR-Searching 화면(`ar-search`) 을 SwiftUI 로 구현해줘.

요구사항:
1. 먼저 DuoTokens.swift 파일을 내 Xcode 프로젝트에 추가해줘 (없으면 새로 만들어서 복사)
2. Jalnan2.ttf 폰트를 프로젝트에 추가하고 Info.plist에 등록해줘
   (~/Downloads/design_handoff_playspot_redesign/source/styles/fonts/Jalnan2.ttf)
3. AR 화면에 필요한 PNG 자산을 Assets.xcassets에 추가해줘:
   - ~/Downloads/design_handoff_playspot_redesign/source/assets/items/i_start.png
4. 새 SwiftUI 파일 `ARSearchView.swift`를 만들어줘. 구성 요소:
   - 상단 그린 그라데이션 HUD 바 (Duo green-500 → green-700)
     - 왼쪽: 청록색 MAP 버튼 (64x36, 코너 라운드 10px)
     - 가운데: 흰색 카드 형식 타이머 (00:09:00, 1.5px 흰 보더, 그림자 없음)
   - 카메라 뷰 배경: 라디얼 그라디언트 (#6FA356 → #1B3815) + 나무 실루엣 SVG
   - Start 아이템 핀 (assets/items/i_start.png 사용, 56pt 크기)
     - 아래 4가지 애니메이션 모두 적용:
       a) Float: -12pt 위아래 (2.2초, spring easing)
       b) Sway: ±5° 좌우 회전 (2.8초)
       c) Pop: 1.08배 scale (2.2초)
       d) 펄스 링: 2개의 노란 원이 0.7배→2.0배 확장하며 페이드 아웃
       e) 회전하는 conic gradient 글로우 링 (3.6초)
       f) 노란 sparkle 입자 3개가 위로 떠올랐다 사라짐
   - 하단 AR HUD 바 (어두운 청록 #1A5E69 → #0E3A42):
     - 왼쪽: Start 깃발 아이콘 + "Start / 2m" (12pt/14pt 2줄 스택, 값은 노란색)
     - 가운데 위로 떠 있는: 녹색 레이더 디스크 (64pt 원, 흰 보더, sweep + 화살표 바늘)
     - 오른쪽: 녹색 지도 마커 아이콘 + "유효 반경 / 100m" (값은 파란색)

5. 색상은 반드시 DuoTokens.swift의 Color extension만 사용해줘 (Color.duoGreen500 등)
6. 작업 완료 후 시뮬레이터에서 빌드되는지 확인하고, 빌드 에러가 있으면 수정해줘

#
PlaySpot 디자인이 업데이트됐어. 변경 사항:
참조 : ./design_handoff_playspot_redesign/README.md
1. Map Play 상단 HUD:
   - 녹색 풀바 → 투명 오버레이 (지도가 끝까지 보임)
   - EXIT: 빨간 candy 버튼 (40px, 라운드 12)
   - 타이머: 흰 pill + 주황 시계 아이콘
   - Locate/Info: 42×42 icon candy 버튼

2. Map Play 하단 HUD:
   - 5컬럼 그리드: 지형/필수/[카메라]/HIDDEN/STEALTH chip
   - 각 chip이 라이트 틴트 + 1.5px 보더 (플랫)
   - 카메라: 64px 녹색 원, 3px 흰 보더 (그림자 없음)

3. AR Searching 상단:
   - status bar 아래 36px 위치 (안 가리게)
   - MAP 버튼: 아이콘만, 테마 색 candy
   - 타이머: Map Play와 동일한 흰 pill

위 변경을 내 SwiftUI 코드에 적용해줘.

