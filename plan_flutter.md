# plan_flutter.md — Flutter AR 오버레이 스파이크 계획 (**Web 우선**)

> **목적**: PlaySpot 의 핵심 화면(AR 카메라 + GPS 좌표 기반 아이템 오버레이) 을 Flutter 단일 코드베이스로 동작시킬 수 있는지를 **Web 부터 먼저 검증** 한다. Web 이 통과해야 Android / iOS 진행. Web 이 막히면 Flutter 전환 자체를 재검토.
> **순서**: **Web → Android → iOS** (Web 이 가장 불확실하고 결정적이므로 최우선)
> **목표 시간**: Web 검증 3~4 영업일 + Android 1~2일 + iOS 1일 = 총 5~7 영업일 (1인 기준).
> **결정 기준**: Web 검증 결과로 PlaySpot 전면 Flutter 전환 진행 여부를 결정.

---

## 1. 배경 / 우선순위 근거

- 현재 PlaySpot 은 SwiftUI iOS 단일 플랫폼 ([CLAUDE.md](CLAUDE.md) 참조).
- 백엔드는 이미 플랫폼 무관 REST (`/api/v1/**`) 라 클라이언트만 새로 만들면 다중 플랫폼 가능.
- 목표: iOS + Android + Web 동시 서비스. 단일 코드베이스 후보 = **Flutter**.

### 왜 Web 부터?

| 플랫폼 | 불확실성 | 검증 결과의 의사결정 가치 |
|---|---|---|
| **Web** | **높음** — Flutter Web 의 카메라/heading/AR 오버레이가 iOS Safari 까지 매끄럽게 동작하는지 불확실 | **결정적** — 안 되면 Flutter 선택 자체 재고 |
| Android | 낮음 — Flutter 네이티브 강점 영역, `camera`/`geolocator`/`flutter_compass` 안정 | 확인용 |
| iOS | 가장 낮음 — Flutter on iOS 는 가장 성숙 (Apple Silicon dev 도구도 풍부) | 확인용 |

→ **불확실성이 가장 높은 Web 을 먼저 깨고**, 통과하면 Android/iOS 는 빠르게 따라옴.

### AR 의존성 분석

- PlaySpot 의 AR 은 **GPS 좌표 + 디바이스 heading + 화면 투영** 방식 ([`PlaySpot/AR/ARCoordinate.swift`](PlaySpot/AR/ARCoordinate.swift), [`PlaySpot/AR/ARGameView.swift`](PlaySpot/AR/ARGameView.swift))
- ARKit/ARCore 의 고급 기능 (plane detection, world anchoring, occlusion, face tracking) **사용 안 함**.
- 따라서 카메라 + GPS + 나침반 + 수학으로 충분 → 3 플랫폼 모두 Flutter 공통 코드로 가능 (이론).
- **이론을 Web 에서 먼저 검증** 후 본 프로젝트 마이그레이션 의사결정.

## 2. 비목표 (스파이크에서 안 함)

- 미션 리스트, 디자인, 마이페이지 등 비AR 화면
- 백엔드 REST 통합 — 가짜 좌표 1개로 충분
- 인증 / 토큰 — 불필요
- StoreKit / IAP, 푸시 알림, 햅틱, 사운드
- 미니게임 (흔들기) — 모션 권한 패턴은 카메라/위치와 동일
- 아이템 획득 팝업, HUD, 디자인 시스템
- 프로덕션 빌드 / 배포 — 디버그 빌드만

## 3. 검증할 핵심 가설

### Web 단계 (Phase 1~5, 필수 통과)

