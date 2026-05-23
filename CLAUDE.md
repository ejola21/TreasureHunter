# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Play Spot** is a location-based treasure hunt iOS game with augmented reality features. Players create and play GPS-based missions with quiz challenges, collectible items, power-ups, and hazards. Supports "real mode" (actual GPS) and "virtual mode" (simulated locations). Localized in English and Korean.

The repo contains **two parallel projects**:

| Project | Path | Status | Bundle ID |
|---|---|---|---|
| **New (active)** | `PlaySpot.xcodeproj` + `PlaySpot/` | Swift / SwiftUI 미그레이션 진행 중 | `com.ejola.playspot.dev` (Personal Team) |
| **Legacy (참고용)** | `TreasureHunter.xcodeproj` + `Classes/` | Objective-C iOS 4 시대 원본 | `com.mking.trasurehunter` |

**작업 기본 대상은 새 PlaySpot 프로젝트입니다.** 레거시는 마이그레이션 시 참조용으로만 사용.

## ⚠️ Build & Modification Rules (반드시 준수)

### 1. 프로젝트 파일 (`PlaySpot.xcodeproj/project.pbxproj`) 직접 편집 금지

- **모든 구조 변경은 `project.yml`에 작성한 뒤 `xcodegen generate`로 재생성한다.**
- 파일 추가/삭제(소스, 리소스), 빌드 세팅, 의존성, entitlement 모두 project.yml이 단일 진실 출처(SOT).
- 예외: 응급 디버깅 시 pbxproj 직접 편집은 가능하나, 동일 변경을 즉시 project.yml에 반영해야 다음 `xcodegen generate`에서 drift 발생하지 않음.

### 2. 리소스 추가 위치

- **이미지**: `PlaySpot/Assets.xcassets/<그룹>/<name>.imageset/` 만 사용. 그룹은 `provides-namespace: true`이므로 코드에서 `Image("AR/ar_mine")`처럼 그룹 prefix 포함해서 호출.
- **탭바/네비게이션 아이콘**: 레거시 PNG가 흰색-on-투명 실루엣인 경우, imageset의 `Contents.json`에 `"properties": { "template-rendering-intent": "template" }`를 반드시 넣어야 시스템 tint 색상으로 마스킹됨. 빠뜨리면 흰 배경 위에 흰 아이콘이 그려져 안 보이는 함정. ([UI/menu_*](PlaySpot/Assets.xcassets/UI/) 5개가 이 패턴).
- **JSON/plist/sqlite/사운드**: `PlaySpot/Resources/` 하위. project.yml의 `resources:` 블록에 등록되어 있는 경로만 빌드에 포함됨.
- 레거시 이미지 일괄 마이그레이션: `bash PlaySpot/Resources/migrate_assets.sh` (이미 실행됨, 168개 imageset 등록)

### 3. ATS / HTTP 서버

- 레거시 서버(`nexapp.co.kr`, `mking.elogin.co.kr`)는 HTTP. `PlaySpot/Info.plist`에 `NSAppTransportSecurity → NSExceptionDomains`로 두 도메인 예외 등록되어 있음.
- 새 HTTP 도메인 추가 시 같은 dict에 추가. HTTPS로 마이그레이션 가능하면 그게 우선.

### 4. Signing (Personal Team 제약)

- 현재 Apple Developer Program 미가입 → Personal Team 사용 → `com.apple.developer.storekit` 등 paid entitlement 불가.
- StoreKit 코드 자체는 entitlement 없이도 컴파일/시뮬레이터 실행 가능 (실제 IAP 테스트는 .storekit 파일로 로컬 시뮬레이션).
- 새 capability 추가 전 Personal Team 호환성 확인 필수.

### 5. 빌드 검증 절차

수정 후 반드시 다음 중 하나로 검증하고 결과 보고:

```bash
# 빠른 검증 (시뮬레이터 빌드만)
xcodebuild -project PlaySpot.xcodeproj -scheme PlaySpot \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  build CODE_SIGNING_ALLOWED=NO

# 풀 검증 (빌드 + 시뮬레이터 설치 + 실행 + 스크린샷 → /tmp/playspot_shot.png)
bash scripts/verify.sh
# 또는 다른 시뮬레이터 지정
bash scripts/verify.sh "iPhone 16 Pro"
```

