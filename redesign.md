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