| # | 가설 | 합격 기준 | 우선순위 |
|---|---|---|---|
| **W1** | Flutter Web 에서 카메라 피드를 풀스크린으로 띄울 수 있다 | Chrome Desktop / Android Chrome / iOS Safari 모두 60s 이상 끊김 없이 표시 | 🔴 필수 |
| **W2** | Web 에서 GPS 좌표를 권한 프롬프트 후 수신 가능 | `Position(lat, lon)` 1초 이내 도착, 1Hz 이상 갱신, 3 브라우저 모두 OK | 🔴 필수 |
| **W3** | Web 에서 디바이스 heading 을 0~360° 로 받을 수 있다 | iOS Safari: `webkitCompassHeading`, Android Chrome: `alpha` 둘 다 수신, Desktop 은 mock 값으로 대체 | 🔴 필수 |
| **W4** | 가짜 아이템 1개를 화면에 GPS+heading 기반으로 투영해 자연스럽게 추적된다 | 폰을 회전하면 아이콘이 화면 좌우로 따라 움직이고, 폰을 아이템 방향으로 향하면 정중앙 위치. 3 브라우저 모두 OK | 🔴 필수 |
| **W5** | iOS Safari 권한 흐름 (camera + location + motion) 이 한 번에 통과 | 사용자 탭 → `requestPermission()` 시퀀스 통과. 거부 시 안내 메시지 | 🔴 필수 |
| **W6** | Web 에서 30fps 이상 유지 | Chrome DevTools / Flutter DevTools 프레임 그래프 측정 | 🟡 중요 |

### 모바일 단계 (Phase 6~7, Web 통과 후)

| # | 가설 | 합격 기준 | 우선순위 |
|---|---|---|---|
| **A1** | Android Flutter 빌드가 카메라/GPS/heading 동작 | 실 디바이스 (Pixel 등) 에서 W1~W4 동등 결과 + 60fps | 🟢 확인 |
| **I1** | iOS Flutter 빌드가 카메라/GPS/heading 동작 | 실 iPhone 에서 W1~W4 동등 결과 + 60fps | 🟢 확인 |
| **C1** | Web/Android/iOS 의 AR 동작이 시각적/체감상 동등 | 같은 좌표에서 같은 화면 위치에 아이콘 표시. 오차 < 5° heading 차 | 🟡 중요 |

**W1~W5 중 하나라도 fail → 원인 분석 → Flutter 전환 NO-GO 가능성 검토.** W6 fail → 튜닝.

## 4. 위치 / 구조

- **위치**: `TreasureHunter/flutter_ar_spike/` (같은 repo 의 서브폴더)
- **이유**:
  - 기존 [`ARCoordinate.swift`](PlaySpot/AR/ARCoordinate.swift), [`ARGameView.swift`](PlaySpot/AR/ARGameView.swift) 를 한 화면에서 참조하며 Dart 로 포팅
  - Xcode / xcodegen 빌드와 격리
  - 폐기 시: `rm -rf flutter_ar_spike/` 한 줄
  - 성공 시: 별도 repo `playspot-flutter` 로 promote
- **package**: `com.ejola.playspot.flutterspike`

```
TreasureHunter/
├── PlaySpot/                        # 기존 SwiftUI (유지)
├── flutter_ar_spike/                # 신규 스파이크
│   ├── lib/
│   │   ├── main.dart
│   │   ├── ar_overlay_view.dart     # 핵심 화면
│   │   ├── ar_coordinate.dart       # ARCoordinate.swift → Dart 포팅
│   │   ├── compass_service.dart     # 플랫폼 분기 (web/mobile)
│   │   └── location_service.dart
│   ├── web/                         # Web 빌드 타겟 (최우선)
│   ├── android/                     # Phase 6 에서 활성화
│   ├── ios/                         # Phase 7 에서 활성화
│   ├── pubspec.yaml
│   └── README.md
└── ...
```

- **.gitignore** 추가: `flutter_ar_spike/build/`, `flutter_ar_spike/.dart_tool/`, `flutter_ar_spike/.flutter-plugins*`, `flutter_ar_spike/ios/Pods/`, `flutter_ar_spike/android/.gradle/`

## 5. 기술 스택

