# item-kdrama.md

# K-Drama Time Machine — 상세 사용자 UX
## "Then vs Now" 패턴의 K-드라마 응용 (코드 85 변형 또는 신규 86)

> 본 문서는 `sechon_play_00.md` 의 Hidden Spot (코드 85) 을 K-드라마 콘텐츠로 확장한 UX 명세이다.
> 사용자가 드라마 촬영지를 찾아 같은 각도에서 사진을 찍고, AI 가 비교한 뒤 Then/Now 영상으로 자동 합성한다.
> 외국인 관광객 중 K-콘텐츠 팬덤이 핵심 타깃.

---

## 0. 사용자 페르소나

**Maria, 28세, 스페인 마드리드**
- 한국 첫 방문, 3박 4일
- "Goblin"·"Reply 1988" 봤음, 한국어 못 함
- 인스타그램 활발, 여행 사진 중심
- 동선: 경복궁 → 서촌 → 북촌 (반나절)

### Goals
- "내가 본 드라마 배경에 진짜 서봤다" 증거
- 가족·친구에게 자랑할 영상 콘텐츠
- 부담 없이 30분 안에 끝나야 함

### Total Time
약 5~7 분 (1 미션 기준)

---

## 1. 발견 단계 — "어, 드라마 미션이 있네?"

서촌 투어를 시작한 Maria 가 첫 스팟 도착. 평소 미션 카드 옆에 새 카드가 자연스럽게 끼어든다.

### 화면 1-1. 홈 카드 — K-Drama 알림 (서촌 도착 시)

```
┌──────────────────────────────────┐
│                                  │
│   🎬  Walking through K-Drama    │
│       History                    │
│                                  │
│   This alley appeared in 3       │
│   famous dramas you might know.  │
│                                  │
│   ▸ Goblin (2017)                │
│   ▸ Reply 1988 (2015)            │
│   ▸ Crash Landing on You (2019)  │
│                                  │
│   [ Try first scene → ]          │
│   [ Maybe later ]                │
│                                  │
└──────────────────────────────────┘
```

### 디자인 의도
- "Walking through… History" — 일상 동선이 콘텐츠로 전환되는 톤
- 3개 드라마를 미리 보여줘 외국인이 익숙한 작품 1개만 있어도 끌림
- 거부 옵션 ("Maybe later") 부드럽게 — 강압감 0

### 기술
GPS 도착 + 사용자 프리프 ("K-drama interest" 온보딩에서 선택 시) 기반 자동 노출. 미선택자는 안 뜸.

---

## 2. 선택 단계 — "어떤 장면을 찾아볼까"

### 화면 2-1. 드라마 씬 갤러리

