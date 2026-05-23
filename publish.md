# publish.md — 멀티플랫폼 (iOS · Android · 모바일 웹) 발행 전략

> 현재 PlaySpot 은 iOS 네이티브(SwiftUI) 단일 코드베이스. iOS + Android + 모바일 웹 3개 타깃으로 확장할 때 어떤 기술 스택이 가장 합리적인지 비교 분석.

---

## 0. 결론 먼저 (TL;DR)

| 추천 순위 | 전략 | 한 줄 요약 |
|---|---|---|
| ⭐ **1순위** | **Flutter 전면 재작성 + AR.js 웹 모드** | iOS·Android 는 Flutter (지도·GPS·미니게임), 웹은 Flutter Web + AR.js(WebGL 카메라 오버레이) 로 AR 까지 커버. 단일 Dart 코드 + 얇은 웹 AR 레이어. |
| **2순위** | **iOS 네이티브 유지 + Android 네이티브(Kotlin/Compose) + PWA(AR.js)** | 각 플랫폼 최고 품질. 웹은 PWA + AR.js 로 라이트 플레이까지. 인력·기간 2~3배. |
| **3순위** | **React Native + Expo + React Native Web + AR.js** | JS 생태계 익숙하면 빠른 진입. 웹 AR 동일. |
| **4순위** | **Vue.js + Capacitor + AR.js** | Vue 단일 코드 → Capacitor 가 iOS/Android WebView 로 패키징 + 같은 빌드 웹 호스팅. AR.js 로 좌표 AR 까지. 백그라운드 GPS·결제 약점은 감수. |

### PlaySpot 의 AR 은 "Geo-AR" 이라서 웹에서도 가능

레거시 [`ARGeoViewController`](Classes/ARGeoViewController.m) 가 하는 일:
1. CoreLocation 으로 사용자 위치/heading 받기
2. 미션 아이템의 GPS 좌표와 사용자 좌표 비교 → 방위각/거리 계산
3. 카메라 프리뷰 위에 아이콘을 좌표에 맞춰 그리기

**이는 SLAM/plane-detection 이 아닌 Location-based AR**. 웹 표준만으로 충분히 구현 가능:

| 웹 AR 라이브러리 | 라이선스 | iOS Safari | Android Chrome | 비고 |
|---|---|---|---|---|
| **AR.js** (location-based mode) | MIT | ✅ Safari 13+ | ✅ | A-Frame 기반. GPS 마커 표시 무료. PlaySpot 에 가장 적합. |
| **8thWall** + Geo | 상용 (~$3000/년~) | ✅ | ✅ | VPS 로 정확도 ↑. 마케팅용 광고 AR 에 많이 씀. |
| **MindAR** | MIT | ✅ | ✅ | 이미지/얼굴 트래킹 위주. Geo 약함. |
| **WebXR (AR)** | W3C | ❌ (iOS 미지원) | ✅ Chrome | SLAM 가능하나 iOS 막혀서 PlaySpot 에 부적합. |

> **PlaySpot 처럼 좌표 기반 AR 은 AR.js 무료 라이선스로 모바일 웹에서 모든 OS 지원 가능.** 단, 정확도/안정성은 ARKit 보다 떨어짐 (heading 흔들림, 카메라 프리뷰 fps 낮음 등). 데모/체험은 OK, 본 플레이는 네이티브 권장.

### 핵심 결정 변수: 웹에서 어느 수준의 AR 까지 제공할 것인가?

| 옵션 | 웹 AR 품질 | 비용 | 권장도 |
|---|---|---|---|
| AR.js (location-based) | 중 (heading 흔들림, 60fps 미만) | 무료 | ⭐ 일반적인 선택 |
| 8thWall + Geo | 높음 (VPS 안정) | 연 $3,000+ | 마케팅·B2B 케이스 |
| WebXR | iOS 차단 (Android 만) | 무료 | iOS 사용자 못 쓰니 비추 |
| AR 웹 미지원 ("앱에서 플레이") | — | — | 안전한 선택 |

---

## 1. 현재 코드베이스 상태