| 영역 | 패키지 | Web 지원 | 비고 |
|---|---|---|---|
| 카메라 | `camera` ^0.11 (공식) | ✅ `camera_web` | iOS/Android/Web 모두 지원 |
| 위치 | `geolocator` ^13 | ✅ | web fallback 포함 |
| 나침반 (mobile) | `flutter_compass` ^0.8 | ❌ | iOS/Android 만 |
| 나침반 (web) | `dart:js_interop` + `DeviceOrientationEvent` | ✅ | iOS Safari `webkitCompassHeading`, Android Chrome `alpha`. 자체 구현 |
| 권한 (web) | 브라우저 자체 프롬프트 | ✅ | `permission_handler` 는 모바일만 |
| 상태 | 기본 `StatefulWidget` | ✅ | 스파이크라 Riverpod 등 안 씀 |
| 렌더러 (Web) | CanvasKit (기본) | ✅ | H6 fail 시 HTML 렌더러 비교 |

## 6. Phase 0 — 환경 (Web 만 활성화)

이미 설치/확인된 항목:
- ✅ Flutter SDK 3.44.0 stable (`/opt/homebrew/bin/flutter`)
- ✅ Dart 3.12.0
- ✅ Chrome (Web 빌드 타겟)
- ✅ Xcode 26.3 (iOS 는 Phase 7 에서만 필요)

스파이크 Web 단계에서 **불필요**:
- ❌ Android toolchain — Phase 6 직전에 설치
- ❌ CocoaPods 업데이트 — Phase 7 직전에 업데이트 (`brew install cocoapods` 또는 `sudo gem install cocoapods`)

**Web 만 검증 → Chrome 만 있으면 충분.** 빠른 시작 가능.

## 7. 단계별 작업

### **Phase 1 — Web 스캐폴드 (Day 1, ~3h)**

- [ ] `flutter create flutter_ar_spike --platforms=web --org=com.ejola.playspot`
- [ ] `pubspec.yaml` 패키지 추가 (camera, geolocator, js_interop_unsafe)
- [ ] `web/index.html` 에 HTTPS / localhost 안내 주석
- [ ] `flutter run -d chrome` 로 빈 앱 표시 확인
- [ ] **산출물**: Chrome 에 빈 Flutter 앱 띄움

### **Phase 2 — Web 카메라 (Day 1~2, ~3h) → W1 검증**

- [ ] `CameraController` 로 후면 카메라 풀스크린 표시 (`camera_web`)
- [ ] `getUserMedia` 자동 권한 프롬프트 동작 확인
- [ ] Chrome Desktop / Chrome Android (실 디바이스 또는 ngrok HTTPS) / Safari iOS 모두 테스트
- [ ] **검증**:
  - Chrome Desktop: 60s 카메라 피드 → 스크린샷
  - Chrome Android: 같은 결과
  - Safari iOS: 같은 결과 (HTTPS 필수)
- [ ] **알려진 트랩**: iOS Safari 는 `playsinline` attribute 필요. `<video playsinline>` 으로 fullscreen 자동 진입 막기.

### **Phase 3 — Web GPS (Day 2, ~2h) → W2 검증**

- [ ] `Geolocator.getPositionStream(LocationSettings(distanceFilter: 1))` 로 위치 스트림
- [ ] 자동 권한 프롬프트 후 1Hz 갱신
- [ ] 화면에 디버그 텍스트: `lat: 37.xxx, lon: 127.xxx, accuracy: ±5m`
- [ ] **검증**: Chrome Desktop (IP 기반 부정확), Chrome Android, Safari iOS — 후자 둘 실 GPS

### **Phase 4 — Web Heading (나침반) (Day 2~3, ~5h) → W3, W5 검증**

가장 까다로운 단계. iOS Safari 의 권한 흐름이 핵심.

