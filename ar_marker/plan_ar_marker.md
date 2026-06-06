# plan_ar_marker.md

# Image Target AR PoC 실행 계획
## "보물찾기 적합성 검증을 위한 2주 미니 프로젝트"

> 본 문서는 `../ar_marker.md` (Image Target AR 보물찾기 가이드) 를 바탕으로 한 **PoC (Proof of Concept) 실행 계획서** 다.
> 본격 개발 (3개월·1명) 에 들어가기 전 **2주 안에 본질적 위험을 검증** 한다.

---

## 0. 한 줄 요약

> **2주, 개발자 1명. iPhone 1대 + 마커 5장으로 "이 기술이 PlaySpot 보물찾기에 적합한가" 답을 얻는다.**

### 작업 폴더

```
ar_marker/                  ← 본 PoC 의 모든 산출물·코드·데이터가 여기에 모임
├── plan_ar_marker.md       (본 문서)
├── flutter_ar_poc/         (PoC 앱 — 별도 Flutter 프로젝트)
├── markers/                (마커 사진 5장 + 메타 JSON)
├── assets/                 (보물상자 .usdz/.glb)
├── data/                   (인식률 측정 CSV)
├── interviews/             (사용자 인터뷰 노트 5개)
├── demo_30s.mp4            (데모 영상)
├── report_poc.md           (분석 리포트)
└── decision.md             (Go/Pivot/Stop 권고)
```

PoC 종료 시 위 디렉토리 전체가 의사결정 패키지가 된다.

---

## 1. PoC 목적

### 1-1. 검증하고 싶은 핵심 가설 5개

| 번호 | 가설 | 검증 방법 |
|---|---|---|
| H1 | ARKit/ARCore Image Target 은 **서촌 같은 실외 환경** 에서 안정적으로 작동한다 | 실제 서촌 골목 5곳에서 마커 인식 시도 100회, 성공률 측정 |
| H2 | **외국인 관광객 폰** (다양한 iPhone·Galaxy 모델) 에서 무리 없이 동작한다 | iPhone 12, iPhone SE 3rd, Galaxy S22, Galaxy A54 4종 테스트 |
| H3 | 보물 발견 순간의 **AR 임팩트가 SNS 공유 욕구를 자극한다** | 사용자 5명에게 체험 후 "공유하고 싶나" 인터뷰 |
| H4 | Flutter 통합이 **3개월 본격 개발 전 막힘 없이 가능하다** | Method Channel 로 1개 마커 인식 → Flutter UI 에 결과 전달 |
| H5 | **마커 운영 비용** (인쇄·교체) 이 감당 가능 수준이다 | 마커 5종 제작·설치 시간·비용 실측 |

### 1-2. PoC 가 답하지 않는 것

| 미검증 영역 | 이유 | 본격 단계에서 검증 |
|---|---|---|
| 다중 마커 동시 인식 | 핵심 가설 아님 | Phase 2 |
| AR Cloud Anchor | 고급 기능 | Phase 3 |
| 백엔드 마커 DB 동기화 | 인프라 작업 | Phase 2 |
| 보물찾기 게임 룰 (단서·진행도) | 메카닉 검증 후 | Phase 2 |
| Web AR | 모바일 우선 | 별도 PoC |

---

## 2. 범위

### 2-1. In Scope ✅

- iPhone 네이티브 (Swift + ARKit) 단일 앱 빌드
- Android 네이티브 (Kotlin + ARCore) 단일 앱 빌드
- 마커 5종 등록 (서촌 실제 간판 또는 자체 인쇄)
- 마커 인식 시 단순 AR 콘텐츠 1종 (보물상자 3D 모델)
- Flutter MethodChannel 통합 (최소 1개 마커만)
- 실외/실내·주간/야간·날씨 다양 조건 테스트
- 디바이스 4종 호환성 측정

### 2-2. Out of Scope ✗

- 백엔드 서버 (모든 마커 DB 는 앱에 번들)
- 사용자 인증·계정·진행도 저장
- 다양한 AR 콘텐츠 (보물상자 1종만)
- 디자이너 도구 (마커 등록은 개발자가 코드로)
- 게임 룰 (단순 인식 → 표시만)
- 다국어 UI (영어만)
- 분석·로깅 시스템 (수기 기록)

