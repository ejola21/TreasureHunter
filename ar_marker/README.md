# AR Marker PoC — PlaySpot 보물찾기

> 본 폴더는 `plan_ar_marker.md` 의 PoC 실행 작업 폴더다.
> Image Target AR 이 PlaySpot 보물찾기에 적합한지 2주 안에 검증한다.

## 진행 현황 (2026-06-06)

| 단계 | 상태 |
|---|---|
| 환경 셋업 (Flutter 3.44 / Xcode 26.3 / Android SDK / JDK 17) | ✅ |
| 작업 폴더 구조 | ✅ |
| `flutter_ar_poc` Flutter 프로젝트 + `ar_flutter_plugin_plus: ^1.1.3` | ✅ |
| iOS 설정 (Info.plist 카메라 권한, deployment 15.0, Podfile post_install) | ✅ |
| Android 설정 (`debuggable false`, minSdk 24, ARCore optional) | ✅ |
| Day 1 — `main.dart` (ARView + 5 마커 + 보물 발견 UI + 로깅) | ✅ |
| **Day 2 — Android APK 빌드** (153MB) | ✅ |
| **iOS Simulator 빌드** | ✅ |
| **48h 게이트 결과** | **🟢 Track A 확정 (Flutter 단독)** |
| Day 3~5 — 실제 마커 사진 교체 + 디바이스 테스트 + 인터뷰 | 사용자 진행 |

## 폴더 구조

```
ar_marker/
├── plan_ar_marker.md          # PoC 계획서 (단일 진실 출처)
├── README.md                   # 본 파일
├── flutter_ar_poc/             # PoC Flutter 앱
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart           # ARView + 점수·보물 발견 UI
│   │   ├── models/
│   │   │   └── treasure_marker.dart  # 5 마커 메타
│   │   └── services/
│   │       └── detection_logger.dart # 인식 이벤트 CSV
│   ├── ios/Runner/Info.plist   # NSCameraUsageDescription
│   ├── ios/Podfile             # platform :ios, '15.0' + post_install
│   └── android/app/build.gradle.kts  # debuggable false + minSdk 24
├── markers/                    # 마커 PNG 5종 (Day 3 에 실사진으로 교체)
│   ├── daeo_bookstore.png
│   ├── tongin_market.png
│   ├── park_nosoo.png
│   ├── cafe_sticker_1.png
│   └── ghouse_sticker_2.png
├── assets/
│   ├── models/                 # 보물상자 GLB (Day 4 추가)
│   └── sounds/                 # 효과음 (Day 4 추가)
├── scripts/
│   └── generate_placeholders.py  # 마커 placeholder 재생성
├── data/                       # 인식률 측정 CSV (Week 2 누적)
└── interviews/                 # 사용자 인터뷰 노트 (Week 2)
```

## 실행 방법

### 0. 사전 요구 사항

- macOS 14+ (이 PoC 는 macOS 환경에서 빌드 검증됨)
- Flutter 3.44.0 이상
- Xcode 15+ (iOS 15.0 SDK 필요)
- Android Studio + Android SDK 34
- **OpenJDK 17** (필수 — `ar_flutter_plugin_plus` 가 toolchain 17 요구)
  ```sh
  brew install openjdk@17
  flutter config --jdk-dir /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
  ```

### 1. 의존성 설치

```sh
cd flutter_ar_poc
flutter pub get
```

### 2. Android 빌드 + 디바이스 실행