- [ ] JS interop 으로 `DeviceOrientationEvent` 구독
  ```dart
  // iOS 13+ 권한 요청 (반드시 사용자 제스처 안에서 호출)
  if (defined(window.DeviceOrientationEvent?.requestPermission)) {
    final result = await window.DeviceOrientationEvent.requestPermission();
    if (result == 'granted') { /* subscribe */ }
  } else {
    /* Android Chrome 은 권한 없이 바로 구독 */
  }
  ```
- [ ] heading 계산:
  - iOS Safari: `event.webkitCompassHeading` (0~360, true heading)
  - Android Chrome: `360 - event.alpha` (또는 `event.absolute` true 면 `alpha` 직접)
  - Desktop: heading 없음 → mock UI (슬라이더로 0~360 입력)
- [ ] 디버그 텍스트: `heading: 234°, source: webkitCompass / alpha / mock`
- [ ] **검증**: 폰 회전 시 heading 갱신, 거부 후 재요청 흐름, Desktop mock 동작

### **Phase 5 — Web AR 투영 (Day 3, ~6h) → W4 검증 (핵심)**

- [ ] [`ARCoordinate.swift`](PlaySpot/AR/ARCoordinate.swift) 의 `from(location:origin:)` 을 Dart 로 포팅
  - 입력: 사용자 위치 (`lat0, lon0`), 아이템 위치 (`lat1, lon1`)
  - 출력: `azimuth` (radians, 진북 기준), `radialDistance` (meters)
  ```dart
  class ArCoordinate {
    final double azimuth;     // 라디안
    final double distance;    // 미터
    static ArCoordinate from(LatLng item, LatLng origin) {
      // Haversine + bearing 공식
    }
  }
  ```
- [ ] 화면 투영 수학 (ARGameView.swift:380-400 참조):
  ```dart
  const viewportWidthRadians = 0.5;
  const maxScaleDistance = 500.0;

  final coord = ArCoordinate.from(item, user);
  final headingRad = compass.heading * pi / 180;
  final relativeAzimuth = normalizeAngle(coord.azimuth - headingRad);

  if (relativeAzimuth.abs() > viewportWidthRadians / 2) return null; // viewport 밖
  if (coord.distance > item.rangeAR) return null;

  final x = size.width / 2 + (relativeAzimuth / viewportWidthRadians) * (size.width / 2);
  final y = size.height / 2;
  final scale = 1.0 - min(coord.distance, maxScaleDistance) / maxScaleDistance * 0.7;
  ```
- [ ] 가짜 아이템 좌표: 사용자 위치에서 북쪽 100m (`lat0 + 0.0009, lon0`)
- [ ] `Stack` + `Positioned` 로 카메라 위에 아이콘 (`assets/items/i_start.png`) 오버레이 + `Transform.scale`
- [ ] **검증**:
  - 폰을 북쪽으로 향함 → 아이콘 정중앙
  - 동쪽으로 돌림 → 아이콘 화면 왼쪽으로 이동 → viewport 밖 사라짐
  - 다시 북쪽 → 아이콘 복귀
  - 3 브라우저 모두 동일 동작

### **Phase 5b — Web 성능 측정 (Day 4, ~3h) → W6 검증**

- [ ] Chrome DevTools Performance 탭 / Flutter DevTools 프레임 그래프
- [ ] FPS 측정 (60s 동안 평균):
  - Chrome Desktop: 60fps 목표
  - Chrome Android (Pixel 6+ 실 디바이스): 30fps 최저
  - Safari iOS (iPhone 12+ 실 디바이스): 30fps 최저
- [ ] CanvasKit 렌더러 (기본) vs HTML 렌더러 (`--web-renderer=html`) 비교
- [ ] 첫 로드 시간 측정 (CanvasKit ~2MB 다운로드 영향)

### **Phase 5c — Web 결과 리포트 (Day 4, ~2h)**

- [ ] `flutter_ar_spike/README.md` 에 Web 결과 기록 (W1~W6 PASS/FAIL + 스크린샷/영상)
- [ ] **Web GO/NO-GO 의사결정 미팅**

