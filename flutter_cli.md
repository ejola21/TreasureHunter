
## 기본 실행 명령어


# 연결된 기기 자동 감지해서 실행
flutter run

# 연결 가능한 기기/시뮬레이터 목록 확인
flutter devices


`flutter devices`로 확인하면 이런 식으로 나와요:

iPhone 15 (mobile)        • 00008110-xxx • ios     • iOS 17.4
sdk gphone64 arm64        • emulator-5554 • android-arm64 • Android 14
Chrome (web)              • chrome        • web-javascript
macOS (desktop)           • macos         • darwin-arm64


## 플랫폼별 실행

**iOS**

# 시뮬레이터 또는 연결된 아이폰
flutter run -d ios

# 특정 기기 지정
flutter run -d "iPhone 15"

# 실기기에 release 모드로
flutter run -d ios --release

※ macOS + Xcode 필요. 실기기 설치는 Apple Developer 계정(무료/유료) 필요.

**Android**

# 에뮬레이터 또는 연결된 안드로이드 폰
flutter run -d android

# 에뮬레이터 띄우기 (먼저 목록 확인)
flutter emulators
flutter emulators --launch <emulator_id>

※ Android Studio + SDK 설치 필요. USB 디버깅 켜진 실기기도 인식돼요.

**Web**

# Chrome으로 실행 (가장 일반적)
flutter run -d chrome

# Edge로 실행
flutter run -d edge

# 특정 포트로 웹 서버만 띄우기
flutter run -d web-server --web-port 8080
```

**데스크탑**
```bash
flutter run -d macos      # macOS
flutter run -d windows    # Windows
flutter run -d linux      # Linux
```

## 빌드 (배포용 파일 생성)

```bash
flutter build apk              # Android APK
flutter build appbundle        # Android AAB (Play Store용)
flutter build ios              # iOS (이후 Xcode에서 아카이브)
flutter build ipa              # iOS IPA 직접 생성
flutter build web              # Web (build/web 폴더에 정적 파일)
flutter build macos            # macOS 앱
flutter build windows          # Windows 앱
flutter build linux            # Linux 앱
```

## 유용한 옵션

```bash
# 모드 지정
flutter run --debug      # 기본값, 핫 리로드 가능
flutter run --profile    # 성능 측정용
flutter run --release    # 배포용 최적화

# Flavor (개발/스테이징/프로덕션 분리)
flutter run --flavor dev -t lib/main_dev.dart

# 전체 기기에 동시 실행
flutter run -d all
```

## 사전 체크

프로젝트가 어떤 플랫폼을 지원하는지는 프로젝트 루트의 폴더로 알 수 있어요:
```
my_app/
├── android/    ← 안드로이드 지원
├── ios/        ← iOS 지원
├── web/        ← 웹 지원
├── macos/      ← macOS 지원
├── windows/    ← Windows 지원
└── linux/      ← Linux 지원
```

기존 프로젝트에 플랫폼 추가하려면:
```bash
flutter create --platforms=web,macos,windows .
```

환경 설정이 잘 됐는지 확인하는 만능 명령어:
```bash
flutter doctor
```
체크리스트 형태로 뭐가 빠졌는지 다 알려줘요. iOS 빌드하려면 Xcode, 안드로이드는 Android Studio, 웹은 Chrome 같은 식으로요.

**한 줄 요약**: `flutter devices`로 뭐가 붙어있는지 보고 → `flutter run -d <기기>`로 실행, 끝이에요. 진짜 편해요.


1.
cd /Users/root1/Documents/workspace/TreasureHunter/flutter_ar_spike

2.
flutter devices

3.
flutter run -d ce10171a43e9930a04