UI를 변경한 경우 풀 검증으로 스크린샷을 확인할 것. 타입체크/빌드 통과는 코드 정확성이지 기능 정확성이 아님.

### 6. 코드 컨벤션 (PlaySpot 신규 프로젝트)

- **SwiftUI 우선**. UIKit은 SwiftUI가 표현 불가한 케이스에만.
- **async/await** 사용. Combine 신규 사용 금지.
- 로깅은 `print` 대신 `os.Logger` 사용.
- 의존성 주입은 생성자 주입 (e.g. `MissionDataSource`를 `AppConfig.dataSource`에서 받아옴).
- 네트워크 백엔드는 `AppConfig.backend` (UserDefaults 영속, 기본값 `.rest`) 로 토글 — [AppConfig.swift](PlaySpot/Network/AppConfig.swift). Settings 화면 segmented Picker 로 변경 가능. `.rest` = `RestRemoteDataSource` (`/api/v1/**`), `.legacy` = `LegacyRemoteDataSource` (`/playspot/J_MyList.php`). LocalDataSource(번들 JSON mock)는 단위 테스트용.

## PlaySpot (신규 프로젝트) Architecture

- **PlaySpotApp.swift**: SwiftUI App 진입점, `AppState` 싱글턴(@Observable) 보유. `body.task` 에서 `AuthBootstrap.ensureAuthenticated()` 호출하여 REST 백엔드면 토큰 자동 발급(저장된 자격증명 → 재로그인, 없으면 `Guest@<ts>` 자동 register+login).
- **AppState**: 위치/모션 서비스, 사용자 ID, IAP 카운트(UserDefaults backed).
- **Network/AppConfig.swift**: 백엔드 토글. 기본 `.rest` (신규 `/api/v1/**` JSON REST).
- **Network/MissionDataSource.swift**: 데이터 소스 프로토콜. 13개 메서드 (read/write/auth/play).
- **Network/RestAPIClient.swift**: actor. URLSession 기반. Authorization 자동 부착 + 401/403 자동 재로그인 인터셉터 (1회 한정).
- **Network/AuthSession.swift**: actor. JWT 토큰 + 자격증명을 `KeychainStore` 에 영속.
- **Network/AuthBootstrap.swift**: 진입점 부트스트랩 헬퍼. 동시 호출 race 차단 (inflight Task 공유).
- **Network/RestRemoteDataSource.swift**: 신규 `/api/v1/**` 백엔드. 기본 사용.
- **Network/LegacyRemoteDataSource.swift**: `@deprecated`. 레거시 `/playspot/J_MyList.php` (TR=200 dispatcher) — 회귀 안전망.
- **Network/APIEndpoint.swift**: 레거시 백엔드 전용. `tr=` 디스패처 매핑.
- **Database/**: GRDB 기반 로컬 저장소. **카탈로그(Mission/Items/Quizzes) 읽기는 `dataSource`(LocalDataSource/RemoteDataSource)가 담당하고, DB는 사용자 플레이 상태(PlayStateRepository, PowerUpRepository, MissionBuilder가 저장한 자작 미션) 전용**. 번들 `treasure.sqlite`의 Mission 테이블은 비어 있으므로 카탈로그를 DB에서 읽으려 하면 빈 결과가 나옴 — 추가 작업 시 이 패턴 유지.
- **Game/GameEngine.swift**: `setup(...)`는 async. `dataSource.fetchMissionDetail`로 (Mission, Items, Quizzes) 한 번에 로드 후 itemID로 퀴즈 그룹핑.
- **Models/ItemType.swift**: 아이템 타입 enum. `mapIcon`/`arIcon`은 namespace prefix(`Items/i_X`, `AR/ar_X`) 포함하여 반환.
- **Views/**: SwiftUI 화면들. MainTabView가 5개 탭(Missions / Design / My Info / Badge / Settings) 호스팅.

## 외부 의존성

- **GRDB.swift 7.0+** (SPM, project.yml에 선언) — SQLite 추상화

## 시뮬레이터 / 시각 검증

```bash
# 시뮬레이터 부팅
xcrun simctl boot "iPhone 16 Pro"; open -a Simulator
# 스크린샷
xcrun simctl io booted screenshot /tmp/shot.png
# 컴파일된 asset 카탈로그 검사
xcrun assetutil --info build/Build/Products/Debug-iphonesimulator/PlaySpot.app/Assets.car | grep '"Name"'
```

## API 회귀 (신규 /api/v1/**)

- 서버: `http://43.201.188.35:8080`
- Swagger UI: <http://43.201.188.35:8080/swagger-ui/index.html>
- OpenAPI JSON: <http://43.201.188.35:8080/api-docs>

```bash
# 13 endpoints 스모크 (anonymous 차단 / register / login / 읽기 9개 / 쓰기 2개 / 401 우회) — 22 케이스
bash scripts/smoke_new_api.sh
```

[api_plan_new.md](api_plan_new.md) 가 마이그레이션 진척/체크리스트의 단일 진실 출처.

## (참고) 레거시 Objective-C 프로젝트

> ⚠️ 이하 섹션은 레거시 `TreasureHunter.xcodeproj` 구조 설명. 신규 작업은 위의 PlaySpot 섹션을 따른다.

### Build System

- **Xcode project**: `TreasureHunter.xcodeproj` — open in Xcode and build the "Play Spot" target
- **Language**: Objective-C (iOS 4+ era)
- **No CocoaPods/SPM** — all third-party libraries are vendored directly in `Classes/`
- **Prefix header**: `TreasureHunter_Prefix.pch` defines global macros (`APPDEL`, `BASEURL`, `RGB`, debug `NSLog`, game state enums)
- **XIB-based UI**: 28 Interface Builder files in `Resources/xib/`

## Architecture

### MVC + DAO Pattern

The app follows standard MVC with a dedicated DAO layer for SQLite persistence:

- **App Delegate** (`TreasureHunterAppDelegate`) acts as a singleton for global state: location manager, database initialization, configuration dictionaries. Accessed via the `APPDEL` macro.
- **Models**: `Mission` and `MissionItem` are the core domain objects. `MissionItem.h` defines all item type constants (quiz, radar, mines, collectibles, power-ups, etc.).
- **DAOs** (`Classes/Dao/`): `BaseDao` provides the DB connection; subclasses (`MissionDao`, `MissionItemDao`, `MissionInPlayDao`, `MissionItemInPlayDao`, `ItemQuizDao`, `ItemRnPInPlayDao`) handle CRUD for each entity against the embedded `treasure.sqlite` database.
- **Controllers**: `MissionPlay` is the main gameplay controller (~85KB, most complex class). `MissionBuilder` handles mission creation on a map. `MissionList` shows available missions.

### Key Subsystems

- **AR**: `ARViewController` and `ARGeoViewController` overlay coordinate-based markers on the camera view, with distance-based scaling.
- **HTTP**: `HTTPRequest` class handles async server communication for mission sync and user progress.
- **StoreKit**: In-app purchases integrated in `MyInfo` controller for virtual currency.
- **Audio**: Background music and sound effects via AudioToolbox.
- **Database**: FMDB library wraps SQLite3. The schema lives in `Resources/treasure.sqlite` (also copied in `doc/`).

### Game State Enums (from prefix header)

- Mission states: `DESIGNING`, `TESTED`, `SERVER_UPLOAD`, `FIRST_DESIGN`
- Play modes: `REAL_MODE`, `VIRTUAL_MODE`
- Item mandatory flag: `MANDATORY_N`, `MANDATORY_Y`

## Bundled Third-Party Libraries

All in `Classes/` subdirectories — no package manager:

| Library | Location | Purpose |
|---------|----------|---------|
| FMDB | `Classes/FMDB/` | SQLite wrapper |
| SBJson | `Classes/JSON/` | JSON parsing |
| SBTickerView | `Classes/flip/` | Flip counter animations |
| CMPopTipView | `Classes/CMPopTipView/` | Tooltip popups |
| SVProgressHUD | `Classes/` | Loading indicator |
| DLStarRatingControl | `Classes/` | Star rating widget |

## Linked Frameworks

MapKit, CoreLocation, StoreKit, AudioToolbox, MediaPlayer, QuartzCore, CoreGraphics, UIKit, Foundation.

## Legacy Version Control

The repo contains `.svn/` directories from a prior Subversion history. These are staged in git but are not part of the active source.