→ **Web GO 시 Phase 6 (Android) 진행. Web NO-GO 시 여기서 종료.**

### **Phase 6 — Android 검증 (Day 5, ~6h) → A1 검증**

Web 통과 후에만 진행. 환경 셋업 포함.

- [ ] Android Studio 또는 cmdline-tools 설치
  ```sh
  brew install --cask android-studio
  # 또는 cmdline-tools 만:
  # https://developer.android.com/studio#command-line-tools-only 다운로드 후 ANDROID_HOME 설정
  ```
- [ ] `flutter doctor --android-licenses` 동의
- [ ] Pixel 6 또는 Pixel 8 에뮬레이터 부팅 (API 34)
- [ ] `flutter_ar_spike/pubspec.yaml` 의 `platforms` 에 android 추가
- [ ] `AndroidManifest.xml` 권한 (CAMERA, ACCESS_FINE_LOCATION, INTERNET)
- [ ] `flutter run -d <android-emu>` 빌드
- [ ] **실 Android 디바이스에서 W1~W4 동등 확인** (에뮬레이터는 GPS/heading 부정확)
- [ ] 60fps 유지 확인

### **Phase 7 — iOS 검증 (Day 6, ~6h) → I1 검증**

Android 통과 후 진행.

- [ ] CocoaPods 1.16.2 업데이트
  ```sh
  brew install cocoapods
  # 또는: sudo gem install cocoapods
  ```
- [ ] `flutter_ar_spike/pubspec.yaml` 의 `platforms` 에 ios 추가 + `cd ios && pod install`
- [ ] `Info.plist` 권한 키 (NSCameraUsageDescription, NSLocationWhenInUseUsageDescription, NSMotionUsageDescription)
- [ ] iOS Simulator 부팅 — 단 카메라/heading 시뮬레이션 부정확이므로 **실 iPhone 필수**
- [ ] `flutter run -d <iphone-device>` 빌드
- [ ] **iPhone 실 디바이스에서 W1~W4 동등 확인 + 60fps**
- [ ] 기존 SwiftUI iOS AR 와 시각적 동등성 비교 (C1)

### **Phase 8 — 최종 리포트 + 의사결정 (Day 7, ~3h)**

- [ ] `flutter_ar_spike/README.md` 에 3 플랫폼 결과표 + 영상 / 스크린샷
- [ ] 플랫폼별 알려진 한계 / quirk
- [ ] **전면 마이그레이션 시 예상**:
  - 작업량 (SwiftUI 화면 수 × Flutter 재작성 시간)
  - 위험 (백엔드 호환성, 디자인 시스템 이식)
  - 마이그레이션 순서 (auth → 미션 리스트 → 디테일 → 빌더 → AR → IAP)
  - 기존 iOS 앱 → Flutter 앱 사용자 마이그레이션 전략
- [ ] **GO / NO-GO 의사결정 미팅** 자료

## 8. 리스크 / 알려진 함정

| 리스크 | 영향 | 완화 |
|---|---|---|
| **iOS Safari `webkitCompassHeading` 노이즈** | Web AR heading 정확도 ↓ | low-pass 필터 / EMA smoothing |
| **iOS Safari 모션 권한 거부** | heading 0 만 옴 | 권한 거부 안내 + Settings 열기 가이드 |
| **Web HTTPS 요구** | localhost 외에서 카메라/위치 동작 안함 | ngrok 또는 `mkcert` 로 dev HTTPS, 배포는 Vercel/Cloudflare Pages |
| **Flutter Web CanvasKit 첫 로드 ~2MB** | 첫 페이지 느림 | service worker 캐싱. 본 마이그레이션 시 splash 화면 |
| **카메라 권한 새로고침 시 재요청** | UX 매번 권한 prompt | 알려진 web 한계. 안내 메시지 |
| **Chrome Desktop 카메라/heading 시뮬레이션 부정확** | 검증 정확도 ↓ | 실 모바일 디바이스 (Android/iOS) 필수 |
| **Android 에뮬레이터 GPS/나침반 시뮬레이션 한계** | A1 검증 정확도 ↓ | 실 Pixel/Galaxy 디바이스 사용 |
| **iOS 시뮬레이터 카메라 미지원** | I1 검증 불가 | 실 iPhone 필수 |
| **Web 백그라운드 동작 불가** | 화면 꺼지면 멈춤 | 알려진 한계 — 정책 결정 |
| **Web SEO 약함 (CanvasKit)** | 검색 노출 ↓ | 미션 카드는 별도 정적 페이지 (Next.js 등) 로 분리 검토 |

