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

- **비동기** NSURLConnection 기반 (delegate 패턴)
- **동기** NSURLConnection `sendSynchronousRequest` 사용
- **메서드**: 모든 요청이 POST (REST가 아닌 트랜잭션 코드 기반)
- **인코딩**: UTF-8, URL-encoded form body (`param1=value1&param2=value2`)
- **인증**: 세션/토큰 없음. 요청마다 user_id 전송, 비밀번호는 MD5 해시 후 전송
- **응답 형식**: 대부분 JSON (SBJsonParser), 일부 단순 문자열 ("SUCCESS" / "FAIL")

```objc
// HTTPRequest.h - 비동기 요청
- (void)requestAsyncPOST:(NSURL *)url
              parameters:(NSString *)params
                delegate:(id)delegate
                callback:(SEL)callback;

// HTTPRequest.h - 동기 요청
- (NSString *)requestSyncPOST:(NSURL *)url
                   parameters:(NSString *)params;
```

**타임아웃:**
| 모드 | 시간 | 캐시 정책 |
|------|------|----------|
| 비동기 | 5초 | `NSURLRequestUseProtocolCachePolicy` |
| 동기 | 30초 | `NSURLRequestReturnCacheDataElseLoad` |

### 8.2 서버 URL 목록

| 용도 | URL |
|------|-----|
| 메인 API | `http://nexapp.co.kr/playspot/J_MyList.php` |
| 미션 랭킹 | `http://nexapp.co.kr/playspot/mission_play_info.php` |
| 비밀번호 변경 | `http://nexapp.co.kr/playspot/user.php` |
| 이미지 업로드 | `http://nexapp.co.kr/playspot/image_save.php` |
| 유저 정보 관리 | `http://mking.elogin.co.kr/xe/user.php` |
| 뱃지 이미지 | `http://nexapp.co.kr/playspot/badge/{ImageName}.png` |

### 8.3 API 상세 인터페이스 (전체 트랜잭션 코드)

---

#### TR=200 — 미션 상세 다운로드

| 항목 | 값 |
|------|-----|
| URL | `J_MyList.php` |
| Method | POST |

**Request:**
```
tr=200&missionID={missionID}
```

**Response:** `^` 구분자로 분리된 멀티파트 포맷
```
^M{"MissionID":"...","Title":"...","Description":"...","Place":"...","Designer":"...", ...}
^I[{"ItemID":1,"Mandatory":0,"ItemType":"40","Latitude":37.5,"Longitude":127.0, ...}, ...]
^Q[{"Seq":1,"Quiz":"질문","Answer":"정답","Probability":100}, ...]
```

**파싱 로직:**
1. 응답을 `^`로 split
2. 각 라인의 첫 글자(M/I/Q) 확인
3. index 1부터 substring → JSON 파싱

**Mission 응답 필드:**
| 필드 | 타입 | 설명 |
|------|------|------|
| MissionID | String | 미션 고유 ID |
| Title | String | 미션 제목 |
| Description | String | 미션 설명 |
| Place | String | 장소명 |
| Designer | String | 디자이너 ID |
| RunLimitTime | String | 제한 시간 |
| Status | Int | 상태 (DESIGNING=0, TESTED=1, SERVER_UPLOAD=2) |
| Quiz | String | 미션 퀴즈 |
| Answer | String | 미션 답 |
| Virtual | Int | 가상모드 지원 (0/1) |
| WriteDate | String | 작성일 |
| PlayCnt | Int | 플레이 수 |
| FailCnt | Int | 실패 수 |
| RecommendCnt | Int | 추천 수 |
| RecommendAvg | Int | 평균 평점 |
| ShortUser1~3 | String | 랭킹 유저명 |
| ShortRecord1~3 | String | 랭킹 기록 |

**MissionItem 응답 필드:**
| 필드 | 타입 | 설명 |
|------|------|------|
| ItemID | Int | 아이템 ID |
| Mandatory | Int | 필수 여부 (0=N, 1=Y) |
| ItemType | String | 아이템 타입 코드 ("40"=퀴즈, "49"=출발 등) |
| Latitude | Double | 위도 |
| Longitude | Double | 경도 |
| BlackCnt | Int | 감점 횟수 |
| BlackTime | Int | 감점 시간(초) |
| RangeAR | Int | AR 표시 범위(m) |
| ShowType | String | 표시 타입 (Normal/Hidden/Stealth/Transparent) |
| EffectiveTime | Int | 유효 시간(초) |
| EffectiveRange | Int | 유효 범위(m) |
| ItemGame | Int | 미니게임 종류 |
| Info | String | 아이템 정보/힌트 |
| RelationItemID | Int | 연관 아이템 ID |

**ItemQuiz 응답 필드:**
| 필드 | 타입 | 설명 |
|------|------|------|
| Seq | Int | 퀴즈 순서 |
| Quiz | String | 퀴즈 문제 |
| Answer | String | 정답 |
| Probability | Int | 출제 확률(%) |

---

#### TR=300 — 미션 댓글 조회

| 항목 | 값 |
|------|-----|
| URL | `J_MyList.php` |

**Request:**
```
tr=300&missionID={missionID}
```

**Response:** JSON 배열
```json
[{"MReply": "재미있어요!"}, {"MReply": "추천합니다"}]
```

---

#### TR=400 — 미션 리뷰/평점 등록

| 항목 | 값 |
|------|-----|
| URL | `J_MyList.php` |

**Request:**
```
tr=400&MID={missionID}&UID={userID}&Score={평점float}&Reply={리뷰텍스트}
```

**Response:** 없음 (fire-and-forget)

---

#### TR=500 — 미션 목록 (전체)

| 항목 | 값 |
|------|-----|
| URL | `J_MyList.php` |

**Request:**
```
tr=500&last={페이지커서}&lang={언어코드}
```
- `last`: 페이지네이션 커서 (정수, 0부터 시작)
- `lang`: `NSUserDefaults`의 `AppleLanguages[0]`

**Response:** JSON 배열 (Mission 객체 목록)

---

#### TR=501 — 미션 목록 (위치 기반)

**Request:**
```
tr=501&last={커서}&lang={언어}&latitude={위도}&longitude={경도}
```

**Response:** JSON 배열 (근처 미션 목록)

---

#### TR=502 — 미션 목록 (탭1)

**Request:**
```
tr=502&last={커서}&lang={언어}
```

**Response:** JSON 배열

---

#### TR=503 — 튜토리얼 미션 목록

**Request:**
```
tr=503&gb={지역코드}
```
- `gb`: 한국어 `"0%"`, 기타 `"1%"`

**Response:** JSON 배열 (튜토리얼 미션 목록)

---

#### TR=600 — 내가 디자인한 미션 목록

**Request:**
```
tr=600&id={userID}
```

**Response:** JSON 배열 (`MissionID` 필드 포함)

---

#### TR=601 — 내가 플레이한 미션 목록

**Request:**
```
tr=601&id={userID}
```

**Response:** JSON 배열 (`MissionID` 필드 포함)

---

#### TR=602 — 현재 플레이 중인 미션 목록

**Request:**
```
tr=602&id={userID}
```

**Response:** JSON 배열

---

#### TR=700 — 미션 서버 업로드

