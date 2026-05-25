# Changelog — v4 (latest)

## What changed since v3

### Map Play 화면 (`map-play`)

- **상단 HUD**: 녹색 풀바 → **투명 오버레이 floating elements**
  - EXIT: 빨간 candy 버튼 (cardinal-deep 2px 보더, 라운드 12px, 높이 42px)
  - 타이머: 흰색 pill + **주황 시계 아이콘** + tabular-nums `00:00:05` (모노스페이스)
  - Locate: 흰색 42×42 icon candy (macaw-deep 십자선)
  - Info: macaw 블루 42×42 icon candy (흰 ⓘ)
  - 상단에 자연스러운 어두운 그라데이션 띠 (텍스트 가독성)

- **하단 HUD**: 어두운 청록 알약 → **컬러별 candy chip 4개 + 카메라 버튼**
  - 좌측 chips: 지형 (macaw blue), 필수 (fox orange)
  - 우측 chips: HIDDEN (neutral white), STEALTH (beetle purple)
  - 각 chip: 라이트 틴트 배경 + 1.5px 보더, **플랫** (그림자 없음)
  - 카메라 버튼: 64×64 녹색 원, 3px 흰 보더, **플랫**
  - 4px 작은 갭으로 칩 잘림 방지

- **전체 플랫화**: Map Play 화면 내 모든 box-shadow 제거 (3D 느낌 완전 제거)

### AR Searching 화면 (`ar-search`)

- **상단 HUD**: ARTopBar 컴포넌트 새 디자인
  - 위치: `top: 36px` (상단 status bar 가리지 않음)
  - 녹색/청록 풀바 → **투명 오버레이** (위 살짝 어두운 그라데이션)
  - MAP 버튼: **글자 제거**, 테마 색깔의 **아이콘 전용** 42×42 candy 버튼
  - 타이머: Map Play와 **완전히 동일한 흰색 pill** + 주황 시계
  - 우측 42px 스페이서로 타이머 중앙 정렬

- **하단 HUD** (`ARBottomHud`): 어두운 청록 알약 → **흰색 candy 카드**
  - 좌측: macaw 깃발 아이콘 (macaw-bg 칩 안) + Start/2m 2줄
  - 중앙: 녹색 레이더 디스크 (68px)
  - 우측: 녹색 핀 아이콘 (green-100 칩 안) + 유효 반경/100m 2줄
  - 라벨 hare gray uppercase + 값 강조 컬러 (fox-deep / green-800)

### 공유 변경사항

- `.ps-digit` (타이머 카드) — box-shadow 제거 (3D 효과 완전 제거)
- ARTopBar 변경은 AR Found 미니게임과 Hint Popup에도 자동 반영됨
- Tweaks 패널의 컬러 테마(Green/Blue/Orange/Purple)가 ARTopBar의 MAP 버튼과
  Map Play 카메라 버튼에도 적용됨

## 적용 우선순위 (SwiftUI 변환 시)

높은 → 낮은:
1. Map Play 상단/하단 HUD (가장 많이 변경됨)
2. AR Searching 상단 ARTopBar
3. AR Searching 하단 ARBottomHud
4. AR Found 미니게임 (ARTopBar 자동 반영)
5. Hint Popup (ARTopBar 자동 반영)

## 파일

- `source/src/screens-game.jsx` — Map Play, AR Search, AR Found, Hint Popup 모두
- `source/styles/app.css` — `.ps-digit` 변경
- 나머지는 v3와 동일