---

## 3. 기술 스택

### 3-1. 결정 사항 — Flutter 우선 + 네이티브 폴백

| 항목 | 1순위 선택 | 폴백 (48h 게이트 실패 시) |
|---|---|---|
| **Flutter AR 플러그인** | **`ar_flutter_plugin_plus: ^1.1.3`** (xinix.tech, Image Tracking 지원) | 네이티브 MethodChannel |
| iOS AR 엔진 | ARKit 5 (iOS 15+) — 플러그인이 내부 호출 | ARKit 5 직접 (Swift 5.9) |
| Android AR 엔진 | ARCore 1.40+ — 플러그인이 내부 호출 | ARCore 1.40+ 직접 (Kotlin) |
| 3D 모델 포맷 | iOS: `.usdz`, Android: `.glb` | 동일 |
| 마커 등록 | 플러그인 `referenceImages` API | iOS: Xcode AR Resource Group / Android: `augmented_image_database` |

### 3-2. ar_flutter_plugin_plus 선택 근거

| 항목 | 값 |
|---|---|
| pub.dev 점수 | 140 / 160 |
| 마지막 의미있는 업데이트 | 4개월 전 (활성) |
| 퍼블리셔 | xinix.tech (verified) |
| Image Tracking 지원 | ✅ 명시적 + 공식 예제 |
| 플랫폼 | iOS + Android 동시 |
| 의존성 | flutter, geolocator ^14.0.2, json_annotation ^4.9.0, permission_handler ^12.0.1, vector_math ^2.2.0 |

원본 `ar_flutter_plugin` (CariusLars) 대비:
- 활성 유지보수 (원본은 2024년 정체)
- Image Tracking 명시 지원
- 검증된 퍼블리셔 (개인 → 회사)

### 3-3. ⚠️ 알려진 함정 — Android ARCore 트래킹 버그

플러그인 문서가 명시: "a bug in the ARCore library on Android which interferes with the tracking functionality on some devices."

**대응**: Android 빌드 시 `android/app/build.gradle` 에서
```gradle
android {
  buildTypes {
    debug {
      debuggable false  // ← 트래킹 안정성 확보
    }
  }
}
```

→ Day 1 환경 셋업 시 미리 적용 권장. 모르면 "왜 디버그에서 인식 끊기지?" 한참 헤맴.

### 3-4. ⚠️ 의존성 충돌 회피 — 별도 프로젝트로 PoC

ar_flutter_plugin_plus 가 요구하는 `geolocator ^14.0.2` 가 PlaySpot 본 앱의 `geolocator ^13.0.0` 과 메이저 충돌. **PoC 는 작업 폴더 `ar_marker/` 안에 별도 Flutter 프로젝트로 진행**.

```
ar_marker/
└── flutter_ar_poc/        ← PoC 전용 프로젝트
    ├── pubspec.yaml       (ar_flutter_plugin_plus + geolocator ^14)
    └── lib/main.dart

flutter_ar_spike/          ← 기존 PlaySpot (건드리지 않음)
```

PoC 검증 통과 후 본격 개발 시 의존성 정리.

### 3-5. 평가 후 채택 안 한 선택지

| 후보 | 미채택 이유 |
|---|---|
| 원본 ar_flutter_plugin (CariusLars) | 2024년 정체, _plus 가 모든 면에서 우위 |
| arkit_plugin + arcore_flutter_plugin 조합 | _plus 가 막히면 보통 둘 다 비슷한 한계 — 바로 네이티브로 가는 게 효율적 |
| Unity AR Foundation | 학습 곡선 + 빌드 용량 +200MB |
| 8th Wall (Web AR) | 월 $99, 별도 PoC 필요 |
| Niantic Lightship | 권한 승인 절차 |

---


## 4. 단계별 실행 계획

### Week 1 — Flutter PoC 구축 (48h 게이트 룰)

#### 핵심 룰: **Day 1~2 가 48시간 게이트**

```
Day 1: Flutter + ar_flutter_plugin_plus 로 iOS 마커 1장 인식 시도
Day 2: Android 추가 시도 (+ debuggable false)
       ↓
   ━━ 48h 게이트 ━━
   iOS·Android 둘 다 마커 인식 OK?
       ↓
   Yes → Day 3~5 Flutter 단독 진행 (Track A)
   No  → Day 3~5 네이티브 MethodChannel 전환 (Track B)
```

