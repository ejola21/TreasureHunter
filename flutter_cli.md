# Flutter CLI — 디바이스 테스트 가이드 (OS 별)

> 프로젝트: `flutter_ar_spike/`. 모든 명령은 이 폴더에서 실행.

## 시작 전

```bash
cd /Users/root1/Documents/workspace/TreasureHunter/flutter_ar_spike

flutter devices     # 연결된 기기 + ID 목록
flutter doctor      # 환경 점검 (한 번만)
```

`flutter run -d <ID>` 형태가 가장 확실. 같은 OS 에 기기가 한 대뿐이면 라벨(`android`/`ios`/`chrome`) 도 가능.

빌드 모드 공통: `--debug` (기본, hot reload) · `--profile` (성능 측정) · `--release` (배포)

콘솔 키 (run 중): `r` hot reload · `R` hot restart · `d` DevTools URL · `q` 종료

---

## Android

### 실기기
```bash
# USB 디버깅 켠 폰을 케이블로 연결
flutter devices
flutter run -d ce10171a43e9930a04         # ID 로 직접 (가장 확실)
flutter run -d android                    # 한 대만 붙어 있을 때

# CLI 로 APK 만들고 직접 설치
flutter build apk --debug --target-platform android-arm64
adb -s <ID> install -r build/app/outputs/flutter-apk/app-debug.apk
```

### 에뮬레이터
```bash
flutter emulators                            # 가용 에뮬 목록
flutter emulators --launch Pixel_7_API_34    # 부팅
flutter run -d emulator-5554                 # 부팅된 에뮬 ID
```

### 도구
```bash
# adb 경로 (PATH 미설정 시)
~/Library/Android/sdk/platform-tools/adb

# 디바이스 스크린샷
adb shell screencap -p /sdcard/s.png && adb pull /sdcard/s.png /tmp/s.png
```

---

## iOS (macOS + Xcode 필요)

### 시뮬레이터
```bash
open -a Simulator
flutter run -d "iPhone 16 Pro"           # 이름으로
flutter run -d ios                       # 한 대만 부팅 시

# 시뮬 도구
xcrun simctl list devices booted         # 부팅된 시뮬 + UDID
xcrun simctl io booted screenshot /tmp/s.png
```

### 실기기 (무료 Apple ID 도 OK)
```bash
flutter devices                          # iPhone + UDID 보임
flutter run -d 00008110-...              # UDID 로
flutter run -d ios --release             # 실기기 release
```

### 빌드만 (Xcode 에서 archive 시)
```bash
flutter build ios                        # Generic iOS Device
flutter build ipa                        # 서명 + IPA 직접
```

---

## Web (Chrome 또는 LAN 서버)

### Chrome 자동
```bash
flutter run -d chrome                    # localhost (secure context, crypto.subtle OK)
flutter run -d chrome --web-port=8080    # 포트 고정 (개발 중 URL 유지)
```

### 같은 와이파이의 폰/태블릿에서 접속
```bash

http :
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
# → 디바이스 브라우저: http://$(ipconfig getifaddr en0):8080

https: 
flutter run -d web-server \
  --web-port=8080 \
  --web-hostname=0.0.0.0 \
  --web-tls-cert-path=.certs/195.114.1.206+2.pem \
  --web-tls-cert-key-path=.certs/195.114.1.206+2-key.pem
```

### 배포용 정적 빌드
```bash
flutter build web --release              # build/web/ (index.html + main.dart.js)
```

### 주의 (이 프로젝트)
- 백엔드 = `https://playapi.letsbidding.com` (HTTPS) → secure context 정상
- 카메라/AR/sensors_plus(흔들기) 는 웹 제한적 — 탭 폴백
- 처음 컴파일 30~60초, 이후 hot reload 빠름
- `flutter devices` 에 `Chrome (web)` 안 보이면 → `flutter config --enable-web`

---

## Desktop

```bash
flutter run -d macos       # Mac 호스트만
flutter run -d windows     # Windows 호스트만
flutter run -d linux       # Linux 호스트만

# 빌드 산출물
# macOS:   build/macos/Build/Products/Release/*.app
# Windows: build/windows/runner/Release/*.exe
# Linux:   build/linux/x64/release/bundle/
```

---

## 트러블슈팅

```bash
flutter clean        # build/ + .dart_tool/ 삭제 (캐시 꼬임)
flutter pub get      # 의존성 재설치
flutter analyze      # 정적 분석
flutter test         # 단위/위젯 테스트
flutter doctor -v    # 환경 상세 점검
```

### 자주 만나는 문제
| 증상 | 원인 / 해결 |
|---|---|
| `flutter devices` 에 Chrome 안 보임 | `flutter config --enable-web` |
| Android USB 인식 안 됨 | "USB 디버깅" 켜기 + 데이터 케이블 확인 |
| iOS 실기기 signing 에러 | Xcode → Signing & Capabilities → Team 선택 |
| Gradle daemon `errno 49` | macOS ephemeral 포트 고갈 — Mac 재부팅 또는 잠시 대기 |
| Plugin 추가 후 동작 안 함 | hot reload/restart 부족 — stop 후 `flutter run` 재실행 (네이티브 재등록 필요) |

---

## 자주 쓰는 패턴 (이 프로젝트)

```bash
# Android 실기기 (가장 자주)
flutter run -d ce10171a43e9930a04

# iOS 시뮬레이터
flutter run -d "iPhone 16 Pro"

# Chrome 로컬
flutter run -d chrome

# Web LAN 노출 (모바일 브라우저로 확인)
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
```