**Request:**
```
tr=700
&mission={missionID}}}{mTitle}}}{mDescription}}}{mPlace}}}{mDesigner}}}{mRunLimitTime}}}{mStatus}}}{mQuiz}}}{mAnswer}}}{mVirtual}}}{mLang}}}{mWriteDate}
&missionItem={missionID}}}{itemID}}}{mandatory}}}{itemType}}}{latitude}}}{longitude}}}{blackCnt}}}{blackTime}}}{rangeAR}}}{showType}}}{effectiveRange}}}{effectiveTime}}}{itemGame}}}{info}}}{relationItemID}}}{writeDate}**{다음아이템...}
&itemQuiz={missionID}}}{itemID}}}{seq}}}{quiz}}}{answer}}}{probability}**{다음퀴즈...}
```

- 필드 구분자: `}}}` (닫는 중괄호 3개)
- 레코드 구분자: `**` (아이템/퀴즈 간)

**Response:** `"SUCCESS"` 문자열

---

#### TR=800 — 로그인

**Request:**
```
tr=800&user_id={이메일}&password={MD5해시}
```

**Response:** `"SUCCESS"` 또는 오류 메시지

---

#### TR=tr_user_reg — 회원가입

| 항목 | 값 |
|------|-----|
| URL | `J_MyList.php` |

**Request:**
```
tr=tr_user_reg&user_id={이메일}&password={MD5해시}
```

**Response:** `"SUCCESS"` 또는 오류 메시지

---

#### TR=tr_pwd_chg — 비밀번호 변경

| 항목 | 값 |
|------|-----|
| URL | `user.php` |

**Request:**
```
tr=tr_pwd_chg&user_id={이메일}&old_password={MD5}&new_password={MD5}
```

**Response:** `"SUCCESS"`

---

#### TR=tr_user_sel — 유저 정보 조회

| 항목 | 값 |
|------|-----|
| URL | `http://mking.elogin.co.kr/xe/user.php` |

**Request:**
```
tr=tr_user_sel&user_id={userID}
```

**Response:** 유저 데이터 (JSON)

---

#### TR=tr_user_chg — 유저 정보 수정

| 항목 | 값 |
|------|-----|
| URL | `http://mking.elogin.co.kr/xe/user.php` |

**Request:**
```
tr=tr_user_chg&user_id={userID}&password={MD5}&email_addr={이메일}&phone_no={전화번호}
```

**Response:** `"SUCCESS"`

---

#### TR=c_mission_play_start — 미션 플레이 시작

**Request:**
```
tr=c_mission_play_start&mission_play={missionID},{playerID},{startTime},{isVirtualMode}
```

---

#### TR=c_mission_play_finish — 미션 완료

**Request:**
```
tr=c_mission_play_finish&mission_play={missionID},{playerID},{endTime},{isVirtualMode}
```

---

#### TR=c_mission_play_fail — 미션 실패

**Request:**
```
tr=c_mission_play_fail&mission_play={missionID},{playerID},{endTime},{isVirtualMode}
```

---

#### TR=c_mission_play_ranking — 미션 랭킹 조회

| 항목 | 값 |
|------|-----|
| URL | `mission_play_info.php` |

**Request:**
```
tr=c_mission_play_ranking&mission_id={missionID}
```

**Response:**
```json
{
  "ShortUser1": "user1", "ShortRecord1": "00:05:30",
  "ShortUser2": "user2", "ShortRecord2": "00:08:12",
  "ShortUser3": "user3", "ShortRecord3": "00:10:45"
}
```

---

### 8.4 이미지 다운로드/업로드

**뱃지 이미지 다운로드:**
```
GET http://nexapp.co.kr/playspot/badge/{ImageName}.png
```

**이미지 업로드:**
```
POST http://nexapp.co.kr/playspot/image_save.php
Content-Type: multipart/form-data; boundary=treasurehunter

--treasurehunter
Content-Disposition: form-data; name="userfile"; filename="{imageID}"
Content-Type: image/png

{바이너리 이미지 데이터}
--treasurehunter--
```

### 8.5 소스 파일 참조

| 트랜잭션 | 소스 파일 |
|----------|-----------|
| TR=200, 300 | `MissionListDetailController.m` |
| TR=400 | `MissionPlay.m` |
| TR=500, 501, 502, 601, 602 | `MissionList.m` |
| TR=503 | `Setting.m` |
| TR=600 | `MissionBuilderList.m` |
| TR=700 | `MissionBuilderList.m` |
| TR=800 | `Login.m` |
| tr_user_reg | `UserReg.m` |
| tr_pwd_chg | `PwdChg.m` |
| tr_user_sel, tr_user_chg | `UserInfoChg.m` |
| c_mission_play_* | `MissionPlay.m` |
| c_mission_play_ranking | `MissionPlayInfo.m` |
| 이미지 다운로드/업로드 | `ImageManager.m` |

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

---

## 부록: MissionItem 테이블 컬럼 완전 분석

본 부록은 [Classes/MissionItem.h](Classes/MissionItem.h), [Classes/MissionItem.m](Classes/MissionItem.m), [Classes/Dao/MissionItemDao.m](Classes/Dao/MissionItemDao.m), [Classes/TreasureHunterAppDelegate.m](Classes/TreasureHunterAppDelegate.m) 등 레거시 소스를 정밀 추적하여 모든 컬럼의 용도, 코드값, 기본값, 허용 범위를 정리한다.

### 컬럼 개요

| 컬럼 | SQLite 타입 | ObjC 타입 | 기본값 (`init`) | 코드값 보유 | 비고 |
|---|---|---|---|:---:|---|
| `missionID` | TEXT | NSMutableString | nil | — | (MissionID, ItemID) PK |
| `itemID` | INTEGER | int | 0 | — | 미션 내 1부터 자동 증가 |
| `mandatory` | INTEGER | int | `MANDATORY_N`(0) | ✅ | 0/1 enum |
| `itemType` | TEXT | NSMutableString | nil | ✅ | 27종 코드 |
| `latitude` | REAL | CLLocationDegrees | 0.0 | — | GPS 위도 |
| `longitude` | REAL | CLLocationDegrees | 0.0 | — | GPS 경도 |
| `blackCnt` | INTEGER | int | **5** | ✅ | 1~10 picker  미구현|
| `blackTime` | INTEGER | int | **300** (5분) | ✅ | 5~10분 picker (초 단위) 미구현|
| `rangeAR` | INTEGER | int | **30** | ✅ | 30~100m picker (10m 단위) |
| `showType` | TEXT | NSMutableString | nil | ✅ | 4종 코드, builder 노출은 3종 |
| `effectiveRange` | INTEGER | int | 0 | ✅ | 2~60m picker |
| `effectiveTime` | INTEGER | int | 0 | — | 타임아웃 제한시간(초) |
| `itemGame` | INTEGER | int | 0 | ✅ | 0~3 (None/Beg/Norm/Senior) |
| `info` | TEXT | NSMutableString | nil | — | 자유 텍스트 (힌트/설명) |
| `relationItemID` | INTEGER | int | 0 | — | RunStart↔End 짝맞춤 |
| `quizSeq` | INTEGER | int | **1** | — | 빌더에서 다음 퀴즈 seq |
| `rnpSeq` | INTEGER | int | 0 | — | (현재 미사용) |

> **세 가지 진실의 출처**:
> - **상수**: `Classes/MissionItem.h` 의 `#define I_*`, `SHOW_*`
> - **enum**: `TreasureHunter_Prefix.pch` 의 `MANDATORY_N/Y`, `DESIGNING/TESTED/SERVER_UPLOAD/FIRST_DESIGN`, `REAL_MODE/VIRTUAL_MODE`
> - **picker 배열**: `TreasureHunterAppDelegate.m:300-317` 의 `itemTypeKeys`, `showTypeKeys`, `itemGame`, `effectiveRange`, `rangeAR`, `blackCnt`, `blackTime`

