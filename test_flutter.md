# test_flutter.md — flutter_ar_spike 테스트 방법 (Android / Web)

`flutter_ar_spike/` 는 두 가지를 담고 있다:
1. **PlaySpot 앱 (미션·디자인 탭)** — plan_playspot_flutter.md Phase 0~4 (아래 §0).
2. **AR 파일럿** (`lib/ar/`) — plan_flutter.md 검증 자산 (아래 §A/§B, 카메라+나침반).

공통 준비: `cd flutter_ar_spike && flutter pub get`

---

## 0. PlaySpot 앱 (미션·디자인 탭) — 실서버 연동

```sh
flutter run -d chrome           # 또는 -d <android-id> / -d <iphone-id>
```
앱 시작 시 게스트 자동 가입(`Guest@<ts>`) + JWT 발급 → iOS 앱과 **같은 /api/v1/** 백엔드/데이터** 공유.

**미션 탭**: 인기/신규/내 주변/전체 4세그 → 카드 탭 → 상세(정보/랭킹/리뷰). 리뷰 작성(별점+글) 가능.
**디자인 탭**: 우상단 `+` → 새 미션(제목/장소/제한시간) 생성 → 빌더 맵에서 길게눌러 아이템 배치,
핀 탭 편집(필수/표시/반경/문구/삭제), 저장. 목록 행 메뉴로 공개/해제/삭제.

확인 포인트:
- 미션 탭에 실서버 미션(예: "튜토리얼: 기본 미션") 표시
- 디자인 탭에서 만든 미션 공개 → 미션 탭(전체)에 노출 (iOS 앱과 데이터 공유 교차 확인)

3플랫폼 빌드 검증: `flutter build web` / `flutter build apk --debug` / `flutter build ios --no-codesign` 모두 통과.
(iOS pod install 시 로케일 에러나면 `LANG=en_US.UTF-8` prefix)

---

## AR 파일럿 (카메라+나침반) 테스트

확인 포인트(공통): START → 카메라/위치 허용 → 폰 돌리면 HUD `heading` 갱신 +
북쪽 향하면 초록 깃발 화면 중앙, 좌우로 돌리면 추적.
(현재 앱 홈은 미션/디자인 탭이라, AR 화면은 `lib/ar/ar_overlay_view.dart` 를 직접 home 으로 띄워 테스트)

---

## A. Android 실기기 (네이티브 — 가장 간단)

HTTPS·터널 불필요. USB만 연결하면 됨.

```sh
# 1) 폰: 설정 → 휴대폰 정보 → 빌드번호 7번 탭(개발자모드) → 개발자 옵션 → USB 디버깅 ON
#    USB 연결 후 폰에 뜨는 "USB 디버깅 허용" 수락
flutter devices                         # 기기 id 확인 (예: ce10171a43e9930a04)
flutter run -d <device-id>              # 빌드 + 설치 + 실행
```

- 첫 빌드만 수 분(Gradle/SDK 자동 설치), 이후 빠름.
- 실행 중 터미널 키: `r` 핫리로드 · `R` 핫리스타트 · `q` 종료.
- heading 출처가 `flutter_compass` 로 뜨면 정상. 에뮬레이터는 GPS/나침반 부정확 → 실기기 권장.

---

## B. Web (iPhone Safari/Chrome — HTTPS 필요)

카메라/위치/모션은 HTTPS(또는 localhost)에서만 동작 → cloudflared 무료 터널 사용.
**반드시 릴리스 빌드로** (디버그 dev-server 는 Chrome 에서 화면이 안 뜸).

```sh
# 0) 최초 1회: brew install cloudflared

# 1) 릴리스 빌드
flutter build web

# 2) 정적 서버 (build/web 을 8080 에 서빙) — 터미널 1
cd build/web && python3 -m http.server 8080 --bind 127.0.0.1

# 3) HTTPS 터널 — 터미널 2
cloudflared tunnel --url http://localhost:8080
#    → 출력된 https://<랜덤>.trycloudflare.com 를 폰 브라우저에서 열기
```

- 폰 Safari/Chrome 로 위 https 주소 접속 → START → 카메라·위치·**모션(나침반)** 허용.
- iOS 는 모션 권한이 START(사용자 탭) 안에서만 요청됨. heading 출처 `webkitCompass`.
- 데스크톱 Chrome 은 나침반 없음 → 하단 mock 슬라이더로 heading 조절.
- 종료: 각 터미널에서 Ctrl+C (터널 닫으면 외부 접근 차단).

---

## 폰 화면을 맥으로 캡처 (adb, Android 연결 시)

```sh
~/Library/Android/sdk/platform-tools/adb exec-out screencap -p > ~/Desktop/and_shot.png
```

---

## 빠른 문제 해결

| 증상 | 원인/해결 |
|---|---|
| Chrome 에서 START 안 보임 | 디버그 dev-server 사용 → **릴리스 빌드(B-1) 정적 서빙**으로 |
| heading 이 `mock` 고정 | (iOS) 모션 권한 거부 → 설정→Safari→동작 및 방향 접근 ON / (Android) 센서 무신호=에뮬레이터 |
| iOS heading `mock` + 권한팝업 안뜸 | 나침반 권한을 카메라/위치보다 **먼저** 요청해야 함 (코드 이미 반영) |
| GPS `lat - lon -` | 위치 권한 허용 + 폰 위치(GPS) ON + 실내면 창가로 |
| 카메라 가로 늘어남 | `controller.aspectRatio` 기반 Transform.scale cover (코드 이미 반영) |

상세 배경은 [plan_flutter.md](plan_flutter.md), 구현/결과는 [flutter_ar_spike/README.md](flutter_ar_spike/README.md) 참고.
