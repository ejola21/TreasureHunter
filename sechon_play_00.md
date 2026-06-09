# sechon_play_00.md

# 서촌 투어 — 신규 아이템·미니게임 설계 (v0.2)
## Items & Minigames for Foreign Tourist Guide Tours

> 본 문서는 `sechon_00.md` (기획·시나리오) 와 `sechon_01.md` (운영·출시) 의 **구현 명세** 다.
> 기존 PlaySpot 의 아이템 체계 (`ItemType` enum) 와 디자이너/플레이 UI 를 **건드리지 않고 자연스럽게 확장** 하는 것이 원칙이다.

---

## 0. 본 문서의 범위

| 영역 | 내용 |
|---|---|
| 신규 아이템 | 투어·포토·미니게임 **4종** (코드 70, 71, 78, 81) |
| 공통 메타 | 모든 아이템에 부착 가능한 **리뷰 / 사진업로드** 기능 |
| 미니게임 추천 | 외국인 친화 모바일 미니게임 8종 |
| 디자이너 UI | `ItemPickerView` / `ItemDetailView` 확장 (탭 1개 추가) |
| 플레이 UI | 기존 popups 스타일 (CandyButton, DuoColors) 재사용 |
| 데이터 모델 | `MissionItem` 호환 필드 + sub-params + 메타 (review/photo) |
| 단계 | **1차만 구현** — 70 Audio · 71 Photo Frame · 78 Trace Stroke · 81 Speak Korean |
| 서촌 매핑 | 6 스팟 × 신규 아이템 적용표 |

> **v0.4 변경 요약** (2차 제거, 1차 집중):
> - **4종만 유지**: 70 Audio Docent · 71 Photo Frame · 78 Trace Stroke · 81 Speak Korean
> - 2차 아이템 (75 Color Bingo · 77 Tap Tempo · 82 Shopping Cart · 85 Hidden Spot) **문서에서 제거**
> - 리뷰·사진업로드는 별도 아이템이 아닌 **공통 메타 컬럼** 으로 유지
> - 듣기·보기·쓰기·말하기 4가지 감각 커버하는 외국인 한국문화 체험 최소 세트

---

# 1. 기존 PlaySpot 아이템 체계 (호환 기준선)

신규 아이템은 다음 원칙을 따른다.

1. 기존 `ItemType` enum 의 **코드 번호 충돌 금지**
2. 기존 `MissionItem` 모델 필드 **추가만 허용** (제거/타입 변경 금지)
3. 기존 디자이너 (`MissionBuilderView`) 흐름 **재사용**, 새 화면 최소화
4. 플레이 시 기존 `popups.dart` / 팝업 스타일 **시각적 일관성** 유지
5. 다국어는 기존 `lib/l10n/app_*.arb` 확장 (en 우선)

## 사용 중 코드 (회피 대상)

```
00~10   collectible numbers/alphabet
40~43   quiz / timeout
48~49   start / end
50~56   random / hint / solution / penaltyRemove / mine / dark
59, 61  coupon / defense
65~69   radar variants
91      store
```

## 신규 할당 범위

```
70   Audio Docent       ← 본 문서 (1차)
71   Photo Frame        ← 본 문서 (1차)
78   Trace Stroke       ← 본 문서 (1차)
81   Speak Korean       ← 본 문서 (1차)
86~89   reserved (확장)
```

> **미사용 슬롯**: 72, 73, 74, 75, 76, 77, 79, 80, 82, 83, 84, 85 — 향후 확장용 빈 슬롯.

---

# 2. 신규 아이템 카탈로그

## 2-1. 카테고리

| 코드 | 라벨 | 카테고리 | 한 줄 | 리뷰 | 사진업로드 | 체험 감각 | 비고 |
|---|---|---|---|---|---|---|---|
| **70** | Audio Docent | 가이드 | 도착 시 오디오 가이드 자동/수동 재생 | ✓ | — | 듣기 | 가이드 코어 — 모든 스팟 진입점 |
| **71** | Photo Frame | 포토 | 오버레이 프레임에 맞춰 사진 촬영 | ✓ | ✓ (필수) | 보기 | **사진 인증 방식 결정 필요** (AI 자동 vs 자기체크), 보정 필터 검토 |
| **78** | Trace Stroke | 미니게임·터치 | 한글 1획 따라 그리기 | ✓ | — | 쓰기 | **디자인 품질이 성패 결정** |
| **81** | Speak Korean | 미니게임·음성 | 한국어 1단어 따라 말하기 (마이크) | ✓ | — | 말하기 | 시도 = 통과, 음성인식 X |