→ 어느 경로든 Week 1 마지막 (Day 5) 에 4대 디바이스 PoC 빌드 완성이 목표.

---

#### Day 1 (월) — 환경 셋업 + Flutter iOS 시도

| 시간 | 작업 |
|---|---|
| 오전 | Xcode 15 / Android Studio 최신화, iPhone 12·SE 3rd, Galaxy S22·A54 4대 확보 |
| 오전 | 별도 Flutter 프로젝트 (`flutter_ar_poc`) 생성, `ar_flutter_plugin_plus: ^1.1.3` 추가 |
| 오후 | iOS 빌드 + 플러그인 공식 Image Tracking 예제 동작 확인 |
| 오후 | 테스트용 마커 1장 (인쇄 PVC) 으로 iPhone 12 인식 검증 |
| 산출 | iPhone 12 에서 마커 1장 인식 ✓ |

```dart
// 핵심 Flutter 코드 골격 (ar_flutter_plugin_plus)
ARView(
  onARViewCreated: (arSessionManager, arObjectManager, arAnchorManager, arLocationManager) {
    arSessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: false,
    );
    arObjectManager.onInitialize();

    // Image Tracking 활성화
    arSessionManager.addReferenceImagesGroup('ARMarkers');
    arSessionManager.onImageDetected = (imageName) {
      print('Marker detected: $imageName');
      // 보물상자 3D 모델 합성
      arObjectManager.addNode(ARNode(
        type: NodeType.localGLTF2,
        uri: 'assets/treasure_chest.glb',
        scale: Vector3(0.2, 0.2, 0.2),
      ));
    };
  },
)
```

#### Day 2 (화) — Android 빌드 + 48h 게이트 결정

| 시간 | 작업 |
|---|---|
| 오전 | `android/app/build.gradle` 에 `debuggable false` 적용 (ARCore 트래킹 버그 회피) |
| 오전 | Android 빌드 + Galaxy S22 에서 동일 마커 인식 검증 |
| 오후 | iOS·Android 둘 다 작동? → **48h 게이트 결정** |
| 오후 | ✅ 둘 다 OK → Track A 확정 (Day 3 부터 Flutter 단독) |
| 오후 | ❌ 막힘 → Track B 전환 (Day 3 부터 네이티브 MethodChannel) |
| 산출 | 게이트 결정 + 다음 3일 경로 확정 |

---

### Track A — Flutter 단독 진행 **(1순위 · 기본 경로)**

> 48h 게이트 통과 시 이 경로로 Day 3~5 진행. 가장 빠르고 본격 개발 연결성 좋음.

#### Day 3 (수) — 마커 5종 등록 + 서촌 답사

| 시간 | 작업 |
|---|---|
| 오전 | 서촌 답사 — 후보 간판 10곳 사진 촬영 (정면·균일 조명) |
| 오후 | 5장 선정 → `assets/markers/` 에 배치 + Flutter 측 referenceImages 등록 |
| 오후 | 5마커 동시 인식 테스트 (iPhone 12) |
| 산출 | 5마커 모두 인식 + 각각 보물상자 표시 |

#### Day 4 (목) — 디바이스 호환성 + 폴리시

| 시간 | 작업 |
|---|---|
| 오전 | iPhone SE 3rd + Galaxy A54 빌드 테스트 |
| 오후 | 사운드 (보물 발견 효과음) + 햅틱 (HeavyImpact) + UI (점수·다음 단서) |
| 산출 | 4 디바이스 모두 동작 |

#### Day 5 (금) — 빌드 안정화 + 테스트 준비

| 시간 | 작업 |
|---|---|
| 오전 | TestFlight (iOS) + APK 직접 배포 (Android) |
| 오후 | 인식률 자동 로깅 (성공·실패·지연 측정) 코드 추가 |
| 산출 | 4 디바이스 PoC 빌드 완성 — Week 2 실증 준비 완료 |

---

### Track B — 네이티브 MethodChannel 전환 **(2차 폴백 · Track A 실패 시에만)**