ARCore 호환 디바이스 필요 ([공식 호환 리스트](https://developers.google.com/ar/devices)):

```sh
# APK 빌드
flutter build apk --debug
# 또는 연결된 디바이스에서 바로 실행
flutter run -d <android-device-id>
```

**중요**: `android/app/build.gradle.kts` 에 `isDebuggable = false` 적용됨 (ar_flutter_plugin_plus 의 ARCore 트래킹 버그 회피).

### 3. iOS 빌드 + 디바이스 실행

ARKit 호환 디바이스 (iPhone XS 이상 권장):

```sh
# 시뮬레이터 빌드 (AR 작동 X, 빌드 검증만)
flutter build ios --debug --no-codesign --simulator

# 실기기 실행 (사이닝 필요)
flutter run -d <iphone-udid>
```

### 4. 사용 흐름

1. 앱 실행 → 홈 화면 "스캔 시작" 탭
2. 권한 허용 (카메라)
3. 화면을 등록된 마커 (`markers/*.png`) 에 비춤
4. 인식 시:
   - 상단 점수 증가 (마커당 100~250 pts)
   - 하단 카드에 마커 이름 + 단서 표시
   - 햅틱 + 클릭 사운드
   - 마커 위에 3D 모델 (Khronos Duck — Day 4 에 보물상자로 교체) 합성
5. 홈 화면 "인식 로그 보기" 로 CSV 확인

## Day 3~5 작업 가이드

### Day 3 — 마커 실사진 교체
1. 서촌 답사, 5개 후보 마커 사진 촬영 (정면·균일 조명·1024×1024+)
2. 기존 `markers/*.png` 5장을 동일 파일명으로 덮어쓰기
3. `flutter clean && flutter pub get && flutter run` 으로 재배포

### Day 4 — UI/콘텐츠 폴리시
1. 보물상자 GLB 모델 추가: `assets/models/treasure_chest.glb`
2. `lib/main.dart:_placeTreasure()` 의 `NodeType.webGLB` → `NodeType.localGLB` 로 변경
3. 효과음: `assets/sounds/treasure_jingle.mp3` 추가 + `audioplayers` 패키지 통합

### Day 5 — 빌드 안정화 + 인식률 측정
1. `DetectionLogger` 가 이미 모든 인식 이벤트 CSV 누적
2. 디바이스 4종 (iPhone 12, SE 3, Galaxy S22, A54) 빌드 + 설치
3. 4×5×20 = 400회 측정 → 홈 → "인식 로그 보기" → 복사 → `data/recognition_rates.csv` 저장

## 주요 파일 한눈에

| 파일 | 역할 |
|---|---|
| `lib/main.dart` | UI + ARView + 인식 콜백 |
| `lib/models/treasure_marker.dart` | 5 마커 메타 데이터 |
| `lib/services/detection_logger.dart` | CSV 로그 (SharedPreferences) |
| `pubspec.yaml` | ar_flutter_plugin_plus + vector_math + shared_preferences |
| `ios/Podfile` | platform 15.0 + post_install deployment target 강제 |
| `ios/Runner/Info.plist` | NSCameraUsageDescription + ARKit key |
| `android/app/build.gradle.kts` | debuggable false + minSdk 24 |
| `android/app/src/main/AndroidManifest.xml` | CAMERA 권한 + ARCore optional |

## 검증 결과 — Day 1~2

### Android (Track A 검증)
- ✅ APK 빌드 성공 (`build/app/outputs/apk/debug/app-debug.apk`, 153MB)
- ⚠️ 빌드 시 JDK 17 필수 — `brew install openjdk@17` + `flutter config --jdk-dir ...`
- ⚠️ `debuggable false` 누락 시 ARCore 트래킹 끊김 (이미 적용)

### iOS (Track A 검증)
- ✅ 시뮬레이터 빌드 성공 (`build/ios/iphonesimulator/Runner.app`)
- ⚠️ Podfile `platform :ios, '15.0'` + `post_install` deployment target 강제 필수
- ⚠️ Pod 초기화 시 `--repo-update` 한 번 필요할 수 있음

### 48h 게이트 결과 — **🟢 PASS**
이전 계획대로 Track A (Flutter 단독) 로 Day 3~5 진행. Track B (네이티브 폴백) 는 비활성.

## 다음 의사결정 포인트 — Week 2

Week 1 빌드 검증 완료. Week 2 는 실측·인터뷰·보고서 (plan_ar_marker.md §4 Week 2).

성공 기준 (`plan_ar_marker.md §5`):
- 주간·맑음 인식률 80%+
- 사용자 공유 욕구 3.5/5+
- AR 표시 지연 <500ms

→ 위 모두 통과 시 **🟢 Go** (3개월 본격 개발 진입).

---

## 알려진 경고 (무해)

```
The following plugins do not support Swift Package Manager for ios:
  - ar_flutter_plugin_plus
```
→ 향후 Flutter 가 SPM 강제할 때 이슈. 현재는 CocoaPods 로 정상 동작.

```
WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP):
  ar_flutter_plugin_plus, package_info_plus
```
→ Flutter 의 Built-in Kotlin 마이그레이션 정책. 본격 개발 시 플러그인 업스트림 PR 또는 fork 고려.