→ **듣기·보기·쓰기·말하기 4가지 감각** 으로 외국인 한국문화 체험 완결.

### 컬럼 의미

- **리뷰**: 각 미션 완료 후 사용자가 한 줄/한 단어 감상 남길 수 있는 옵션. 모든 아이템에 부착 가능한 메타 기능. 기본 ON, 디자이너가 OFF 가능.
- **사진업로드**:
  - `✓ (필수)`: 사진 없이 미션 통과 불가
  - `✓ (선택)`: 보너스 점수, 없어도 통과
  - `—`: 미사용

### 제거된 아이템 (v0.1 → v0.2)

| 코드 | 라벨 | 제거 이유 |
|---|---|---|
| 72 | AR Sticker | 구현 난이도 대비 ROI 낮음. 한복 합성은 face mesh 한계로 자연스러움 부족. Photo Frame (71) 으로 대체. |
| 73 | Sound Hunt | 게임감 약함, 1회성 |
| 74 | One-Word Review | **모든 아이템의 메타 컬럼** 으로 승격 — 별도 아이템 불요 |
| 76 | Sign Match | 정적 매칭은 재미 약함 (AI 비전 버전은 별도 검토) |
| 79 | Compass Find | 단조로움 |
| 80 | Dot Connect | 단조로움 |
| 83 | Order Up | 기존 quiz (40) 와 메카닉 동일 |
| 84 | Stamp Collect | **메타 보상 레이어** 로 흡수 — 다른 아이템 완료 시 자동 발화, 별도 아이템 불요 |

---

## 2-2. MissionItem 필드 확장

기존 필드 보존 + 다음 옵셔널 필드 추가:

```dart
// flutter_ar_spike/lib/models/mission_item.dart 확장 예시
class MissionItem {
  // ... 기존 필드 ...

  /// 아이템 타입별 추가 파라미터 (예: pairs, colors, audioUrl)
  Map<String, dynamic>? subParams;

  /// 모든 아이템에 부착 가능한 공통 메타
  ItemMeta meta;
}

class ItemMeta {
  /// 미션 완료 후 사용자 리뷰 입력 활성화 (기본 true)
  bool reviewEnabled;

  /// 사진 업로드 모드
  PhotoMode photoMode;  // none / optional / required

  /// 리뷰 템플릿 문구 (선택)
  String? reviewTemplate;  // "Today felt like ___"

  /// 리뷰 태그 칩 (선택)
  List<String>? reviewTags;  // ["Cozy", "Retro"]

  /// 사진 보정 필터 옵션 (71 Photo Frame 전용)
  List<String>? photoFilters;  // ["sepia", "warm", "vintage"]
}

enum PhotoMode { none, optional, required }
```

각 아이템 타입의 `subParams` 스키마:

| 코드 | subParams 키 | 예 |
|---|---|---|
| 70 Audio | `audioUrl`, `langs`, `durationSec`, `autoplay` | `{ "audioUrl":"audio_tongin_en.mp3", "langs":["en","ko"], "durationSec":75, "autoplay":true }` |
| 71 Photo Frame | `frameAsset`, `aspect`, `hintText`, `verifyMode` | `{ "frameAsset":"ar/frame_retro.png", "aspect":"4:5", "hintText":"Old sign inside frame", "verifyMode":"selfCheck" }` |
| 78 Trace Stroke | `glyph`, `strokes`, `threshold` | `{ "glyph":"길","strokes":[ {…path…} ], "threshold":0.8 }` |
| 81 Speak Korean | `word`, `romaji`, `meaning` | `{ "word":"맛있어요","romaji":"masisseoyo","meaning":"delicious" }` |

신규 아이템은 모두 `mandatory: false` 기본값 — 외국인 관광객이 부담 없이 Skip 가능해야 함.

---

# 3. 미니게임 상세 설계 (서촌 문맥)

각 미니게임은 **1~3분 안에 완료**, **장소 맥락 연결**, **언어 장벽 최소화** 원칙.

## 3-1. 포토형 (Capture)

### MG-1. Retro Cover Shot (Photo Frame · 코드 71)
- 사용 스팟: 대오서점, 세종마을 음식문화거리
- 메커니즘: 카메라 화면에 빈티지 프레임 오버레이 + 흰 가이드 라인. 사용자가 프레임 안에 간판/문을 맞춰 1탭 촬영.
- **인증 결정 사항**:
  - **Option A (단순)**: 사진 저장 = 통과 (AI 판정 X). 신뢰 기반, 외국인 친화.
  - **Option B (강화)**: Gemini Vision 으로 "프레임 안에 의도된 사물이 있나" 판정. 비용 $0.0003/회.
  - **Option C (자기체크)**: 사용자가 "OK / Retake" 선택. 가장 부담 없음.