---

### 컬럼별 상세 분석

#### `missionID` (TEXT, PK)
- 값 형식: `{userID}{yyyyMMddHHmmss}` 또는 서버 발급 ID
- 미션과 1:N 외래키. (`missionID`, `itemID`) 가 복합 PK
- 신규 PlaySpot Swift: 동일 (`MissionItem.missionID: String`)

#### `itemID` (INTEGER, PK)
- 미션 내 자동 증가 정수. 빌더에서 1번부터 부여
- 다른 컬럼(`relationItemID`)과 cross-reference 시 참조 키
- 신규: `MissionItem.itemID: Int`

#### `mandatory` (INTEGER, enum)

[`TreasureHunter_Prefix.pch:32-35`](TreasureHunter_Prefix.pch#L32-L35):

| 코드값 | 상수 | 의미 | UI 라벨 (en/ko) |
|:---:|---|---|---|
| `0` | `MANDATORY_N` | 선택 아이템 | "Option" / "선택" |
| `1` | `MANDATORY_Y` | 필수 아이템 (★ 표시) | "Mandatory" / "필수" |

- 화면 하단 "남은필수" 카운터에 반영
- **End 자신**도 항상 `MANDATORY_Y` (별표 아이콘)
- `MissionItem.h:62`: `mandatory = MANDATORY_N` 가 기본값
- 빌더 picker: [`AppDelegate.m:312`](Classes/TreasureHunterAppDelegate.m#L312)

#### `itemType` (TEXT, 27 코드값)

[`MissionItem.h:18-59`](Classes/MissionItem.h#L18-L59) 의 모든 `#define I_*` 매크로 — **빠진 것 없음 전체 27개**:

| 코드 | 매크로 | 카테고리 | 영문 라벨 | 한글 라벨 | 빌더 노출 | 기능 |
|:---:|---|---|---|---|:---:|---|
| `"00"` | `I_NUM00` | 수집 | (Number 0) | — | ✗ | 숫자 수집 (현재 미사용) |
| `"01"` | `I_NUM01` | 수집 | (Number 1) | — | ✗ | 숫자 수집 |
| `"02"` | `I_NUM02` | 수집 | (Number 2) | — | ✗ | 숫자 수집 |
| `"03"` | `I_NUM03` | 수집 | (Number 3) | — | ✗ | 숫자 수집 |
| `"04"` | `I_NUM04` | 수집 | (Number 4) | — | ✗ | 숫자 수집 |
| `"05"` | `I_NUM05` | 수집 | (Number 5) | — | ✗ | 숫자 수집 |
| `"06"` | `I_NUM06` | 수집 | (Number 6) | — | ✗ | 숫자 수집 |
| `"07"` | `I_NUM07` | 수집 | (Number 7) | — | ✗ | 숫자 수집 |
| `"08"` | `I_NUM08` | 수집 | (Number 8) | — | ✗ | 숫자 수집 |
| `"09"` | `I_NUM09` | 수집 | (Number 9) | — | ✗ | 숫자 수집 |
| `"10"` | `I_ALPHABET` | 수집 | (Alphabet) | — | ✗ | 문자 수집 (현재 미사용) |
| `"40"` | `I_QUIZ` | 퀴즈 | "Quiz" | "Quiz" | ✓ | 퀴즈 풀기 |
| `"41"` | `I_QUIZ20` | 퀴즈 | (Quiz20) | — | ✗ | 20개+ 변형 퀴즈 |
| `"42"` | `I_TIMEOUT_S` | 타임아웃 | "Run Start" | "Run Start" | ✓ | 카운트다운 시작 |
| `"43"` | `I_TIMEOUT_E` | 타임아웃 | "Run End" | "Run End" | ✓ | 카운트다운 종료 (relationItemID 필요) |
| `"48"` | `I_END` | 미션 | "End" | "End" | ✓ | 미션 종료. 항상 mandatory |
| `"49"` | `I_START` | 미션 | "Start" | "Start" | ✓ | 미션 시작. 항상 mandatory |
| `"50"` | `I_RANDOM` | 특수 | "Gambling" | "Gambling" | ✓ | 랜덤 미보유 아이템 1개 획득 |
| `"51"` | `I_SIMPLE` | 수집 | "Hint" | "Hint" | ✓ | 힌트 (itemGame≠0이면 미니게임) |
| `"52"` | `I_SOLUTION` | 파워업 | "Solution" | "Solution" | ✓ | 퀴즈 정답 공개 |
| `"54"` | `I_PENALTY_REMOVE` | 파워업 | (Penalty Remove) | — | ✗ | 퀴즈 페널티 초기화 (현재 미사용) |
| `"55"` | `I_MINE` | 위험 | "Mine" | "Mine" | ✓ | 진입 시 자동 폭발 |
| `"56"` | `I_BLACK` | 위험 | "Dark" | "Dark" | ✓ | 영역 내 아이템 가림 |
| `"59"` | `I_COUPON` | 보상 | "쿠폰" | "쿠폰" | ✓ | 쿠폰/할인 (info 에 내용) |
| `"61"` | `I_MINE_NOBOMB` | 파워업 | "Defense" | "Defense" | ✓ | 지뢰 1회 방어 |
| `"65"` | `I_RADAR_AR` | 레이더 | "Stealth Radar" | "Stealth Radar" | ✓ | Stealth ShowType AR 표시 |
| `"66"` | `I_RADAR_MAP` | 레이더 | "Map Radar" | "Map Radar" | ✓ | Hidden ShowType 지도 표시 |
| `"67"` | `I_RADAR_ALL` | 레이더 | (All Radar) | — | ✗ | Map+AR Radar 동시 효과 (코드만 존재) |
| `"68"` | `I_RADAR_MINE` | 레이더 | "Mine Radar" | "Mine Radar" | ✓ | 지뢰 영역 빨간 원 표시 |
| `"69"` | `I_RADAR_BLACK` | 레이더 | (Radar Black) | — | ✗ | 미구현 (`MissionBuilderDetail.m:523` "현재 구현 안됨" 주석) |
| `"91"` | `I_STORE` | 보상 | "Store" | "Store" | ✓ | 상점/IAP (info 에 상품 정보) |

**빌더 picker 라벨** ([`AppDelegate.m:300-303`](Classes/TreasureHunterAppDelegate.m#L300-L303)):
- `itemTypeKeys`: `[Start, End, Hint, Quiz, Gambling, Run Start, Run End, Mine, Dark, Defense, Solution, Stealth Radar, Map Radar, Mine Radar, 쿠폰, Store]` (16개)
- `itemTypeFiles`: `[start, end, simple, quiz, random_box, time_start, time_end, mine, black, mine_nobomb, genius, radar_ar, radar_map, radar_mine, coupon, store]` — 이미지 파일명 prefix

> **요약**: 헤더에 정의된 27개 중 **빌더에서 노출되는 건 16개**. 나머지(NUM00~09, ALPHABET, QUIZ20, PENALTY_REMOVE, RADAR_ALL, RADAR_BLACK)는 코드만 정의되어 있고 빌더 UI 에서 선택 불가하다 (서버 마이그레이션 데이터에서만 등장 가능).

#### `latitude`, `longitude` (REAL)
- WGS84 GPS 좌표
- 빌더에서 지도를 길게 눌러 핀 추가, 드래그로 이동
- Virtual 모드 setup 시 [VirtualModeManager](PlaySpot/Game/VirtualModeManager.swift) 가 start 아이템 좌표를 플레이어 위치로 평행이동
- 신규: `CLLocationDegrees` (둘 다 0.0 기본)

#### `blackCnt` (INTEGER, 1~10)

[`AppDelegate.m:315`](Classes/TreasureHunterAppDelegate.m#L315):
```objc
blackCnt = [@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10"]
```

- 기본값: `5` ([`MissionItem.m:64`](Classes/MissionItem.m#L64))
- 의도: Dark/Mine 영역의 페널티 횟수. 그러나 **현재 레거시 런타임에서 사용처 없음** (DAO 저장만)
- 신규 Swift: 동일 디폴트 (`MissionItem.swift:13`)

#### `blackTime` (INTEGER, 초 단위)

[`AppDelegate.m:317`](Classes/TreasureHunterAppDelegate.m#L317):
```objc
blackTime = [@"5분", @"6분", @"7분", @"8분", @"9분", @"10분"]
// 빌더에서 (선택 인덱스+1) * 5 * 60 초로 저장 (MissionBuilderDetail.m:752)
```

| picker 인덱스 | 라벨 | 저장값 (초) |
|:---:|---|---:|
| 0 | "5분" | 300 |
| 1 | "6분" | 360 |
| 2 | "7분" | 420 |
| 3 | "8분" | 480 |
| 4 | "9분" | 540 |
| 5 | "10분" | 600 |

- 기본값: `300` (5분)
- 의도: Dark/Mine 영역 시간 패널티. 현재 사용처 없음 (DAO 저장만)
- 빌더 코드 ([`MissionBuilderDetail.m:752`](Classes/MissionBuilderDetail.m#L752)): `blackTime = (selectedRow+1) * 5 * 60`

#### `rangeAR` (INTEGER, 미터, 30~100)

[`AppDelegate.m:314`](Classes/TreasureHunterAppDelegate.m#L314):
```objc
rangeAR = [@"30", @"40", @"50", @"60", @"70", @"80", @"90", @"100"]
```

- 기본값: `30`
- 빌더에서 10m 단위 8단계로 선택
- **3가지 런타임 용도** ([`MissionPlay.m`](Classes/MissionPlay.m)):
  1. AR 가시성 ([`ARViewController.m:1219`](Classes/ARViewController.m#L1219)): `radialDistance > rangeAR` 면 AR 표시 안 함
  2. 지뢰 폭발 범위 ([`MissionPlay.m:1469`](Classes/MissionPlay.m#L1469)): `[playerLoc distanceFromLocation:itemLoc] <= rangeAR` 면 폭발
  3. 다크존 영향 범위 ([`MissionPlay.m:2138`](Classes/MissionPlay.m#L2138)): black 아이템의 rangeAR 안에 있는 다른 아이템 가림
- 지도에서는 mine/black 아이템에 한해 `rangeAR` 반경의 원을 그림 ([`MissionPlay.m:906`](Classes/MissionPlay.m#L906))

#### `showType` (TEXT, 4 코드값)

[`MissionItem.h:65-68`](Classes/MissionItem.h#L65-L68):

| 코드 | 매크로 | UI 라벨 | 지도 기본 | AR 기본 | 빌더 노출 |
|:---:|---|---|:---:|:---:|:---:|
| `"1"` | `SHOW_TRANSPARENT` | (Transparent) | ✗ | ✗ | ✗ |
| `"2"` | `SHOW_AR` | "Hidden" | ✗ | ✓ | ✓ |
| `"3"` | `SHOW_MAP` | "Stealth" | ✓ | ✗ | ✓ |
| `"4"` | `SHOW_ALL` | "Normal" | ✓ | ✓ | ✓ |

[`AppDelegate.m:305-306`](Classes/TreasureHunterAppDelegate.m#L305-L306):
```objc
showTypeKeys = [SHOW_ALL, SHOW_AR, SHOW_MAP]      // ← TRANSPARENT 제외
showTypeObjects = [@"Normal", @"Hidden", @"Stealth"]
```

> **중요**: `SHOW_TRANSPARENT` 코드는 헤더에 정의되어 있고 런타임 가시성 판정에서 사용되지만 ([`MissionPlay.m`](Classes/MissionPlay.m) 내 9곳), **빌더 UI에는 노출되지 않는다**. 즉 사용자가 직접 만든 미션은 1/2/3/4 중 2/3/4만 가질 수 있고, 1(Transparent)은 서버에서 다운로드 받은 데이터에만 존재 가능.

가시성 매트릭스 (자세한 내용은 본문 § 부록 "파워업/레이더 가시성 매트릭스" 참고):
- Normal(4): 항상 보임
- Hidden(2): 지도에선 Map Radar/All Radar 필요, AR엔 항상 보임
- Stealth(3): 지도엔 항상 보임, AR엔 Stealth Radar/All Radar 필요
- Transparent(1): 양쪽 모두 레이더 필요

#### `effectiveRange` (INTEGER, 미터, 2~60)

[`AppDelegate.m:313`](Classes/TreasureHunterAppDelegate.m#L313):
```objc
effectiveRange = [@"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"20", @"30", @"40", @"50", @"60"]
```

- 기본값: 0
- 의도: Run End 가 Run Start 와 떨어져 있어야 하는 거리(?). [`MissionBuilder.m:651`](Classes/MissionBuilder.m#L651) 에서 Run End 생성 시 `effectiveRange = 42` 하드코딩 + [`MissionBuilderDetail.m:553`](Classes/MissionBuilderDetail.m#L553) 에서 두 아이템 거리 자동 측정
- **현재 게임 런타임에서 직접 검사하는 코드 없음** (저장만)

#### `effectiveTime` (INTEGER, 초)

- 기본값: 0
- **타임아웃 제한 시간** (Run Start ~ Run End)
- [`MissionPlay.m:880, 1394`](Classes/MissionPlay.m#L880): `timeOutLimitTime = item.effectiveTime`
- 빌더에서 `MM:SS` 형식 입력 후 [`AppDelegate.timeFormat2sec`](Classes/TreasureHunterAppDelegate.m) 로 초 변환
- Run Start (`I_TIMEOUT_S`)와 Run End (`I_TIMEOUT_E`) 둘 다 동일 값으로 저장 ([`MissionBuilder.m:551-552`](Classes/MissionBuilder.m#L551-L552))
- 신규 Swift: `MissionItem.effectiveTime: Int` 동일

#### `itemGame` (INTEGER, 4 코드값)

[`AppDelegate.m:311`](Classes/TreasureHunterAppDelegate.m#L311):

| 값 | 매크로 | 영문 (`appDel_game*`) | 한글 |
|:---:|---|---|---|
| `0` | — | "None" | "없음" |
| `1` | — | "Beginer Level" | "난이도 하" |
| `2` | — | "Normal Level" | "난이도 중" |
| `3` | — | "Senior Level" | "난이도 상" |

- 기본값: `0`
- **`0` = 미니게임 없음** (단순 획득). 1~3 = 미니게임 활성
- **적용 가능 아이템** ([`ARViewController.m:715, 753`](Classes/ARViewController.m#L715)):
  - `simple`(Hint), `radarAR`, `radarMap`, `radarAll`, `radarMine`, `solution`, `mineNoBomb` 가 `itemGame != 0` 이면 미니게임 발동
- **미니게임 메커니즘** ([`GamePlayAlert.m:31-33`](Classes/GamePlayAlert.m#L31-L33)):
  - `type` 이 `arc4random()%2` 로 매번 랜덤하게 0(터치) / 1(흔들기) 결정
  - `level` = `itemGame` 값
- **레벨별 진행도 가산값** ([`GamePlayAlert.m:114-141`](Classes/GamePlayAlert.m#L114-L141)):

| level | 터치 (type=0) per 클릭 | 흔들기 (type=1) per 흔들기 |
|:---:|---:|---:|
| 1 (Beginner) | +6 | +7 |
| 2 (Normal) | +5 | +6 |
| 3 (Senior) | +4 | +5 |
| 그 외 | +7 | +8 |

- timeCount 가 100 도달 → 클리어, 0 → 실패. 1초마다 -1
- 흔들기 임계: 가속도 1.4G

#### `info` (TEXT, 자유 텍스트)

빌더에서 텍스트 입력으로 설정 ([`MissionBuilderDetail.m:258, 277, 308`](Classes/MissionBuilderDetail.m#L258)). 아이템 타입별로 의미가 다름:

| 적용 아이템 | 용도 | 표시 시점 |
|---|---|---|
| Hint | 힌트 메시지. 비어있으면 "Lose the draw!! No hint." | 획득 알림 |
| Start | 시작 안내 메시지 | "Start Item acquired!" 팝업 |
| Run Start | 타임어택 안내 | 획득 알림 |
| Run End | 타임어택 종료 안내 | 획득 알림 |
| Solution | 솔루션 사용 안내 | 획득 알림 |
| 레이더 (각종) | 레이더 효과 설명 | 획득 알림 |
| Coupon | 쿠폰 코드/내용 | 획득 알림 |
| Store | 상품 정보 (key=value 등) | 획득 알림 |

- 신규 Swift: `MissionItem.info: String = ""`. 모든 `setAcquiredAlert` 케이스에서 `if item.info.isEmpty` 체크 후 디폴트 메시지 fallback ([`GameEngine.swift:386-440`](PlaySpot/Game/GameEngine.swift))

#### `relationItemID` (INTEGER)

- Run Start ↔ Run End 짝맞춤 키
- 빌더에서 Run End 추가 시 자동으로 가장 최근 Run Start 의 `itemID` 를 양쪽에 set ([`MissionBuilder.m:649-657`](Classes/MissionBuilder.m#L649-L657))
- 런타임에서 Run Start 획득 시 같은 `relationItemID` 를 가진 Run End 검색 → `effectiveTime` 추출하여 카운트다운 시작
- Run End 획득 시 Run Start 가 활성 상태인지 검증
- **시간 검증 로직**: Run End 의 `effectiveTime` 안에 Run End 도달 못 하면 실패 (`finishRunTimeAlert`)
- 신규 Swift: 동일 (`MissionItem.relationItemID: Int = 0`)

#### `quizSeq` (INTEGER, 빌더 카운터)

- 기본값: `1` ([`MissionItem.m:63`](Classes/MissionItem.m#L63))
- **빌더에서만 사용**: 한 아이템에 여러 퀴즈 변형(`ItemQuiz.seq`)을 추가할 때 다음 seq 번호 부여용
- [`MissionItem.m:79`](Classes/MissionItem.m#L79) `addItemQuiz`: `itemQuiz.seq = self.quizSeq++` (post-increment)
- DB 저장은 안 됨 (모델 메모리 카운터)
- 신규 Swift: 동일 (`MissionItem.quizSeq: Int = 1`) — 단, Swift 포트는 빌더 미구현이라 사용처 없음

#### `rnpSeq` (INTEGER, 미사용)

- 기본값: 0
- **레거시/신규 모두 사용처 없음**. 향후 power-up 아이템 시퀀스용으로 예약된 것으로 추정
- DAO 저장 컬럼에도 없음 ([`MissionItemDao.m`](Classes/Dao/MissionItemDao.m) 의 select/insert 컬럼 목록에 미포함)

#### `itemQuizzes` (관계, 별도 테이블)

- `MissionItem` 자체 컬럼이 아닌 1:N 관계 (배열)
- 별도 `ItemQuiz` 테이블 (`missionID`, `itemID`, `seq` PK)
- `MissionItem.itemType == I_QUIZ`(40) 또는 `I_QUIZ20`(41) 일 때만 의미
- 신규 Swift: `MissionItem.quizzes: [ItemQuiz] = []` (디코딩 시 별도 그룹핑, [`GameEngine.swift:62-67`](PlaySpot/Game/GameEngine.swift#L62-L67))

---

### 빌더 picker → DB 저장값 매핑 한눈에 보기

| picker 컬럼 | 노출 옵션 수 | 저장 형식 | 저장 변환 |
|---|---:|---|---|
| `itemType` | 16 | TEXT 코드 | picker 키 그대로 |
| `mandatory` | 2 | INT (0/1) | 인덱스 그대로 |
| `showType` | 3 | TEXT 코드 | picker 키 그대로 (TRANSPARENT 제외) |
| `rangeAR` | 8 | INT (m) | 라벨 → intValue |
| `effectiveRange` | 14 | INT (m) | 라벨 → intValue |
| `effectiveTime` | (텍스트 입력) | INT (초) | `MM:SS` → `timeFormat2sec` |
| `itemGame` | 4 | INT (0~3) | 인덱스 그대로 |
| `blackCnt` | 10 | INT | 라벨 → intValue |
| `blackTime` | 6 | INT (초) | (인덱스+1) × 300 |
| `info` | (텍스트 입력) | TEXT | 그대로 |
| `relationItemID` | (자동) | INT | Run End 추가 시 자동 산출 |

### 컬럼 사용 빈도 vs 미사용 컬럼

| 분류 | 컬럼 |
|---|---|
| **항상 사용** | missionID, itemID, mandatory, itemType, latitude, longitude, rangeAR, showType |
| **타입별 조건부 사용** | effectiveTime (Run S/E), relationItemID (Run S/E), info (Hint/Start/...), itemGame (Hint/Radar/Solution/Defense), itemQuizzes (Quiz) |
| **저장은 되지만 런타임 미참조** | blackCnt (DAO 저장만), blackTime (DAO 저장만), effectiveRange (저장+빌더UI만) |
| **완전 미사용** | rnpSeq |

### Swift 포트와의 차이점

| 컬럼 | 레거시 ObjC 기본값 | 신규 Swift 기본값 ([`MissionItem.swift`](PlaySpot/Models/MissionItem.swift)) | 비고 |
|---|---|---|---|
| `mandatory` | `MANDATORY_N`(0) | `.optional` (`MandatoryFlag` enum) | 동일 |
| `itemType` | nil | `.simple` (`ItemType` enum) | Swift 가 `.simple` 디폴트 |
| `rangeAR` | 30 | 30 | 동일 |
| `blackCnt` | 5 | 5 | 동일 |
| `blackTime` | 300 | 300 | 동일 |
| `quizSeq` | 1 | 1 | 동일 |
| `showType` | nil | `.all` (`ShowType` enum) | Swift 가 `.all`(Normal) 디폴트 |
| `info` | nil | `""` | 동일 의미 |
| `rnpSeq` | 0 | 0 | 둘 다 미사용 |

> Swift 포트는 enum 기반 type-safe 디코딩으로 nil 가능성을 제거. JSON 디코딩 시 누락 필드는 위 디폴트가 적용됨 ([`MissionItem.swift:52-72`](PlaySpot/Models/MissionItem.swift#L52-L72)).

---

## 부록: AR 화면 아이템 가시성 / 획득 가능성 정밀 분석

> 본 부록은 "AR 화면에서 획득 불가능한 아이템이 있는가", "start 획득 전에 더 가까운 다른 아이템이 표시되는가", "start 획득 후 표시 순서/획득 불가 로직" 질문에 대한 정밀 분석이다. 레거시 [Classes/ARViewController.m](Classes/ARViewController.m)와 신규 [PlaySpot/AR/ARGameView.swift](PlaySpot/AR/ARGameView.swift) / [PlaySpot/Game/GameEngine.swift](PlaySpot/Game/GameEngine.swift)를 함께 비교한다.

### A. 핵심 원칙 — AR 화면에는 "가장 가까운 1개"만 표시된다

레거시 [ARViewController.m:1487-1546](Classes/ARViewController.m#L1487-L1546)에서 `minDistItem` 을 계산해 후보 중 거리 최소 한 개만 선정하고, 이어지는 [1549-1613](Classes/ARViewController.m#L1549-L1613) 의 두 번째 루프에서 `minDistItem.annoItem == coordinate.annoItem` 인 경우에만 viewToDraw를 화면에 추가한다. 즉 AR 화면에는 **항상 단 하나의 아이템 아이콘**만 그려진다.

Swift 포트 [ARGameView.swift:201-204](PlaySpot/AR/ARGameView.swift#L201-L204) 도 `visibleItems`가 nearest 1개만 반환하도록 같은 동작을 구현한다 — `return [nearest]`.

> 이 사실은 모든 후속 분석의 전제다. "여러 아이템이 동시에 떠 있을 텐데..."라는 가정은 이 게임의 AR 모델에서 잘못된 가정이다.

---

### B. start 획득 전(`missionStarted == false`)의 AR 표시 규칙

#### B-1. 레거시 동작 — **START 만** 표시 (END 도 제외됨)

[ARViewController.m:1496-1547](Classes/ARViewController.m#L1496-L1547) 의 minDistItem 선정 루프는 **2단계 필터** 구조다.

**1단계 — outer filter ([1498-1502](Classes/ARViewController.m#L1498-L1502))** — START AND END 둘 다 통과:
```objc
for (ARCoordinate *coordinate in ar_coordinates) {
    if(([coordinate.annoItem.missionItem.itemType isEqualToString:I_START] == NO) &&
       ([coordinate.annoItem.missionItem.itemType isEqualToString:I_END] == NO) &&
       (caller.missionStarted == NO)) {
        continue;   // ← start/end 외엔 스킵 (END는 통과)
    }
    ...
```

**2단계 — inner branch ([1510-1544](Classes/ARViewController.m#L1510-L1544))** — `missionStarted == NO` 분기는 **START 만** 받음:
```objc
if(caller.missionStarted == YES) {
    ... // END는 mandatory > 1 체크 후 candidate (post-start 전용)
    minDistItem.annoItem = coordinate.annoItem;
}
else if ([coordinate.annoItem.missionItem.itemType isEqualToString:I_START] == YES)
{
    // ← pre-start 일 때 오직 START 만 minDistItem 으로 등록됨
    minDistItem.annoItem = coordinate.annoItem;
}
// END + missionStarted == NO → 어느 분기에도 매칭 안 됨 → minDistItem 갱신 안 됨
```

**결과**: pre-start 시 END 가 START 보다 가까워도 `minDistItem` 은 START 로 유지된다. AR 두 번째 루프 ([1549-1613](Classes/ARViewController.m#L1549-L1613)) 는 `minDistItem.annoItem == coordinate.annoItem` 인 경우에만 그리므로 END는 화면에 안 그려진다.

> 참고: [viewportContainsCoordinate:1222-1226](Classes/ARViewController.m#L1222-L1226) 도 START/END 둘 다 통과시키지만, 이 함수는 "뷰포트 안에 있는가"만 판단하고 실제 그리기는 위의 2단계 필터를 통과해 minDistItem 으로 선정된 항목만 한다.

**최종 결론**: 레거시 AR 화면은 start 획득 전에 **오직 START 아이템 1개만** 표시한다. quiz/hint/radar 는 물론 END 도 표시되지 않는다.

#### B-2. start 보다 가까운 mine — 폭발 처리

mine 은 후보 풀에서는 빠지지만 [viewportContainsCoordinate:1232-1240](Classes/ARViewController.m#L1232-L1240) 에서 **별도 분기**로 처리된다:

```objc
if([item.itemType isEqualToString:I_MINE]){
    if (coordinate.radialDistance <= item.rangeAR) {
        [caller mineBlast:item];   // ← 표시 없이 즉시 폭발
        ...
    }
}
```

따라서 start 미획득 상태에서도 mine 의 rangeAR 안에 들어가면 폭발은 발생한다. mine 자체는 AR에 그려지지 않으며 "획득" 대상도 아니다.

#### B-3. shake-to-acquire 의 2차 방어선

[ARViewController.m:492-496](Classes/ARViewController.m#L492-L496) `getItemAnimation` 안에서 흔들기로 획득을 시도할 때도 한 번 더 검사:

```objc
outstandingItem = minDistItemInView.annoItem.missionItem;
if([outstandingItem.itemType isEqualToString:I_START] == NO) {
    if(caller.missionStarted == NO) {
        return;   // ← 흔들어도 무시
    }
}
```

#### B-4. Swift 포트 매칭 여부

[ARGameView.swift:220-223](PlaySpot/AR/ARGameView.swift#L220-L223):
```swift
// 미션 시작 전엔 start / end 만 허용
if !engine.missionStarted, item.itemType != .start, item.itemType != .end {
    continue
}
```

[ARGameView.swift:226](PlaySpot/AR/ARGameView.swift#L226) — mine/black 영구 제외:
```swift
if item.itemType == .black || item.itemType.isMine { continue }
```

**❌ B-1 동작 불일치**: Swift 는 START / END 둘 다 후보로 잡고 거리 최소를 그대로 nearest 로 선정한다. 따라서 pre-start 에 END 가 START 보다 가까우면 **END 가 표시된다** — 레거시는 START 만 표시. **수정 필요.**

올바른 Swift 코드:
```swift
if !engine.missionStarted, item.itemType != .start { continue }   // ← START 만
```

**⚠️ B-2 (mine 자동 폭발) 차이점**: Swift `nearestVisibleItem` 은 mine 을 단순 `continue` 로 스킵만 한다. 레거시처럼 "AR 화면을 켜고 mine 의 rangeAR 안에 있으면 자동 폭발" 을 트리거하는 코드는 [ARGameView](PlaySpot/AR/ARGameView.swift) 어디에도 없다. mine 폭발은 Map 화면의 `MissionPlayView.handleItemTap` → `engine.handleMineBlast(item:)` 경로로만 실행된다. **AR 화면에 진입한 상태에서 자동 mine 폭발은 발생하지 않는다.** (의도적인지 누락인지 확인 필요.)

---

### C. start 획득 후(`missionStarted == true`)의 표시 규칙

#### C-1. 레거시 minDistItem 후보 필터 ([ARViewController.m:1504-1547](Classes/ARViewController.m#L1504-L1547))

후보가 되려면 모두 통과해야 한다:

| 조건 | 코드 위치 | 설명 |
|---|---|---|
| 미획득 (`dicItemEnd[id] != "Y"`) | 1505 | 이미 먹은 건 제외 |
| `itemType != I_MINE` | 1506 | mine 은 표시 후보 아님 |
| `itemType != I_BLACK` | 1507 | black 도 제외 |
| `itemType != I_TIMEOUT_S` 이거나 `isTimeOutS == 0` | 1522-1526 | 이미 타임아웃 진행 중이면 또 다른 timeoutStart 숨김 |
| `itemType != I_END` 이거나 `mandatory ≤ 1` | 1527-1530 | end 는 다른 필수가 1개 이하로 줄어야 후보 |

> ⚠️ **레거시의 "주석 처리된" ShowType 필터** ([1512-1521](Classes/ARViewController.m#L1512-L1521)):
> ```objc
> if(caller.missionStarted == YES)
> {
>     /*
>      //아이템이 ALL 투명이거나 AR 투명일경우 AR 레이더, all 레이더 없을경우 skip
>      if (([coordinate.annoItem.missionItem.showType isEqualToString:SHOW_TRANSPARENT] ||
>      [coordinate.annoItem.missionItem.showType isEqualToString:SHOW_MAP]) &&
>      ([caller.dicRnPTaken valueForKey:I_RADAR_AR] == nil &&
>      [caller.dicRnPTaken valueForKey:I_RADAR_ALL] == nil ))
>      {
>      continue;
>      }
>      */
>     ...
> }
> ```
> 이 ShowType skip 로직은 **주석 처리되어 비활성**이다. 즉 레거시도 `transparent`/`mapOnly` 아이템을 후보에서 제외하지 않는다 — 대신 "후보로는 선정되지만 그릴 때 아이콘 대신 'Hidden' 안내 문구로 대체"하는 방식([1622-1638](Classes/ARViewController.m#L1622-L1638))을 쓴다:
> ```objc
> if (([minDistItem.annoItem.missionItem.showType isEqualToString:SHOW_TRANSPARENT] ||
>      [minDistItem.annoItem.missionItem.showType isEqualToString:SHOW_MAP]) &&
>     ([caller.dicRnPTaken valueForKey:I_RADAR_AR] == nil &&
>      [caller.dicRnPTaken valueForKey:I_RADAR_ALL] == nil ))
> {
>     [ar_infoView setTitle:NSLocalizedString(@"ar_clear1", nil) forState:UIControlStateNormal];
>     [ar_infoView1 setTitle:NSLocalizedString(@"ar_clear2", nil) forState:UIControlStateNormal];
>     [radianItem removeFromSuperview];   // ← 레이더 화살표도 숨김
>     [radianPhone removeFromSuperview];
> }
> ```

#### C-2. Swift 포트 차이점 — ShowType "Hidden 문구 대체" 누락

Swift [ARGameView.swift:206-251](PlaySpot/AR/ARGameView.swift#L206-L251) `nearestVisibleItem` 은 ShowType 을 **전혀 보지 않는다**:

| ShowType | 레이더 보유 | 레거시 AR | Swift AR |
|---|---|---|---|
| `all`(4) | — | 아이콘 표시 | 아이콘 표시 ✓ |
| `arOnly`(2) | — | 아이콘 표시 | 아이콘 표시 ✓ |
| `mapOnly`(3) | radarAR / radarAll 없음 | "Hidden" 문구 + 화살표 숨김 | **아이콘 그대로 노출** ❌ |
| `transparent`(1) | radarAR / radarAll 없음 | "Hidden" 문구 + 화살표 숨김 | **아이콘 그대로 노출** ❌ |
| `mapOnly`/`transparent` | radarAR / radarAll 보유 | 아이콘 표시 | 아이콘 표시 ✓ |

> ⚠️ **버그 후보**: Swift 포트는 `Stealth(mapOnly)` / `Hidden(transparent)` 아이템이 가까이 있을 때 레이더 없이도 AR에 그대로 그려진다. 레거시는 같은 상황에서 화면에 "Hidden — radar required" 안내만 띄우고 실제 위치는 가렸다. (현재 Swift 동작이 더 관대함 → 게임 밸런스 깨짐 소지.)

#### C-3. 두 코드 모두 일치하는 "표시는 되지만 획득 불가" 케이스

엄밀히 말하면 AR 화면에 표시된 아이템이 **곧 획득 가능**은 아니다. 표시 후 획득 진행은 다음을 통과해야 한다:

1. 사용자가 아이콘을 탭하거나 폰을 흔든다.
2. Swift: [MissionPlayView.handleItemTap](PlaySpot/Views/MissionPlay/MissionPlayView.swift#L148-L164) → `ItemInteraction.isInRange` (rangeAR 내) → `ItemInteraction.interactionType` 분기.
3. interactionType 별 처리:
   - `.quiz` → `QuizView` 시트 표시. **퀴즈 정답 맞추기 전까지 획득 안 됨.**
   - `.miniGame` → `MiniGameView` 시트 표시. **미니게임 클리어 전까지 획득 안 됨.**
   - `.mineExplode` → `engine.handleMineBlast(item:)` (보호 아이템 없으면 폭발).
   - `.darkEffect` → `acquireItem` 으로 처리되지만 black 은 nearest 후보에서 이미 제외됨.
   - 그 외 → `engine.acquireItem(item)` 즉시 획득.

따라서 AR에 표시되는 1개의 아이템이 quiz/miniGame 이라면, 사용자는 그 아이템을 **봐도 흔들기/탭만으로는 절대 획득 못 한다.** 별도 UI(퀴즈/미니게임)를 통과해야 한다.

> ⚠️ AR 화면에서 흔들기로 quiz / miniGame 을 띄우는 동작이 [ARGameView.handleShake](PlaySpot/AR/ARGameView.swift#L90-L102) 에 명시적으로 구현되어 있지 않다. `onItemTapped?(item)` 만 호출하므로 결국 `MissionPlayView.handleItemTap` 의 분기를 타게 되는데, 이 핸들러는 `appState.locationService.currentLocation` 을 다시 읽어 `ItemInteraction.isInRange` 검사를 한 번 더 한다. 즉 AR이 "표시했다 = 획득 가능"이 아니라, 흔들기 → tap 핸들러 → 거리 재검사 → 거리 OK 면 quiz/miniGame 시트 또는 즉시 획득. AR 표시 후 시트 표시까지 한 단계 더 거치는 셈.

---

### D. AR에서 절대 획득 불가능한 아이템 (의도적 설계)

| 아이템 타입 | AR 표시 여부 | 사유 |
|---|---|---|
| `mine`(55) | 표시 안 됨 | 거리 진입 시 자동 폭발(레거시) — 획득이 아닌 피격 대상. Swift는 폭발도 발생 안 함(누락) |
| `mineNoBomb`(61) | 표시 안 됨 | `.isMine == true` 로 분류되어 nearest 후보에서 제외. 지도에서만 획득 가능 |
| `black`(56) | 표시 안 됨 | unconditionally `continue`. dark 영역은 시각적 효과일 뿐 획득 대상 아님 |
| `end`(48), 필수 잔여 > 1 | 표시 안 됨 | 모든 필수 아이템 처리 후에만 노출 |
| `timeoutStart`(42), 이미 진행 중 | 표시 안 됨 | 중복 트리거 방지 |
| `start`(49), 미션 진행 중 | 표시 안 됨 | 이미 획득됨(`dicItemEnd == "Y"`) → 미획득 필터에서 제외 |

> 즉 mine, mineNoBomb, black 은 **AR 흔들기로 절대 획득되지 않는 아이템들**이다. mineNoBomb (Defence) 는 의외로 AR에 안 뜨는데, `ItemType.isMine` 정의에 포함되기 때문이다 ([ItemType.swift:98](PlaySpot/Models/ItemType.swift#L98)):
> ```swift
> var isMine: Bool { self == .mine || self == .mineNoBomb }
> ```
> 이건 레거시 [ARViewController.m:1506](Classes/ARViewController.m#L1506) 의 `I_MINE` 단독 체크와 비교하면 Swift가 **더 엄격**하다. 레거시는 mineNoBomb 를 nearest 후보에서 제외하지 않으므로 AR에서 흔들어 획득할 수 있다. Swift 는 같은 케이스에서 후보 자체에서 빠진다 → **mineNoBomb (방어 아이템) 을 AR에서 획득 불가능.** 지도에서만 가능.
>
> ⚠️ 이는 레거시와 행동 차이이며 의도된 변경인지 확인 필요.

---

### E. 지도(Map)에서의 추가 가시성 규칙 (참고)

질문에 직접 포함되진 않았지만, "표시 순서" 측면에서 지도는 AR과 다른 규칙을 가진다.

#### E-1. 신규 Swift `GameEngine.shouldShowOnMap` ([GameEngine.swift:365-384](PlaySpot/Game/GameEngine.swift#L365-L384))

```swift
func shouldShowOnMap(_ item: MissionItem) -> Bool {
    // 1) 미션 시작 전엔 start 만 표시
    if !missionStarted, item.itemType != .start { return false }
    // 2) end 는 필수 잔여 > 1 이면 숨김
    if item.itemType == .end, mandatoryRemaining > 1 { return false }
    // 3) mine 은 radarMine 이 있을 때만
    if item.itemType.isMine { return hasRadarMine }
    // 4) ShowType + 레이더 조합으로 판정
    return item.showType.isVisibleOnMap(hasRadarMap: hasRadarMap, hasRadarAll: hasRadarAll)
}
```

#### E-2. 레거시 지도 — Dark Zone 가림 효과 ([MissionPlay.m:2128-2157](Classes/MissionPlay.m#L2128-L2157))

레거시는 "black 아이템의 rangeAR 원 안에 있는 다른 아이템은 지도에서 아이콘이 nil 처리되어 가려짐" 로직이 있다:

```objc
for (CircleItem *circleItem in self.mapOverlays)
{
    if([circleItem.missionItem.itemType isEqualToString:I_BLACK] &&
       /* black 미획득 */)
    {
        if ([circleItemLoc distanceFromLocation:tmpItemLoc] <= circleItem.missionItem.rangeAR &&
            ![_tmpItem.missionItem.itemType isEqualToString:I_START])
        {
            if ([_tmpItem.missionItem.itemType isEqualToString:I_BLACK]) { break; }
            else {
                imgFile = nil;                       // ← 아이콘 숨김
                customPinView.canShowCallout = NO;
                break;
            }
        }
    }
}
```

> ⚠️ Swift `shouldShowOnMap` 에는 이 "다크존 안에 들어간 다른 아이템 가리기" 로직이 **누락**되어 있다. dark004 미션 등에서 dark 원 내부의 아이템이 레거시처럼 사라지지 않고 그대로 보이게 된다.

---

### F. 정리 — 발견한 차이점 요약

| # | 항목 | 레거시 | Swift 포트 | 영향 |
|---|---|---|---|---|
| F-1 | start 미획득 시 AR 표시 | **START 만** (END 도 제외) | START + END 둘 다 후보 → END 가 더 가까우면 END 표시 | ❌ 행동 차이 |
| F-2 | AR 화면 mine 자동 폭발 | rangeAR 진입 시 자동 `mineBlast:` | `.onChange(currentLocation)` 으로 `detectMineBlast()` → `onItemTapped(mine)` 라우팅하여 폭발 + AR 닫기 (`mineBlastTriggered` 플래그로 중복 방지) | ✅ 적용 |
| F-3 | AR 에서 mineNoBomb(Defence) 흔들기 획득 | 가능 | 후보 제외 조건을 `isMine` → `== .mine` 으로 좁힘 (mineNoBomb 후보 포함) | ✅ 적용 |
| F-4 | Stealth/Hidden 아이템 (radar 없음) AR 표시 | 후보로 잡되 "Hidden" 안내 문구로 대체 + 화살표 숨김 | (b) 방식: `nearestItemIsHiddenByShowType` 컴퓨티드 프로퍼티가 nearest 의 ShowType + 레이더 보유를 검사하여 `ARItemView(isHiddenByShowType:)` 분기로 "Hidden — Stealth Radar required" 플레이스홀더 렌더, `ARRadarView(suppressArrows:)` 로 phone/item 화살표 둘 다 숨김. 흔들기 획득은 정상 동작 | ✅ 적용 (방식 b) |
| F-5 | end 아이템 표시 (필수 잔여 > 1) | 숨김 | 숨김 | ✅ 일치 |
| F-6 | timeoutStart 중복 표시 | 숨김 | 숨김 | ✅ 일치 |
| F-7 | 다크존 내 아이템 지도 가리기 | 지원 | `GameEngine.shouldShowOnMap` 에 `isInsideUnacquiredDarkZone(_:)` 헬퍼 추가, 미획득 black 아이템 원 안의 다른 아이템 (start, black 자신 제외) 은 지도 숨김 | ✅ 적용 |
| F-8 | quiz / miniGame "표시 = 획득 아님" | 별도 UI 필수 | 별도 UI 필수 (`MissionPlayView.handleItemTap` 분기) | ✅ 일치 |
| F-9 | shake 0.5초 쿨다운 | 있음 | 있음 (`shakeAcquireCooldown`) | ✅ 일치 |
| F-10 | nearest 1개만 표시 | 1개 | 1개 (`visibleItems = [nearest]`) | ✅ 일치 |

### G. 권장 후속 작업

1. **F-2 (mine 자동 폭발 누락)**: [ARGameView](PlaySpot/AR/ARGameView.swift) 의 `nearestVisibleItem` 또는 별도 onChange 훅에서 mine 들의 거리 검사 후 `engine.handleMineBlast(item:)` 트리거. 레거시 의도 복원.
2. **F-3 (mineNoBomb AR 획득 불가)**: nearest 후보 필터를 `item.itemType == .mine` 로만 좁히거나, `isMine` 체크를 nearest 단계가 아닌 인터랙션 단계로 옮긴다. 의도 결정 필요.
3. **F-4 (Stealth ShowType 무시)**: `nearestVisibleItem` 에 `item.showType.isVisibleInAR(hasRadarAR:hasRadarAll:)` 체크 추가. 레이더 없는 stealth 후보는 후보군에서 빼거나 ARItemView 가 "Hidden" 플레이스홀더를 그리도록 조건부 분기.
4. **F-7 (다크존 가리기)**: `GameEngine.shouldShowOnMap` 에 black 아이템 + 거리 검사 추가. dark004 미션 시뮬레이터 검증으로 동작 확인.

이 4개 차이점은 게임플레이 의도/밸런스에 직접 영향을 주므로 의도된 변경인지 확인 후 동기화해야 한다.
