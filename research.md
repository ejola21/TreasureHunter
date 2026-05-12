# Play Spot (TreasureHunter) — 완전 분석 보고서

## 목차
1. [게임 개요](#1-게임-개요)
2. [게임 플레이 모드](#2-게임-플레이-모드)
3. [AR 증강현실 시스템 상세 분석](#3-ar-증강현실-시스템-상세-분석)
4. [아이템 시스템 전체 분석](#4-아이템-시스템-전체-분석)
5. [게임 플레이 흐름](#5-게임-플레이-흐름)
6. [미션 디자인 시스템](#6-미션-디자인-시스템)
7. [데이터베이스 구조](#7-데이터베이스-구조)
8. [서버 통신 시스템](#8-서버-통신-시스템)
9. [사운드 & 애니메이션 시스템](#9-사운드--애니메이션-시스템)
10. [인앱 결제 시스템](#10-인앱-결제-시스템)
11. [이미지 에셋 체계](#11-이미지-에셋-체계)
12. [튜토리얼 이미지 분석](#12-튜토리얼-이미지-분석)

---

## 1. 게임 개요

**Play Spot**은 GPS 기반의 보물찾기 게임으로, 사용자가 실제 세계를 돌아다니며 지도와 AR(증강현실) 카메라를 통해 아이템을 찾아 미션을 완수하는 iOS 앱이다.

- **Bundle ID**: `com.mking.trasurehunter`
- **앱 이름**: Play Spot (v2.0)
- **언어**: Objective-C (iOS 4+ 시대)
- **지원 언어**: 한국어, 영어
- **서버**: `http://nexapp.co.kr/playspot/`

### 핵심 컨셉
- 사용자가 직접 미션을 **디자인**하고, 다른 사용자가 이를 **플레이**한다
- GPS 좌표에 아이템을 배치하고, 실제로 그 위치에 가서 수집해야 한다
- AR 카메라로 현실 세계 위에 겹쳐진 아이템을 보고, **폰을 흔들어** 획득한다
- 퀴즈, 지뢰, 타임아웃 등 다양한 게임 요소로 난이도를 조절한다

---

## 2. 게임 플레이 모드

### Real Mode (리얼 모드)
- 미션이 **생성된 실제 장소**에서 플레이
- GPS로 실제 사용자 위치를 추적
- 실제로 걸어다니며 아이템 위치에 접근해야 한다
- 지형 특성상 플레이가 어려울 수 있다

### Virtual Mode (가상 모드)
- 미션이 생성된 장소가 아닌 **사용자의 현재 위치 기준**으로 플레이
- `virtualMode()` 메서드가 모든 아이템 좌표에 오프셋(offset)을 적용
- 오프셋 계산: `START 아이템 좌표 - 플레이어 현재 좌표`의 차이를 모든 아이템에 적용
- 재개(resume) 시에는 마지막 획득 아이템 기준으로 오프셋 재계산
- 장소에 가지 않고도 게임 테스트/연습 가능

---

## 3. AR 증강현실 시스템 상세 분석

### 3.1 AR 시스템 아키텍처

AR 시스템은 4개의 핵심 클래스로 구성된다:

```
ARCoordinate          ← 극좌표 기본 모델 (거리, 방위각, 경사각)
    ↑
ARGeoCoordinate       ← GPS 좌표 → 극좌표 변환
    
ARViewController      ← AR 카메라 렌더링 엔진 (가속도계, 나침반, 화면 좌표 계산)
    ↑
ARGeoViewController   ← GPS + AR 통합 컨트롤러 (아이템 표시, 상호작용)
```

### 3.2 ARCoordinate — 극좌표 모델

모든 AR 아이템은 구면 극좌표(Spherical Polar Coordinates)로 표현된다:

| 속성 | 타입 | 설명 |
|------|------|------|
| `radialDistance` | double | 플레이어~아이템 거리 (미터) |
| `azimuth` | double | 수평 방위각 (라디안, 0~2π) |
| `inclination` | double | 수직 경사각 (라디안) |
| `annoItem` | AnnoItem | 연결된 미션 아이템 참조 |

**특수 거리값**:
- 거리 = 0 → `[Phone: bearing°]` (사용자 자신의 위치)
- 거리 = 9999999 → `"mission_complete"` (미션 완료 신호)

### 3.3 ARGeoCoordinate — GPS→극좌표 변환

GPS 좌표를 AR 극좌표로 변환하는 핵심 로직:

**거리 계산**: CLLocation의 `distanceFromLocation:`을 사용 (Haversine 공식으로 지구 곡률 반영)
```
radialDistance = [origin distanceFromLocation:self.geoLocation]
// 고도(altitude)는 사용하지 않음 — 수평 거리만 사용
```

**방위각(Azimuth) 계산**:
```
위도차 = 목표.latitude - 원점.latitude
경도차 = 목표.longitude - 원점.longitude

if 경도차 == 0:
    위도차 >= 0 → 방위각 = 0° (정북)
    위도차 < 0  → 방위각 = 180° (정남)
else:
    방위각 = (π/2) - atan(위도차 / 경도차)
    if 경도차 < 0: 방위각 += π (서쪽 보정)
```

**교정(Calibration)**: `calibrateUsingOrigin:` — 플레이어 위치가 변경될 때마다 모든 아이템의 거리와 방위각을 재계산한다.

### 3.4 ARViewController — AR 렌더링 엔진

#### 뷰포트(화면 시야) 설정
```objc
#define VIEWPORT_WIDTH_RADIANS  0.5     // 수평 시야각 ≈ 28.6°
#define VIEWPORT_HEIGHT_RADIANS 0.7392  // 수직 시야각 ≈ 42.4°
#define kFilteringFactor        0.05    // 가속도계 저주파 필터 계수
#define kDirectionFilterFactor  0.05    // 나침반 저주파 필터 계수
```

#### 카메라 설정 (CameraOpen)
- `UIImagePickerController`를 카메라 소스로 사용
- 카메라 뷰 스케일: 가로 1.0x, 세로 1.25x
- `ar_overlayView`가 카메라 위에 오버레이되어 모든 AR 요소를 렌더링

#### 화면 좌표 계산 (`pointInView:forCoordinate:`)

**X좌표 (수평/방위각 기반)**:
```
좌측경계 = 현재방위 - 시야폭/2
아이템방위 = coordinate.azimuth

if 아이템방위 < 좌측경계 (360° 래핑):
    x = ((2π - 좌측경계 + 아이템방위) / 시야폭) × 화면너비
else:
    x = ((아이템방위 - 좌측경계) / 시야폭) × 화면너비
```

**Y좌표 (수직/경사각 기반)**:
```
상단경계 = 현재경사 - 시야높이/2
y = 화면높이 - ((아이템경사 - 상단경계) / 시야높이) × 화면높이
```

#### 거리 기반 스케일링
```
scaleFactor = 1.0 - minimumScaleFactor × (거리 / maximumScaleDistance)
```
- `minimumScaleFactor` = 0.5 → 최대 거리에서 50% 크기
- `scaleViewsBasedOnDistance` = YES로 활성화

#### 3D 원근 변환 (Perspective Transform)
```
transform.m34 = 1.0 / 300.0  // 원근 깊이
각도차 = 아이템방위 - 현재방위 (래핑 보정 포함)
회전각 = maximumRotationAngle × 각도차 / (시야높이/2)
transform = CATransform3DRotate(transform, 회전각, 0, 1, 0)  // Y축 회전
```
- `maximumRotationAngle` = π/6 (30°)
- 화면 중앙에서 벗어난 아이템은 3D 회전이 적용됨

### 3.5 가속도계 (Accelerometer) 통합

**설정**: 업데이트 간격 0.25초, 필터 계수 0.05

**경사각(Inclination) 계산** — 폰의 기울기를 AR 수직 좌표로 변환:
```
rollingZ = (가속도Z × 0.05) + (이전Z × 0.95)   // 저주파 필터
rollingX = (가속도Y × 0.05) + (이전X × 0.95)

if rollingZ > 0:  경사각 = atan(rollingX/rollingZ) + π/2
if rollingZ < 0:  경사각 = atan(rollingX/rollingZ) - π/2
if rollingZ == 0: rollingX < 0 → 경사각 = π/2, else → 경사각 = 3π/2
```

**흔들기(Shake) 감지**:
- 가속도 크기 > **1.4G** (모든 축)
- 감지 시간 창: **1.5초**
- 흔들기 감지 시 → `getItemAnimation` (가장 가까운 아이템 획득 시도)
- `shakeEnable` 플래그로 활성화/비활성화

### 3.6 나침반 (Compass/Heading) 통합

**방향 업데이트 흐름**:
```
원시 방향 (rawDirection) → 저주파 필터 → 보정 방향 (correctedDirection) → 라디안 변환

보정계산:
  차이 = rawDirection - correctedDirection
  if 차이 < -180: 차이 += 360  // 래핑 보정
  if 차이 > 180:  차이 -= 360
  correctedDirection = 차이 × 0.05 + correctedDirection
  centerCoordinate.azimuth = correctedDirection × (2π/360)
```
- 정확도 < 30° 또는 양수일 때만 업데이트
- True heading 우선, Magnetic heading 폴백

### 3.7 AR 뷰포트 가시성 판정 (`viewportContainsCoordinate:`)

아이템이 AR 화면에 표시되려면 **모든** 조건 충족 필요:

1. **거리**: `radialDistance ≤ item.rangeAR` (기본 30m)
2. **미획득**: `dicItemEnd`에 "Y"로 등록되지 않음
3. **아이템 유형별 규칙**:
   - START/END: 미션 시작 전에도 항상 보임
   - BLACK: **절대 보이지 않음**
   - MINE: 범위 내 진입 시 **자동으로 폭발** (`mineBlast:` 호출)
   - 기타: 미션 시작 후에만 보임
4. **수평 가시성**: 방위각이 중앙 ± VIEWPORT_WIDTH_RADIANS/2 이내
5. **수직 가시성**: 경사각이 중앙 ± VIEWPORT_HEIGHT_RADIANS/2 이내

### 3.8 AR 레이더 디스플레이

화면 하단 중앙에 레이더 패널 표시:
- `radianPanel` (319×61px) — 레이더 배경
- `radianCenter` (61×61px) — 십자선
- `radianPhone` (33×28px) — 기기 방향 표시 (노란색 ▼ 아이콘)
- `radianItem` (11×25px) — 아이템 방향 표시 (녹색 ▲ 아이콘)
- 각각 방위각에 따라 회전

**정보 표시 버튼**:
- 좌측 (`ar_infoView`): 가장 가까운 아이템 유형 및 거리 — `"ItemType:XXXm"`
- 우측 (`ar_infoView1`): 감지 반경 — `"Radius:XXXm"`

### 3.9 AR에서 아이템 획득

**터치 방식**: 화면의 `imgItemView`(표시된 아이템)를 터치
**흔들기 방식**: 폰을 세게 흔들기 (1.4G 이상)

**획득 애니메이션** (`getItemAnimation`):
1. 0.5초 쿨다운 (연속 트리거 방지)
2. 아이템 뷰를 **1.5배**로 확대 (0.3초, EaseOut)
3. 원래 크기로 복원 (0.3초, EaseIn)
4. `getItem:` 호출하여 아이템 처리

**랜덤 이펙트 애니메이션** (`randAni`):
- CALayer에 커스텀 그리기
- 180°/2초 회전 (10000회 반복)
- 동시에 페이드아웃 (1.0 → 0.0 투명도)
- 4초 후 자동 제거

### 3.10 아이템 표시 방식 (ARGeoViewController)

각 아이템은 150×100px 박스로 표시:
- 상단: 어두운 반투명 배경의 타이틀 레이블
- 중앙: 아이템 아이콘 이미지
- 필수(Mandatory) 아이템: `itemMandatoryARFile:` 아이콘 사용 (별표 마크)
- 선택(Optional) 아이템: `itemARFile:` 아이콘 사용

---

## 4. 아이템 시스템 전체 분석

### 4.1 투명도 속성 (Transparency Properties)

아이템의 가시성을 결정하는 `showType` 속성:

| showType 코드 | 이름 | 지도에서 | AR에서 |
|---------------|------|---------|--------|
| `"4"` SHOW_ALL | Normal | 보임 | 보임 |
| `"1"` SHOW_TRANSPARENT | Hidden | 안보임 | 안보임 (레이더로만) |
| `"3"` SHOW_MAP | Stealth | 보임 | 안보임 (거리/방향 정보 없음) |
| `"2"` SHOW_AR | Hidden(Map) | 안보임 | 보임 |

### 4.2 필수(Required) 속성

- `mandatory = MANDATORY_Y` → 별(★) 표시가 붙은 필수 아이템
- 미션 완료를 위해 **반드시** 수집해야 함
- 화면 하단 상태 바의 "남은필수" 카운터로 추적

### 4.3 전체 아이템 목록

#### Start (시작 아이템) — 코드: `"49"` (I_START)
- **아이콘**: 체크무늬 깃발 + 별표
- **기능**: 미션 시작 지점. 이 아이템을 획득해야 미션이 공식 시작됨
- **획득 시**: 미션의 제한시간, 퀴즈 등 정보가 공개됨
- **가시성**: 미션 시작 전에도 항상 보임
- **필수 여부**: 항상 필수

#### End (종료 아이템) — 코드: `"48"` (I_END)
- **아이콘**: 체크무늬 깃발 + 별표
- **기능**: 미션 종료 지점. 모든 필수 아이템을 수집한 후 이 아이템을 획득하면 미션 완료
- **특수 규칙**: 지도상의 필수 아이템이 **1개만 남을 때까지** 보이지 않음
- **퀴즈**: 미션 레벨 퀴즈 (`missionQuiz`, `missionAnswer`)가 있을 수 있음
- **필수 여부**: 항상 필수

#### Hint (힌트) — 코드: `"51"` (I_SIMPLE)
- **아이콘**: 빨간 말풍선에 "Hint" 텍스트
- **기능**: 퀴즈에 대한 단서를 제공. 퀴즈가 없으면 해당 장소의 위치 정보를 표시
- **게임 내 역할**: 숫자나 문자 형태의 힌트를 수집하여 미션 퀴즈 답을 유추

#### Quiz (퀴즈) — 코드: `"40"` (I_QUIZ)
- **아이콘**: 녹색 배경에 "Quiz" + 물음표
- **기능**: 퀴즈를 풀어야 진행 가능. 오답이면 힌트가 나옴
- **힌트 시스템**: 1차 실패 → 정답 글자 수, 2차 실패 → 첫 글자 공개
- **퀴즈 저장**: `ItemQuiz` 테이블에 `quiz`(문제), `answer`(정답), `probability`(확률) 저장
- **다중 퀴즈**: 하나의 아이템에 여러 퀴즈 변형(seq)을 가질 수 있음

#### Quiz20 (확장 퀴즈) — 코드: `"41"` (I_QUIZ20)
- **기능**: 20개 이상의 퀴즈 변형이 있는 고급 퀴즈
- **추적**: `quizSeq`로 플레이어가 몇 번째 퀴즈까지 진행했는지 추적
- **재플레이**: 다른 seq의 퀴즈가 출제됨

#### Mine (지뢰) — 코드: `"55"` (I_MINE)
- **아이콘**: 녹색 핀에 폭탄 그림
- **기능**: 아이템 주변 반경(rangeAR) 안에 들어가면 **자동으로 폭발**
- **피해**: 가장 최근 획득한 아이템을 **상실** (되돌림)
- **지도 표시**: 기본적으로 지도에서 보이지 않음. Mine Radar를 가져야 빨간 원으로 표시
- **폭발 시 효과**:
  - 진동 (`AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)`)
  - 폭발음 (`s_explosion.mp3`)
  - 타이머음 (`s_timer.mp3`)
- **속성**:
  - `blackCnt` (기본 5) — 해당 영역의 지뢰 개수
  - `blackTime` (기본 300초 = 5분) — 시간 패널티
  - `rangeAR` — 폭발 반경 (미터)
- **타임아웃 중 피격**: 활성 타임아웃이 취소됨

#### Mine NoBomb (비폭발 지뢰) — 코드: `"61"` (I_MINE_NOBOMB)
- **기능**: 폭발하지 않는 안전한 지뢰 변형
- **용도**: 원형 오버레이 영역만 표시 (영역 표시용)

#### Defence (방어) — 코드: `"61"` (I_MINE_NOBOMB를 파워업으로 사용)
- **아이콘**: 녹색 방패
- **기능**: 획득하면 지뢰 폭발로부터 보호
- **동작**: 지뢰 진입 시 `dicRnPTaken`에서 `I_MINE_NOBOMB` 확인
  - ableCnt > 0이면: 지뢰 불발, "Mine protected!" 알림, ableCnt 감소
  - ableCnt = 0이면: 정상 폭발
- **추적**: `ItemRnPInPlay` 테이블에 `ableCnt`(남은 사용 횟수)로 관리

#### Gambling (도박/랜덤) — 코드: `"50"` (I_RANDOM)
- **아이콘**: 노란색 상자에 물음표 (선물상자)
- **기능**: 획득하면 아직 수집하지 않은 아이템 중 **무작위 1개**를 자동 획득
- **제외 목록**: End 아이템, Gambling 아이템, Black 아이템은 제외
- **쿼리**: `selectRand()` — `itemType NOT IN ('48','50','56')`

#### Solution (솔루션) — 코드: `"52"` (I_SOLUTION)
- **아이콘**: 졸업모자 (파란색)
- **기능**: 퀴즈와 미션 퀴즈의 **정답을 즉시 알려줌**
- **사용법**: 퀴즈 화면에서 "Solution" 버튼 터치
- **인앱 구매**: `solution_add_10` 상품으로 10개 추가 구매 가능
- **추적**: `ItemRnPInPlay`에서 `ableCnt`로 남은 횟수 관리

#### Penalty Remove (패널티 제거) — 코드: `"54"` (I_PENALTY_REMOVE)
- **기능**: 퀴즈 실패 페널티를 제거/초기화

#### Map Radar (맵 레이더) — 코드: `"66"` (I_RADAR_MAP)
- **아이콘**: 녹색 원에 "Map" 텍스트
- **기능**: **Hidden** 속성을 가진 아이템을 **지도에 표시**
- **동작**: `dicRnPTaken`에 `I_RADAR_MAP` 키가 있으면 SHOW_TRANSPARENT/SHOW_AR 아이템도 지도에 표시

#### Stealth Radar (스텔스 레이더) — 코드: `"65"` (I_RADAR_AR)
- **아이콘**: 파란색 원에 "ST" 텍스트
- **기능**: **Stealth** 속성을 가진 아이템의 정보를 **AR 화면에서 표시**
- **동작**: `dicRnPTaken`에 `I_RADAR_AR` 키가 있으면 SHOW_MAP 아이템도 AR에서 보임

#### All Radar (전체 레이더) — 코드: `"67"` (I_RADAR_ALL)
- **기능**: Map Radar + Stealth Radar 효과를 동시에 적용
- **동작**: 모든 숨겨진 아이템을 지도와 AR 모두에서 표시

#### Mine Radar (지뢰 레이더) — 코드: `"68"` (I_RADAR_MINE)
- **아이콘**: 보라색 원에 "Mine" 텍스트
- **기능**: 지뢰의 **폭발 반경을 지도에 빨간 원으로** 표시
- **동작**: 빨간색 40% 투명도 원으로 지뢰 영역 시각화

#### Run Start (달리기 시작) — 코드: `"42"` (I_TIMEOUT_S)
- **아이콘**: 스톱워치 + 녹색 화살표
- **기능**: 제한 시간 내에 **Run End 아이템**을 찾아야 하는 타임어택 이벤트 시작
- **동작**: 획득 시 보조 타이머(timeOutView)가 카운트다운 시작
- **속성**: `effectiveTime` — 제한 시간(초)

#### Run End (달리기 종료) — 코드: `"43"` (I_TIMEOUT_E)
- **아이콘**: 스톱워치 + 빨간 정지 표시
- **기능**: Run Start 후 제한 시간 내에 이 아이템을 찾아야 함
- **특수 표시**: 지도에서 **맥동(pulsing) 애니메이션** (1.5배 스케일, 0.35초, 무한 반복)
- **연결**: `relationItemID`로 대응하는 Run Start와 연결

#### Dark (어둠) — 코드: `"56"` (I_BLACK)
- **아이콘**: 보라색 원에 어둠 표시
- **기능**: Dark 아이템 반경 내의 **모든 아이템이 지도에서 사라짐**
- **탐색**: AR 레이더의 거리와 방향 정보만으로 아이템을 찾아야 함
- **지도 표시**: 검은색 반투명 원으로 영역 표시

#### Coupon (쿠폰) — 코드: `"59"` (I_COUPON)
- **기능**: 보상 쿠폰/할인 코드
- **데이터**: `info` 필드에 쿠폰 내용 저장

#### Store (상점) — 코드: `"91"` (I_STORE)
- **기능**: 인앱 구매/상점 아이템
- **데이터**: `info` 필드에 상품 정보 저장

### 4.4 아이템 공통 속성 (MissionItem 모델)

| 속성 | 기본값 | 설명 |
|------|--------|------|
| `missionID` | — | 소속 미션 ID |
| `itemID` | 자동증가 | 미션 내 고유 번호 |
| `mandatory` | MANDATORY_N | 필수 여부 (별표 표시) |
| `itemType` | — | 아이템 유형 코드 |
| `latitude` | — | GPS 위도 |
| `longitude` | — | GPS 경도 |
| `rangeAR` | 30m | AR 감지 반경 (30~100m, 10m 단위) |
| `showType` | — | 투명도 속성 (Normal/Hidden/Stealth/AR) |
| `blackCnt` | 5 | 지뢰 개수 |
| `blackTime` | 300초 | 시간 패널티 |
| `effectiveRange` | — | 유효 범위 (2~60m) |
| `effectiveTime` | — | 유효 시간 (타임아웃용) |
| `itemGame` | — | 미니게임 난이도 레벨 |
| `info` | — | 추가 메타데이터 |
| `relationItemID` | — | 연관 아이템 ID (Run Start↔End) |
| `itemQuizzes` | [] | 퀴즈 배열 |
| `quizSeq` | 1 | 현재 퀴즈 시퀀스 |

---

## 5. 게임 플레이 흐름

### 5.1 미션 초기화 (`setupPlay`)

```
1. DB에서 미션 데이터 로드 (MissionDao, MissionItemDao)
2. QUIZ 타입 아이템은 ItemQuizDao에서 퀴즈 옵션 로드
3. 신규 시작(isNewStart=1)이면 이전 진행 기록 삭제
4. START 아이템 존재 여부 확인:
   - 없으면 → 즉시 미션 시작 (startYN="Y")
   - 있으면 → START 위치 도달 대기
5. 진행 중 데이터 로드 (dicItemEnd, dicRnPTaken)
6. 타임아웃 상태 복원 (TIMEOUT_S/E 확인)
7. Virtual Mode이면 좌표 오프셋 적용
8. 지도에 아이템 핀과 오버레이 배치
```

### 5.2 게임 상태 전이

```
[미시작] ──── START 획득 ────→ [진행중] ──── 모든 필수 아이템 ────→ [END 획득] ──→ [완료]
                                  │                                                    ↑
                                  ├── Run Start 획득 ──→ [타임어택] ── Run End 획득 ───┘
                                  │                         │
                                  │                         └── 시간 초과 → finishRunTimeAlert
                                  │
                                  ├── 지뢰 진입 ──→ 최근 아이템 상실 → [진행중]으로 복귀
                                  │
                                  └── 나가기 ──→ [실패] (전체 기록 삭제)
```

### 5.3 아이템 획득 방식

**지도 모드**: 아이템 핀 탭 → 상세 정보 확인
**AR 모드**: 
1. 아이템 범위(rangeAR) 내 진입
2. AR 화면에 아이템 아이콘 표시
3. **폰 흔들기** 또는 **화면 터치**로 획득
4. 획득 애니메이션 재생 (1.5배 확대 → 원래 크기)

**지뢰는 예외**: AR 범위 내 진입 시 **자동 폭발** (터치/흔들기 불필요)

### 5.4 미니게임 시스템 (GamePlayAlert)

아이템에 `itemGame` 속성이 설정된 경우 미니게임이 시작됨:

| 게임 유형 | 입력 방식 | 설명 |
|-----------|----------|------|
| type=0 | 터치 (Touch) | 버튼을 빠르게 연타 |
| type=1 | 흔들기 (Shake) | 폰을 세게 흔들기 |

**난이도 레벨**:
- Level 1: +6/+7 진행도 per 액션
- Level 2: +5/+6 진행도 per 액션
- Level 3: +4/+5 진행도 per 액션
- Level 4: +7/+8 진행도 per 액션

- 프로그레스 바: 0~100까지 채워야 성공
- 가속도계 임계값: 1.4G (흔들기 모드)
- 업데이트 간격: 0.1초

### 5.5 타이머 시스템

**메인 미션 타이머** (`updatePassedTime:`, 1초마다 호출):
- SBTickerView 6개 (HH:MM:SS) 각 자릿수 애니메이션
- 일반: 회색 (RGBA 30,30,30,1)
- 100초 미만: 빨간색 (RGBA 255,0,51,1)
- 시간 제한 있으면 카운트다운, 없으면 카운트업

**타임아웃 타이머** (Run 이벤트):
- 별도 SBTickerView 6개 (빨간 배경)
- Run Start 획득 시 활성화
- Run End 획득 또는 시간 만료 시 비활성화

### 5.6 점수 및 완료

- 점수 = 남은 시간 (빠를수록 높은 점수)
- 미션 완료 시 별점 평가 (DLStarRatingControl)
- 서버에 결과 전송 (`c_mission_play_finish`)

### 5.7 지도 표시 규칙

**핀 아이콘 체계**:
- 필수 아이템: `itemMandatoryMapFile:` (별표 있는 아이콘)
- 선택 아이템: `itemMapFile:` (일반 아이콘)
- 수집 완료 아이템: 흑백 변환 (`convertImageBW:`)
- 크기: 화면 경계에 맞춰 자동 스케일링

**오버레이 체계**:
- 지뢰 (활성): 빨간색 40% 투명도 원 (Mine Radar 필요)
- 지뢰 (폭발 완료): 갈색 원
- Dark 영역: 검은색 30% 투명도 원
- 미션 미시작 시: 원 표시 없음

### 5.8 상태 바 (Status View)

화면 하단 320×55px 상태 바에 4개 카운터:

| 레이블 | 표시 | 의미 |
|--------|------|------|
| `mine` | "001" | 숨겨진 지뢰 수 |
| `mandatory` | "004" | 남은 필수 아이템 수 |
| `invisibleMap` | "001" | 지도에서 안보이는 아이템 수 (Hidden) |
| `invisibleAR` | "000" | AR에서 안보이는 아이템 수 (Stealth) |

각 카운터에 CMPopTipView 툴팁 연결 (탭하면 설명 표시)

---

## 6. 미션 디자인 시스템

### 6.1 디자인 흐름 (튜토리얼 이미지 기반)

```
① 지도에 아이템 배치 → ② 아이템 세부 설정 → ③ 미션 정보 입력 → ④ 테스트 → ⑤ 업로드
```

### 6.2 아이템 배치 (MissionBuilder)

1. 지도를 탭하면 `UITapGestureRecognizer`가 좌표 캡처
2. `MultiPickerView` 3단계 선택:
   - 1단계: 아이템 유형 (Start, End, Quiz, Mine 등)
   - 2단계: 투명도 속성 (Normal, Hidden, Stealth)
   - 3단계: AR 감지 반경 (30~100m)
3. 아이템 핀이 지도에 추가됨
4. **드래그**로 위치 조정 가능

### 6.3 아이템 세부 설정 (MissionBuilderDetail)

- 아이템 유형 (Item Type)
- 필수 여부 (Mandatory?)
- 투명도 속성 (Display Type?)
- 감지 반경 (Visible Range)
- 퀴즈 문제/답안 입력 (Quiz 타입인 경우)

### 6.4 미션 설정

- 미션 배지(Badge) 이미지 설정
- 미션 제목
- 미션 설명
- 장소(Place)
- 미션 퀴즈 (전체 미션에 대한 퀴즈)
- 제한 시간

### 6.5 유효성 검사 (dataCheck)

| 규칙 | 설명 |
|------|------|
| 제목/설명/장소 필수 | 비어있으면 안됨 |
| 최소 3개 아이템 | 아이템이 3개 미만이면 안됨 |
| START/END 각 1개 | 중복이나 누락 불가 |
| QUIZ 검증 | 모든 Quiz 아이템에 문제+답이 있어야 함 |
| TIMEOUT 짝 맞춤 | Run Start 수 = Run End 수 |
| 레이더 연동 | SHOW_MAP 아이템이 있으면 I_RADAR_AR 필수 |

### 6.6 미션 상태 흐름
```
FIRST_DESIGN → DESIGNING → TESTED → SERVER_UPLOAD
```
- `FIRST_DESIGN`: 최초 디자인 (취소 시 삭제)
- `DESIGNING`: 편집 중
- `TESTED`: 테스트 완료
- `SERVER_UPLOAD`: 서버 업로드 완료 (수정 불가)

---

## 7. 데이터베이스 구조

### 7.1 로컬 SQLite (FMDB)

**데이터베이스 파일**: `treasure.sqlite` (번들에서 Documents 디렉토리로 복사)

### 7.2 테이블 스키마 (DAO 기반 추론)

#### Mission 테이블
```sql
missionID     TEXT PK    -- 미션 고유 ID (userID + timestamp)
Title         TEXT       -- 미션 제목
Description   TEXT       -- 미션 설명
Place         TEXT       -- 장소
Designer      TEXT       -- 제작자
StartTime     TEXT       -- 시작 시간
RunLimitTime  TEXT       -- 제한 시간
Status        INTEGER    -- 상태 (DESIGNING/TESTED/SERVER_UPLOAD)
WriteDate     TEXT       -- 작성일
Virtual       INTEGER    -- 가상모드 여부
Quiz          TEXT       -- 미션 퀴즈 질문
Answer        TEXT       -- 미션 퀴즈 답
```

#### MissionItem 테이블
```sql
(missionID, itemID)  PK
mandatory       INTEGER  -- 필수 여부
itemType        TEXT     -- 아이템 유형 코드
latitude        REAL     -- GPS 위도
longitude       REAL     -- GPS 경도
blackCnt        INTEGER  -- 지뢰 개수
blackTime       INTEGER  -- 시간 패널티(초)
rangeAR         INTEGER  -- AR 감지 반경(m)
showType        TEXT     -- 투명도 속성
effectiveRange  INTEGER  -- 유효 범위
effectiveTime   INTEGER  -- 유효 시간
itemGame        INTEGER  -- 미니게임 레벨
info            TEXT     -- 추가 정보
relationItemID  INTEGER  -- 연관 아이템 ID
WriteDate       TEXT     -- 작성일
```

#### ItemQuiz 테이블
```sql
(missionID, itemID, seq)  PK
quiz        TEXT     -- 퀴즈 질문
answer      TEXT     -- 정답
probability INTEGER  -- 출제 확률/난이도
```

#### MissionInPlay 테이블
```sql
(MissionID, PlayerID)  PK
StartYN     TEXT     -- 미션 시작 여부 ('Y'/'N')
EndYN       TEXT     -- 미션 종료 여부 ('Y'/'N')
StartTime   TEXT     -- 시작 시간
EndTime     TEXT     -- 종료 시간
```

#### MissionItemInPlay 테이블
```sql
(MissionID, PlayerID, ItemID)  PK
EndYN       TEXT     -- 아이템 획득 여부 ('Y'/'N')
FailCnt     INTEGER  -- 퀴즈 실패 횟수
StartTime   TEXT     -- 시작 시간
EndTime     TEXT     -- 종료 시간
QuizSeq     INTEGER  -- 완료한 퀴즈 시퀀스
```

#### ItemRnPInPlay 테이블
```sql
(MissionID, PlayerID, ItemType)  PK
AbleCnt      INTEGER  -- 남은 사용 횟수
AbleTime     TEXT     -- 사용 가능 시간
AcquiredTime TEXT     -- 획득 시간
```

### 7.3 핵심 DAO 쿼리

| 메서드 | 기능 |
|--------|------|
| `missionCompleted()` | 모든 필수 아이템 수집 여부 확인 |
| `missionCompletedExceptEndItem()` | End 제외 필수 완료 여부 |
| `selectLastAcquiredItem()` | 최근 획득 아이템 (Mine/Random/Timeout 제외) |
| `selectRand()` | 미획득 아이템 중 랜덤 선택 (End/Random/Black 제외) |
| `selectLastStartedTimeOut()` | 마지막 활성 타임아웃 이벤트 |
| `selectDicAt()` | ItemID → EndYN 딕셔너리 반환 |

---

## 8. 서버 통신 시스템

### 8.1 HTTPRequest 아키텍처

- **비동기** NSURLConnection 기반
- **타임아웃**: 5초
- **Base URL**: `http://nexapp.co.kr/playspot/J_MyList.php`
- **메서드**: 모든 요청이 POST (REST가 아닌 트랜잭션 코드 기반)
- **인코딩**: NSDictionary → URL-encoded form body

### 8.2 트랜잭션 코드 목록

| 코드 | 용도 | 주요 파라미터 |
|------|------|-------------|
| 200 | 미션 상세 조회 | missionID |
| 300 | 미션 리뷰/댓글 | missionID |
| 500 | 플레이 중 미션 목록 | last, lang |
| 501 | 공개 미션 목록 | last, lang, lat, lon |
| 502 | 내 디자인 목록 | last, lang |
| 503 | 튜토리얼 미션 | gb (언어) |
| 600 | 디자인 미션 수 | id |
| 601 | 플레이 미션 수 | id |
| 602 | 현재 게임 목록 | id |
| 800 | 로그인 | user_id, password(MD5) |
| tr_user_reg | 회원가입 | user_id, password(MD5) |

### 8.3 미션 다운로드 응답 형식

```
M{미션JSON}^I{아이템JSON배열}^Q{퀴즈JSON배열}
```
- `^` 구분자로 섹션 분리
- M = Mission, I = Items, Q = Quizzes
- SBJsonParser로 각 섹션 파싱

### 8.4 이미지 서버

- **배지 다운로드**: `http://nexapp.co.kr/playspot/badge/{missionID}.png`
- **배지 업로드**: `http://nexapp.co.kr/playspot/image_save.php` (multipart form-data)

---

## 9. 사운드 & 애니메이션 시스템

### 9.1 사운드 파일 목록

| 파일명 | 재생 시점 |
|--------|----------|
| `s_explosion.mp3` | 지뢰 폭발 |
| `s_timer.mp3` | 카운트다운 경고 |
| `s_timeover.mp3` | 시간 만료 |
| `quiz_rightanswer.mp3` | 퀴즈 정답 |
| `quiz_wronganswer.mp3` | 퀴즈 오답 |
| `s_quiz_fail.mp3` | 퀴즈 실패 |
| `s_yougotit.mp3` | 아이템 획득 |
| `s_applause.mp3` | 환호 (미션 완료) |
| `s_gogogo.mp3` | 출발 (미션 시작) |
| `s_game_touch.mp3` | 미니게임 터치 |
| `s_winsomething.wav` | 보상 획득 |
| `s_radar.mp3` | 레이더 작동 |
| `game_finish.mp3` | 게임 종료 |
| `radar.mp3` | 레이더 효과음 |

### 9.2 진동 피드백

```objc
AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)  // 지뢰 피격 시
```

### 9.3 애니메이션

**타이머 자릿수 변경**: SBTickerView 스크롤 (아래로 넘어가는 효과)  
**Run End 아이템 맥동**: CABasicAnimation scale 1.5x→1.0x, 0.35초, 무한 반복  
**아이템 획득**: 1.5배 확대 → 원래 크기 (0.3초+0.3초)  
**랜덤 이펙트**: 180°/2초 회전 + 페이드아웃, 4초 후 자동 제거

---

## 10. 인앱 결제 시스템

### 10.1 StoreKit 통합

| 상품 ID | 내용 | 사용처 |
|---------|------|--------|
| `time_add_10` | 시간 10분 추가 | MissionPlay (시간 제한 미션) |
| `solution_add_10` | 솔루션 10개 추가 | QuizPlayAlert (퀴즈 정답 공개) |

### 10.2 구매 흐름
```
사용자 탭 → SKProductsRequest → 상품 확인 → SKPayment 생성 → 
SKPaymentQueue 추가 → 트랜잭션 관찰 → 
  성공: completeTransaction → resultbuy() → NSUserDefaults 저장
  실패: failedTransaction → 알림 표시
  복원: restoreTransaction
```

### 10.3 잔고 관리

```objc
// NSUserDefaults에 영구 저장
setSolutionCount:  → key: "solution"
setTimeAddCount:   → key: "timeAdd"
// 음수 방지 (0으로 클램프)
```

---

## 11. 이미지 에셋 체계

### 11.1 이미지 네이밍 규칙

| 접두사 | 용도 | 예시 |
|--------|------|------|
| `ar_` | AR 화면 아이콘 (선택 아이템) | `ar_quiz.png`, `ar_mine.png` |
| `arn_` | AR 화면 아이콘 (필수 아이템) | `arn_quiz.png`, `arn_mine.png` |
| `i_` | 일반 아이콘 (지도/정보) | `i_quiz.png`, `i_mine.png` |
| `in_` | 필수 아이콘 (지도/정보) | `in_quiz.png`, `in_mine.png` |

### 11.2 AR 아이콘 목록 (ar_ 접두사)

```
ar_start.png        ar_end.png          ar_quiz.png
ar_simple.png       ar_mine.png         ar_mine_nobomb.png
ar_random_box.png   ar_genius.png       ar_coupon.png
ar_store.png        ar_radar_all.png    ar_radar_ar.png
ar_radar_map.png    ar_radar_mine.png   ar_time_start.png
ar_time_end.png     ar_rader_body.png
```

### 11.3 레이더 UI 에셋

```
radar_body.png    — 레이더 패널 배경
radar_cross.png   — 십자선
radar_item.png    — 아이템 방향 표시
radar_myway.png   — 기기 방향 표시
```

### 11.4 게임 에셋

```
game_touch.png / game_touch@2x.png     — 터치 미니게임 버튼 (비활성)
game_touch1.png / game_touch1@2x.png   — 터치 미니게임 버튼 (활성)
game_shake.png / game_shake@2x.png     — 흔들기 미니게임 (비활성)
game_shake1.png / game_shake1@2x.png   — 흔들기 미니게임 (활성)
```

### 11.5 배지 시스템 (ImgBadg/)

- `play1.png` ~ `play100.png` — 플레이 횟수 배지 (1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100회)
- `design1.png` ~ `design60.png` — 디자인 횟수 배지 (1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 60회)
- `frame160.png`, `frame160_1.png` — 배지 프레임
- `mask1.png`, `mask2.png` — 이미지 마스킹용
- `empty02.png` — 빈 배지 플레이스홀더

### 11.6 이미지 캐싱 (ImageManager)

**2단계 캐시 전략**:
1. **로컬 디스크** (Documents/{missionID}.png) — 우선 확인
2. **서버 다운로드** — 캐시 미스 시 동기 다운로드
3. **서버 실패** → `empty02.png` 플레이스홀더 반환
4. **다운로드 성공** → 로컬 디스크에 저장 (다음 접근 시 캐시 히트)

**이미지 가공**:
- `ImageMerge:` — 배지 이미지 + 상태 아이콘 합성 (첫클리어, 리얼모드 등)
- `imageResizeImage:` — 160×160px 표준화
- `maskImage:` — mask1.png 마스크 적용
- `uploadImgWithID:Image:` — multipart form-data POST 업로드

---

## 12. 튜토리얼 이미지 분석

### 12.1 Tutorial 0 — 아이템 가이드 (tutorial0_en@2x.jpg / tutorial0@2x.jpg)

**투명도 속성 설명**:
- **Normal**: 지도와 AR 화면 모두에서 보임
- **Stealth**: AR 화면에서 아이템 정보 없음 (거리/방향 비표시)
- **Hidden**: 지도에 안 보이지만 AR 화면에 보임

**필수 속성 설명**:
- 별(★)이 붙은 아이템은 미션 완료를 위해 반드시 수집해야 함

**각 아이템 설명** (영문 튜토리얼 기준):
1. **Start**: 미션 시작 아이템. 획득하면 시간제한, 퀴즈 등 정보 공개
2. **End**: 미션 종료 아이템. 모든 필수 아이템을 모은 뒤 마지막 1개 남으면 나타남
3. **Hint**: 퀴즈 답에 대한 힌트. 힌트가 없으면 위치 정보 표시
4. **Mine**: 근처에 폭탄이 있음. 지도에서 보이지 않으며 진입 시 최근 아이템 상실
5. **Defence**: 획득하면 모든 폭탄으로부터 보호
6. **Gambling**: 랜덤으로 미보유 아이템 1개 획득 (End/Gambling 제외)
7. **Quiz**: 퀴즈를 풀어야 진행. 오답 시에도 힌트 제공
8. **Solution**: 퀴즈의 정답을 즉시 알려줌
9. **Map Radar**: Hidden 속성 아이템을 지도에 표시
10. **Mine Radar**: 폭탄 영역을 지도에 표시
11. **Stealth Radar**: Stealth 속성 아이템을 AR 화면에 표시
12. **Run Start**: 제한 시간 내에 Run End 아이템을 찾아야 함
13. **Run End**: Run Start 후 이 아이템을 찾아야 미션 계속 가능
14. **Dark**: Dark 반경 내 모든 아이템이 지도에서 사라짐. AR 레이더의 거리/방향만으로 탐색

### 12.2 Tutorial 1 — 게임 플레이 가이드 (tutorial1_en@2x.jpg / tutorial1@2x.jpg)

**Play Spot 소개**: GPS 기반 보물찾기 게임. 지도와 AR 화면으로 아이템 위치를 찾아 수집

**Play Spot Mode 설명**:
- **Real Mode**: 미션 생성 장소에서 플레이
- **Virtual Mode**: 현재 위치 기준 플레이 (지형에 따라 어려울 수 있음)

**How to Play 설명**:
1. 지도에서 아이템 위치 확인
2. 핸드폰을 들고 돌아다니며 접근
3. AR 화면에서 아이템 발견 시 **폰을 흔들어** 획득

**화면 UI 설명** (스크린샷 기반):
- **상태 바**: Mine(숨겨진 지뢰 수) | Mandatory(남은 필수 수) | 카메라 버튼 | Hidden(안보이는 수) | Stealth(스텔스 수)
- **타이머**: 00:09:00 형식의 경과/남은 시간
- **Exit 버튼**: 미션 나가기
- **Info 버튼**: 미션 정보 확인

**AR 화면 설명**:
- `@Map` 라벨 표시 + 타이머
- 아이템이 카메라에 오버레이되어 표시
- **Start:2m** — 아이템과의 거리
- **Visible range:30m** — AR 화면에서 아이템이 보이는 범위
- **▲ (녹색)**: 아이템 방향
- **▼ (노란색)**: 아이폰 방향

**게임 완료**: Start 아이템 획득 후 → 필수 아이템 모두 수집 → End 아이템 획득 → **Clear!**

### 12.3 Tutorial 2 — 미션 디자인 가이드 (tutorial2_en@2x.jpg / tutorial2@2x.jpg)

**5단계 미션 디자인 프로세스**:

**① 지도에 아이템 배치**:
- 지도를 길게 누르면 아이템 이동 가능 ("Press and drag an item to locate")
- 탭하면 세부 설정 화면 열림 ("Tap to set detail")

**② 아이템 세부 설정**:
- Basic Item Info: Item Type(Quiz), Mandatory?(Mandatory), Display Type?(Normal), Visible Range(30)
- Item Quiz: 퀴즈 문제와 답 입력
- "퀴즈 답을 볼 수 있는 아이템의 이름은?" → 답: "solution"

**③ 미션 설정**:
- Mission Badge Setup: 미션 심볼/배지 이미지
- Mission Title: "Level 3 Quiz and Solution"
- Mission Description
- Place: "South Korea, Seoul"
- Mission Quiz: 전체 미션에 대한 최종 퀴즈
- 제한 시간, 퀴즈 등 메타데이터 입력

**④ 테스트**:
- 직접 만든 미션을 테스트 플레이 ("I made this, so I play without problem" / "Pass easily~")

**⑤ 업로드**:
- 업로드 버튼을 누르면 서버에 공개 ("Once you press the upload button, you can't modify the mission")
- 업로드 후 수정 불가

---

## 부록: 클래스 관계도

```
TreasureHunterAppDelegate (싱글턴 — 전역 상태)
├── CLLocationManager (GPS)
├── FMDatabase (SQLite)
├── soundIDDic (사운드 캐시)
├── gUserID / guestUserID (사용자 세션)
├── playMission / playingDic (현재 게임 상태)
│
├── MissionList (미션 목록 탭)
│   ├── HTTPRequest → 서버에서 미션 목록 조회
│   ├── MissionListDetailController (미션 상세)
│   │   ├── StartGameAlert (게임 시작 — Real/Virtual 선택)
│   │   └── MissionPlay ★ (메인 게임 컨트롤러)
│   │       ├── MKMapView (지도 뷰)
│   │       ├── SBTickerView ×12 (타이머 표시)
│   │       ├── CMPopTipView (상태 바 툴팁)
│   │       ├── ARGeoViewController (AR 카메라 뷰)
│   │       │   ├── ARViewController (AR 렌더링 엔진)
│   │       │   │   ├── UIImagePickerController (카메라)
│   │       │   │   ├── UIAccelerometer (기울기/흔들기)
│   │       │   │   └── CLLocationManager (GPS + 나침반)
│   │       │   └── ARGeoCoordinate[] (아이템 극좌표)
│   │       ├── QuizPlayAlert (퀴즈 UI)
│   │       ├── GamePlayAlert (미니게임 UI)
│   │       ├── NoticAlertView (알림 UI)
│   │       └── SKPaymentQueue (인앱 결제)
│   └── ImageManager (배지 이미지 캐시)
│
├── MissionBuilder (미션 디자인 탭)
│   ├── MKMapView + UITapGestureRecognizer
│   ├── MultiPickerView (아이템 유형 선택)
│   ├── MissionBuilderDetail (아이템 세부 설정)
│   └── MissionDao / MissionItemDao / ItemQuizDao (DB 저장)
│
├── MyInfo (내 정보 탭)
│   ├── SKPaymentQueue (인앱 결제)
│   └── HTTPRequest → 통계 조회
│
├── Login / UserReg (인증)
│   └── HTTPRequest → 로그인/가입
│
└── Setting (설정 탭)
    └── 튜토리얼 이미지 캐러셀

DAO Layer (데이터 접근):
BaseDao (FMDatabase 연결)
├── MissionDao
├── MissionItemDao
├── ItemQuizDao
├── MissionInPlayDao
├── MissionItemInPlayDao
└── ItemRnPInPlayDao

Model Layer:
Mission ──┬── MissionItem[] ──── ItemQuiz[]
          └── AnnoItem (MKAnnotation 프로토콜)
```

---

## 부록: 파워업/레이더 가시성 매트릭스

아이템의 `showType`과 보유 레이더에 따른 가시성:

| showType | 보유 레이더 없음 | Map Radar | AR Radar | All Radar | Mine Radar |
|----------|-----------------|-----------|----------|-----------|------------|
| Normal(4) | 지도✓ AR✓ | 지도✓ AR✓ | 지도✓ AR✓ | 지도✓ AR✓ | — |
| Hidden(1) | 지도✗ AR✗ | 지도✓ AR✗ | 지도✗ AR✓ | 지도✓ AR✓ | — |
| AR(2) | 지도✗ AR✓ | 지도✓ AR✓ | 지도✗ AR✓ | 지도✓ AR✓ | — |
| Map(3) | 지도✓ AR✗ | 지도✓ AR✗ | 지도✓ AR✓ | 지도✓ AR✓ | — |
| Mine | 지도✗ | 지도✗ | 지도✗ | 지도✗ | 지도✓(빨간원) |

---

*이 보고서는 TreasureHunter(Play Spot) 프로젝트의 전체 소스 코드, 튜토리얼 이미지, 리소스 에셋을 분석하여 작성되었습니다.*