- **보정 필터**: 결과 화면에서 3종 옵션 (Original / Sepia / Vintage) 제공. SNS 공유율 ↑.
- 보상: 70 pts + Photo Stamp (메타 자동 발화)

---

## 3-2. 쓰기형 (Trace)

### MG-2. Trace Stroke (Trace Stroke · 코드 78)
- 사용 스팟: 대오서점
- 메커니즘: "길" 한 글자의 1획을 화면에 따라 그리기. 80% 일치 통과
- **디자인 품질이 핵심** — 붓 텍스처, 종이 결, 획 흐름의 완성도가 사용자 만족 결정
- 외국인 친화: 한글 1획만 — 부담 없이 한글 체험
- 보상: 70 pts

---

## 3-3. 말하기형 (Speak)

### MG-3. Speak Korean (Speak Korean · 코드 81)
- 사용 스팟: 통인시장 (음식 단어), 골목 (인사말)
- 메커니즘: 한국어 단어 표시 (`맛있어요` + romaji `masisseoyo` + 의미) → 마이크 녹음 → **파형만 비교** (음성인식 X, 시도만으로 통과)
- 외국인 친화: 실패 없음, 도전 자체가 보상
- 보상: 50 pts + Language Stamp (메타 자동)

---

# 4. 디자이너 UI — 신규 아이템 추가 인터페이스

기존 디자이너 흐름:
```
MissionBuilderView → 미션 행 탭 → MissionSetupView
                                      ↓
                               ItemPickerView (그리드)
                                      ↓
                               ItemDetailView (편집)
```

## 4-1. ItemPickerView 확장

기존 그리드 상단에 **카테고리 탭** 추가:

```
[ Classic ] [ Tour ] [ Photo ] [ Minigame ]
   기존       70       71         78 / 81
```

- `Classic`: 기존 모든 아이템 (변경 없음)
- `Tour`: 70 Audio Docent
- `Photo`: 71 Photo Frame
- `Minigame`: 78 Trace Stroke, 81 Speak Korean

탭 전환은 상태만 바꿈 — 그리드 셀 위젯은 동일 (썸네일 + 라벨).

## 4-2. ItemDetailView 동적 폼

선택된 ItemType 에 따라 폼 섹션을 동적 렌더:

| ItemType | 노출 필드 |
|---|---|
| Audio (70) | 오디오 파일 업로드, 언어 다중 선택, 자동재생 토글 |
| Photo Frame (71) | 프레임 에셋 선택 (드롭다운), 비율, 힌트 문구, 인증 모드 (selfCheck/AI/save-only), 필터 옵션 |
| Trace Stroke (78) | 글자 입력 1자, 획 그리기 (캔버스), 통과 임계값 |
| Speak Korean (81) | 단어, 로마자, 의미 (모두 텍스트) |

## 4-3. 공통 메타 폼 (모든 아이템 공유)

```
┌─────────────────────────────────────┐
│  Item 7 · Photo Frame          ⋯   │
├─────────────────────────────────────┤
│  Mandatory       [ Yes  No  Tog ]   │
│                                     │
│  ━━━ 타입별 필드 ━━━                  │
│  (Photo Frame 의 frame asset 등)     │
│                                     │
│  ━━━ 공통 메타 ━━━                   │
│                                     │
│  📝 Review                          │
│   [ ✓ ] Enable review                │
│   Template:                         │
│   ┌─────────────────────────────┐  │
│   │ Today felt like ___          │  │
│   └─────────────────────────────┘  │
│   Tags: [Cozy] [Retro] [Quiet] [+] │
│                                     │
│  📷 Photo Upload                    │
│   ◯ None  ◉ Required  ○ Optional   │
│   Filters: [✓ Original] [✓ Sepia]  │
│            [✓ Vintage]              │
│                                     │
│  Reward          ●● 70 pts          │
└─────────────────────────────────────┘
```

UI 토큰은 기존 `DuoColors` / `CandyButton` / `FormGroup` 그대로 사용 — 새 디자인 시스템 도입 없음.

---

# 5. 플레이 UI — 사용자 경험