```
┌──────────────────────────────────┐
│ [←]    K-Drama Spots — Seochon   │
├──────────────────────────────────┤
│                                  │
│  💜 Most Loved                    │
│  ┌──────────────────────────────┐│
│  │  [블러처리된 드라마 스틸]      ││
│  │                              ││
│  │  ★ Goblin                    ││
│  │  "이번엔 안 잡혀 줄게"          ││
│  │  Ep 12 · 2017 · 4-min walk   ││
│  │                              ││
│  │  127 explorers found this    ││
│  └──────────────────────────────┘│
│                                  │
│  ┌──────────────────────────────┐│
│  │  [블러 스틸]                  ││
│  │  Reply 1988                   ││
│  │  "여기서 보자"                 ││
│  │  Ep 7 · 2015 · 2-min walk    ││
│  └──────────────────────────────┘│
│                                  │
│  ┌──────────────────────────────┐│
│  │  [블러 스틸]                  ││
│  │  Crash Landing on You         ││
│  │  Ep 3 · 2019 · 7-min walk    ││
│  └──────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

### 디자인 의도
- **스틸을 일부러 블러** — 사용자가 "직접 찾아 인증해야 풀린다" 는 게임감
- "X explorers found this" 사회 증명 → 신뢰 + 도전 욕구
- 거리 (4-min walk) 정확히 표시 → 무리한 선택 방지
- 평소 미션과 시각적으로 구별: 보라색 톤 (K-pop 톤)

Maria 가 **Goblin** 선택.

---

## 3. 단서 단계 — "어디로 가야 하지?"

### 화면 3-1. 미션 브리핑

```
┌──────────────────────────────────┐
│ [×]   Mission: Find the Goblin    │
├──────────────────────────────────┤
│                                  │
│   🎬  Goblin · Episode 12         │
│       February 2017               │
│                                  │
│   ┌─────────────────────────────┐│
│   │  [반투명 블러처리 드라마 컷]  ││
│   │    👤 Gong Yoo standing      ││
│   │       in a narrow alley     ││
│   │                              ││
│   │  Quote: "이번엔 안 잡혀 줄게" ││
│   │  "This time, I won't get    ││
│   │   caught"                    ││
│   └─────────────────────────────┘│
│                                  │
│   📍 Walk 4 minutes northwest    │
│                                  │
│   Clues:                         │
│   ▸ A narrow alley with         │
│     brick walls                  │
│   ▸ Near a small wooden door     │
│   ▸ The camera was at chest      │
│     height, facing south         │
│                                  │
│   [ 🧭 Start walking ]            │
│   [ 👁 Show full still ]          │
│                                  │
└──────────────────────────────────┘
```

### 디자인 의도
- **단서 텍스트 3줄** = 외국인이 풀 수 있는 시각 단서, 한국어 모름 OK
- "Show full still" = **포기 옵션** — 처음부터 풀버전 보여줘도 됨, 게임 페어플레이
- 인용구 한국어 + 영어 = 학습 효과
- 옵션 두 가지 톤: 도전적 ("Start walking") vs 편한 ("Show full still")

### 화면 3-2. 길찾기 (걷는 동안)

```
┌──────────────────────────────────┐
│ [×]   Walking to Goblin scene    │
├──────────────────────────────────┤
│                                  │
│   ┌─────────────────────────────┐│
│   │                              ││
│   │   [지도 — 현재 위치 + 화살표] ││
│   │                              ││
│   │      👤 ───→  🎯              ││
│   │                              ││
│   └─────────────────────────────┘│
│                                  │
│   3 min · 240 m                  │
│                                  │
│   💭 "While you walk…"            │
│   "Goblin (Episode 12) was       │
│   filmed during winter 2016.     │
│   Director Lee Eung-bok said    │
│   he chose this alley for its   │
│   quiet, lonely feel."           │
│                                  │
│   ▶ Listen (0:30)                │
│                                  │
└──────────────────────────────────┘
```

### 디자인 의도
- 걷는 동안 **지루함 0** — 트리비아 카드 + 음성 옵션
- "While you walk…" 음성은 헤드폰 자동 페어. 끄기 가능.
- 진행도 (3 min · 240m) 명확

### 화면 3-3. 도착 직전 (30m 이내)

```
┌──────────────────────────────────┐
│                                  │
│        🎯  Almost there!         │
│                                  │
│        Look around for           │
│        a narrow brick alley.     │
│                                  │
│        [핸드폰 흔들기 또는 회전    │
│         가이드 애니메이션]         │
│                                  │
└──────────────────────────────────┘
```

GPS 정확도 한계 (도심 ±10m) 보완 — 마지막 몇 미터는 사용자 시각 탐색에 맡김.

---

## 4. 도착 단계 — "여기인가?"

### 화면 4-1. 위치 인식 — 카메라 활성

```
┌──────────────────────────────────┐
│ [×]   📍 Spot detected            │
├──────────────────────────────────┤
│                                  │
│  ┌─────────────────────────────┐ │
│  │                              │ │
│  │   [라이브 카메라 영상]         │ │
│  │                              │ │
│  │   ┌─────────────────────┐    │ │
│  │   │ [드라마 컷 반투명 50%]│    │ │
│  │   │  Gong Yoo silhouette │    │ │
│  │   │  Brick wall pattern  │    │ │
│  │   └─────────────────────┘    │ │
│  │                              │ │
│  │   Match the angle ↑          │ │
│  │                              │ │
│  └─────────────────────────────┘ │
│                                  │
│  💡 Move closer, rotate phone,   │
│      until the brick wall lines  │
│      up with the overlay.        │
│                                  │
│       [    📸 Capture    ]       │
│                                  │
│  [ Hint: -10 pts ]               │
└──────────────────────────────────┘
```

### 디자인 의도
- **드라마 컷이 카메라 위에 반투명 합성** → 사용자가 직접 "맞춰 찍는" 인터랙션
- **벽돌 패턴 같은 시각 단서** 가 일치되는 순간 사용자 눈에 직접 보임
- "Move closer, rotate" 짧고 명확한 가이드
- 힌트는 비용 (-10 pts) — 게임 균형

### 화면 4-2. 보조 가이드 (자이로/나침반 활용)

```
┌──────────────────────────────────┐
│  ┌─────────────────────────────┐ │
│  │   [라이브 카메라]              │ │
│  │                              │ │
│  │   🧭 Turn 15° right          │ │
│  │      ━━━━━●━━━━ (compass)   │ │
│  │                              │ │
│  │   📐 Tilt down 5°            │ │
│  │      ━━●━━━━━━━ (pitch)     │ │
│  │                              │ │
│  └─────────────────────────────┘ │
│                                  │
│   Almost matching! Hold steady…  │
└──────────────────────────────────┘
```

### 디자인 의도
폰의 나침반 + 가속도 센서로 **실시간 보조 가이드** — Maria 가 정확한 각도에 가까워질수록 안내가 사라지고 셔터 활성화.

---

## 5. 인증 단계 — "맞았을까?"

### 화면 5-1. 분석 중 (가짜 3단계)

```
┌──────────────────────────────────┐
│                                  │
│      [Maria 가 찍은 사진]          │
│      (블러 처리)                   │
│                                  │
│      🔍 Analyzing your shot…      │
│                                  │
│      ▰▰▰▰▱▱▱▱  step 2 of 3       │
│                                  │
│      ▸ Reading brick pattern…    │
│      ✓ Matching angle…           │
│      ▸ Comparing with 2017…      │
│                                  │
└──────────────────────────────────┘
```

### 디자인 의도
- 실제 AI 호출은 1.5~3초. 단순 스피너는 답답함 ↑
- **3단계 가짜 진행 표시** 로 체감 단축 + 기술 신뢰감
- 사진은 블러로 미리 보여줌 → "결과 준비 중" 감각

### 화면 5-2. 성공 케이스

```
┌──────────────────────────────────┐
│                                  │
│         🎬                        │
│       MATCH FOUND                │
│                                  │
│     93% angle accuracy           │
│                                  │
│   ┌─────────────────────────────┐│
│   │  ╔═══════════╗               ││
│   │  ║ Then 2017 ║  [드라마 컷]  ││
│   │  ╠═══════════╣               ││
│   │  ║ Now  2026 ║  [사용자 사진] ││
│   │  ╚═══════════╝               ││
│   │                              ││
│   │  ━━━━━●━━━━━ slide to       ││
│   │   compare                    ││
│   └─────────────────────────────┘│
│                                  │
│   [ ▶ Watch the transition ]     │
│   [ 🎁 See what changed ]         │
│                                  │
└──────────────────────────────────┘
```

### 디자인 의도
- "93% accuracy" — 정량 피드백, 게임감 ↑
- **좌우 슬라이더** 로 사용자가 직접 Then/Now 비교 — 인터랙티브 = 몰입
- 두 가지 다음 액션: "Watch the transition" (감성) / "See what changed" (탐험)

### 화면 5-3. 실패 케이스 (부드러운 처리)

```
┌──────────────────────────────────┐
│                                  │
│         🤔                        │
│       Not quite there             │
│                                  │
│     58% angle accuracy           │
│                                  │
│   Camera angle is too high.       │
│   Try crouching a bit.            │
│                                  │
│   Hint: The original was shot     │
│   at chest height.                │
│                                  │
│   [ 📷 Try again (free) ]         │
│   [ 👁 Accept anyway (-30 pts) ]  │
│   [ Skip ]                        │
│                                  │
└──────────────────────────────────┘
```

### 디자인 의도
- "Not quite there" — 부드러운 톤, 실패 부담 ↓
- 구체적 개선 힌트 ("crouching") → 학습형 피드백
- **재시도 무료** — 사용자가 답답해할 비용 부과 X
- "Accept anyway" 옵션 — 60% 정도면 그냥 통과해주는 관용

---

## 6. 보상 단계 — "와, 진짜 시간 여행 같다"

### 화면 6-1. Then/Now 비교 — 슬라이더 인터랙션

```
┌──────────────────────────────────┐
│  [×]   Goblin · Then vs Now      │
├──────────────────────────────────┤
│                                  │
│   ╔═════════════════════════════╗ │
│   ║                              ║ │
│   ║   [좌측 50% — 2017 드라마]    ║ │
│   ║   [우측 50% — 2026 사용자]    ║ │
│   ║                              ║ │
│   ║      ━━━━●━━━━━━━━           ║ │
│   ║   ← drag to slide →          ║ │
│   ║                              ║ │
│   ╚═════════════════════════════╝ │
│                                  │
│   Differences spotted (AI):       │
│   ✓ The blue door is gone        │
│   ✓ Trees grew taller             │
│   ✓ New cafe sign on the right    │
│   ✓ Lamp post style changed      │
│                                  │
│   What stayed the same:           │
│   ✓ The brick wall                │
│   ✓ The cobblestone path          │
│                                  │
│   [ Tap a difference for trivia ] │
│                                  │
└──────────────────────────────────┘
```

### 디자인 의도
- **슬라이더** = 사용자 직접 비교 → 능동적 발견
- **변한 것 vs 변하지 않은 것** 두 컬럼 — 시간의 깊이감 양방향 전달
- 각 차이 탭하면 트리비아:
  ```
  "The blue door belonged to a 60-year
   tailor shop. Closed in 2019 due to
   the owner's retirement."
  ```

### 화면 6-2. 자동 디졸브 영상 — Reel

```
┌──────────────────────────────────┐
│                                  │
│   [5초 영상 자동 재생]              │
│                                  │
│   0:00 ━━━━━●━━━━━━━ 0:05         │
│                                  │
│   Frame 1: Drama still            │
│   Frame 2: Cross-fade             │
│   Frame 3: User photo             │
│   Caption: "Seochon · 2017→2026" │
│   BGM: Goblin OST (5 sec)        │
│                                  │
│   [ Save to gallery ]             │
│   [ Share to Instagram ]          │
│   [ Add to my Vlog ]              │
│                                  │
└──────────────────────────────────┘
```

### 디자인 의도
- **세로 9:16** 자동 — 인스타·틱톡 즉시 호환
- BGM 5초 = 라이선스 안전 범위 + 강력한 감정 트리거
- 3개 액션:
  - Save (앨범) — 개인 보관
  - Share (인스타) — 외부 확산
  - Add to my Vlog — 투어 종료 V로그 자동 편입

### 화면 6-3. 완료 보상

```
┌──────────────────────────────────┐
│                                  │
│         🏆                        │
│      K-Drama Pilgrim              │
│                                  │
│   You walked where Gong Yoo       │
│   walked in 2017.                 │
│                                  │
│   +120 pts                        │
│   Drama Stamp 획득                 │
│                                  │
│   2 more dramas waiting in        │
│   Seochon:                        │
│   ▸ Reply 1988                    │
│   ▸ Crash Landing on You          │
│                                  │
│   [ Continue tour ]               │
│   [ Try next K-drama ]            │
│                                  │
└──────────────────────────────────┘
```

### 디자인 의도
- "Pilgrim" 칭호 = 종교적 무게감, K-콘텐츠 팬 정체성 강화
- 다음 미션 노출 — 연속 플레이 유도
- 일반 보상 (120 pts) + 특별 보상 (Drama Stamp) 이중 구조

---

## 7. 메타 레이어 — 컬렉션 & 진행도

### 화면 7-1. Drama Passport (전역 컬렉션 화면)

```
┌──────────────────────────────────┐
│ [←]   🎬 My K-Drama Passport     │
├──────────────────────────────────┤
│                                  │
│   Seoul                           │
│   ┌──────┐ ┌──────┐ ┌──────┐     │
│   │Goblin│ │ R88  │ │  ?   │     │
│   │ ✓    │ │ ✓    │ │ Crash│     │
│   └──────┘ └──────┘ └──────┘     │
│                                  │
│   ┌──────┐ ┌──────┐ ┌──────┐     │
│   │  ?   │ │  ?   │ │  ?   │     │
│   │ More │ │ More │ │ More │     │
│   └──────┘ └──────┘ └──────┘     │
│                                  │
│   Busan (coming soon) 🔒          │
│   Jeju (coming soon) 🔒           │
│                                  │
│   ─────────────────────           │
│                                  │
│   Lifetime stats                  │
│   ▸ 2 / 6 Seoul scenes            │
│   ▸ K-Drama Pilgrim (Level 1)     │
│   ▸ Next badge: 5 scenes →        │
│     K-Drama Hunter                │
│                                  │
└──────────────────────────────────┘
```

### 디자인 의도
- **포켓몬 도감 메카닉** — 빈 슬롯이 채워지는 시각적 진행
- 도시별 락 → 재방문 동기
- 레벨링 (Pilgrim → Hunter → Legend) → 장기 목표

### 화면 7-2. 투어 종료 후 V로그 (Drama 시퀀스 자동 통합)

```
┌──────────────────────────────────┐
│                                  │
│   🎬  Your Seochon Drama Story   │
│                                  │
│   ╔═══════════════════════════╗   │
│   ║                            ║   │
│   ║   [15초 자동 릴]            ║   │
│   ║                            ║   │
│   ║   00:00 — Maria smiling    ║   │
│   ║   00:03 — Goblin Then/Now  ║   │
│   ║   00:07 — R88 Then/Now     ║   │
│   ║   00:12 — Closing caption  ║   │
│   ║                            ║   │
│   ║   "I walked through        ║   │
│   ║    K-Drama Seoul today."   ║   │
│   ╚═══════════════════════════╝   │
│                                  │
│   #SeochonDrama #KDramaTour      │
│   #Goblin #Reply1988             │
│                                  │
│   [ Share to Instagram ]          │
│   [ Send to friends ]             │
│                                  │
└──────────────────────────────────┘
```

---

## 8. 감정 곡선 분석

```
감정 강도
 │
 │                              📸 ★ 6-3 Pilgrim
 │                          🌅 ★ 6-2 Reel
 │                    🎉★ 6-1 Slider
 │                ✓★ 5-2 Match
 │            😰 5-1 Analyzing
 │       😊 4-1 Camera
 │   🎯 3-3 Almost
 │  📖 3-2 Walking
 │  🎬 2-1 Gallery
 │ 👀 1-1 Discovery
 └────────────────────────────────→ 시간
   0초   1분  3분  4분 5분  6분