| 항목 | 현재 (iOS) |
|---|---|
| UI 프레임워크 | SwiftUI (+ MapKit `UIViewRepresentable`) |
| 언어 | Swift 5.9 / async-await |
| 지도 | MapKit (`MKMapView`, `MKCircle`, `MKAnnotation`) |
| AR | `ARGeoViewController` (좌표 기반 카메라 오버레이) — 레거시 ObjC 일부 잔존 |
| 위치 | CoreLocation (전경 + 백그라운드) |
| 모션 | CoreMotion (흔들기 미니게임 — accelerometer) |
| 로컬 DB | GRDB (SQLite) — 플레이 상태/파워업만 |
| 네트워크 | URLSession async/await (`/api/v1/**` REST + JWT) |
| 결제 | StoreKit (Personal Team 제약으로 시뮬레이션만) |
| 음원 | AudioToolbox / AVFoundation |
| 푸시 | (미구현) |
| 다국어 | `Localizable.xcstrings` (Ko/En) |
| 백엔드 | Spring Boot REST (`43.201.188.35:8080`) — **이미 클라이언트 독립적** |

**핵심**: 백엔드가 REST 표준이므로 **어떤 클라이언트 기술이든 API 재사용 가능**. 마이그레이션 비용은 거의 100% 클라이언트 측에 발생.

---

## 2. 기능별 플랫폼 가능성 매트릭스

각 기능을 5개 옵션이 얼마나 잘 지원하는지. ✅ 네이티브 수준 / 🟡 플러그인/약간 손해 / 🔴 부족하거나 미지원.

| 기능 | iOS Native (현재) | Flutter | React Native | Vue+Capacitor (PWA) | 분리 네이티브 |
|---|---|---|---|---|---|
| **GPS 위치** (전경) | ✅ | ✅ `geolocator` | ✅ `react-native-geolocation` | 🟡 `navigator.geolocation` (정확도 ↓) | ✅ |
| **GPS 위치** (백그라운드) | ✅ | 🟡 OS 제약, 플러그인 필요 | 🟡 동일 | 🔴 (브라우저 종료 시 중단) | ✅ |
| **나침반/Heading** | ✅ | ✅ `flutter_compass` | ✅ `react-native-compass-heading` | 🟡 `DeviceOrientationEvent` (iOS 권한 prompt) | ✅ |
| **AR — SLAM/plane** (ARKit/ARCore) | ✅ | 🟡 `ar_flutter_plugin` (커뮤니티) | 🟡 `viro-react`(중단) / `expo-ar`(제한) | 🔴 WebXR — iOS Safari 미지원 | ✅ |
| **AR — Location-based** (PlaySpot 의 실제 방식) | ✅ | ✅ `ar_flutter_plugin` 또는 자체 구현(센서+카메라) | ✅ 동일 | 🟡 **AR.js** — 양 OS 지원, fps/heading 정확도 ↓ | ✅ |
| **지도 + 커스텀 오버레이** | ✅ MapKit | 🟡 `google_maps_flutter` / `flutter_map` (Mapbox) | 🟡 `react-native-maps` | 🟡 Leaflet/Mapbox GL (성능 ↓) | ✅ |
| **로컬 SQLite** | ✅ GRDB | ✅ `sqflite` | ✅ `expo-sqlite` | 🟡 IndexedDB (SQL 아님) / sql.js WASM | ✅ |
| **REST + JWT** | ✅ | ✅ `dio` | ✅ `axios` | ✅ `axios` | ✅ |
| **결제 (IAP)** | ✅ StoreKit | ✅ `in_app_purchase` | ✅ `react-native-iap` | 🔴 (Stripe 등 외부 결제 — 앱스토어 정책 위반 위험) | ✅ |
| **푸시 알림** | ✅ APNs | ✅ FCM 통합 | ✅ FCM 통합 | 🟡 Web Push (iOS 16.4+ PWA만) | ✅ |
| **흔들기 감지** (Accelerometer) | ✅ CoreMotion | ✅ `sensors_plus` | ✅ `expo-sensors` | 🟡 `DeviceMotionEvent` | ✅ |
| **오디오/사운드** | ✅ | ✅ `just_audio` | ✅ `expo-av` | ✅ HTML Audio | ✅ |
| **다국어 (Ko/En)** | ✅ | ✅ `intl` | ✅ `i18next` | ✅ | ✅ |
| **앱스토어 출시** | ✅ | ✅ 양 스토어 | ✅ 양 스토어 | N/A | ✅ |
| **웹 동시 빌드** | 🔴 | ✅ Flutter Web | 🟡 RN Web (UI 호환 한계) | ✅ 본업 | 별도 SPA 작성 |

**남는 약점은 백그라운드 GPS 와 결제(웹).** AR 자체는 PlaySpot 이 쓰는 location-based 방식이라 AR.js 로 웹까지 가능. 다만 카메라 fps/heading 정확도는 네이티브 ARKit 보다 떨어지므로 **웹 AR 은 "체험판" 수준** 으로 설계하는 것이 안전.