## 9. 결과별 다음 단계

| 결과 | 다음 |
|---|---|
| **Web W1~W6 모두 PASS** | Phase 6 (Android), Phase 7 (iOS) 진행 → 전면 마이그레이션 RFC 작성 |
| **Web W1~W4 PASS, W6 (성능) FAIL** | HTML 렌더러 / 이미지 캐싱 튜닝 → 재측정. 그래도 안 되면 모바일만 Flutter + Web 은 React/AR.js 별도 |
| **Web W3 (heading) FAIL on iOS Safari** | iOS Web 만 별도 안내 ("AR 은 iOS 앱으로 접속해 주세요") + Android/Desktop Web 만 지원 |
| **Web W1 또는 W2 FAIL** | Flutter Web 부적합 결론. Plan B: iOS Swift (현재) 유지 + Android Kotlin + Web PWA 별도 — 3 코드베이스 경로 |
| **Web 통과, Android FAIL** | 비현실적 (Flutter Android 는 매우 안정). 디버깅 후 진행 |
| **Web/Android 통과, iOS FAIL** | 비현실적. CocoaPods/Xcode 설정 문제일 가능성 — 디버깅 후 진행 |

## 10. 일정 요약

| Day | 단계 | 산출물 |
|---|---|---|
| 1 | Phase 1 (스캐폴드) + Phase 2 (카메라) | Chrome 에서 카메라 60s 표시 |
| 2 | Phase 3 (GPS) + Phase 4 (heading) | 디버그 텍스트 실시간 갱신 |
| 3 | Phase 5 (AR 투영) | 아이콘 heading 따라 움직임 (Web 3 브라우저) |
| 4 | Phase 5b (성능) + 5c (리포트) | **Web GO/NO-GO 결정** |
| 5 | Phase 6 (Android) | 실 Android 디바이스 W1~W4 PASS |
| 6 | Phase 7 (iOS) | 실 iPhone W1~W4 PASS |
| 7 | Phase 8 (최종 리포트) | **전면 마이그레이션 GO/NO-GO** |

**총 5~7 영업일 (1인)**. Day 4 의 Web GO/NO-GO 가 가장 결정적 분기점.

## 11. 작업 시작 전 체크리스트

- [x] Flutter SDK 3.44.0 stable 설치 (`/opt/homebrew/bin/flutter`)
- [x] Chrome 동작 (`flutter devices` 에 표시)
- [ ] 본 plan 의 가설 / 합격 기준 / 일정 동의
- [ ] (Phase 5 까지는 불필요) Android Studio, CocoaPods 업데이트, 실 Android/iOS 디바이스
- [ ] (Phase 2~4 검증용) 실 모바일 브라우저 접근 — ngrok 또는 mkcert 로 HTTPS dev 서버

---

**작성**: 2026-05-26
**상태**: 작성 완료, 사용자 승인 대기
**우선순위**: **Web → Android → iOS** (Web 이 가장 불확실/결정적이므로 최우선)
**관련**: [CLAUDE.md](CLAUDE.md), [PlaySpot/AR/ARCoordinate.swift](PlaySpot/AR/ARCoordinate.swift), [PlaySpot/AR/ARGameView.swift](PlaySpot/AR/ARGameView.swift)