```

- **0~3분**: 호기심 누적 (낮은 강도)
- **3~5분**: 도전·분석 (불안 + 기대)
- **5~7분**: 보상 폭발 (강도 최고)

기존 PlaySpot 미션 (일반 퀴즈) 의 감정 곡선보다 **3배 깊은 골과 봉우리** — 그래서 결과 영상 SNS 공유율이 압도적으로 높음.

---

## 9. 실패·에지 케이스 처리

| 상황 | 처리 |
|---|---|
| GPS 신호 불량 | "Tap here when you arrive" 수동 도착 버튼 |
| 카메라 권한 거부 | "Plan B 모드" — 위치만 인증, 사진 없이 통과 (보상 -30%) |
| AI 호출 실패 (네트워크) | 30초 대기 후 "Show me later" — 결과는 다음 접속 시 노출 |
| 사용자가 다른 사진 (셀카, 음식 등) | Gemini confidence 검사 → "Hmm, that doesn't look like an alley. Retake?" |
| 같은 미션 재플레이 | 처음 1회만 보상, 이후 0 pts + "Already explored" 라벨 |
| 시간대 (밤) | 드라마 컷이 낮 장면 → 사용자 사진은 밤 → AI 가 자동 인식 후 "Visit in daylight for better match?" 조언 |

---

## 10. UX 핵심 원칙 5가지

| 원칙 | 적용 |
|---|---|
| **부담 없는 진입** | 항상 Skip 옵션, 거부 페널티 0 |
| **외국인 우선** | 모든 안내 영어 기본, 한국어는 부차 |
| **단서 점진적 공개** | 텍스트 단서 → 블러 스틸 → 풀 스틸, 사용자가 선택 |
| **실패 학습화** | 오답·부정확 = "다음엔 이렇게" 코칭 |
| **결과물 즉시 손에** | Reel 자동 생성, 추가 작업 0 |

---

## 11. 측정 지표 (KPI)

| 지표 | 목표 |
|---|---|
| 드라마 미션 시작률 (도착 → Start) | 60% |
| 드라마 미션 완주율 | 70% |
| AI 매칭 1회 성공률 | 65% |
| 평균 재시도 횟수 | 1.5회 |
| Reel 생성 → SNS 공유 비율 | **30%** ⭐ (일반 미션 8% 대비) |
| 드라마 미션 후 다음 미션 진행률 | 80% |
| Drama Passport 컬렉션 5/6 도달 비율 | 15% |

**SNS 공유 30%** 가 진짜 KPI — 이게 다음 사용자 1.8명을 유입시킴 (바이럴 계수).

---

## 12. 데이터 모델 보강

기존 `MissionItem.subParams` 확장:

```dart
class KDramaSceneItem {
  String dramaId;          // "goblin_ep12"
  String dramaTitle;       // "Goblin"
  int episode;             // 12
  int year;                // 2017
  String stillUrl;         // 드라마 컷 (블러·풀 두 버전)
  String stillBlurUrl;
  String? ostClipUrl;      // 5초 OST
  Location filmingSpot;    // GPS 좌표
  double filmingBearing;   // 카메라 방향 (도)
  double filmingHeight;    // 카메라 높이 (m)
  double filmingPitch;     // 카메라 기울기
  String quoteKo;          // "이번엔 안 잡혀 줄게"
  String quoteEn;          // "This time, I won't get caught"
  List<String> clues;      // ["narrow alley", "brick wall", "wooden door"]
  String directorNote;     // 트리비아 본문
  String? directorAudioUrl;
  int passThreshold;       // 70 (= 70% accuracy)
  int rewardPts;           // 120
}
```

---

## 13. 한 줄 결론

> **K-Drama Time Machine 의 UX 핵심은 "기술 자랑" 이 아니라 "감정 설계"다.**
>
> AI 매칭은 0.3초 백그라운드 마법, 사용자가 보는 건 **드라마 컷 ↔ 자기 사진 슬라이더**.
> Maria 가 슬라이더를 천천히 드래그하며 "와…" 하는 1.5초 — 이걸 위해 전체 5분의 흐름이 설계됩니다.
> 이 1.5초가 인스타 스토리에 올라가는 그 사진입니다.

---

## 14. 변경 이력

| 일자 | 버전 | 변경 |
|---|---|---|
| 2026-06-05 | v0.1 | sechon_play_00.md 의 Hidden Spot (코드 85) 응용으로 K-Drama 변형 UX 명세 작성. 14개 화면 + 감정 곡선 + KPI + 데이터 모델 포함 |