> ⚠️ **이 경로는 2차다.** Day 1~2 의 48h 게이트에서 Flutter 플러그인 시도가 막혔을 때만 진입.
> Track A 로 진행 중이면 본 섹션은 무시. 기존 네이티브 계획을 참고 자료로 보존.

#### Day 3 (수) — 마커 5종 촬영·등록 (네이티브 도구)

| 시간 | 작업 |
|---|---|
| 오전 | 서촌 답사 — 후보 간판 10곳 사진 촬영 |
| 오후 | 5장 선정 → Xcode AR Resource Group 등록 + ARCore `augmented_image_database` 도구로 `.imgdb` 생성 |
| 산출 | 마커 5종 등록된 네이티브 리소스 |

#### Day 4 (목) — iOS Swift + ARKit 구현

| 시간 | 작업 |
|---|---|
| 종일 | Swift 프로젝트 + ARKit Image Tracking (~150 LOC) + USDZ 보물상자 합성 + 사운드/햅틱 |
| 산출 | iOS 빌드 — 마커 5종 인식 |

```swift
// Swift 핵심 코드
let config = ARImageTrackingConfiguration()
config.trackingImages = ARReferenceImage.referenceImages(
  inGroupNamed: "ARMarkers", bundle: nil
)
config.maximumNumberOfTrackedImages = 5
sceneView.session.run(config)

func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
  guard let imageAnchor = anchor as? ARImageAnchor else { return }
  let chestNode = SCNScene(named: "treasure_chest.usdz")!.rootNode
  node.addChildNode(chestNode)
  AudioServicesPlaySystemSound(1304)
  UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
}
```

#### Day 5 (금) — Android Kotlin + Flutter MethodChannel 통합

| 시간 | 작업 |
|---|---|
| 오전 | Kotlin + ARCore Augmented Images + Filament 렌더링 |
| 오후 | Flutter MethodChannel + PlatformView 로 네이티브 AR View 호스팅 |
| 산출 | Flutter 앱이 네이티브 AR 호출 + 인식 결과 Dart 콜백 |

```dart
// Flutter ↔ Native 통신 (Track B)
const channel = MethodChannel('playspot/ar');
channel.setMethodCallHandler((call) async {
  if (call.method == 'onMarkerDetected') {
    final markerId = call.arguments['markerId'];
    // UI 업데이트
  }
});

PlatformViewLink(
  viewType: 'ARMarkerView',
  // iOS: UIKitView, Android: AndroidViewSurface
  ...
)
```

---

### Track 공통 — Week 1 마커 후보 5종

| # | 마커 | 위치 | 크기 |
|---|---|---|---|
| 1 | 대오서점 간판 | 서촌 골목 | 약 80 cm |
| 2 | 통인시장 입구 안내판 | 시장 입구 | 약 120 cm |
| 3 | 박노수미술관 안내판 | 미술관 정원 | 약 60 cm |
| 4 | 자체 인쇄 PVC 스티커 #1 | 카페 협의 | 20 cm |
| 5 | 자체 인쇄 PVC 스티커 #2 | 게스트하우스 협의 | 20 cm |

---

### Week 2 — 실증·측정·인터뷰·보고

#### Day 6 (월) — 서촌 현장 테스트 1차
| 시간 | 작업 |
|---|---|
| 오전 (맑은 날) | 4대 디바이스로 5개 마커 각각 20회 인식 시도 → 성공률 기록 |
| 오후 | 인식 실패 케이스 분석 (조명·각도·거리) |
| 산출 | 1차 인식률 표 (디바이스 × 마커 매트릭스) |

**1차 테스트 매트릭스 (예시 양식)**:
| 마커 \ 디바이스 | iPhone 12 | iPhone SE 3 | Galaxy S22 | Galaxy A54 |
|---|---|---|---|---|
| 대오서점 간판 | 19/20 | 18/20 | 17/20 | 14/20 |
| 통인시장 입구 | … | … | … | … |
| 박노수미술관 | … | … | … | … |
| 카페 PVC #1 | … | … | … | … |
| 게하 PVC #2 | … | … | … | … |

#### Day 7 (화) — 환경 변동 테스트
| 시간 | 작업 |
|---|---|
| 새벽 7시 | 일출 직후 (강한 그림자) 테스트 |
| 정오 | 정오 직사광 테스트 |
| 일몰 후 | 어두운 골목 + 가로등 조명 테스트 |
| 산출 | 시간대별 인식률 그래프 |

