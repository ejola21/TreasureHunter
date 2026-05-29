# flutter_ar_spike — PlaySpot AR 검증 스파이크 (Web 우선)

PlaySpot 의 핵심 화면(카메라 + GPS + 나침반 기반 아이템 오버레이)을 **Flutter 단일 코드베이스**로
동작시킬 수 있는지 검증하는 스파이크. 상위 [`plan_flutter.md`](../plan_flutter.md) 의 Phase 1~5 구현.

> AR 의존성: ARKit/ARCore 없이 **GPS 좌표 + heading + 화면 투영 수학** 만 사용 →
> 3 플랫폼 공통 코드 가능. 투영 로직은 `PlaySpot/AR/ARCoordinate.swift` / `ARGameView.swift` 포팅.

## 구조

```
lib/
├── main.dart            # 진입점 (ArSpikeApp → ArOverlayView)
├── ar_coordinate.dart   # ARCoordinate.swift 포팅 (bearing/Haversine/normalizeAngle)
├── location_service.dart# geolocator 권한 + 위치 스트림
├── compass_service.dart # DeviceOrientationEvent JS interop (webkitCompassHeading/alpha + iOS 권한)
└── ar_overlay_view.dart # 카메라 피드 + 투영 + 디버그 HUD + 시작/ mock 슬라이더
```

## 실행

```sh
flutter pub get

# 데스크톱 Chrome (heading 은 하단 슬라이더로 mock)
flutter run -d chrome

# 정적 번들 빌드
flutter build web
```

### 실 모바일 브라우저에서 테스트 (W3/W4/W5 핵심)

카메라·위치·모션은 **HTTPS(또는 localhost)** 에서만 동작. 폰에서 열려면 dev HTTPS 필요:

```sh
# 방법 A) ngrok
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
ngrok http 8080          # 발급된 https URL 을 폰 브라우저에서 열기

# 방법 B) mkcert 로 로컬 HTTPS 인증서
```

iOS Safari: "시작" 버튼(사용자 제스처) 안에서 `DeviceOrientationEvent.requestPermission()` 가 호출됨.
거부 시 heading 0 → 안내. 데스크톱은 자동으로 mock 슬라이더 표시.

### Android 실기기 (네이티브, plan Phase 6)

HTTPS 불필요. 나침반은 `flutter_compass`(플랫폼 회전벡터 센서) 사용 — 권한 프롬프트 없음.

```sh
# 1) 폰: 개발자 옵션 → USB 디버깅 ON, USB 연결 후 "USB 디버깅 허용" 수락
flutter devices                 # 기기가 목록에 뜨는지 확인
flutter run -d <device-id>      # 빌드 + 설치 + 실행 (디버그)
# 또는 이미 빌드한 APK 설치만:
flutter install -d <device-id>  # build/app/outputs/flutter-apk/app-debug.apk
```

- 첫 빌드는 Gradle/NDK/SDK(Build-Tools·Platform 36, CMake) 자동 설치로 수 분 소요.
- 실행 후 START → 카메라·위치 권한 허용. heading 은 폰을 돌리면 `src flutter_compass` 로 갱신.
- 나침반 센서 없는 기기/에뮬레이터는 2초 후 mock 슬라이더로 폴백 (에뮬레이터 GPS/나침반은 부정확 — 실기기 권장).

## 동작

1. **시작** 버튼 → 카메라 / 위치 권한 프롬프트 → (iOS) 모션 권한.
2. 위치 확보 시 가짜 아이템을 현재 위치 **북쪽 ~100m** 에 자동 배치.
3. 폰을 북쪽으로 향하면 초록 깃발 아이콘이 화면 중앙, 좌우로 돌리면 따라 이동, viewport 밖이면 사라짐.
4. 상단 HUD 에 lat/lon/accuracy, heading(+source), 아이템 거리/방위각 실시간 표시.

투영 상수 (`ARGameView.swift` 동일): `viewportWidthRadians = 0.5`, `maxScaleDistance = 500`,
표시 반경 `itemRangeMeters = 300`.

## 검증 체크리스트 (plan §3) — 결과 기록

| # | 가설 | Chrome Desktop | Android Chrome | iOS Safari |
|---|---|---|---|---|
| W1 | 카메라 풀스크린 60s | ⬜ | ⬜ | ✅ |
| W2 | GPS 좌표 수신/갱신 | ⬜ | ⬜ | ✅ (±22m) |
| W3 | heading 0~360° | mock | ⬜ (alpha) | ✅ (webkitCompass) |
| W4 | 아이템 투영 추적 | ⬜ | ⬜ | ✅ |
| W5 | iOS 권한 흐름 통과 | — | — | ✅ |
| W6 | 30fps 이상 | ⬜ | ⬜ | ⬜ |

⬜ = 미검증.

### 결과 메모 (2026-05-29, 실 iPhone iOS 26.5 / Safari·Chrome, cloudflared HTTPS 터널)

- **iOS Safari + iOS Chrome 둘 다 W1~W5 PASS** — Flutter Web AR(카메라+GPS+나침반+투영)이
  가장 불확실하던 플랫폼에서 동작 확인. **plan 의 핵심 GO 신호.**
- **핵심 발견 1 (마이그레이션 필수)**: iOS `DeviceOrientationEvent.requestPermission()` 은
  **사용자 제스처 활성화가 살아있는 동안** 호출해야 한다. 카메라/위치 권한을 먼저 `await` 하면
  제스처가 소비돼 모션 권한이 거부됨 → **나침반 권한을 가장 먼저 요청**하도록 순서 고정.
- **핵심 발견 2**: `flutter run -d web-server`(디버그/DDC) 는 브라우저별 부트스트랩 편차로
  Chrome 에서 화면이 안 뜨는 경우가 있었음. **릴리스 빌드(`flutter build web`, CanvasKit) 를
  정적 서빙** 하니 Safari·Chrome 모두 정상. → 실 기기 검증은 릴리스 빌드로 할 것.
- heading 떨림 완화용 원형 EMA(α=0.2) 적용.
- **Android 네이티브 (plan Phase 6 / A1) PASS** — 실 SM-G950N(Android 9):
  W1 카메라 / W2 GPS(±12m) / W3 heading(`flutter_compass`) / W4 투영 전부 동작.
  나침반은 플랫폼 분기(`compass_service_web.dart` / `compass_service_mobile.dart`, 조건부 export)로
  웹=DeviceOrientation, 모바일=flutter_compass 사용. flutter_compass 0.8.1 은 AGP8 namespace 이슈 없이 빌드됨.
- 남음: W6(fps) 측정, Android Chrome(`alpha` 경로), Phase 7 네이티브 iOS.

## 알려진 함정 (plan §8 발췌)

- iOS Safari `webkitCompassHeading` 노이즈 → 필요 시 EMA 스무딩 추가.
- 카메라/위치는 HTTPS 필수 (localhost 예외).
- Chrome Desktop 은 카메라/heading 시뮬레이션 부정확 → 실 모바일 필수.
- Web CanvasKit 첫 로드 ~2MB.

## 폐기 / promote

- 폐기: `rm -rf flutter_ar_spike/`
- 성공: 별도 repo `playspot-flutter` 로 promote (plan §4).