---

## 3. 옵션별 상세 비교

### 3.1 Option A — Flutter (단일 코드베이스) ⭐ 추천

**아키텍처**
```
              ┌──────────────────┐
              │  Spring Boot API │
              └────────▲─────────┘
                       │ REST + JWT
       ┌───────────────┼───────────────┐
       │               │               │
  Flutter iOS    Flutter Android   Flutter Web
  (ARKit bridge) (ARCore bridge)  (지도만, AR ❌)
```

**장점**
- 단일 Dart 코드베이스 — UI/로직 80%+ 공유
- 네이티브 컴파일 → 60fps 보장 (지도 panning, 애니메이션 매끄러움)
- Material/Cupertino 위젯 모두 제공 — iOS 디자이너의 SwiftUI 감각과 비슷
- Flutter Web 안정화 (3.0+) — 같은 코드 그대로 웹 빌드
- GRDB ↔ `drift` (구 Moor) 마이그레이션 깔끔 (둘 다 Swift/Dart 의 SQL 추상화 비슷)
- 백그라운드 GPS, IAP, 푸시 — 공식/준공식 플러그인 존재

**단점**
- **AR**: 공식 지원 없음. `ar_flutter_plugin` (커뮤니티, 2024 활발), 또는 ARKit/ARCore 를 직접 `MethodChannel` 로 브릿지 — **개발 공수 증가**
- **MapKit 대체**: `google_maps_flutter` 사용 시 Google API 키 비용 + Apple Maps 못 씀 → iOS 사용자 체감 다름
- 웹에서는 AR 불가 — Flutter Web 빌드에서 AR 화면을 "앱에서 플레이하세요" 안내로 대체
- Dart 학습곡선 (1~2주)
- 현재 Swift 코드는 **참조용으로만 사용** — 전면 재작성

**개발 공수 추정 (현재 PlaySpot 기능 풀 포팅)**
- 단일 개발자: 3~4개월
- 2인 페어: 1.5~2개월
- AR 부분 네이티브 브릿지 별도 +2주

**적합한 상황**
- 인력 1~2명, 빠른 멀티플랫폼 출시 필요
- iOS·Android UX 가 동일해도 OK (스토어 심사 통과는 됨)
- 웹은 "체험판/맛보기" 수준이면 OK

---

### 3.2 Option B — iOS 네이티브 유지 + Android 네이티브 + PWA

**아키텍처**
```
  PlaySpot.xcodeproj      Android Studio        web/ (Vue/Next.js)
  SwiftUI + ARKit         Kotlin + Compose      Vue + Leaflet
        │                       │                     │
        └───────────────────────┼─────────────────────┘
                                ▼
                       Spring Boot REST
```

**장점**
- 각 플랫폼에서 **최상의 성능과 UX** (네이티브 컴포넌트, ARKit/ARCore 직접 사용)
- 현재 SwiftUI 코드 **그대로 살림** — 매몰비용 0
- 플랫폼별 디자인 가이드 완전 준수 (Apple HIG, Material Design 3)
- 웹은 PWA "라이트 버전" — 미션 둘러보기/리뷰만, 플레이는 앱 유도

**단점**
- **인력 2~3배** — iOS Swift, Android Kotlin, Web TS/Vue 세 명 필요 (또는 한 명이 트리플 풀스택)
- 기능 추가 시 3곳 동시 수정 — 동기화 비용 영구히 발생
- 디자인/스펙 변경 시 3중 작업

**개발 공수 추정**
- Android Compose 처음부터: 4~6개월 (현재 SwiftUI 기능 풀 포팅)
- PWA (Vue + Leaflet/Mapbox + Vite): 1.5~2개월
- 향후 유지보수: 1.5~2배 부담 영구

**적합한 상황**
- 자본·인력 충분, AR 품질이 사업의 핵심
- 향후 플랫폼별 차별화 기능 계획 있음 (예: iOS 위젯, Android Wear 연동)

---

### 3.3 Option C — React Native + Expo + React Native Web

**아키텍처**
```
   Expo Monorepo
   ├─ app/        (iOS·Android RN 공유)
   ├─ web/        (RN Web 컴파일)
   └─ shared/     (비즈니스 로직, API 클라)
```