#### Day 8 (수) — 사용자 인터뷰 5명
| 시간 | 작업 |
|---|---|
| 오전 | 외국인 관광객 3명 (가능하면 서촌 게스트하우스 협력) |
| 오후 | 한국인 친구·가족 동반 그룹 2팀 |
| 산출 | 정성 인터뷰 노트 + "공유하고 싶나" 5점 척도 |

**인터뷰 질문 (10개)**:
1. 마커를 찾기 어렵지 않았나?
2. 인식 속도가 답답했나?
3. AR 보물상자가 등장했을 때 어떤 느낌?
4. 친구·가족에게 보여주고 싶나? (1~5점)
5. SNS 에 올릴 만한 영상인가? (1~5점)
6. 기존 GPS 기반 미션과 어떻게 다른가?
7. 가장 좋았던 순간은?
8. 가장 답답했던 순간은?
9. 진짜 보물찾기 서비스로 출시되면 돈을 낼 의향?
10. 친구에게 추천하겠는가? (NPS)

#### Day 9 (목) — 데이터 정리·분석
| 시간 | 작업 |
|---|---|
| 오전 | 인식률·인터뷰 데이터 정리, 차트 작성 |
| 오후 | 5개 가설 (H1~H5) 검증 결과 작성 |
| 산출 | 분석 리포트 초안 |

#### Day 10 (금) — 보고서 작성·발표
| 시간 | 작업 |
|---|---|
| 오전 | 의사결정 리포트 작성 (Go / Pivot / Stop 권고) |
| 오후 | 이해관계자 발표 (30분, 데모 포함) |
| 산출 | `report_poc.md` + 데모 영상 30초 + 의사결정 |

---

## 5. 성공 기준 (Go/No-Go)

### 5-1. 정량 기준

| 지표 | 목표 | 측정 |
|---|---|---|
| 평균 인식률 (주간·맑음) | **80% 이상** | 4 디바이스 × 5 마커 × 20회 = 400회 |
| 평균 인식률 (저녁·흐림) | 50% 이상 | 동일 |
| 최고 디바이스 (iPhone 12) 인식률 | 90% 이상 | 100회 |
| 최저 디바이스 (Galaxy A54) 인식률 | 60% 이상 | 100회 |
| 인식 후 AR 표시 지연 | **<500ms** | 자동 측정 |
| 마커 1개 검출 시간 (카메라 시야 진입 → 표시) | <1초 | 자동 측정 |

### 5-2. 정성 기준

| 지표 | 목표 |
|---|---|
| 사용자 "공유 욕구" 5점 척도 평균 | 3.5점 이상 |
| 사용자 NPS | 30 이상 |
| 외국인 관광객 "직관적이다" 응답 | 5명 중 4명 이상 |

### 5-3. 종합 의사결정 매트릭스

| 결과 | 권고 |
|---|---|
| **정량 ★★★ + 정성 ★★★** | **🟢 Go** — Phase 1 본격 개발 (3개월) 즉시 시작 |
| 정량 ★★ + 정성 ★★★ | 🟡 Pivot — 마커 후보 재선정, 인식률 보강 방안 PoC v2 (1주 추가) |
| 정량 ★★★ + 정성 ★★ | 🟡 Pivot — 게임 메카닉·스토리 보강, UX 강화 |
| 정량 ★ 또는 정성 ★ | 🔴 Stop — GPS 기반 강화로 회귀, AR 보류 |

---

## 6. 마커 후보 5종 — 상세


### 후보 1. 대오서점 간판
- 위치: 서울 종로구 자하문로 17길 13
- 크기: 약 80 × 30 cm
- 재질: 페인트 도장 나무 + 손글씨
- 특징점 예상: 1,500+ (글씨 풍부)
- 협의: 가게 주인 1회 방문 면담 필요

### 후보 2. 통인시장 입구 안내판
- 위치: 시장 정문
- 크기: 약 120 × 80 cm
- 재질: 인쇄 알루미늄
- 특징점 예상: 800+
- 협의: 상인회 (공식 안내판)