기존 PlaySpot 의 아이템 획득 흐름 (`features/play/popups.dart` 의 팝업 컨벤션) 을 그대로 재사용한다.

## 5-1. 공통 진입 흐름

```
GPS 도착 감지 → 스팟 카드 노출 (기존 동작)
              ↓
        [ Listen ] [ Play Quest ] [ Skip ]
              ↓                ↓
       Audio Docent       Minigame Modal
       (70 코드)          (71 / 78 / 81)
              ↓                ↓
       [ Next Spot ]      [ Reward Popup ]
                                ↓
                          (메타 활성 시)
                              ↓
                       [ Review Input ]
                              ↓
                       [ Photo Upload ]
                              ↓
                       [ Stamp Award ]
```

## 5-2. 미니게임 모달 공통 레이아웃

```
┌──────────────────────────────────┐
│  [×]              Mission 2/5    │
├──────────────────────────────────┤
│                                  │
│      < 미니게임 본체 >            │
│                                  │
├──────────────────────────────────┤
│      Skip          [ Submit ]    │
└──────────────────────────────────┘
```

- 상단: 닫기 + 진행도 (기존 popups 와 동일)
- 본체: 미니게임 타입별 위젯
- 하단: Skip 항상 노출 (강제 없음) + 제출 CandyButton

## 5-3. 완료 → 메타 흐름 → 보상

미니게임 완료 시 메타 활성 여부에 따라 단계가 추가됨:

```
┌──────────────────────────────────┐
│   📝 One-Word Review              │
│                                  │
│   Today felt like ___            │
│   [ Cozy ] [ Retro ] [ Quiet ]    │
│   [ ___________________________ ]│
│                                  │
│   [ Skip ]      [ Save ]          │
└──────────────────────────────────┘

         ↓ (사진업로드 활성 시)

┌──────────────────────────────────┐
│   📷 Add a photo                  │
│                                  │
│   [ 카메라 ] [ 앨범 ] [ Skip ]    │
└──────────────────────────────────┘

         ↓

┌────────────────────┐
│   ⭐                │
│  +70 pts           │
│  Photo Stamp 획득 │
│  [ Next Spot ]     │
└────────────────────┘
```

## 5-4. 오디오 도슨트 (코드 70) 인터랙션

```
[ Spot Detected ]
Tongin Market

[ 오디오 플레이어 ]
00:00 ━━━━━━━━━━ 01:15
   ▶ Play   1.0x   EN ▾

[ Start Quest ]
[ Skip to Map ]
```

- 처음 도착: 자동 재생 (`autoplay: true`) 권장, 사용자가 끄면 다음 스팟부터 수동
- 헤드폰 권장 안내는 첫 스팟 1회만

---

# 6. 데이터 모델 변경 사항

## 6-1. MissionItem 확장 (Flutter)

```dart
// lib/models/mission_item.dart
class MissionItem {
  // ... 기존 필드 ...
  Map<String, dynamic>? subParams;
  ItemMeta meta;

  T? param<T>(String key) => subParams?[key] as T?;
}
```

JSON 직렬화:
```json
{
  "ItemID": 7,
  "ItemType": "71",
  "Mandatory": "N",
  "subParams": {
    "frameAsset": "ar/frame_retro.png",
    "aspect": "4:5"
  },
  "meta": {
    "reviewEnabled": true,
    "reviewTemplate": "This place felt like ___",
    "reviewTags": ["Retro", "Cozy", "Quiet"],
    "photoMode": "required",
    "photoFilters": ["original", "sepia", "vintage"]
  }
}
```

## 6-2. iOS Mirror

`PlaySpot/Models/MissionItem.swift` 에 동일하게:
- `var subParams: [String: AnyCodable]?`
- `var meta: ItemMeta`

(AnyCodable 헬퍼 도입)

## 6-3. 서버 API 영향

- `POST /api/v1/missions`, `PATCH /api/v1/missions/{id}`: items[].subParams + items[].meta 필드 추가
- 기존 클라이언트 (subParams/meta 모르는) 가 무시해도 동작해야 함 → 서버 측은 옵셔널 nullable 로 설계
- 리뷰 저장: `POST /api/v1/missions/{mid}/items/{iid}/reviews` 신규
- 사진 업로드: 기존 `/api/v1/files/upload` 재사용

---

# 7. 구현 단계 (~4주, 1차만)