**장점**
- JS/TS 단일 코드베이스 — 백엔드 개발자가 익숙
- Expo 가 빌드/배포 자동화 (EAS Build/Submit)
- 큰 생태계 (`react-native-maps`, `react-native-iap` 등 검증)
- RN Web 으로 웹도 동시 빌드 (UI 일부 호환 안 되긴 함)

**단점**
- **AR 가장 약점**: `viro-react` 는 사실상 유지보수 중단. `expo-ar` 는 일부 기능만. ARKit/ARCore 직접 브릿지 필요 → Flutter 와 비슷한 비용
- New Architecture (Fabric/Turbo Modules) 마이그레이션 진행 중 → 플러그인 호환성 변동
- JS 브리지 성능 — 60fps 지도/AR 에서 jank 발생 가능
- iOS·Android 외에 **웹 호환 위해 추가 분기 로직** 잔존 (Flutter Web 보다 호환성 약함)

**개발 공수 추정**: Flutter 와 거의 동일 (3~4개월). AR 까다로움.

**적합한 상황**
- 팀에 React/JS 숙련자 다수
- 웹 우선순위가 모바일과 동등

---

### 3.4 Option D — Vue.js + Capacitor + AR.js (단일 웹 스택 → 3 플랫폼)

#### Capacitor 가 뭐고 어떻게 동작하나