### 후보 3. 박노수미술관 외부 안내판
- 위치: 미술관 정문
- 크기: 약 60 × 40 cm
- 재질: 동판 음각
- 특징점 예상: 600+
- 협의: 미술관 사전 협조 요청

### 후보 4. 자체 인쇄 PVC 스티커 #1
- 위치: 카페 "Slow" 외벽 (협의 후)
- 크기: 20 × 20 cm
- 재질: 컬러 PVC 스티커
- 디자인: 자체 디자인 (문양 풍부)
- 특징점 예상: 2,000+
- 비용: ₩2,000

### 후보 5. 자체 인쇄 PVC 스티커 #2
- 위치: 게스트하우스 입구 (협의 후)
- 동일 사양

후보 추가 -> 광고 포스터 등
---

## 7. 테스트 시나리오

### 시나리오 A. 표준 인식
- 거리: 1m
- 각도: 정면
- 조명: 균일 (그늘 또는 흐린 날)
- 기대: 95%+ 성공

### 시나리오 B. 거리 변화
- 0.3m / 1m / 2m / 3m
- 각각 10회씩
- 기대: 0.5~2m 구간에서 90%+

### 시나리오 C. 각도 변화
- 정면 / 30° / 60° / 80°
- 기대: 60° 까지 70%+, 80° 는 30% 이하

### 시나리오 D. 조명 변화
- 일출 / 정오 / 일몰 / 야간 (조명 있음)
- 기대: 야간 인식률 최저

### 시나리오 E. 가림 (Occlusion)
- 마커의 25% / 50% 가림
- 기대: 25% 까지 인식, 50% 부터 실패

### 시나리오 F. 동시 인식
- 화면에 마커 2개 동시 노출
- 기대: 둘 다 인식 + 각각 보물상자 표시

---

## 8. 필요 리소스

### 8-1. 인력
| 역할 | 인원 | 기간 |
|---|---|---|
| 모바일 개발자 (Flutter + iOS + Android 동시 가능) | 1 | 2주 풀타임 |
| 디자이너 (스티커 디자인·3D 모델 1종) | 0.2 | 3일 |
| 기획자 (인터뷰·테스트 진행) | 0.3 | 5일 |

### 8-2. 디바이스
| 디바이스 | 용도 |
|---|---|
| iPhone 12 (소유) | iOS 메인 테스트 |
| iPhone SE 3rd (소유 또는 대여) | iOS 보급기 검증 |
| Galaxy S22 (소유) | Android 메인 |
| Galaxy A54 (대여) | Android 보급기 검증 |

### 8-3. 비용 추정

| 항목 | 금액 |
|---|---|
| 개발자 인건비 (2주) | ₩4,000,000 |
| 디자이너 (스티커 + 보물상자 3D) | ₩500,000 |
| 기획자 (인터뷰·답사) | ₩400,000 |
| 스티커 인쇄 (10장) | ₩20,000 |
| 디바이스 대여 (Galaxy A54 2주) | ₩100,000 |
| 인터뷰 답례 (5명 × ₩30,000) | ₩150,000 |
| 교통·식비 답사 | ₩200,000 |
| **합계** | **₩5,370,000** |

본격 개발 (3개월 ₩30M+) 의 약 1/6 비용으로 결정 근거 확보.

---

## 9. 리스크 및 대응

| 리스크 | 가능성 | 대응 |
|---|---|---|
| 가게 주인 사전 협의 불발 | 중 | 자체 PVC 스티커 비중 늘림 (마커 5중 3장 자체 제작) |
| Galaxy A54 등 보급기 AR 미지원 | 낮 | 사전 ARCore 호환성 확인, 미지원 시 보급기는 평가 제외 |
| Flutter MethodChannel 메모리 누수 | 중 | 5분 이상 세션 지양, 단발성 테스트 위주 |
| 마커 인식률 50% 미만 | 낮 | 마커 후보 재선정 + 인쇄 마커 비중 ↑ |
| 외국인 인터뷰 섭외 실패 | 중 | 한국인 영어 가능자 2명 대체 가능 |
| 우천 (테스트 일정 지연) | 중 | 실내 마커 (박노수미술관 실내) 우선 진행 |

---

## 10. 산출물

PoC 종료 시 다음 산출물 확보:

| 산출물 | 파일 |
|---|---|
| 1. PoC 앱 (iOS) | `playspot-ar-poc.ipa` (TestFlight) |
| 2. PoC 앱 (Android) | `playspot-ar-poc.apk` |
| 3. Flutter 통합 샘플 | `flutter_ar_poc/` 디렉토리 |
| 4. 마커 데이터셋 | `markers/` (5장 PNG + 메타 JSON) |
| 5. 3D 보물상자 모델 | `assets/treasure_chest.usdz`, `.glb` |
| 6. 측정 데이터 | `data/recognition_rates.csv` |
| 7. 인터뷰 노트 | `interviews/01.md` ~ `05.md` |
| 8. 데모 영상 | `demo_30s.mp4` (30초 컷) |
| 9. 분석 리포트 | `report_poc.md` |
| 10. 의사결정 권고 | `decision.md` (Go/Pivot/Stop) |

---

## 11. 간략 간트차트

```
            W1 M  T  W  T  F   W2 M  T  W  T  F
환경셋업    ■  ·  ·  ·  ·   ·  ·  ·  ·  ·
마커등록    ·  ■  ·  ·  ·   ·  ·  ·  ·  ·
iOS 구현    ·  ·  ■  ·  ·   ·  ·  ·  ·  ·
Android 구현·  ·  ·  ■  ·   ·  ·  ·  ·  ·
Flutter 통합·  ·  ·  ·  ■   ·  ·  ·  ·  ·
현장 테스트1·  ·  ·  ·  ·   ■  ·  ·  ·  ·
환경 변동   ·  ·  ·  ·  ·   ·  ■  ·  ·  ·
사용자 인터뷰· ·  ·  ·  ·   ·  ·  ■  ·  ·
분석        ·  ·  ·  ·  ·   ·  ·  ·  ■  ·
보고        ·  ·  ·  ·  ·   ·  ·  ·  ·  ■
```

---

## 12. PoC 이후 — 결정에 따른 후속 단계

### 🟢 Go 시나리오 (Phase 1 본격 개발)
1. 백엔드 마커 DB API 설계 (1주)
2. 디자이너 도구 (마커 등록 UI) 개발 (3주)
3. 사용자용 게임 시스템 (단서·진행도·보상) (4주)
4. 첫 보물찾기 시나리오 "통인시장 도시락 수사대" 콘텐츠 제작 (2주)
5. 베타 출시 (서촌 5개 마커)

→ **총 3개월, 결과물: 1개 보물찾기 코스 운영 가능**

### 🟡 Pivot 시나리오
- 마커 후보 재선정 + 인식률 보강 1주 추가 PoC
- 또는 게임 메카닉 보강 (스토리·인센티브)
- 1주 후 재평가

### 🔴 Stop 시나리오
- GPS 기반 강화 + Cloud Vision (Gemini) 으로 회귀
- AR 보물찾기는 1년 보류, 시장 상황 재검토

---

## 13. 변경 이력

| 일자 | 버전 | 변경 |
|---|---|---|
| 2026-06-06 | v0.1 | 2주 PoC 실행 계획 작성. 5개 가설, Week 1 (구축) + Week 2 (실증) 일정, 마커 5종 후보, 4종 디바이스 테스트 매트릭스, 의사결정 매트릭스 (Go/Pivot/Stop), 비용 ₩5.37M |
| 2026-06-06 | v0.2 | **Flutter 우선 + 네이티브 폴백** 전략으로 전환. `ar_flutter_plugin_plus: ^1.1.3` (xinix.tech, Image Tracking 지원) 1순위 채택. **Day 1~2 = 48h 게이트** 룰 신설. 통과 시 Track A (Flutter 단독), 실패 시 Track B (네이티브 MethodChannel) 로 Day 3~5 분기. ARCore `debuggable false` 함정 + 의존성 충돌 회피 (별도 `flutter_ar_poc` 프로젝트) 명시. |
| 2026-06-06 | v0.3 | **작업 폴더 = `ar_marker/`** 명시 (Section 0 에 디렉토리 구조 추가). Track A 를 **1순위·기본 경로**, Track B 를 **2차 폴백 (Track A 실패 시에만)** 으로 명확히 라벨링. |