| 코드 | 아이템 | 이유 |
|---|---|---|
| **70** | Audio Docent | 가이드 코어 — 모든 스팟의 진입점 |
| **71** | Photo Frame | 포토형 핵심 + 메타 (리뷰/사진) 검증 |
| **78** | Trace Stroke | 한글 1획 — 외국인 친화 한국문화 체험 |
| **81** | Speak Korean | "맛있어요" 발음 — 언어 장벽 게임화 |
| **공통 메타 시스템** | — | 리뷰·사진업로드·스탬프 자동 발화 (모든 아이템 부착) |

**산출물**: 서촌 6 스팟 운영 가능 + 디자이너·플레이 UI 확장 + MissionItem 모델·서버 API 확장 + iOS/Flutter 양쪽 동등 구현.

---

# 8. 서촌 코스 적용 매핑

| 스팟 | 추천 신규 아이템 | 미션 흐름 |
|---|---|---|
| SPOT 0 경복궁역 | 70 Audio + 71 Photo Frame | 들어보기 → 1장 촬영 → 리뷰 한 단어 |
| SPOT 1 음식문화거리 | 70 Audio + 71 Photo Frame | 듣기 → 골목 사진 → 한 단어 |
| SPOT 2 통인시장 | 70 Audio + 81 Speak Korean | 듣기 → "맛있어요" 발음 |
| SPOT 3 대오서점 | 70 Audio + 71 Photo Frame + 78 Trace Stroke | 듣기 → 레트로 샷 → 한글 1획 |
| SPOT 4 박노수미술관 | 70 Audio + 40 Quiz (Artist's Eye) | 듣기 → 4지선다 |
| SPOT 5 수성동계곡 | 70 Audio + 71 Photo Frame | 듣기 → 마지막 한 장면 + 한 문장 |
| 종료 | (시스템 자동) Stamp 합산 + V로그 카드 | 누적 스탬프북 + 자동 릴 |

---

# 9. 리스크 및 결정 보류 항목

| 항목 | 결정 필요 |
|---|---|
| **71 사진 인증 모드** | self-check (관용) vs AI 검증 (정확) vs save-only (단순). MVP 권장: self-check |
| **71 보정 필터** | 어떤 필터 셋? 라이선스 무료 (FilterX 등) vs 자체 제작 |
| **78 Trace Stroke 글자 데이터** | 한글 stroke 라이브러리 (폰트 path 활용?) vs 디자이너 수기 |
| **81 음성 비교 알고리즘** | 시도만 인정 vs Whisper STT (추후 검토) |
| **공통 메타 — 리뷰 다국어** | 사용자가 어떤 언어로 리뷰 작성? 자동 번역 표시? |
| **공통 메타 — 사진 저장 위치** | 서버 보관 vs 디바이스 only (개인정보 부담) |
| **subParams 검증** | 서버측 JSON schema 검증 추가 여부 |

---

# 10. 변경 이력

| 일자 | 버전 | 변경 |
|---|---|---|
| 2026-06-05 | v0.1 | 신규 아이템 16종 (코드 70~85), 미니게임 16개 추천, 디자이너/플레이 UI 확장 명세, Phase 1~3, 서촌 코스 매핑 |
| 2026-06-05 | v0.2 | **아이템 16종 → 8종 축소** (72/73/74/76/79/80/83/84 제거). 리뷰·사진업로드는 **공통 메타 컬럼** 으로 승격. 85 Hidden Spot 를 Hidden / Then vs Now / K-드라마 3가지 모드로 재정의 (K-드라마 변형은 `item-kdrama.md` 참조). Stamp Collect 는 메타 보상 레이어로 흡수. |
| 2026-06-06 | v0.3 | **Phase 1·2·3 (3단계) → 1차·2차 (2단계)** 로 단순화. **1차 = 70 Audio + 71 Photo Frame + 78 Trace Stroke + 81 Speak Korean** (외국인 친화 한국문화 체험 중심) + 공통 메타. **2차 = 75 / 77 / 82 / 85** 로 이연. 85 Hidden Spot 는 사진 노후화·큐레이션 부담으로 1차 미포함. |
| 2026-06-06 | v0.4 | **2차 아이템 (75 Color Bingo · 77 Tap Tempo · 82 Shopping Cart · 85 Hidden Spot) 문서에서 완전 제거** — 1차 4종 (70 · 71 · 78 · 81) 만 유지. 카탈로그 표·subParams 스키마·미니게임 상세·디자이너 UI 표·서촌 코스 매핑·리스크 항목 모두 1차 4종에 맞춰 단순화. 듣기·보기·쓰기·말하기 4감각 체험 세트로 외국인 핵심 가치 제안 집중. |