[Capacitor](https://capacitorjs.com/) 는 Ionic 팀이 만든 Cordova 후계자. **웹 앱을 WebView 로 감싸서 iOS·Android 네이티브 패키지로 만들어 주는 런타임 + 플러그인 시스템**.

```
       Vue / React / Angular 웹 앱 (HTML/CSS/JS)
                       │
                   Capacitor 래퍼
       ┌───────────────┼───────────────┐
       ▼               ▼               ▼
   iOS .ipa       Android .apk      웹 (그대로 호스팅)
  (WebView+JS)    (WebView+JS)     (브라우저)
```

특징:
- 같은 Vue 빌드 결과물이 **모바일 앱 셸 안의 WebView** 로도 돌고, **순수 웹** 으로도 돌아감
- 네이티브 기능은 플러그인으로 호출: `@capacitor/geolocation`, `@capacitor/camera`, `@capacitor-community/in-app-purchases`, FCM 푸시 등
- Cordova 와 달리 **모던 ES 모듈 / TypeScript 친화** + 작은 API 표면
- 핫리로드, 시뮬레이터/디바이스 라이브 디버깅 모두 됨

#### Vue.js 로 웹 AR 가능?

**가능합니다.** Vue 는 UI 프레임워크일 뿐이라 AR 라이브러리(AR.js / A-Frame / MindAR / 8thWall) 와 자유롭게 결합 가능. PlaySpot 처럼 좌표 기반 AR 이면 **AR.js (location-based)** 가 가장 적합 (무료, iOS Safari 13+ / Android Chrome 동작).

##### 코드 예 — Vue + A-Frame + AR.js (PlaySpot Geo-AR)

```vue
<!-- MissionARView.vue -->
<template>
  <a-scene
    vr-mode-ui="enabled: false"
    embedded
    arjs="sourceType: webcam; videoTexture: true; debugUIEnabled: false;"
    renderer="antialias: true; alpha: true">

    <!-- 미션 아이템: GPS 좌표에 카드 배치 -->
    <a-entity
      v-for="item in items" :key="item.itemID"
      :gps-entity-place="`latitude: ${item.lat}; longitude: ${item.lng}`">
      <a-image
        :src="item.iconURL"
        scale="20 20 20"
        look-at="[gps-camera]" />
      <a-text
        :value="item.displayLabel"
        position="0 -25 0"
        align="center"
        scale="10 10 10"
        look-at="[gps-camera]" />
    </a-entity>

    <!-- 카메라: 사용자 GPS+heading 자동 추적 -->
    <a-camera gps-camera rotation-reader />
  </a-scene>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import 'aframe'
import 'ar.js/aframe/build/aframe-ar.js'
import { fetchMissionItems } from '@/api/missions'

const items = ref<MissionItem[]>([])
onMounted(async () => { items.value = await fetchMissionItems() })
</script>
```

핵심 포인트:
- `<a-scene>`, `<a-entity>` 는 A-Frame 의 Web Components — Vue 가 그냥 HTML 로 취급, 별도 wrapper 컴포넌트 불필요
- `gps-entity-place="latitude:...; longitude:..."` 가 AR.js 의 location-based 디렉티브 → GPS 좌표로 마커 자동 배치
- `gps-camera` 컴포넌트가 사용자 위치/heading 추적 + 카메라 프리뷰 렌더
- **HTTPS 필수** (카메라/위치 권한 조건)
- `DeviceOrientationEvent.requestPermission()` 은 AR.js 가 내부적으로 사용자 첫 터치 시 호출

대안:
- **MindAR** — 이미지·얼굴 트래킹 위주, Geo 약함. PlaySpot 부적합.
- **8thWall + Geo** — 상용 (~$3,000/년~). VPS 로 정확도 ↑. 마케팅/B2B 케이스.

#### 장점

- 단일 Vue 코드 → iOS·Android·웹 동시 출시 — 인력 효율 최고
- 웹 개발자 진입장벽 가장 낮음, 핫리로드 빠름
- AR 도 AR.js 로 모바일/웹 모두 커버 (Capacitor 빌드에서도 WebView 가 AR.js 실행)
- 웹 빌드 품질이 Flutter Web 보다 자연스러움 (DOM 기반, SEO·접근성 양호)

#### 단점

- **백그라운드 위치**: 순수 웹은 브라우저 종료 시 중단. Capacitor 모바일 빌드는 `@capacitor/background-geolocation` 같은 plugin 으로 부분 보완 가능하나 네이티브보다 약함.
- **지도 성능**: Leaflet/Mapbox GL — 60fps 어렵고, 네이티브 MapKit 인터랙션(드래그·롱프레스 정확도) 차이 큼.
- **AR 정확도**: AR.js 의 heading 흔들림, 카메라 fps 가 ARKit 보다 낮음 — 데모/맛보기 수준.
- **흔들기 감지**: iOS Safari `DeviceMotionEvent` 명시 권한 prompt 필요. UX 거침.
- **결제**: 웹 결제는 앱스토어 정책 위반 — 모바일 앱(Capacitor 빌드)에서는 `@capacitor-community/in-app-purchases` 로 IAP 처리, 웹 빌드는 결제 비활성화하거나 외부 결제 페이지.

#### Vue 단독(웹) vs Vue+Capacitor (모바일+웹) 비교

| 기능 | Vue + AR.js (웹 단독) | Vue + Capacitor + AR.js (모바일 + 웹) |
|---|---|---|
| Geo-AR (좌표 마커) | ✅ | ✅ |
| 전경 GPS | ✅ `navigator.geolocation` | ✅ `@capacitor/geolocation` |
| 카메라 프리뷰 | ✅ `getUserMedia` | ✅ |
| 흔들기 미니게임 | 🟡 `DeviceMotionEvent` (iOS 권한) | 🟡 동일 |
| 백그라운드 GPS | ❌ 브라우저 종료 시 중단 | 🟡 plugin 으로 부분 가능 |
| 결제 (IAP) | ❌ 정책 위반 위험 | ✅ Capacitor IAP plugin |
| 푸시 알림 | 🟡 Web Push (iOS 16.4+ PWA) | ✅ FCM/APNs |
| 60fps 지도 | 🟡 Leaflet/Mapbox GL | 🟡 동일 |
| 스토어 출시 | N/A | ✅ App Store + Play Store |

#### 개발 공수 추정

- Vue 부트스트랩 + 디자인 시스템: 2~3주
- 미션 목록/디테일/빌더(지도 + Leaflet): 1.5개월
- 미션 플레이 (GPS + 미니게임): 1개월
- AR.js Geo-AR 화면: 2주
- Capacitor 모바일 빌드 + 플러그인 통합 (위치/카메라/IAP/푸시): 3주
- 양 스토어 출시 + 안정화: 2주
- **총 3.5~4개월**, 1~2인 가능

#### 적합한 상황

- 웹 우선/빠른 프로토타입 — 단일 코드로 3 플랫폼
- "라이트 게임" — 짧은 세션, 카페·관광지 미션, 백그라운드 추적 불필요
- 디자이너/관리자용 미션 빌더 도구
- 게임 외 카탈로그/리뷰/이벤트 페이지

#### 부적합한 상황

- 장시간 산책·등산 미션 (백그라운드 위치 필수)
- AR 정확도가 핵심 차별화 (heading 정밀도 부족)
- 결제 비중 큰 사업 (IAP 외 추가 결제 흐름 복잡)

---

### 3.5 Option E — Kotlin Multiplatform (KMP) + Compose Multiplatform

**아키텍처**
```
  shared/ (Kotlin, 비즈니스 로직 + Repository + ViewModel)
   ├─ iOSMain        — Swift 가 import, SwiftUI 와 결합
   ├─ androidMain    — Compose UI
   └─ jsMain / wasmJs — Compose for Web 또는 React 바인딩
```

**장점**
- 비즈니스 로직(API 클라, 도메인 모델, 검증, 상태머신)만 공유 — UI 는 각 플랫폼 네이티브
- iOS SwiftUI 코드를 **상당 부분 유지** 가능 (UI 레이어만)
- Android UI 는 Compose 로 새로 작성 — Material 최신
- ARKit/ARCore/MapKit 모두 네이티브 자유 사용

**단점**
- iOS UI 는 어쨌든 Swift 로 다시 짜야 함 (현재 SwiftUI 그대로 둘 거면 KMP 는 "공유 로직 레이어" 만)
- Compose Multiplatform Web (Wasm) 은 아직 베타 — 모바일 웹 성능/번들 사이즈 우려
- 학습곡선: Kotlin + KMP 빌드 구조 (Gradle 멀티프로젝트)
- iOS 빌드에 .framework 추가 필요 (xcodegen project.yml 수정)

**적합한 상황**
- iOS 코드 유지하면서 Android 만 추가 (웹은 별도 SPA)
- 백엔드/도메인 로직이 복잡해서 공유 가치가 큰 경우

---

## 4. 평가 매트릭스 (1~5점, 높을수록 좋음)

| 항목 | Flutter | 분리 네이티브 | RN+Expo | Vue+Capacitor | KMP |
|---|---|---|---|---|---|
| iOS UX 품질 | 4 | 5 | 4 | 2 | 5 (Swift 유지) |
| Android UX 품질 | 4 | 5 | 4 | 2 | 5 |
| 웹 가능성 | 4 (제약 있음) | 3 (별도 작성) | 3 | 5 | 2 (Wasm 베타) |
| AR 지원 (Geo, 모바일) | 4 | 5 | 4 | 3 (Capacitor + AR.js) | 5 |
| AR 지원 (Geo, 웹) | 3 (AR.js 임베드) | 3 (별도 작성) | 3 | 4 (AR.js 자연스러움) | 2 |
| 백그라운드 GPS | 4 | 5 | 4 | 1 | 5 |
| 결제(IAP) | 5 | 5 | 5 | 2 | 5 |
| 인력 효율 | 5 | 2 | 5 | 5 | 4 |
| 기존 코드 재사용 | 1 | 5 (iOS) | 1 | 1 | 4 (도메인) |
| 출시 속도 (3 플랫폼) | 5 | 1 | 4 | 4 | 3 |
| 유지보수 비용 | 4 | 1 | 4 | 4 | 3 |
| **합계 (55점)** | **43** | **40** | **41** | **33** | **43** |

> KMP 가 점수상 1위지만 "공유 로직만"이라는 한계 ↔ Flutter 는 UI 까지 통합이라 출시 속도가 가장 빠름.
> **사업 단계 / 인력 규모로 결정**: 단기 출시 = Flutter, 장기 품질 = 분리 네이티브 or KMP.

---

## 5. PlaySpot 의 특수 제약 — 이것부터 결정해야 함

### 5.1 모바일 웹의 "역할" 정의

| 시나리오 | 모바일 웹의 역할 | 결과 |
|---|---|---|
| **A. 풀 플레이 가능** | GPS + AR + 결제 모두 웹에서 | 부분 가능. AR.js 로 AR ✅, 단 ① 백그라운드 GPS ❌ ② IAP ❌ — 세션 짧고 결제 없는 무료 미션만. |
| **B. 라이트 + AR 데모 (추천)** | 미션 둘러보기 + 리뷰 + 빌더(지도) + **짧은 AR 체험** + 앱 설치 유도 | PWA 1.5~2개월. AR.js 한 두 화면만 임베드. 본 플레이는 앱. |
| **C. 라이트 (AR 없음)** | 미션 둘러보기 + 빌더(지도) | PWA 1개월. AR 빠지면 단순 SPA. |
| **D. 관리자/디자이너 전용** | 미션 빌더(지도) + 통계 + 관리 | PWA 1개월. 일반 유저는 모바일 앱 사용. |

> **B 권장**: AR.js 로 "맛보기" 경험을 웹에서도 제공해 앱 다운로드 전환률 ↑. 본 플레이(백그라운드 위치, 결제, 긴 세션)는 앱에서.

### 5.2 AR 의존도 & 웹 AR 품질 기대치

PlaySpot 의 AR 은 좌표 기반(GPS + heading) 이므로 웹에서도 AR.js 로 구현 가능. 다만 품질은 다음과 같이 갈림:

| AR 품질 목표 | 추천 스택 |
|---|---|
| **모바일 ARKit 수준** (steady tracking, 60fps, anchor 안정) | iOS 네이티브 또는 Flutter + 네이티브 브릿지 |
| **모바일 + 웹 데모 수준** (heading 흔들리지만 좌표 마커 보임) | Flutter (모바일) + AR.js (웹) |
| **웹 우선 단일 스택** (모바일 앱은 WebView 래퍼) | Vue+Capacitor + AR.js — 품질 낮지만 가능 |
| AR 자체 **포기 가능** | 모든 옵션, Flutter 가 최선 |

### 5.3 결제 정책

- 모바일 웹에서 결제 처리 시 **앱스토어 정책 위반** 위험 — iOS 앱에서 "웹에서 결제" 링크 자체 금지(2024 가이드라인 변경 있었지만 여전히 제약). 가능하면 결제는 앱 내 IAP 로 한정.

---

## 6. 최종 추천 시나리오

### 시나리오 1: "빠르게 3 플랫폼 출시, 적은 인력" — **Flutter + AR.js 웹 모드**

```
Phase 1 (1개월):  Flutter 프로젝트 부트스트랩, 디자인 시스템 구축, REST 클라이언트
Phase 2 (1개월):  미션 목록 / 디테일 / 빌더 (지도) — iOS + Android 동시
Phase 3 (1개월):  미션 플레이 (GPS + 미니게임) — AR 제외하고 먼저 마무리
Phase 4 (3주):    AR 화면 (모바일) — `ar_flutter_plugin` 또는 ARKit/ARCore 브릿지
Phase 5 (2주):    Flutter Web 빌드 + AR 화면만 AR.js iframe/HTML 임베드
Phase 6 (1주):    스토어 출시 + 안정화
```
**총 4개월**. iOS 매몰비용은 참조용으로만 활용. 웹도 AR 데모까지 포함.

### 시나리오 2: "iOS 품질 유지, Android+웹 추가" — **iOS 그대로 + Android 네이티브 + PWA**

```
Phase 1 (4~6개월):  Android Kotlin/Compose 네이티브로 PlaySpot 포팅
Phase 2 (1.5~2개월):  Vue/Next.js PWA — 미션 둘러보기 + 빌더(지도)
Phase 3 (지속):     3 플랫폼 동시 유지보수
```
**총 6~8개월**, 인력 2~3명, 유지보수 영구 부담.

### 시나리오 3: "균형" — **KMP 공유 도메인 + iOS 유지 + Android Compose + PWA**

```
Phase 1 (1.5개월):  현재 Swift 의 Network/Models/Validator/ViewModel 을 KMP 공유 모듈로 추출
Phase 2 (3개월):    Android Compose UI 작성 (KMP 모듈 import)
Phase 3 (1.5개월):  Vue PWA (KMP Wasm 또는 별도 API 클라 — Wasm 베타라서 권장 안 함)
```
**총 6개월**, KMP 학습 1개월 별도. iOS 코드 손상 최소.

### 시나리오 4: "웹 우선·최소 인력" — **Vue + Capacitor + AR.js**

```
Phase 1 (2~3주):  Vue 3 + Vite + 디자인 시스템, Capacitor 셋업 (iOS·Android 빌드 확인)
Phase 2 (1.5개월): 미션 목록/디테일/빌더 (Leaflet 지도) + REST 클라
Phase 3 (1개월):  미션 플레이 (GPS + 흔들기 미니게임) — `@capacitor/geolocation`, `DeviceMotionEvent`
Phase 4 (2주):    AR.js Geo-AR 화면 (A-Frame + GPS 마커)
Phase 5 (3주):    Capacitor 플러그인 통합 (IAP / 푸시 / 백그라운드 위치)
Phase 6 (2주):    양 스토어 출시 + 웹 호스팅 + 안정화
```
**총 3.5~4개월**, 1~2인. AR 정확도와 백그라운드 위치 품질은 네이티브보다 떨어짐 — "라이트 게임" 컨셉에 적합.

---

## 7. 이 프로젝트의 권장사항

> 사업 단계 정보가 없으므로 **두 가지 권장**:

### 🚀 MVP/스타트업이라면 → **Flutter (시나리오 1)**
- 매몰비용(iOS Swift) 일부 손해 보더라도 3 플랫폼 동시 출시 효과가 큼
- AR 은 안드로이드/iOS 만 — 웹은 라이트
- 추후 사용자 트래픽 확보 후 네이티브로 갈아탈 옵션 항상 열려 있음

### 🏛️ 자본·품질 중시라면 → **시나리오 3 (KMP 균형)**
- iOS 코드 보존 + Android Compose + Web 별도
- 도메인 로직 한 번만 작성 (검증/플레이 규칙)
- 시간/인력 더 들지만 장기 운영비 절감

### 🌐 웹 우선/빠른 프로토타입 → **Vue + Capacitor + AR.js (시나리오 4)**
- 단일 Vue 코드로 모바일 앱(Capacitor 래퍼) + 웹(직접 호스팅) 동시 출시
- AR.js 로 좌표 기반 AR 구현
- 백그라운드 GPS 와 결제 약점은 감수 (또는 모바일 앱에서만 활성화)
- 게임이 가벼우면 충분 — 무거우면 Flutter 권장

### 🛑 비추천
- **iOS 만 유지 + 외주**: 향후 동기화 비용 무한

---

## 8. 결정을 위한 체크리스트

| 질문 | 답이 Yes 면 | 답이 No 면 |
|---|---|---|
| 3개월 안에 3 플랫폼 출시 필요? | Flutter or Vue+Capacitor | KMP/분리 네이티브 |
| 모바일 웹에서도 AR 플레이 필수? | Flutter + AR.js / Vue + Capacitor + AR.js (단, 품질은 데모 수준) | 모든 옵션 가능 |
| 웹 AR 도 네이티브 수준 정확도 필요? | 8thWall + Geo (상용 ~$3,000/년) 또는 사양 재검토 | AR.js 로 충분 |
| 인력 1~2명? | Flutter or RN | 분리 네이티브 검토 가능 |
| iOS Swift 코드 매몰비용 보호 우선? | KMP (도메인만 추출) | Flutter (전면 재작성) |
| AR 품질이 차별화 핵심? | 분리 네이티브 or KMP (AR 은 네이티브) | Flutter or Capacitor+AR.js OK |
| 백엔드/도메인 로직 복잡? | KMP (공유 가치 큼) | Flutter (전부 통합) |
| Google Maps 비용 부담 가능? | Flutter OK | 분리 네이티브 (iOS 는 MapKit 무료) |
| 백그라운드 위치 추적 필수? (걸으면서 플레이) | 모바일 네이티브 또는 Flutter, Vue+Capacitor 어려움 | Vue+Capacitor 도 OK |

---

## 9. 다음 단계 제안

1. **시나리오 결정**: 위 체크리스트로 1·2·3 중 선택
2. **PoC (Proof of Concept) — 1주**: 선택한 스택으로 "지도 + GPS 위치 표시 + REST 미션 목록" 까지만 검증. AR/결제는 본 개발 시작 후.
3. **백엔드 보강**: 클라이언트 다양화에 대비해 `/api/v1/**` 응답 안정화, OpenAPI 스펙 고정 ([api_designer.md](api_designer.md) 후속 작업과 연결).
4. **디자인 시스템 통일**: 색상/타이포/아이콘 토큰을 별도 문서로 분리 → Flutter ThemeData / Compose MaterialTheme / Vue CSS Variables 어느 스택에서도 import 가능하게.

---

## 참고

- 현재 클라이언트 코드: [PlaySpot/](PlaySpot/)
- 백엔드 계약: [api_designer.md](api_designer.md)
- 빌더 계획: [plan_designer.md](plan_designer.md)
- 게임 룰: [game_rule.md](game_rule.md)

### 외부 자료
- Flutter Web: <https://docs.flutter.dev/platform-integration/web>
- `ar_flutter_plugin`: <https://pub.dev/packages/ar_flutter_plugin>
- React Native Web: <https://necolas.github.io/react-native-web/>
- Capacitor: <https://capacitorjs.com/>
- Kotlin Multiplatform: <https://kotlinlang.org/docs/multiplatform.html>
- Compose Multiplatform: <https://www.jetbrains.com/lp/compose-multiplatform/>
- **AR.js (location-based AR — PlaySpot 의 웹 AR 후보)**: <https://ar-js-org.github.io/AR.js-Docs/>
- **8thWall (상용 WebAR + Geo)**: <https://www.8thwall.com/>
- **MindAR (오픈소스 WebAR, 이미지/얼굴 트래킹)**: <https://hiukim.github.io/mind-ar-js-doc/>
- WebXR 지원 현황 (iOS Safari ❌): <https://caniuse.com/webxr>
