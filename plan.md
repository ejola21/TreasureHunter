# Play Spot — iOS 최신 마이그레이션 상세 계획서

## 개요

Objective-C (iOS 4, 2012년) → **Swift 5.9 + SwiftUI + SwiftData** (iOS 17+) 전면 재작성 계획.
기존 리소스 파일(이미지, 사운드, SQLite, Localizable.strings)은 그대로 재활용한다.

---

## 목차

1. [프로젝트 구조](#1-프로젝트-구조)
2. [Phase 1 — 데이터 모델 & 상수 정의](#2-phase-1--데이터-모델--상수-정의)
3. [Phase 2 — 데이터베이스 (SwiftData)](#3-phase-2--데이터베이스-swiftdata)
4. [Phase 3 — 네트워크 레이어](#4-phase-3--네트워크-레이어)
5. [Phase 4 — 위치 & 센서 서비스](#5-phase-4--위치--센서-서비스)
6. [Phase 5 — AR 시스템 (ARKit)](#6-phase-5--ar-시스템-arkit)
7. [Phase 6 — 게임 엔진 (핵심 로직)](#7-phase-6--게임-엔진-핵심-로직)
8. [Phase 7 — UI (SwiftUI)](#8-phase-7--ui-swiftui)
9. [Phase 8 — 인앱 결제 (StoreKit 2)](#9-phase-8--인앱-결제-storekit-2)
10. [Phase 9 — 사운드 & 햅틱](#10-phase-9--사운드--햅틱)
11. [Phase 10 — 이미지 매니저](#11-phase-10--이미지-매니저)
12. [Phase 11 — 인증 시스템](#12-phase-11--인증-시스템)
13. [Phase 12 — 리소스 마이그레이션](#13-phase-12--리소스-마이그레이션)
14. [Phase 13 — 테스트](#14-phase-13--테스트)
15. [기존 코드 ↔ 신규 코드 매핑표](#15-기존-코드--신규-코드-매핑표)

---

## 1. 프로젝트 구조

```
PlaySpot/
├── PlaySpotApp.swift                    ← TreasureHunterAppDelegate 대체
├── Models/
│   ├── ItemType.swift                   ← MissionItem.h 상수들
│   ├── ShowType.swift                   ← SHOW_TRANSPARENT 등
│   ├── GameState.swift                  ← DESIGNING/TESTED 등 enum
│   ├── Mission.swift                    ← Mission.h/m
│   ├── MissionItem.swift               ← MissionItem.h/m
│   ├── ItemQuiz.swift                   ← ItemQuiz.h/m
│   ├── MissionInPlay.swift             ← MissionInPlay.h/m
│   ├── MissionItemInPlay.swift         ← MissionItemInPlay.h/m
│   └── ItemRnPInPlay.swift             ← ItemRnPInPlay.h/m
├── Database/
│   ├── DatabaseManager.swift            ← BaseDao + initDatabase
│   ├── MissionRepository.swift          ← MissionDao
│   ├── MissionItemRepository.swift      ← MissionItemDao
│   ├── PlayStateRepository.swift        ← MissionInPlayDao + MissionItemInPlayDao
│   ├── QuizRepository.swift             ← ItemQuizDao
│   └── PowerUpRepository.swift          ← ItemRnPInPlayDao
├── Network/
│   ├── APIClient.swift                  ← HTTPRequest.h/m
│   ├── APIEndpoint.swift                ← 트랜잭션 코드 정의
│   └── MissionDTO.swift                 ← 서버 응답 파싱
├── Services/
│   ├── LocationService.swift            ← CLLocationManager 래핑
│   ├── MotionService.swift              ← CMMotionManager (가속도계)
│   ├── SoundService.swift               ← playSystemSound 대체
│   ├── HapticService.swift              ← AudioServicesPlaySystemSound 대체
│   ├── ImageCacheService.swift          ← ImageManager.h/m
│   └── StoreService.swift               ← StoreKit 2
├── AR/
│   ├── ARGameView.swift                 ← ARViewController + ARGeoViewController
│   ├── ARCoordinate.swift               ← ARCoordinate.h/m + ARGeoCoordinate.h/m
│   ├── ARItemNode.swift                 ← viewForCoordinate 대체
│   └── ARRadarView.swift                ← 레이더 UI
├── Game/
│   ├── GameEngine.swift                 ← MissionPlay 핵심 로직 분리
│   ├── ItemInteraction.swift            ← getItem/mineBlast/quiz 로직
│   ├── TimerManager.swift               ← updatePassedTime/타임아웃
│   └── VirtualModeManager.swift         ← virtualMode 좌표 오프셋
├── Views/
│   ├── App/
│   │   ├── MainTabView.swift            ← UITabBarController
│   │   └── ContentView.swift
│   ├── Auth/
│   │   ├── LoginView.swift              ← Login.h/m
│   │   └── RegisterView.swift           ← UserReg.h/m
│   ├── MissionList/
│   │   ├── MissionListView.swift        ← MissionList.h/m
│   │   ├── MissionDetailView.swift      ← MissionListDetailController
│   │   └── MissionRowView.swift         ← MissionListCell.xib
│   ├── MissionPlay/
│   │   ├── MissionPlayView.swift        ← MissionPlay.h/m (지도)
│   │   ├── GameStatusBar.swift          ← statusView (mine/mandatory/hidden/stealth)
│   │   ├── GameTimerView.swift          ← SBTickerView 타이머
│   │   ├── QuizView.swift               ← QuizPlayAlert.h/m
│   │   ├── MiniGameView.swift           ← GamePlayAlert.h/m
│   │   ├── StartGameView.swift          ← StartGameAlert.h/m
│   │   └── MissionInfoSheet.swift       ← MissionInfoAlertView
│   ├── MissionBuilder/
│   │   ├── MissionBuilderView.swift     ← MissionBuilder.h/m
│   │   ├── ItemDetailView.swift         ← MissionBuilderDetail
│   │   ├── MissionSetupView.swift       ← MissionBuilderInfo
│   │   └── ItemPickerView.swift         ← MultiPickerView + pickerData.plist
│   ├── MyInfo/
│   │   ├── MyInfoView.swift             ← MyInfo.h/m
│   │   └── BadgeListView.swift          ← Bulletin
│   └── Settings/
│       └── SettingsView.swift           ← Setting.h/m
└── Resources/
    ├── Assets.xcassets/                  ← 기존 img/, ImgBadg/ 이미지 이관
    ├── Sounds/                           ← 기존 sounds/ 그대로
    ├── treasure.sqlite                   ← 기존 DB 그대로
    ├── pickerData.plist                  ← 기존 그대로
    └── Localizable.xcstrings             ← 기존 .strings → xcstrings 변환
```

---

## 2. Phase 1 — 데이터 모델 & 상수 정의

### 2.1 아이템 타입 (기존: MissionItem.h 상수 24개)

```swift
// Models/ItemType.swift
enum ItemType: String, Codable, CaseIterable {
    // 수집 아이템 (00~10)
    case num00 = "00", num01 = "01", num02 = "02", num03 = "03", num04 = "04"
    case num05 = "05", num06 = "06", num07 = "07", num08 = "08", num09 = "09"
    case alphabet = "10"
    
    // 퀴즈 (40~43)
    case quiz = "40"
    case quiz20 = "41"
    case timeoutStart = "42"
    case timeoutEnd = "43"
    
    // 미션 필수 (48~49)
    case end = "48"
    case start = "49"
    
    // 특수 아이템 (50~56, 61)
    case random = "50"
    case simple = "51"       // Hint
    case solution = "52"
    case penaltyRemove = "54"
    case mine = "55"
    case black = "56"        // Dark
    case coupon = "59"
    case mineNoBomb = "61"   // Defence
    
    // 레이더 (65~69)
    case radarAR = "65"      // Stealth Radar
    case radarMap = "66"     // Map Radar
    case radarAll = "67"
    case radarMine = "68"
    case radarBlack = "69"
    
    // 상점
    case store = "91"
    
    // MARK: - 분류 프로퍼티
    
    var displayName: LocalizedStringKey {
        switch self {
        case .start: "Start"
        case .end: "End"
        case .simple: "Hint"
        case .quiz, .quiz20: "Quiz"
        case .random: "Gambling"
        case .timeoutStart: "Run Start"
        case .timeoutEnd: "Run End"
        case .mine: "Mine"
        case .black: "Dark"
        case .mineNoBomb: "Defense"
        case .solution: "Solution"
        case .radarAR: "Stealth Radar"
        case .radarMap: "Map Radar"
        case .radarAll: "All Radar"
        case .radarMine: "Mine Radar"
        case .coupon: "Coupon"
        case .store: "Store"
        default: "Item"
        }
    }
    
    /// 기존 itemTypeFiles 배열 대체 — 리소스 이미지 파일명 접두사
    var imageFileName: String {
        switch self {
        case .start: "start"
        case .end: "end"
        case .simple: "simple"
        case .quiz, .quiz20: "quiz"
        case .random: "random_box"
        case .timeoutStart: "time_start"
        case .timeoutEnd: "time_end"
        case .mine: "mine"
        case .black: "black"
        case .mineNoBomb: "mine_nobomb"
        case .solution: "genius"
        case .radarAR: "radar_ar"
        case .radarMap: "radar_map"
        case .radarMine: "radar_mine"
        case .radarAll: "radar_all"
        case .coupon: "coupon"
        case .store: "store"
        default: "original"
        }
    }
    
    /// 기존 itemMapFile: / itemARFile: 대체
    func mapIcon(mandatory: Bool) -> String {
        mandatory ? "in_\(imageFileName)" : "i_\(imageFileName)"
    }
    
    func arIcon(mandatory: Bool) -> String {
        mandatory ? "arn_\(imageFileName)" : "ar_\(imageFileName)"
    }
    
    var isMine: Bool { self == .mine || self == .mineNoBomb }
    var isRadar: Bool { [.radarAR, .radarMap, .radarAll, .radarMine].contains(self) }
    var isTimeout: Bool { self == .timeoutStart || self == .timeoutEnd }
    
    /// mineBlast에서 제외되는 타입 — selectLastAcquiredItem 쿼리의 NOT IN ('55','61','50','42')
    var excludedFromLastAcquired: Bool {
        [.mine, .mineNoBomb, .random, .timeoutStart].contains(self)
    }
    
    /// selectRand에서 제외 — NOT IN ('48','50','56')
    var excludedFromRandom: Bool {
        [.end, .random, .black].contains(self)
    }
}
```

### 2.2 투명도 속성 (기존: SHOW_TRANSPARENT 등)

```swift
// Models/ShowType.swift
enum ShowType: String, Codable {
    case transparent = "1"  // Hidden — 레이더로만 발견
    case arOnly = "2"       // AR에서만 보임, 지도에서 안보임
    case mapOnly = "3"      // Stealth — 지도에서만 보임, AR 정보 없음
    case all = "4"          // Normal — 모두 보임
    
    /// 기존 showTypeObjects 배열 대체
    var displayName: String {
        switch self {
        case .all: "Normal"
        case .arOnly: "Hidden"
        case .mapOnly: "Stealth"
        case .transparent: "Transparent"
        }
    }
    
    /// 레이더 보유 상태에 따른 지도 가시성 판정
    /// 기존 MissionPlay.m의 InfoUpdate / mapView:viewForAnnotation: 로직
    func isVisibleOnMap(hasRadarMap: Bool, hasRadarAll: Bool) -> Bool {
        switch self {
        case .all, .mapOnly: true
        case .arOnly, .transparent: hasRadarMap || hasRadarAll
        }
    }
    
    /// 레이더 보유 상태에 따른 AR 가시성 판정
    /// 기존 ARViewController의 viewportContainsCoordinate: 로직
    func isVisibleInAR(hasRadarAR: Bool, hasRadarAll: Bool) -> Bool {
        switch self {
        case .all, .arOnly: true
        case .mapOnly, .transparent: hasRadarAR || hasRadarAll
        }
    }
}
```

### 2.3 게임 상태 (기존: prefix.pch enum)

```swift
// Models/GameState.swift
enum MissionStatus: Int, Codable {
    case designing = 0      // DESIGNING
    case tested = 1         // TESTED
    case serverUpload = 2   // SERVER_UPLOAD
    case firstDesign = 3    // FIRST_DESIGN
}

enum PlayMode: Int, Codable {
    case real = 0           // REAL_MODE
    case virtual = 1        // VIRTUAL_MODE
}

enum MandatoryFlag: Int, Codable {
    case optional = 0       // MANDATORY_N
    case mandatory = 1      // MANDATORY_Y
}
```

### 2.4 Mission 모델 (기존: Mission.h — 15개 프로퍼티)

```swift
// Models/Mission.swift
import Foundation
import CoreLocation

struct Mission: Identifiable, Codable {
    var id: String                  // mID — "userID + timestamp" 형식
    var title: String               // mTitle
    var description: String         // mDescription
    var place: String               // mPlace
    var designer: String            // mDesigner
    var startTime: Date?            // mStartTime
    var runLimitTime: Date?         // mRunLimitTime
    var quiz: String                // mQuiz
    var answer: String              // mAnswer
    var status: MissionStatus       // mStatus (0~3)
    var items: [MissionItem]        // mItems
    var writeDate: Date             // mWriteDate
    var isVirtual: PlayMode         // mVirtual
    var seq: Int                    // mSeq — 아이템 ID 시퀀서
    var lang: String                // mLang
    
    /// 기존 Mission.m의 addMissionItem 대체
    mutating func addItem() -> MissionItem {
        seq += 1
        let item = MissionItem(missionID: id, itemID: seq)
        items.append(item)
        return item
    }
}
```

### 2.5 MissionItem 모델 (기존: MissionItem.h — 18개 프로퍼티)

```swift
// Models/MissionItem.swift
import CoreLocation

struct MissionItem: Identifiable, Codable {
    var id: String { "\(missionID)_\(itemID)" }
    
    var missionID: String
    var itemID: Int
    var mandatory: MandatoryFlag = .optional
    var itemType: ItemType = .simple
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    var blackCnt: Int = 5              // 기본값 5 (기존 init에서 설정)
    var blackTime: Int = 300           // 기본값 300초 = 5분
    var rangeAR: Int = 30              // 기본값 30m
    var showType: ShowType = .all
    var effectiveRange: Int = 0
    var effectiveTime: Int = 0
    var itemGame: Int = 0
    var info: String = ""
    var relationItemID: Int = 0
    var quizSeq: Int = 1               // 기본값 1
    var rnpSeq: Int = 0
    var quizzes: [ItemQuiz] = []
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    var isMandatory: Bool { mandatory == .mandatory }
}
```

### 2.6 나머지 모델들

```swift
// Models/ItemQuiz.swift
struct ItemQuiz: Identifiable, Codable {
    var id: String { "\(missionID)_\(itemID)_\(seq)" }
    var missionID: String
    var itemID: Int
    var seq: Int
    var quiz: String
    var answer: String
    var probability: Int = 0
}

// Models/MissionInPlay.swift
struct MissionInPlay: Codable {
    var missionID: String
    var playerID: String
    var startYN: String = "N"        // "Y" / "N"
    var endYN: String = "N"
    var startTime: Date?
    var endTime: Date?
    
    var hasStarted: Bool { startYN == "Y" }
    var hasEnded: Bool { endYN == "Y" }
}

// Models/MissionItemInPlay.swift
struct MissionItemInPlay: Codable {
    var missionID: String
    var playerID: String
    var itemID: Int
    var endYN: String = "N"
    var failCnt: Int = 0
    var startTime: Date?
    var endTime: Date?
    var quizSeq: Int = 0
    
    var isAcquired: Bool { endYN == "Y" }
}

// Models/ItemRnPInPlay.swift
struct ItemRnPInPlay: Codable {
    var missionID: String
    var playerID: String
    var itemType: String             // ItemType.rawValue
    var ableCnt: Int = 0
    var ableTime: Date?
    var acquiredTime: Date?
}
```

---

## 3. Phase 2 — 데이터베이스 (SwiftData)

기존 FMDB + 수동 SQL → **GRDB.swift** (SQLite 래퍼, 기존 treasure.sqlite 스키마 호환).

> SwiftData는 자체 스키마를 생성하므로 기존 `treasure.sqlite`와 호환이 어렵다. GRDB를 사용하여 기존 DB 파일과 SQL 쿼리를 그대로 활용한다.

### 3.1 DatabaseManager (기존: BaseDao + AppDelegate.initDatabase)

```swift
// Database/DatabaseManager.swift
import GRDB

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private(set) var dbQueue: DatabaseQueue!
    
    /// 기존 TreasureHunterAppDelegate.m의 initDatabase 로직 그대로
    func setup() throws {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dbURL = documentsURL.appendingPathComponent("treasure.sqlite")
        
        // 번들에서 Documents로 복사 (최초 1회) — 기존 로직 동일
        if !fileManager.fileExists(atPath: dbURL.path) {
            guard let bundleDB = Bundle.main.url(forResource: "treasure", withExtension: "sqlite") else {
                throw DatabaseError.bundleNotFound
            }
            try fileManager.copyItem(at: bundleDB, to: dbURL)
        }
        
        dbQueue = try DatabaseQueue(path: dbURL.path)
    }
    
    enum DatabaseError: Error {
        case bundleNotFound
    }
}
```

### 3.2 MissionRepository (기존: MissionDao — SQL 7개)

```swift
// Database/MissionRepository.swift
import GRDB

struct MissionRepository {
    private let db = DatabaseManager.shared.dbQueue!
    
    /// 기존: SELECT * FROM Mission WHERE missionID=?
    func fetchByID(_ missionID: String) throws -> Mission? {
        try db.read { db in
            let row = try Row.fetchOne(db,
                sql: "SELECT * FROM Mission WHERE missionID = ?",
                arguments: [missionID])
            return row.map { mapRowToMission($0) }
        }
    }
    
    /// 기존: SELECT * FROM Mission WHERE Status <= ? ORDER BY WriteDate DESC
    func fetchByStatus(_ status: MissionStatus) throws -> [Mission] {
        try db.read { db in
            let rows = try Row.fetchAll(db,
                sql: "SELECT * FROM Mission WHERE Status <= ? ORDER BY WriteDate DESC",
                arguments: [status.rawValue])
            return rows.map { mapRowToMission($0) }
        }
    }
    
    /// 기존: INSERT INTO Mission (missionID, Title, Description, Place, Quiz, Answer, 
    ///        Designer, StartTime, RunLimitTime, Virtual, Status, WriteDate) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
    func insert(_ mission: Mission) throws {
        try db.write { db in
            try db.execute(
                sql: """
                    INSERT INTO Mission (missionID, Title, Description, Place, Quiz, Answer,
                        Designer, StartTime, RunLimitTime, Virtual, Status, WriteDate)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                arguments: [
                    mission.id, mission.title, mission.description, mission.place,
                    mission.quiz, mission.answer, mission.designer,
                    mission.startTime, mission.runLimitTime,
                    mission.isVirtual.rawValue, mission.status.rawValue, mission.writeDate
                ])
        }
    }
    
    /// 기존: save 패턴 — selectWithPK 후 있으면 update, 없으면 insert
    func save(_ mission: Mission) throws {
        if try fetchByID(mission.id) != nil {
            try update(mission)
        } else {
            try insert(mission)
        }
    }
    
    /// 기존: UPDATE Mission SET Title=?, ... WHERE missionID=?
    func update(_ mission: Mission) throws {
        try db.write { db in
            try db.execute(
                sql: """
                    UPDATE Mission SET Title=?, Description=?, Place=?, Quiz=?, Answer=?,
                        Designer=?, StartTime=?, RunLimitTime=?, Virtual=?, Status=?, WriteDate=?
                    WHERE missionID=?
                    """,
                arguments: [
                    mission.title, mission.description, mission.place,
                    mission.quiz, mission.answer, mission.designer,
                    mission.startTime, mission.runLimitTime,
                    mission.isVirtual.rawValue, mission.status.rawValue, Date(),
                    mission.id
                ])
        }
    }
    
    /// 기존: DELETE FROM Mission WHERE missionID=?
    func delete(missionID: String) throws {
        try db.write { db in
            try db.execute(sql: "DELETE FROM Mission WHERE missionID = ?", arguments: [missionID])
        }
    }
    
    private func mapRowToMission(_ row: Row) -> Mission {
        Mission(
            id: row["missionID"],
            title: row["Title"] ?? "",
            description: row["Description"] ?? "",
            place: row["Place"] ?? "",
            designer: row["Designer"] ?? "",
            startTime: row["StartTime"],
            runLimitTime: row["RunLimitTime"],
            quiz: row["Quiz"] ?? "",
            answer: row["Answer"] ?? "",
            status: MissionStatus(rawValue: row["Status"]) ?? .designing,
            items: [],
            writeDate: row["WriteDate"] ?? Date(),
            isVirtual: PlayMode(rawValue: row["Virtual"]) ?? .real,
            seq: 0,
            lang: ""
        )
    }
}
```

### 3.3 PlayStateRepository (기존: MissionItemInPlayDao — 가장 복잡, SQL 18개)

```swift
// Database/PlayStateRepository.swift
import GRDB

struct PlayStateRepository {
    private let db = DatabaseManager.shared.dbQueue!
    
    /// 기존: SELECT ItemID, EndYN FROM MissionItemInPlay WHERE MissionID=? AND PlayerID=?
    /// → dicItemEnd 딕셔너리 생성용
    func fetchItemStatusDict(missionID: String, playerID: String) throws -> [Int: String] {
        try db.read { db in
            var dict: [Int: String] = [:]
            let rows = try Row.fetchAll(db,
                sql: "SELECT ItemID, EndYN FROM MissionItemInPlay WHERE MissionID=? AND PlayerID=?",
                arguments: [missionID, playerID])
            for row in rows {
                dict[row["ItemID"]] = row["EndYN"]
            }
            return dict
        }
    }
    
    /// 기존: selectLastAcquiredItem — 지뢰 폭발 시 되돌릴 아이템 조회
    /// SQL: ... AND I.itemType NOT IN ('55','61','50','42') AND itemplay.endYN IN ('Y')
    ///      AND itemplay.itemID <> ? ORDER BY itemplay.endTime DESC
    func fetchLastAcquiredItem(missionID: String, playerID: String, excludeItemID: Int) throws -> MissionItemInPlay? {
        try db.read { db in
            let row = try Row.fetchOne(db, sql: """
                SELECT itemplay.* FROM MissionItemInPlay itemplay
                INNER JOIN MissionItem I ON itemplay.missionID = I.missionID AND itemplay.itemID = I.itemID
                WHERE itemplay.missionID=? AND itemplay.playerID=?
                AND I.itemType NOT IN ('55','61','50','42')
                AND itemplay.endYN IN ('Y')
                AND itemplay.itemID <> ?
                ORDER BY itemplay.endTime DESC
                LIMIT 1
                """, arguments: [missionID, playerID, excludeItemID])
            return row.map { mapRowToItemInPlay($0) }
        }
    }
    
    /// 기존: missionCompleted — 필수 아이템 전부 수집 여부
    /// 반환: true = 미완료 필수 아이템 없음 (기존과 반대 — 기존은 YES = 미완료 있음)
    func isMissionCompleted(missionID: String, playerID: String) throws -> Bool {
        try db.read { db in
            let row = try Row.fetchOne(db, sql: """
                SELECT A.* FROM MissionItemInPlay A, MissionItem B
                WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID
                AND A.itemID = B.itemID AND B.mandatory = 1 AND A.endYN = 'N'
                """, arguments: [missionID, playerID])
            return row == nil  // 미완료 항목이 없으면 완료
        }
    }
    
    /// 기존: missionCompletedExceptEndItem — End 아이템 제외 완료 여부
    func isMissionCompletedExceptEnd(missionID: String, playerID: String) throws -> Bool {
        try db.read { db in
            let row = try Row.fetchOne(db, sql: """
                SELECT A.* FROM MissionItemInPlay A, MissionItem B
                WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID
                AND A.itemID = B.itemID AND B.mandatory = 1 AND B.itemType <> '48'
                AND A.endYN = 'N'
                """, arguments: [missionID, playerID])
            return row == nil
        }
    }
    
    /// 기존: selectRand — Gambling 아이템이 줄 랜덤 미획득 아이템 목록
    func fetchRandomCandidates(missionID: String, playerID: String) throws -> [MissionItem] {
        try db.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT B.* FROM MissionItemInPlay A, MissionItem B
                WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID
                AND A.itemID = B.itemID AND A.EndYN = 'N'
                AND B.itemType NOT IN ('48','50','56')
                """, arguments: [missionID, playerID])
            return rows.map { mapRowToMissionItem($0) }
        }
    }
    
    /// 기존: selectLastStartedTimeOut — 활성 타임아웃 조회 (type 42)
    func fetchActiveTimeout(missionID: String, playerID: String) throws -> MissionItemInPlay? {
        try db.read { db in
            let row = try Row.fetchOne(db, sql: """
                SELECT A.* FROM MissionItemInPlay A, MissionItem B
                WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID
                AND A.itemID = B.itemID AND B.itemType='42' AND A.endYN='N'
                AND A.endTime IS NOT NULL
                ORDER BY A.endTime DESC
                LIMIT 1
                """, arguments: [missionID, playerID])
            return row.map { mapRowToItemInPlay($0) }
        }
    }
    
    /// 기존: INSERT INTO MissionItemInPlay (...) VALUES (?,?,?,?,?,?,?,?)
    func insertItemInPlay(_ item: MissionItemInPlay) throws {
        try db.write { db in
            try db.execute(sql: """
                INSERT INTO MissionItemInPlay (MissionID, PlayerID, ItemID, EndYN, FailCnt, StartTime, EndTime, QuizSeq)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, arguments: [
                    item.missionID, item.playerID, item.itemID,
                    item.endYN, item.failCnt, item.startTime, item.endTime, item.quizSeq
                ])
        }
    }
    
    /// 기존: UPDATE MissionItemInPlay SET EndYN=?, ... WHERE MissionID=? AND PlayerID=? AND ItemID=?
    func updateItemInPlay(_ item: MissionItemInPlay) throws {
        try db.write { db in
            try db.execute(sql: """
                UPDATE MissionItemInPlay SET EndYN=?, FailCnt=?, StartTime=?, EndTime=?, QuizSeq=?
                WHERE MissionID=? AND PlayerID=? AND ItemID=?
                """, arguments: [
                    item.endYN, item.failCnt, item.startTime, item.endTime, item.quizSeq,
                    item.missionID, item.playerID, item.itemID
                ])
        }
    }
    
    /// 기존: DELETE FROM MissionItemInPlay WHERE MissionID=? AND PlayerID=?
    func deleteAll(missionID: String, playerID: String) throws {
        try db.write { db in
            try db.execute(
                sql: "DELETE FROM MissionItemInPlay WHERE MissionID=? AND PlayerID=?",
                arguments: [missionID, playerID])
        }
    }
    
    // ... mapRow 헬퍼 생략
}
```

---

## 4. Phase 3 — 네트워크 레이어

기존 `HTTPRequest` (NSURLConnection delegate 패턴) → **async/await + URLSession**

### 4.1 API 엔드포인트 정의 (기존: 트랜잭션 코드 "tr" 파라미터)

```swift
// Network/APIEndpoint.swift
enum APIEndpoint {
    static let baseURL = URL(string: "http://nexapp.co.kr/playspot/J_MyList.php")!
    static let badgeBaseURL = "http://nexapp.co.kr/playspot/badge/"
    static let imageUploadURL = URL(string: "http://nexapp.co.kr/playspot/image_save.php")!
    
    // 기존 트랜잭션 코드 매핑
    case missionDetail(missionID: String)              // tr=200
    case missionReviews(missionID: String)              // tr=300
    case playingMissions(last: Int, lang: String)       // tr=500
    case publishedMissions(last: Int, lang: String, lat: Double, lon: Double)  // tr=501
    case myDesigns(last: Int, lang: String)             // tr=502
    case tutorials(lang: String)                        // tr=503
    case designedCount(userID: String)                  // tr=600
    case playedCount(userID: String)                    // tr=601
    case currentGames(userID: String)                   // tr=602
    case login(userID: String, passwordMD5: String)     // tr=800
    case register(userID: String, passwordMD5: String)  // tr=tr_user_reg
    
    var transactionCode: String {
        switch self {
        case .missionDetail: "200"
        case .missionReviews: "300"
        case .playingMissions: "500"
        case .publishedMissions: "501"
        case .myDesigns: "502"
        case .tutorials: "503"
        case .designedCount: "600"
        case .playedCount: "601"
        case .currentGames: "602"
        case .login: "800"
        case .register: "tr_user_reg"
        }
    }
    
    /// 기존 HTTPRequest.m의 bodyObject → URL-encoded query string 변환
    var parameters: [String: String] {
        var params: [String: String] = ["tr": transactionCode]
        switch self {
        case .missionDetail(let id): params["missionID"] = id
        case .missionReviews(let id): params["missionID"] = id
        case .playingMissions(let last, let lang): params["last"] = "\(last)"; params["lang"] = lang
        case .publishedMissions(let last, let lang, let lat, let lon):
            params["last"] = "\(last)"; params["lang"] = lang
            params["latitude"] = "\(lat)"; params["longitude"] = "\(lon)"
        case .myDesigns(let last, let lang): params["last"] = "\(last)"; params["lang"] = lang
        case .tutorials(let lang): params["gb"] = lang
        case .designedCount(let id): params["id"] = id
        case .playedCount(let id): params["id"] = id
        case .currentGames(let id): params["id"] = id
        case .login(let id, let pwd): params["user_id"] = id; params["password"] = pwd
        case .register(let id, let pwd): params["user_id"] = id; params["password"] = pwd
        }
        return params
    }
}
```

### 4.2 APIClient (기존: HTTPRequest.h/m)

```swift
// Network/APIClient.swift
import Foundation
import CryptoKit

actor APIClient {
    static let shared = APIClient()
    
    /// 기존 HTTPRequest.requestUrl:bodyObject: (비동기) 대체
    /// 기존 timeout: 5초, POST, UTF8
    func request(_ endpoint: APIEndpoint) async throws -> String {
        var request = URLRequest(url: APIEndpoint.baseURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 5.0
        
        // 기존 파라미터 인코딩: key1=value1&key2=value2 (percent-escaped)
        let body = endpoint.parameters
            .map { "\($0.key.urlEncoded)=\($0.value.urlEncoded)" }
            .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    /// 기존 HTTPRequest.requestUrlsync:bodyObject: (동기, timeout 30초) 대체
    func requestSync(_ endpoint: APIEndpoint) async throws -> String {
        var request = URLRequest(url: APIEndpoint.baseURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 30.0
        
        let body = endpoint.parameters
            .map { "\($0.key.urlEncoded)=\($0.value.urlEncoded)" }
            .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    /// 기존 Login.m의 md5: 대체 — CC_MD5 → CryptoKit
    static func md5(_ string: String) -> String {
        let data = Data(string.utf8)
        return Insecure.MD5.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

private extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
```

### 4.3 미션 DTO 파싱 (기존: ^M, ^I, ^Q 구분자 파싱)

```swift
// Network/MissionDTO.swift
import Foundation

struct MissionDTO {
    /// 기존 MissionListDetailController.m의 didReceiveFinished: 파싱 로직
    /// 응답 형식: M{미션JSON}^I{아이템JSON}^Q{퀴즈JSON}
    static func parse(response: String) -> (mission: Mission, items: [MissionItem], quizzes: [ItemQuiz])? {
        let sections = response.components(separatedBy: "^")
        guard sections.count >= 3 else { return nil }
        
        // "M" prefix 제거 후 JSON 파싱 — 기존 SBJsonParser 대체
        let missionJSON = String(sections[0].dropFirst())   // "M" 제거
        let itemsJSON = String(sections[1].dropFirst())     // "I" 제거
        let quizzesJSON = String(sections[2].dropFirst())   // "Q" 제거
        
        let decoder = JSONDecoder()
        guard let missionData = missionJSON.data(using: .utf8),
              let itemsData = itemsJSON.data(using: .utf8),
              let quizzesData = quizzesJSON.data(using: .utf8) else { return nil }
        
        do {
            let mission = try decoder.decode(Mission.self, from: missionData)
            let items = try decoder.decode([MissionItem].self, from: itemsData)
            let quizzes = try decoder.decode([ItemQuiz].self, from: quizzesData)
            return (mission, items, quizzes)
        } catch {
            return nil
        }
    }
}
```

---

## 5. Phase 4 — 위치 & 센서 서비스

### 5.1 LocationService (기존: AppDelegate의 CLLocationManagerDelegate + MissionPlay의 GPS)

```swift
// Services/LocationService.swift
import CoreLocation
import Combine

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    var currentLocation: CLLocation?
    var heading: CLHeading?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        // 기존: desiredAccuracy = kCLLocationAccuracyBest, distanceFilter = kCLDistanceFilterNone
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        // 기존: headingFilter = 1 (ARGeoViewController.startListening)
        manager.headingFilter = 1
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdating() {
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }
    
    func stopUpdating() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        // 기존 ARGeoViewController.m 정확도 필터: 0~100m, 타임스탬프 15초 이내
        let age = -location.timestamp.timeIntervalSinceNow
        guard location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= 100,
              age < 15 else { return }
        currentLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // 기존: headingAccuracy < 30 또는 양수
        guard newHeading.headingAccuracy > 0, newHeading.headingAccuracy < 30 else { return }
        heading = newHeading
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
```

### 5.2 MotionService (기존: UIAccelerometer → CMMotionManager)

```swift
// Services/MotionService.swift
import CoreMotion
import Combine

@Observable
final class MotionService {
    private let motionManager = CMMotionManager()
    
    var inclination: Double = 0           // 기존 ARViewController의 경사각
    var isShaking: Bool = false
    
    // 기존 kFilteringFactor = 0.05
    private let filteringFactor = 0.05
    // 기존 흔들기 임계값 1.4G
    private let shakeThreshold = 1.4
    
    private var rollingX: Double = 0
    private var rollingZ: Double = 0
    private var lastShakeTime: Date = .distantPast
    
    func startAccelerometer() {
        guard motionManager.isAccelerometerAvailable else { return }
        // 기존: updateInterval = 0.25초
        motionManager.accelerometerUpdateInterval = 0.25
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.processAcceleration(data.acceleration)
        }
    }
    
    func stopAccelerometer() {
        motionManager.stopAccelerometerUpdates()
    }
    
    /// 기존 ARViewController.m의 accelerometer:didAccelerate: 로직 그대로
    private func processAcceleration(_ accel: CMAcceleration) {
        // 저주파 필터 — 기존 rollingZ/rollingX 계산
        rollingZ = accel.z * filteringFactor + rollingZ * (1.0 - filteringFactor)
        rollingX = accel.y * filteringFactor + rollingX * (1.0 - filteringFactor)
        
        // 경사각 계산 — 기존 로직 그대로
        if rollingZ > 0 {
            inclination = atan(rollingX / rollingZ) + .pi / 2
        } else if rollingZ < 0 {
            inclination = atan(rollingX / rollingZ) - .pi / 2
        } else {
            inclination = rollingX < 0 ? .pi / 2 : 3 * .pi / 2
        }
        
        // 흔들기 감지 — 기존: > 1.4G, 1.5초 간격
        let magnitude = max(abs(accel.x), abs(accel.y), abs(accel.z))
        if magnitude > shakeThreshold {
            let now = Date()
            if now.timeIntervalSince(lastShakeTime) > 1.5 {
                isShaking = true
                lastShakeTime = now
                // 0.5초 후 리셋
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isShaking = false
                }
            }
        }
    }
}
```

---

## 6. Phase 5 — AR 시스템 (ARKit)

기존 UIImagePickerController + 수동 좌표 계산 → **ARKit + RealityKit**

### 6.1 ARCoordinate (기존: ARCoordinate.h/m + ARGeoCoordinate.h/m)

```swift
// AR/ARCoordinate.swift
import CoreLocation

struct ARCoordinate: Identifiable {
    let id = UUID()
    var radialDistance: Double = 0     // 미터
    var azimuth: Double = 0           // 라디안 (0~2π)
    var inclination: Double = 0       // 라디안
    var item: MissionItem
    
    /// 기존 ARGeoCoordinate.m의 calibrateUsingOrigin: 로직 그대로
    mutating func calibrate(from origin: CLLocation) {
        let itemLocation = item.location
        radialDistance = origin.distance(from: itemLocation)
        azimuth = Self.bearing(from: origin.coordinate, to: itemLocation.coordinate)
    }
    
    /// 기존 ARGeoCoordinate.m의 angleFromCoordinate:toCoordinate: 로직 그대로
    static func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let latDiff = to.latitude - from.latitude
        let lonDiff = to.longitude - from.longitude
        
        if lonDiff == 0 {
            return latDiff >= 0 ? 0 : .pi
        }
        
        var angle = (.pi * 0.5) - atan(latDiff / lonDiff)
        if lonDiff < 0 { angle += .pi }
        return angle
    }
    
    /// 기존 ARViewController.m의 pointInView:forCoordinate: 수평 부분
    func screenX(centerAzimuth: Double, viewportWidth: Double, screenWidth: Double) -> Double {
        let leftAzimuth = centerAzimuth - viewportWidth / 2.0
        let rightAzimuth = centerAzimuth + viewportWidth / 2.0
        
        if azimuth < leftAzimuth {
            return ((2 * .pi - leftAzimuth + azimuth) / viewportWidth) * screenWidth
        } else {
            return ((azimuth - leftAzimuth) / viewportWidth) * screenWidth
        }
    }
}
```

### 6.2 ARGameView (기존: ARViewController + ARGeoViewController → ARKit 기반)

```swift
// AR/ARGameView.swift
import SwiftUI
import ARKit
import RealityKit
import CoreLocation

struct ARGameView: UIViewRepresentable {
    let items: [MissionItem]
    let playerLocation: CLLocation
    let acquiredItems: Set<Int>           // dicItemEnd에서 "Y"인 아이템 ID 집합
    let powerUps: Set<String>             // dicRnPTaken 키 집합
    let onItemAcquired: (MissionItem) -> Void
    let onMineTriggered: (MissionItem) -> Void
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravityAndHeading  // 나침반 연동 — 기존 CLLocationManager heading 대체
        arView.session.run(config)
        context.coordinator.arView = arView
        return arView
    }
    
    func updateUIView(_ arView: ARView, context: Context) {
        context.coordinator.updateItems(
            items: items,
            playerLocation: playerLocation,
            acquiredItems: acquiredItems,
            powerUps: powerUps
        )
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onItemAcquired: onItemAcquired, onMineTriggered: onMineTriggered)
    }
    
    class Coordinator {
        var arView: ARView?
        let onItemAcquired: (MissionItem) -> Void
        let onMineTriggered: (MissionItem) -> Void
        private var itemAnchors: [Int: AnchorEntity] = [:]
        
        init(onItemAcquired: @escaping (MissionItem) -> Void,
             onMineTriggered: @escaping (MissionItem) -> Void) {
            self.onItemAcquired = onItemAcquired
            self.onMineTriggered = onMineTriggered
        }
        
        func updateItems(items: [MissionItem], playerLocation: CLLocation,
                         acquiredItems: Set<Int>, powerUps: Set<String>) {
            guard let arView else { return }
            
            for item in items {
                guard !acquiredItems.contains(item.itemID) else {
                    // 이미 획득한 아이템은 제거
                    if let anchor = itemAnchors[item.itemID] {
                        arView.scene.removeAnchor(anchor)
                        itemAnchors.removeValue(forKey: item.itemID)
                    }
                    continue
                }
                
                let distance = playerLocation.distance(from: item.location)
                
                // 기존 viewportContainsCoordinate:의 거리 체크: radialDistance <= rangeAR
                guard distance <= Double(item.rangeAR) else { continue }
                
                // 기존: BLACK 아이템은 AR에서 절대 안보임
                guard item.itemType != .black else { continue }
                
                // 기존: MINE은 범위 내 진입 시 자동 폭발
                if item.itemType == .mine {
                    onMineTriggered(item)
                    continue
                }
                
                // 가시성 판정 — 기존 showType + 레이더 로직
                let hasRadarAR = powerUps.contains(ItemType.radarAR.rawValue)
                let hasRadarAll = powerUps.contains(ItemType.radarAll.rawValue)
                guard item.showType.isVisibleInAR(hasRadarAR: hasRadarAR, hasRadarAll: hasRadarAll) else { continue }
                
                // ARKit 좌표 변환: GPS → 로컬 3D 좌표
                if itemAnchors[item.itemID] == nil {
                    let bearing = ARCoordinate.bearing(
                        from: playerLocation.coordinate, to: item.coordinate)
                    
                    // GPS 거리/방위각 → ARKit의 x/z 좌표
                    let x = Float(distance * sin(bearing))
                    let z = Float(-distance * cos(bearing))
                    
                    let anchor = AnchorEntity(world: SIMD3(x, 0, z))
                    
                    // 아이템 아이콘을 3D 플레인으로 표시
                    let iconName = item.itemType.arIcon(mandatory: item.isMandatory)
                    if let texture = try? TextureResource.load(named: iconName) {
                        var material = UnlitMaterial()
                        material.color = .init(texture: .init(texture))
                        // 기존 BOX_WIDTH=150, BOX_HEIGHT=100 → 실제 세계 0.3m×0.2m
                        let mesh = MeshResource.generatePlane(width: 0.3, height: 0.2)
                        let entity = ModelEntity(mesh: mesh, materials: [material])
                        entity.generateCollisionShapes(recursive: true)
                        anchor.addChild(entity)
                    }
                    
                    arView.scene.addAnchor(anchor)
                    itemAnchors[item.itemID] = anchor
                }
            }
        }
    }
}
```

### 6.3 AR 레이더 오버레이 (기존: radianPanel + radianPhone + radianItem)

```swift
// AR/ARRadarView.swift
import SwiftUI

struct ARRadarView: View {
    let playerHeading: Double        // 기기 방향 (도)
    let closestItemBearing: Double?  // 가장 가까운 아이템 방위각 (도)
    let closestItemDistance: Double?
    let closestItemType: ItemType?
    let visibleRange: Int?
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                // 좌측 정보 — 기존 ar_infoView: "ItemType:XXXm"
                if let type = closestItemType, let dist = closestItemDistance {
                    Text("\(type.displayName):\(Int(dist))m")
                        .font(.caption)
                        .padding(6)
                        .background(.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                // 레이더 — 기존 radianPanel (319x61)
                ZStack {
                    // 기존 radar_body.png
                    Image("radar_body")
                        .resizable()
                        .frame(width: 160, height: 30)
                    
                    // 기기 방향 — 기존 radianPhone (radar_myway.png)
                    Image("radar_myway")
                        .resizable()
                        .frame(width: 16, height: 14)
                        .rotationEffect(.degrees(playerHeading))
                    
                    // 아이템 방향 — 기존 radianItem (radar_item.png)
                    if let bearing = closestItemBearing {
                        Image("radar_item")
                            .resizable()
                            .frame(width: 6, height: 12)
                            .rotationEffect(.degrees(bearing))
                    }
                }
                
                Spacer()
                
                // 우측 정보 — 기존 ar_infoView1: "Radius:XXXm"
                if let range = visibleRange {
                    Text("Radius:\(range)m")
                        .font(.caption)
                        .padding(6)
                        .background(.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}
```

---

## 7. Phase 6 — 게임 엔진 (핵심 로직)

기존 `MissionPlay.m` (2,259줄)의 비즈니스 로직을 UI에서 분리.

### 7.1 GameEngine (기존: MissionPlay.setupPlay + 상태 관리)

```swift
// Game/GameEngine.swift
import Foundation
import CoreLocation
import Observation

@Observable
final class GameEngine {
    // MARK: - 상태 (기존 MissionPlay.h 프로퍼티)
    var missionStarted = false
    var missionCompleted = false
    var isMissionEnd = false
    var isVirtualMode = false
    
    var dicItemEnd: [Int: String] = [:]         // itemID → "Y"/"N"
    var dicRnPTaken: [String: Int] = [:]        // itemType.rawValue → ableCnt
    
    var missionStartTime: Date?
    var timeOutStartTime: Date?
    var timeOutLimitTime: Int = 0
    var isTimeOutActive = false
    
    var elapsedTime: TimeInterval = 0
    var remainingRunTime: TimeInterval = 0
    
    var mineCount = 0
    var mandatoryRemaining = 0
    var hiddenOnMapCount = 0
    var stealthOnARCount = 0
    
    // MARK: - 데이터
    private(set) var mission: Mission?
    private(set) var items: [MissionItem] = []
    private(set) var annotations: [MissionItem] = []  // 지도 표시용
    
    private let missionRepo = MissionRepository()
    private let itemRepo = MissionItemRepository()
    private let playRepo = PlayStateRepository()
    private let quizRepo = QuizRepository()
    private let powerUpRepo = PowerUpRepository()
    
    private var playerID: String { AppState.shared.userID }
    private var timer: Timer?
    
    // MARK: - 초기화 (기존: setupPlay)
    
    /// 기존 MissionPlay.m setupPlay 메서드 전체 흐름
    func setup(missionID: String, isNewStart: Bool, virtualMode: Bool) throws {
        self.isVirtualMode = virtualMode
        
        // 1. DB에서 미션/아이템 로드
        guard var loadedMission = try missionRepo.fetchByID(missionID) else { return }
        let loadedItems = try itemRepo.fetchByMissionID(missionID)
        
        // 퀴즈 로드
        for i in loadedItems.indices {
            if loadedItems[i].itemType == .quiz || loadedItems[i].itemType == .quiz20 {
                loadedItems[i].quizzes = try quizRepo.fetchByItem(
                    missionID: missionID, itemID: loadedItems[i].itemID)
            }
        }
        loadedMission.items = loadedItems
        
        // 2. 신규 시작이면 이전 기록 삭제 (기존: isNewStart == 1)
        if isNewStart {
            try playRepo.deleteAll(missionID: missionID, playerID: playerID)
            try powerUpRepo.deleteAll(missionID: missionID, playerID: playerID)
        }
        
        // 3. MissionInPlay 생성 또는 로드
        var playState = try playRepo.fetchMissionInPlay(missionID: missionID, playerID: playerID)
        if playState == nil {
            // START 아이템 유무 확인 (기존: startItemExists)
            let hasStart = try itemRepo.startItemExists(missionID: missionID)
            let newPlay = MissionInPlay(
                missionID: missionID,
                playerID: playerID,
                startYN: hasStart ? "N" : "Y",     // START 없으면 즉시 시작
                startTime: hasStart ? nil : Date()
            )
            try playRepo.insertMissionInPlay(newPlay)
            playState = newPlay
            missionStarted = !hasStart
        } else {
            missionStarted = playState?.hasStarted ?? false
        }
        
        if missionStarted { missionStartTime = playState?.startTime }
        
        // 4. 아이템 진행 상태 로드 (기존: selectDicAt)
        dicItemEnd = try playRepo.fetchItemStatusDict(missionID: missionID, playerID: playerID)
        dicRnPTaken = try powerUpRepo.fetchPowerUpDict(missionID: missionID, playerID: playerID)
        
        // 5. 타임아웃 복원 (기존: selectLastStartedTimeOut)
        if let timeout = try playRepo.fetchActiveTimeout(missionID: missionID, playerID: playerID) {
            timeOutStartTime = timeout.endTime
            if let startItem = loadedItems.first(where: { $0.itemID == timeout.itemID }),
               let endItem = loadedItems.first(where: { $0.itemType == .timeoutEnd && $0.relationItemID == startItem.itemID }) {
                timeOutLimitTime = endItem.effectiveTime
                isTimeOutActive = true
            }
        }
        
        // 6. Virtual Mode 좌표 오프셋
        if virtualMode, let location = LocationService.shared.currentLocation {
            VirtualModeManager.applyOffset(items: &loadedMission.items, playerLocation: location, isNewStart: isNewStart)
        }
        
        self.mission = loadedMission
        self.items = loadedMission.items
        
        // 7. 카운터 업데이트
        updateCounters()
        
        // 8. 타이머 시작 (기존: passedTimer, 1초 간격)
        startTimer()
    }
    
    // MARK: - 타이머 (기존: updatePassedTime:)
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    private func tick() {
        guard missionStarted, let startTime = missionStartTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime)
        
        if isTimeOutActive, let timeoutStart = timeOutStartTime {
            remainingRunTime = Double(timeOutLimitTime) - Date().timeIntervalSince(timeoutStart)
            if remainingRunTime <= 0 {
                isTimeOutActive = false
                // TODO: finishRunTimeAlert 호출
            }
        }
    }
    
    // MARK: - 지뢰 폭발 (기존: mineBlast:)
    
    func handleMineBlast(item: MissionItem) throws {
        // 1. Defence 파워업 확인
        if let defenseCount = dicRnPTaken[ItemType.mineNoBomb.rawValue], defenseCount > 0 {
            // 보호됨 — ableCnt 감소
            dicRnPTaken[ItemType.mineNoBomb.rawValue] = defenseCount - 1
            try powerUpRepo.decrementCount(
                missionID: mission!.id, playerID: playerID,
                itemType: ItemType.mineNoBomb.rawValue)
            return  // 폭발 없음
        }
        
        // 2. 지뢰 수집 처리
        dicItemEnd[item.itemID] = "Y"
        var minePlay = MissionItemInPlay(missionID: mission!.id, playerID: playerID, itemID: item.itemID)
        minePlay.endYN = "Y"
        minePlay.endTime = Date()
        try playRepo.updateItemInPlay(minePlay)
        
        // 3. 최근 획득 아이템 되돌리기 (기존: selectLastAcquiredItem)
        if let lastItem = try playRepo.fetchLastAcquiredItem(
            missionID: mission!.id, playerID: playerID, excludeItemID: item.itemID) {
            dicItemEnd[lastItem.itemID] = "N"
            var revert = lastItem
            revert.endYN = "N"
            try playRepo.updateItemInPlay(revert)
        }
        
        // 4. 타임아웃 중이면 취소
        if isTimeOutActive {
            isTimeOutActive = false
        }
        
        updateCounters()
        
        SoundService.shared.play(.explosion)
        HapticService.shared.vibrate()
    }
    
    // MARK: - 아이템 획득 (기존: getItem:)
    
    func acquireItem(_ item: MissionItem) throws {
        dicItemEnd[item.itemID] = "Y"
        var itemPlay = MissionItemInPlay(
            missionID: mission!.id, playerID: playerID, itemID: item.itemID)
        itemPlay.endYN = "Y"
        itemPlay.endTime = Date()
        try playRepo.saveItemInPlay(itemPlay)
        
        // 파워업 처리
        if item.itemType.isRadar || item.itemType == .mineNoBomb || item.itemType == .solution {
            let rnp = ItemRnPInPlay(
                missionID: mission!.id, playerID: playerID,
                itemType: item.itemType.rawValue, ableCnt: 1, acquiredTime: Date())
            try powerUpRepo.save(rnp)
            dicRnPTaken[item.itemType.rawValue] = (dicRnPTaken[item.itemType.rawValue] ?? 0) + 1
        }
        
        // Gambling 처리 (기존: selectRand → 랜덤 1개 획득)
        if item.itemType == .random {
            let candidates = try playRepo.fetchRandomCandidates(
                missionID: mission!.id, playerID: playerID)
            if let lucky = candidates.randomElement() {
                try acquireItem(lucky)
            }
        }
        
        // Start 아이템 → 미션 시작
        if item.itemType == .start && !missionStarted {
            missionStarted = true
            missionStartTime = Date()
            var play = MissionInPlay(missionID: mission!.id, playerID: playerID, startYN: "Y", startTime: Date())
            try playRepo.updateMissionInPlay(play)
        }
        
        // Run Start → 타임아웃 시작
        if item.itemType == .timeoutStart {
            timeOutStartTime = Date()
            if let endItem = items.first(where: { $0.itemType == .timeoutEnd && $0.relationItemID == item.itemID }) {
                timeOutLimitTime = endItem.effectiveTime
                isTimeOutActive = true
            }
        }
        
        // Run End → 타임아웃 종료
        if item.itemType == .timeoutEnd { isTimeOutActive = false }
        
        // End 아이템 → 미션 완료 확인
        if item.itemType == .end {
            if try playRepo.isMissionCompleted(missionID: mission!.id, playerID: playerID) {
                missionCompleted = true
                isMissionEnd = true
            }
        }
        
        updateCounters()
        SoundService.shared.play(.itemGet)
    }
    
    // MARK: - 카운터 업데이트 (기존: InfoUpdate / updatePlayInfo)
    
    func updateCounters() {
        let hasRadarMap = dicRnPTaken[ItemType.radarMap.rawValue] != nil
        let hasRadarAR = dicRnPTaken[ItemType.radarAR.rawValue] != nil
        let hasRadarAll = dicRnPTaken[ItemType.radarAll.rawValue] != nil
        let hasRadarMine = dicRnPTaken[ItemType.radarMine.rawValue] != nil
        
        mineCount = 0; mandatoryRemaining = 0; hiddenOnMapCount = 0; stealthOnARCount = 0
        
        for item in items {
            guard dicItemEnd[item.itemID] != "Y" else { continue }
            
            if item.itemType.isMine && !hasRadarMine { mineCount += 1 }
            if item.isMandatory { mandatoryRemaining += 1 }
            if !item.showType.isVisibleOnMap(hasRadarMap: hasRadarMap, hasRadarAll: hasRadarAll) {
                hiddenOnMapCount += 1
            }
            if !item.showType.isVisibleInAR(hasRadarAR: hasRadarAR, hasRadarAll: hasRadarAll) {
                stealthOnARCount += 1
            }
        }
    }
    
    deinit { timer?.invalidate() }
}
```

### 7.2 VirtualModeManager (기존: MissionPlay.virtualMode:)

```swift
// Game/VirtualModeManager.swift
import CoreLocation

enum VirtualModeManager {
    /// 기존 MissionPlay.m virtualMode: 로직 — 좌표 오프셋 적용
    static func applyOffset(items: inout [MissionItem], playerLocation: CLLocation, isNewStart: Bool) {
        // START 아이템 찾기
        guard let startItem = items.first(where: { $0.itemType == .start }) else { return }
        
        let latOffset = playerLocation.coordinate.latitude - startItem.latitude
        let lonOffset = playerLocation.coordinate.longitude - startItem.longitude
        
        // 모든 아이템에 오프셋 적용
        for i in items.indices {
            items[i].latitude += latOffset
            items[i].longitude += lonOffset
        }
    }
}
```

---

## 8. Phase 7 — UI (SwiftUI)

### 8.1 앱 진입점 (기존: TreasureHunterAppDelegate)

```swift
// PlaySpotApp.swift
import SwiftUI

@main
struct PlaySpotApp: App {
    @State private var appState = AppState.shared
    
    init() {
        try? DatabaseManager.shared.setup()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(appState)
        }
    }
}

// 기존 AppDelegate 전역 상태 → @Observable 싱글턴
@Observable
final class AppState {
    static let shared = AppState()
    
    let locationService = LocationService()
    
    var userID: String {
        get { UserDefaults.standard.string(forKey: "gUserID") ?? guestUserID }
        set { UserDefaults.standard.set(newValue, forKey: "gUserID") }
    }
    
    var guestUserID: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMddhhmmssSSS"
        return "Guest@\(formatter.string(from: Date()))"
    }
    
    var isGuest: Bool { userID.hasPrefix("Guest@") }
    
    var solutionCount: Int {
        get { UserDefaults.standard.integer(forKey: "solution") }
        set { UserDefaults.standard.set(max(0, newValue), forKey: "solution") }
    }
    
    var timeAddCount: Int {
        get { UserDefaults.standard.integer(forKey: "timeAdd") }
        set { UserDefaults.standard.set(max(0, newValue), forKey: "timeAdd") }
    }
}
```

### 8.2 메인 탭 (기존: UITabBarController + 5개 탭)

```swift
// Views/App/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) var appState
    @State private var selectedTab = 0
    @State private var showLogin = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 기존 탭 0: 미션 목록
            MissionListView()
                .tabItem { Label("Missions", image: "menu_list") }
                .tag(0)
            
            // 기존 탭 1: 미션 디자인
            MissionBuilderListView()
                .tabItem { Label("Design", image: "menu_design") }
                .tag(1)
            
            // 기존 탭 2: 내 정보
            MyInfoView()
                .tabItem { Label("My Info", image: "menu_info") }
                .tag(2)
            
            // 기존 탭 3: 배지
            BadgeListView()
                .tabItem { Label("Badge", image: "menu_board") }
                .tag(3)
            
            // 기존 탭 4: 설정
            SettingsView()
                .tabItem { Label("Settings", image: "menu_help") }
                .tag(4)
        }
        // 기존: tabBarController:didSelectViewController: — 게스트일 때 로그인 필요
        .onChange(of: selectedTab) { _, newTab in
            if appState.isGuest && [1, 2, 3].contains(newTab) {
                showLogin = true
                selectedTab = 0
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
        }
    }
}
```

### 8.3 미션 플레이 화면 (기존: MissionPlay.h/m — 지도 + 상태바 + 타이머)

```swift
// Views/MissionPlay/MissionPlayView.swift
import SwiftUI
import MapKit

struct MissionPlayView: View {
    @State private var engine = GameEngine()
    @State private var showAR = false
    @State private var showInfo = false
    @State private var showQuiz: MissionItem?
    @State private var showMiniGame: MissionItem?
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    let missionID: String
    let isNewStart: Bool
    let isVirtualMode: Bool
    
    var body: some View {
        ZStack {
            // MARK: - 지도 (기존 MKMapView)
            Map(position: $cameraPosition) {
                // 기존 mapView:viewForAnnotation: 로직
                ForEach(engine.items, id: \.itemID) { item in
                    if shouldShowOnMap(item) {
                        Annotation(item.itemType.displayName, coordinate: item.coordinate) {
                            Image(item.itemType.mapIcon(mandatory: item.isMandatory))
                                .resizable()
                                .frame(width: 30, height: 30)
                                .grayscale(engine.dicItemEnd[item.itemID] == "Y" ? 1.0 : 0.0)
                                .onTapGesture { handleItemTap(item) }
                        }
                    }
                }
                
                // 기존 mapView:viewForOverlay: — 지뢰/Dark 영역 원
                ForEach(engine.items.filter { shouldShowCircle($0) }, id: \.itemID) { item in
                    MapCircle(center: item.coordinate, radius: CLLocationDistance(item.rangeAR))
                        .foregroundStyle(circleColor(for: item).opacity(0.3))
                        .stroke(circleColor(for: item), lineWidth: 1)
                }
            }
            .mapControls { MapUserLocationButton() }
            
            VStack {
                // MARK: - 타이머 (기존 SBTickerView 6개 → 디지털 시계)
                GameTimerView(
                    elapsedTime: engine.elapsedTime,
                    isTimeOutActive: engine.isTimeOutActive,
                    remainingRunTime: engine.remainingRunTime
                )
                
                Spacer()
                
                // MARK: - 상태 바 (기존 statusView — mine/mandatory/hidden/stealth)
                GameStatusBar(
                    mineCount: engine.mineCount,
                    mandatoryRemaining: engine.mandatoryRemaining,
                    hiddenOnMap: engine.hiddenOnMapCount,
                    stealthOnAR: engine.stealthOnARCount
                )
                
                // MARK: - AR 카메라 버튼 (기존 bCamera, playAR_button.png)
                Button(action: { showAR = true }) {
                    Image("playAR_button")
                        .resizable()
                        .frame(width: 60, height: 60)
                }
                .padding(.bottom, 8)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Exit") { /* 기존 ExitClick */ }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showInfo = true }) {
                    Image("button_info")
                }
            }
        }
        .fullScreenCover(isPresented: $showAR) {
            ARGameView(
                items: engine.items,
                playerLocation: LocationService.shared.currentLocation ?? CLLocation(),
                acquiredItems: Set(engine.dicItemEnd.filter { $0.value == "Y" }.keys),
                powerUps: Set(engine.dicRnPTaken.filter { $0.value > 0 }.keys),
                onItemAcquired: { item in try? engine.acquireItem(item) },
                onMineTriggered: { item in try? engine.handleMineBlast(item: item) }
            )
        }
        .sheet(isPresented: $showInfo) {
            MissionInfoSheet(engine: engine)
        }
        .sheet(item: $showQuiz) { item in
            QuizView(item: item, engine: engine)
        }
        .task {
            try? engine.setup(missionID: missionID, isNewStart: isNewStart, virtualMode: isVirtualMode)
        }
    }
    
    // MARK: - 가시성 판정 (기존 mapView:viewForAnnotation: 내 조건문)
    
    private func shouldShowOnMap(_ item: MissionItem) -> Bool {
        let hasRadarMap = engine.dicRnPTaken[ItemType.radarMap.rawValue] != nil
        let hasRadarAll = engine.dicRnPTaken[ItemType.radarAll.rawValue] != nil
        return item.showType.isVisibleOnMap(hasRadarMap: hasRadarMap, hasRadarAll: hasRadarAll)
    }
    
    private func shouldShowCircle(_ item: MissionItem) -> Bool {
        guard engine.missionStarted else { return false }
        let hasRadarMine = engine.dicRnPTaken[ItemType.radarMine.rawValue] != nil
        return (item.itemType == .mine && hasRadarMine) || item.itemType == .black
    }
    
    private func circleColor(for item: MissionItem) -> Color {
        item.itemType == .mine ? .red : .black
    }
    
    private func handleItemTap(_ item: MissionItem) {
        if item.itemType == .quiz || item.itemType == .quiz20 {
            showQuiz = item
        } else if item.itemGame > 0 {
            showMiniGame = item
        }
    }
}
```

### 8.4 퀴즈 뷰 (기존: QuizPlayAlert — UIAlertView 서브클래스)

```swift
// Views/MissionPlay/QuizView.swift
import SwiftUI

struct QuizView: View {
    let item: MissionItem
    @Bindable var engine: GameEngine
    
    @State private var answer = ""
    @State private var currentQuiz: ItemQuiz?
    @State private var failCount = 0
    @State private var showHint = false
    @State private var showResult: QuizResult?
    @Environment(\.dismiss) var dismiss
    
    enum QuizResult { case correct, wrong }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 아이콘 — 기존 ArIconView (맥동 애니메이션)
                Image(item.itemType.arIcon(mandatory: item.isMandatory))
                    .resizable()
                    .frame(width: 60, height: 60)
                    .pulseAnimation()
                
                // 퀴즈 문제 — 기존 questionView
                if let quiz = currentQuiz {
                    Text(quiz.quiz)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // 답 입력 — 기존 answerField
                TextField(String(localized: "quiz_message_0"), text: $answer)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                // 힌트 — 기존: 1차 실패 → 글자 수, 2차 실패 → 첫 글자
                if showHint, let quiz = currentQuiz {
                    Text(hintText(for: quiz))
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                HStack(spacing: 16) {
                    // Solution 버튼 — 기존 solutionButton
                    if AppState.shared.solutionCount > 0 {
                        Button(String(localized: "quiz_button_0")) {
                            answer = currentQuiz?.answer ?? ""
                        }
                    }
                    
                    // 제출 — 기존 homeButton
                    Button(String(localized: "ok")) { checkAnswer() }
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Quiz")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) { dismiss() }
                }
            }
            .onAppear { pickQuiz() }
        }
    }
    
    /// 기존 QuizPlayAlert initWithItem: 에서 랜덤 퀴즈 선택
    private func pickQuiz() {
        currentQuiz = item.quizzes.randomElement()
    }
    
    /// 기존 QuizPlayAlert의 homeButton 액션
    private func checkAnswer() {
        guard let quiz = currentQuiz else { return }
        // 기존: 대소문자 무시 비교
        if answer.trimmingCharacters(in: .whitespaces).caseInsensitiveCompare(quiz.answer) == .orderedSame {
            try? engine.acquireItem(item)
            SoundService.shared.play(.quizCorrect)
            HapticService.shared.vibrate()
            dismiss()
        } else {
            failCount += 1
            showHint = true
            SoundService.shared.play(.quizWrong)
            answer = ""
            // 기존 failQuiz: 다른 퀴즈 변형으로 교체
            if item.quizzes.count > 1 { pickQuiz() }
        }
    }
    
    /// 기존: 1차 = 글자 수 힌트, 2차 이후 = 첫 글자 힌트
    private func hintText(for quiz: ItemQuiz) -> String {
        if failCount == 1 {
            return String(format: String(localized: "quiz_6"), quiz.answer.count)
        } else {
            return String(format: String(localized: "quiz_7"), String(quiz.answer.prefix(1)))
        }
    }
}
```

### 8.5 게임 시작 모달 (기존: StartGameAlert — Real/Virtual 선택)

```swift
// Views/MissionPlay/StartGameView.swift
import SwiftUI

struct StartGameView: View {
    @State private var playMode: PlayMode = .virtual
    let onStart: (PlayMode, Bool) -> Void  // (모드, 신규 여부)
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Play Mode")
                .font(.headline)
            
            // 기존 segControl (Virtual/Real)
            Picker("Mode", selection: $playMode) {
                Text("Virtual").tag(PlayMode.virtual)
                Text("Real").tag(PlayMode.real)
            }
            .pickerStyle(.segmented)
            
            HStack(spacing: 16) {
                // 기존 btnLeft: "Detail_7" — 연습/미리보기
                Button(String(localized: "Detail_7")) {
                    onStart(playMode, false)  // 이어하기
                    dismiss()
                }
                
                // 기존 btnRight: "Detail_8" — 시작
                Button(String(localized: "Detail_8")) {
                    onStart(playMode, true)   // 신규 시작
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
```

### 8.6 미니게임 뷰 (기존: GamePlayAlert — Touch/Shake)

```swift
// Views/MissionPlay/MiniGameView.swift
import SwiftUI

struct MiniGameView: View {
    let item: MissionItem
    let onComplete: () -> Void
    @State private var progress: Double = 0
    @State private var motionService = MotionService()
    @Environment(\.dismiss) var dismiss
    
    // 기존 GamePlayAlert: type=0 Touch, type=1 Shake
    // 기존 level별 진행도: L1=+6/+7, L2=+5/+6, L3=+4/+5, L4=+7/+8
    private var incrementPerAction: Double {
        switch item.itemGame {
        case 1: return 6.5
        case 2: return 5.5
        case 3: return 4.5
        case 4: return 7.5
        default: return 6.0
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // 프로그레스 바 (기존 progressView + progressTopView)
            ProgressView(value: progress, total: 100)
                .scaleEffect(y: 3)
                .padding(.horizontal)
            
            Text("\(Int(progress))%")
                .font(.largeTitle.bold())
            
            if item.itemGame % 2 == 0 {
                // Touch 모드 — 기존 game_touch.png
                Button(action: { handleAction() }) {
                    Image("game_touch1")
                        .resizable()
                        .frame(width: 150, height: 200)
                }
            } else {
                // Shake 모드 — 기존 game_shake.png
                Image("game_shake1")
                    .resizable()
                    .frame(width: 150, height: 200)
                Text("Shake your phone!")
                    .font(.headline)
            }
        }
        .onChange(of: motionService.isShaking) { _, shaking in
            if shaking { handleAction() }
        }
        .onAppear {
            if item.itemGame % 2 == 1 { motionService.startAccelerometer() }
        }
        .onDisappear { motionService.stopAccelerometer() }
    }
    
    private func handleAction() {
        progress = min(100, progress + incrementPerAction)
        SoundService.shared.play(.gameTouch)
        if progress >= 100 {
            onComplete()
            dismiss()
        }
    }
}
```

### 8.7 미션 빌더 (기존: MissionBuilder — 지도에 아이템 배치)

```swift
// Views/MissionBuilder/MissionBuilderView.swift
import SwiftUI
import MapKit

struct MissionBuilderView: View {
    @State private var mission: Mission
    @State private var selectedItem: MissionItem?
    @State private var showItemPicker = false
    @State private var showItemDetail = false
    @State private var showMissionSetup = false
    @State private var tapCoordinate: CLLocationCoordinate2D?
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        ZStack {
            // 기존 MKMapView + UITapGestureRecognizer
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    ForEach(mission.items, id: \.itemID) { item in
                        Annotation(item.itemType.displayName, coordinate: item.coordinate) {
                            // 기존: draggable annotation
                            Image(item.itemType.mapIcon(mandatory: item.isMandatory))
                                .resizable()
                                .frame(width: 30, height: 30)
                                .onTapGesture {
                                    selectedItem = item
                                    showItemDetail = true
                                }
                        }
                    }
                    
                    // 지뢰/Dark 오버레이 (기존 overlayRefresh)
                    ForEach(mission.items.filter { $0.itemType.isMine || $0.itemType == .black }, id: \.itemID) { item in
                        MapCircle(center: item.coordinate, radius: CLLocationDistance(item.rangeAR))
                            .foregroundStyle(item.itemType == .mine ? Color.red.opacity(0.3) : Color.black.opacity(0.3))
                    }
                }
                .onTapGesture { position in
                    // 기존 openItemPicker: — 탭 좌표 → 지도 좌표 변환
                    if let coord = proxy.convert(position, from: .local) {
                        tapCoordinate = coord
                        showItemPicker = true
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // 기존 editSaveClick
                Button("Save") { saveMission() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                // 기존 MissionBuilderInfo 화면
                Button("Setup") { showMissionSetup = true }
            }
        }
        .sheet(isPresented: $showItemPicker) {
            // 기존 MultiPickerView — 아이템 타입/투명도/범위 3단계 선택
            ItemPickerView { itemType, showType, rangeAR in
                addItem(type: itemType, show: showType, range: rangeAR)
            }
        }
        .sheet(item: $selectedItem) { item in
            // 기존 MissionBuilderDetail
            ItemDetailView(item: item, mission: $mission)
        }
        .sheet(isPresented: $showMissionSetup) {
            MissionSetupView(mission: $mission)
        }
    }
    
    /// 기존 MultiPickerView 선택 완료 → 아이템 생성
    private func addItem(type: ItemType, show: ShowType, range: Int) {
        guard let coord = tapCoordinate else { return }
        var item = mission.addItem()
        item.itemType = type
        item.showType = show
        item.rangeAR = range
        item.latitude = coord.latitude
        item.longitude = coord.longitude
    }
    
    /// 기존 dataCheck + localdbInput 로직
    private func saveMission() {
        guard validateMission() else { return }
        do {
            try MissionRepository().save(mission)
            for item in mission.items {
                try MissionItemRepository().save(item)
                for quiz in item.quizzes {
                    try QuizRepository().save(quiz)
                }
            }
        } catch {
            // 에러 처리
        }
    }
    
    /// 기존 MissionBuilder.m dataCheck — 유효성 검사 17개 규칙
    private func validateMission() -> Bool {
        guard !mission.title.isEmpty else { return false }
        guard !mission.description.isEmpty else { return false }
        guard !mission.place.isEmpty else { return false }
        guard mission.items.count >= 3 else { return false }
        
        let starts = mission.items.filter { $0.itemType == .start }
        let ends = mission.items.filter { $0.itemType == .end }
        guard starts.count == 1, ends.count == 1 else { return false }
        
        // 퀴즈 검증
        for item in mission.items where item.itemType == .quiz || item.itemType == .quiz20 {
            guard !item.quizzes.isEmpty else { return false }
            for q in item.quizzes {
                guard !q.quiz.isEmpty, !q.answer.isEmpty else { return false }
            }
        }
        
        // 타임아웃 짝 검증
        let timeoutStarts = mission.items.filter { $0.itemType == .timeoutStart }.count
        let timeoutEnds = mission.items.filter { $0.itemType == .timeoutEnd }.count
        guard timeoutStarts == timeoutEnds else { return false }
        
        return true
    }
}
```

---

## 9. Phase 8 — 인앱 결제 (StoreKit 2)

기존 `SKPaymentQueue` + `SKPaymentTransactionObserver` → **StoreKit 2 async API**

```swift
// Services/StoreService.swift
import StoreKit

actor StoreService {
    static let shared = StoreService()
    
    // 기존 product ID: "time_add_10", "solution_add_10"
    enum ProductID: String {
        case timeAdd = "time_add_10"
        case solutionAdd = "solution_add_10"
    }
    
    private var products: [Product] = []
    
    func loadProducts() async throws {
        products = try await Product.products(for: [ProductID.timeAdd.rawValue, ProductID.solutionAdd.rawValue])
    }
    
    /// 기존 MyInfo.m / QuizPlayAlert.m의 startPayment: 대체
    func purchase(_ productID: ProductID) async throws -> Bool {
        guard let product = products.first(where: { $0.id == productID.rawValue }) else { return false }
        
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try verification.payloadValue
            // 기존 completeTransaction: → resultbuy: 로직
            switch productID {
            case .timeAdd: AppState.shared.timeAddCount += 10
            case .solutionAdd: AppState.shared.solutionCount += 10
            }
            await transaction.finish()
            return true
        case .pending, .userCancelled: return false
        @unknown default: return false
        }
    }
}
```

---

## 10. Phase 9 — 사운드 & 햅틱

기존 `AudioToolbox` + `AudioServicesCreateSystemSoundID` → **AVFoundation + UIImpactFeedbackGenerator**

```swift
// Services/SoundService.swift
import AVFoundation

final class SoundService {
    static let shared = SoundService()
    
    // 기존 soundIDDic 캐시 → AVAudioPlayer 캐시
    private var players: [SoundEffect: AVAudioPlayer] = [:]
    
    /// 기존 사운드 파일 매핑 (Resources/sounds/)
    enum SoundEffect: String {
        case explosion = "s_explosion"
        case timer = "s_timer"
        case timeOver = "s_timeover"
        case quizCorrect = "quiz_rightanswer"
        case quizWrong = "quiz_wronganswer"
        case quizFail = "s_quiz_fail"
        case itemGet = "s_yougotit"
        case applause = "s_applause"
        case goGoGo = "s_gogogo"
        case gameTouch = "s_game_touch"
        case radar = "s_radar"
        case gameFinish = "game_finish"
        case winSomething = "s_winsomething"
    }
    
    /// 기존 AppDelegate.playSystemSound:fileType: 대체
    func play(_ effect: SoundEffect) {
        if players[effect] == nil {
            // 기존: mp3 우선, wav 폴백
            let extensions = ["mp3", "wav"]
            for ext in extensions {
                if let url = Bundle.main.url(forResource: effect.rawValue, withExtension: ext) {
                    players[effect] = try? AVAudioPlayer(contentsOf: url)
                    break
                }
            }
        }
        players[effect]?.play()
    }
}

// Services/HapticService.swift
import UIKit

final class HapticService {
    static let shared = HapticService()
    
    /// 기존 AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) 대체
    func vibrate() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
```

---

## 11. Phase 10 — 이미지 매니저

기존 `ImageManager` (동기 다운로드 + Documents 캐시) → **async + FileManager 캐시**

```swift
// Services/ImageCacheService.swift
import UIKit

actor ImageCacheService {
    static let shared = ImageCacheService()
    
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    /// 기존 ImageManager.loadBadgeImg: — 로컬 캐시 → 서버 다운로드 → empty02 폴백
    func loadBadgeImage(missionID: String) async -> UIImage {
        let localURL = documentsURL.appendingPathComponent("\(missionID).png")
        
        // 1. 로컬 캐시 확인 (기존 동일)
        if let image = UIImage(contentsOfFile: localURL.path) {
            return image
        }
        
        // 2. 서버에서 다운로드 (기존: http://nexapp.co.kr/playspot/badge/{missionID}.png)
        let remoteURL = URL(string: "\(APIEndpoint.badgeBaseURL)\(missionID).png")!
        do {
            let (data, _) = try await URLSession.shared.data(from: remoteURL)
            if let image = UIImage(data: data) {
                // 로컬에 저장 (기존 동일)
                try? UIImagePNGRepresentation(image)?.write(to: localURL)
                return image
            }
        } catch { }
        
        // 3. 폴백 (기존: empty02.png)
        return UIImage(named: "empty02") ?? UIImage()
    }
    
    /// 기존 ImageManager.uploadImgWithID:Image: — multipart POST
    func uploadBadge(imageID: String, image: UIImage) async throws {
        var request = URLRequest(url: APIEndpoint.imageUploadURL)
        request.httpMethod = "POST"
        let boundary = "treasurehunter"  // 기존 boundary 동일
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"userfile\"; filename=\"\(imageID)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(image.pngData()!)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let _ = try await URLSession.shared.data(for: request)
    }
    
    /// 기존 ImageManager.maskImage: — CGImageMask 적용
    func applyMask(to image: UIImage) -> UIImage {
        guard let maskImage = UIImage(named: "mask1"),
              let maskRef = maskImage.cgImage,
              let imageRef = image.cgImage else { return image }
        
        let mask = CGImage(maskWidth: maskRef.width, height: maskRef.height,
                           bitsPerComponent: maskRef.bitsPerComponent,
                           bitsPerPixel: maskRef.bitsPerPixel,
                           bytesPerRow: maskRef.bytesPerRow,
                           provider: maskRef.dataProvider!,
                           decode: nil, shouldInterpolate: false)!
        
        if let masked = imageRef.masking(mask) {
            return UIImage(cgImage: masked)
        }
        return image
    }
}

private func UIImagePNGRepresentation(_ image: UIImage) -> Data? {
    image.pngData()
}
```

---

## 12. Phase 11 — 인증 시스템

기존 `Login.m` + `UserReg.m` (MD5 + 서버 POST) → **SwiftUI + async**

```swift
// Views/Auth/LoginView.swift
import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                
                if let error = errorMessage {
                    Text(error).foregroundColor(.red)
                }
                
                Button(isLoading ? "..." : String(localized: "success_login")) {
                    Task { await login() }
                }
                .disabled(isLoading)
            }
            .navigationTitle("Login")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("Register") { RegisterView() }
                }
            }
        }
    }
    
    /// 기존 Login.m checkLogin:pwd: + didReceiveFinished:
    private func login() async {
        isLoading = true
        defer { isLoading = false }
        
        let md5Password = APIClient.md5(password)  // 기존 MD5 해싱
        do {
            let result = try await APIClient.shared.request(
                .login(userID: email, passwordMD5: md5Password))
            
            if result.trimmingCharacters(in: .whitespacesAndNewlines) == "SUCCESS" {
                AppState.shared.userID = email
                dismiss()
            } else {
                errorMessage = String(localized: "fail_login_message")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

---

## 13. Phase 12 — 리소스 마이그레이션

### 13.1 이미지 에셋 이관

기존 `Resources/img/` 파일들을 `Assets.xcassets`로 이관:

| 기존 경로 | 대상 | 비고 |
|-----------|------|------|
| `Resources/img/ar_*.png` | `Assets.xcassets/AR/` | AR 아이콘 17개 |
| `Resources/img/arn_*.png` | `Assets.xcassets/AR/` | AR 필수 아이콘 16개 |
| `Resources/img/i_*.png` | `Assets.xcassets/Items/` | 지도 아이콘 20개 |
| `Resources/img/in_*.png` | `Assets.xcassets/Items/` | 지도 필수 아이콘 16개 |
| `Resources/img/radar_*.png` | `Assets.xcassets/Radar/` | 레이더 UI 4개 |
| `Resources/img/game_*.png` | `Assets.xcassets/Game/` | 미니게임 8개 |
| `Resources/img/tutorial*` | `Assets.xcassets/Tutorial/` | 튜토리얼 12개 |
| `Resources/img/button_*.png` | `Assets.xcassets/UI/` | 버튼 아이콘 |
| `Resources/img/popup*.png` | `Assets.xcassets/UI/` | 팝업 배경 |
| `Resources/img/login*.png` | `Assets.xcassets/Auth/` | 로그인 UI |
| `Resources/ImgBadg/*.png` | `Assets.xcassets/Badges/` | 배지 ~75개 |

### 13.2 사운드 파일

`Resources/sounds/` → `PlaySpot/Resources/Sounds/` (22개 파일 그대로 복사)

### 13.3 데이터베이스

`Resources/treasure.sqlite` → `PlaySpot/Resources/treasure.sqlite` (번들 리소스)

### 13.4 로컬라이제이션

기존 `.strings` → Xcode 15+ `.xcstrings` 형식으로 변환:

```bash
# 기존 149개 키-값 쌍을 xcstrings로 변환
# Xcode에서 자동 마이그레이션 지원
```

기존 키 중 수정이 필요한 것들:
- `"builer_word_*"` → 오타 유지 (서버 호환)
- `"appDel_game*"` → `GameEngine`에서 직접 참조

### 13.5 pickerData.plist

`Classes/others/pickerData.plist` → `PlaySpot/Resources/pickerData.plist`
기존 3단계 picker 데이터(아이템타입→투명도→범위) 그대로 사용.

### 13.6 폰트

`NanumGothic.ttf` → `Assets.xcassets` 또는 번들 리소스로 등록.
Info.plist의 `UIAppFonts` 설정 유지.

---

## 14. Phase 13 — 테스트

### 14.1 단위 테스트

| 테스트 대상 | 검증 내용 |
|------------|----------|
| `ItemType` enum | rawValue 매핑, imageFileName, mapIcon/arIcon 생성 |
| `ShowType` 가시성 | `isVisibleOnMap`/`isVisibleInAR` 레이더 조합별 결과 |
| `ARCoordinate.bearing` | 기존 angleFromCoordinate 수학 검증 |
| `VirtualModeManager` | 좌표 오프셋 적용 정확성 |
| `MissionRepository` | CRUD + save(upsert) 패턴 |
| `PlayStateRepository` | 복잡 쿼리 18개 결과 검증 |
| `APIClient.md5` | 기존 Login.m md5: 출력과 동일성 |
| `MissionDTO.parse` | ^M^I^Q 구분자 파싱 |
| `GameEngine.handleMineBlast` | Defence 보호, 아이템 되돌리기, 타임아웃 취소 |
| `GameEngine.acquireItem` | 각 아이템 타입별 사이드이펙트 |
| Mission 유효성 검사 | dataCheck 17개 규칙 |

### 14.2 UI 테스트

| 화면 | 검증 시나리오 |
|------|-------------|
| 로그인 | 성공/실패 플로우, 게스트 접근 제한 |
| 미션 목록 | 세그먼트 전환, 페이지네이션 |
| 미션 플레이 | 지도 핀 표시, AR 전환, 타이머 |
| 퀴즈 | 정답/오답/힌트/솔루션 |
| 미니게임 | Touch/Shake 모드, 프로그레스 |
| 미션 빌더 | 아이템 배치/편집/검증 |

---

## 15. 기존 코드 ↔ 신규 코드 매핑표

### 15.1 클래스 매핑

| 기존 (Objective-C) | 신규 (Swift) | 변경 사유 |
|-------------------|-------------|----------|
| `TreasureHunterAppDelegate` | `PlaySpotApp` + `AppState` | SwiftUI App 프로토콜 |
| `Mission` (NSCopying) | `Mission` (struct, Codable) | 값 타입 |
| `MissionItem` (NSCopying) | `MissionItem` (struct, Codable) | 값 타입 |
| `ItemQuiz` (NSCopying) | `ItemQuiz` (struct, Codable) | 값 타입 |
| `MissionInPlay` | `MissionInPlay` (struct) | 값 타입 |
| `MissionItemInPlay` | `MissionItemInPlay` (struct) | 값 타입 |
| `ItemRnPInPlay` | `ItemRnPInPlay` (struct) | 값 타입 |
| `AnnoItem` (MKAnnotation) | SwiftUI `Annotation` | MapKit SwiftUI |
| `CircleItem` (MKCircle) | `MapCircle` | MapKit SwiftUI |
| `BaseDao` + 6 DAO | `*Repository` 6개 | GRDB.swift |
| `HTTPRequest` | `APIClient` (actor) | async/await |
| `ImageManager` | `ImageCacheService` (actor) | async |
| `ARViewController` | `ARGameView` (UIViewRepresentable) | ARKit |
| `ARGeoViewController` | `ARGameView.Coordinator` | ARKit |
| `ARCoordinate` + `ARGeoCoordinate` | `ARCoordinate` (struct) | 통합 |
| `MissionPlay` (2,259줄) | `GameEngine` + `MissionPlayView` + `ItemInteraction` | MVC→MVVM 분리 |
| `MissionBuilder` | `MissionBuilderView` | SwiftUI |
| `MissionList` | `MissionListView` | SwiftUI |
| `QuizPlayAlert` (UIAlertView) | `QuizView` | SwiftUI Sheet |
| `GamePlayAlert` (UIAlertView) | `MiniGameView` | SwiftUI Sheet |
| `StartGameAlert` (UIAlertView) | `StartGameView` | SwiftUI Sheet |
| `Login` + `UserReg` | `LoginView` + `RegisterView` | SwiftUI |
| `MyInfo` + `Bulletin` | `MyInfoView` + `BadgeListView` | SwiftUI |
| `Setting` | `SettingsView` | SwiftUI |
| `SVProgressHUD` | SwiftUI `ProgressView` | 내장 |
| `CMPopTipView` | SwiftUI `.popover` | 내장 |
| `DLStarRatingControl` | 커스텀 SwiftUI `RatingView` | 내장 |
| `SBTickerView` × 12 | `GameTimerView` (Text + 애니메이션) | SwiftUI |
| `MultiPickerView` | `ItemPickerView` (Picker) | SwiftUI |
| `MRScrollView` | `ScrollView` | 내장 |
| FMDB | GRDB.swift | 기존 SQLite 호환 |
| SBJson | Codable | 내장 |
| `UIAccelerometer` | `CMMotionManager` | iOS 4 deprecated |
| `SKPaymentQueue` | StoreKit 2 `Product.purchase()` | 최신 API |
| `AudioServicesCreateSystemSoundID` | `AVAudioPlayer` | 유연성 |
| `AudioServicesPlaySystemSound(vibrate)` | `UIImpactFeedbackGenerator` | Haptics API |
| NIB/XIB 28개 | SwiftUI View | 코드 UI |

### 15.2 제거되는 라이브러리

| 기존 | 대체 |
|------|------|
| FMDB (Classes/FMDB/) | GRDB.swift (SPM) |
| SBJson (Classes/JSON/) | Foundation.JSONDecoder |
| SBTickerView (Classes/flip/) | SwiftUI Text + animation |
| CMPopTipView (Classes/CMPopTipView/) | SwiftUI .popover |
| SVProgressHUD (Classes/) | SwiftUI ProgressView |
| DLStarRatingControl (Classes/) | 커스텀 SwiftUI View |
| MultiPickerView (Classes/MultiPickerView/) | SwiftUI Picker |

### 15.3 SPM 의존성

```swift
// Package.swift dependencies
dependencies: [
    .package(url: "https://github.com/groue/GRDB.swift", from: "6.0.0"),
]
```

---

## 구현 순서 요약

```
Phase 1  → 모델 & 상수 정의 (enum, struct)
Phase 2  → DB (GRDB + Repository)
Phase 3  → 네트워크 (APIClient + DTO)
Phase 4  → 위치/센서 서비스
Phase 5  → AR 시스템 (ARKit)
Phase 6  → 게임 엔진 (비즈니스 로직)
Phase 7  → UI (SwiftUI 전체)
Phase 8  → 인앱 결제 (StoreKit 2)
Phase 9  → 사운드 & 햅틱
Phase 10 → 이미지 캐시
Phase 11 → 인증
Phase 12 → 리소스 이관
Phase 13 → 테스트
```

각 Phase는 독립적으로 빌드/테스트 가능하며, Phase 1~4를 먼저 완성하면 나머지는 병렬 진행 가능하다.

## 로컬 Mock 데이터 전략 (서버 미준비 대응)

서버(`nexapp.co.kr`)가 아직 준비되지 않았으므로, 모든 API 호출을 로컬 JSON 파일로 대체하는 Mock 레이어를 구성한다.

### 아키텍처: Protocol 기반 DataSource 분리

```swift
// Network/MissionDataSource.swift
protocol MissionDataSource {
    func fetchMissionList(cursor: Int, lang: String) async throws -> [Mission]
    func fetchMissionDetail(missionID: String) async throws -> (Mission, [MissionItem], [ItemQuiz])
    func fetchReplies(missionID: String) async throws -> [MissionReply]
    func fetchTutorialMissions(region: String) async throws -> [Mission]
    func fetchMyDesigned(userID: String) async throws -> [Mission]
    func fetchMyPlayed(userID: String) async throws -> [Mission]
    func fetchCurrentGames(userID: String) async throws -> [Mission]
    func fetchRanking(missionID: String) async throws -> [RankingEntry]
    func login(email: String, passwordMD5: String) async throws -> Bool
}
```

```swift
// Network/LocalDataSource.swift — 로컬 JSON 파일 기반 Mock 구현
struct LocalDataSource: MissionDataSource {
    
    func fetchMissionList(cursor: Int, lang: String) async throws -> [Mission] {
        try loadJSON("mock_mission_list")
    }
    
    func fetchMissionDetail(missionID: String) async throws -> (Mission, [MissionItem], [ItemQuiz]) {
        let mission: Mission = try loadJSON("mock_mission_\(missionID)")
        let items: [MissionItem] = try loadJSON("mock_items_\(missionID)")
        let quizzes: [ItemQuiz] = try loadJSON("mock_quizzes_\(missionID)")
        return (mission, items, quizzes)
    }
    
    func fetchReplies(missionID: String) async throws -> [MissionReply] {
        try loadJSON("mock_replies")
    }
    
    func fetchTutorialMissions(region: String) async throws -> [Mission] {
        try loadJSON("mock_tutorials")
    }
    
    func fetchMyDesigned(userID: String) async throws -> [Mission] {
        try loadJSON("mock_my_designed")
    }
    
    func fetchMyPlayed(userID: String) async throws -> [Mission] {
        try loadJSON("mock_my_played")
    }
    
    func fetchCurrentGames(userID: String) async throws -> [Mission] {
        try loadJSON("mock_current_games")
    }
    
    func fetchRanking(missionID: String) async throws -> [RankingEntry] {
        try loadJSON("mock_ranking")
    }
    
    func login(email: String, passwordMD5: String) async throws -> Bool {
        true // Mock에서는 항상 로그인 성공
    }
    
    // MARK: - JSON 로더
    private func loadJSON<T: Decodable>(_ name: String) throws -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw DataSourceError.fileNotFound(name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

enum DataSourceError: Error {
    case fileNotFound(String)
}
```

```swift
// Network/RemoteDataSource.swift — 서버 준비 후 전환
struct RemoteDataSource: MissionDataSource {
    private let client = APIClient.shared
    
    func fetchMissionList(cursor: Int, lang: String) async throws -> [Mission] {
        let response = try await client.request(.playingMissions(last: cursor, lang: lang))
        return try JSONDecoder().decode([Mission].self, from: Data(response.utf8))
    }
    // ... 나머지 메서드도 기존 APIClient 호출로 구현
}
```

```swift
// DataSource 전환: AppConfig에서 한 줄로 제어
enum AppConfig {
    #if DEBUG
    static let dataSource: MissionDataSource = LocalDataSource()
    #else
    static let dataSource: MissionDataSource = RemoteDataSource()
    #endif
}
```

### Mock JSON 파일 목록 (Bundle Resources에 포함)

SQLite `treasure.sqlite`의 실제 데이터를 기반으로 생성한다.

```
Resources/MockData/
├── mock_mission_list.json              ← MissionInPlay 테이블 기반
├── mock_mission_ejola20110517204326.json  ← 아이템 4개짜리 미션 상세
├── mock_items_ejola20110517204326.json   ← MissionItem 4건
├── mock_quizzes_ejola20110410131343.json  ← ItemQuiz 2건
├── mock_replies.json                   ← 더미 댓글
├── mock_tutorials.json                 ← 튜토리얼 미션 목록
├── mock_my_designed.json               ← 내가 디자인한 미션
├── mock_my_played.json                 ← 내가 플레이한 미션
├── mock_current_games.json             ← 현재 진행 중 미션
└── mock_ranking.json                   ← 랭킹 데이터
```

### Mock 데이터 샘플 (SQLite 실제 데이터 기반)

**mock_mission_list.json** — MissionInPlay 테이블의 실제 미션 ID 사용:
```json
[
  {
    "MissionID": "ejola20110517204326",
    "Title": "관악산 보물찾기",
    "Description": "관악산 근처 보물을 찾아보세요",
    "Place": "서울 관악구",
    "Designer": "ejola",
    "RunLimitTime": "01:00:00",
    "Status": 2,
    "Virtual": 1,
    "WriteDate": "2011-05-17",
    "PlayCnt": 15,
    "FailCnt": 3,
    "RecommendCnt": 8,
    "RecommendAvg": 4
  },
  {
    "MissionID": "ejola20110602210324",
    "Title": "서울대입구 탐험",
    "Description": "서울대입구역 주변 미션",
    "Place": "서울 관악구",
    "Designer": "ejola",
    "RunLimitTime": "00:30:00",
    "Status": 2,
    "Virtual": 1,
    "WriteDate": "2011-06-02",
    "PlayCnt": 22,
    "FailCnt": 5,
    "RecommendCnt": 12,
    "RecommendAvg": 5
  }
]
```

**mock_items_ejola20110517204326.json** — MissionItem 테이블 실제 좌표(서울 관악구):
```json
[
  {
    "ItemID": 1,
    "ItemType": "51",
    "Latitude": 37.4849216918135,
    "Longitude": 126.807965040207,
    "Mandatory": 1,
    "ShowType": "2",
    "RangeAR": 10,
    "EffectiveRange": 0,
    "EffectiveTime": 0,
    "ItemGame": 1,
    "Info": "",
    "RelationItemID": 0,
    "BlackCnt": 0,
    "BlackTime": 0
  },
  {
    "ItemID": 2,
    "ItemType": "61",
    "Latitude": 37.4846322330535,
    "Longitude": 126.808222532272,
    "Mandatory": 1,
    "ShowType": "4",
    "RangeAR": 10,
    "EffectiveRange": 0,
    "EffectiveTime": 0,
    "ItemGame": 0,
    "Info": "",
    "RelationItemID": 0,
    "BlackCnt": 0,
    "BlackTime": 0
  },
  {
    "ItemID": 4,
    "ItemType": "48",
    "Latitude": 37.485211149452,
    "Longitude": 126.807278394699,
    "Mandatory": 1,
    "ShowType": "4",
    "RangeAR": 10,
    "EffectiveRange": 0,
    "EffectiveTime": 0,
    "ItemGame": 0,
    "Info": "",
    "RelationItemID": 0,
    "BlackCnt": 0,
    "BlackTime": 0
  },
  {
    "ItemID": 5,
    "ItemType": "41",
    "Latitude": 37.4853984449734,
    "Longitude": 126.807814836502,
    "Mandatory": 1,
    "ShowType": "4",
    "RangeAR": 10,
    "EffectiveRange": 0,
    "EffectiveTime": 0,
    "ItemGame": 0,
    "Info": "",
    "RelationItemID": 0,
    "BlackCnt": 0,
    "BlackTime": 0
  }
]
```

**mock_quizzes_ejola20110410131343.json** — ItemQuiz 테이블 실제 데이터:
```json
[
  {
    "Seq": 1,
    "Quiz": "무시로",
    "Answer": "나훈아",
    "Probability": 50
  },
  {
    "Seq": 2,
    "Quiz": "저 푸른 초원위에",
    "Answer": "남진",
    "Probability": 50
  }
]
```

**mock_ranking.json**:
```json
{
  "ShortUser1": "ejola",
  "ShortRecord1": "00:05:30",
  "ShortUser2": "player2",
  "ShortRecord2": "00:08:12",
  "ShortUser3": "player3",
  "ShortRecord3": "00:10:45"
}
```

### GameEngine / View에서의 사용

```swift
// 기존: HTTPRequest로 서버 호출
// 변경: AppConfig.dataSource로 통일 (Mock/Remote 자동 전환)

class GameEngine: ObservableObject {
    private let dataSource: MissionDataSource
    
    init(dataSource: MissionDataSource = AppConfig.dataSource) {
        self.dataSource = dataSource
    }
    
    func loadMission(_ missionID: String) async throws {
        let (mission, items, quizzes) = try await dataSource.fetchMissionDetail(missionID: missionID)
        // 기존 MissionPlay.m의 로컬 DB 저장 로직과 동일하게 처리
    }
}
```

### 서버 전환 시 변경 사항

서버가 준비되면 `AppConfig.dataSource`를 `RemoteDataSource()`로 변경하면 된다.
Protocol 기반이므로 View/GameEngine 코드 변경 없이 전환 가능.

```swift
// 서버 준비 후: 이 한 줄만 변경
static let dataSource: MissionDataSource = RemoteDataSource()
``` 

## 기존 라이브러리 호환성 조사 및 마이그레이션 방안

### 서드파티 라이브러리 현황

| 기존 라이브러리 | 상태 | Swift 대체 방안 | 비고 |
|----------------|------|-----------------|------|
| **FMDB** (Classes/FMDB/) | 유지보수 중 (ObjC) | **GRDB.swift** | Swift 네이티브 SQLite, Codable 지원, SwiftUI 관찰 API 제공 |
| **SBJson** (Classes/JSON/) | 레거시 (2011) | **Swift Codable** (내장) | 별도 라이브러리 불필요. `JSONDecoder`/`JSONEncoder`로 완전 대체 |
| **SBTickerView** (Classes/flip/) | 폐기 (2014 이후 업데이트 없음) | **커스텀 SwiftUI 뷰** | `rotation3DEffect` + `animation`으로 플립 카운터 구현 (~50줄) |
| **CMPopTipView** (Classes/CMPopTipView/) | 폐기 (2020) | **Apple TipKit** (iOS 17+) | Apple 공식 툴팁 프레임워크. 게임용 말풍선은 SwiftUI `.popover()` 활용 |
| **SVProgressHUD** (Classes/) | 유지보수 중 (ObjC) | **커스텀 SwiftUI 오버레이** | `ProgressView` + `.overlay()` modifier로 구현 (~30줄) |
| **DLStarRatingControl** (Classes/) | 폐기 (2016) | **커스텀 SwiftUI 뷰** | `HStack` + `Image(systemName: "star.fill")` (~25줄) |

### AR 관련 API 호환성 조사

| 기존 API | iOS 17+ 상태 | 대체 API | 영향 범위 |
|----------|-------------|----------|----------|
| **UIAccelerometer** | **삭제됨** (iOS 5에서 deprecated) | **CMMotionManager** (CoreMotion) | `ARViewController.m`, `GamePlayAlert.m` |
| **UIImagePickerController** (카메라 오버레이) | 동작하지만 제한적 | **AVCaptureSession** + `AVCaptureVideoPreviewLayer` | `ARViewController.m` 카메라 피드 |
| **CLLocationManager** | 정상 | 그대로 사용 (async/await 래핑) | GPS 위치, 나침반 방향 |
| **MKMapView** | 정상 | SwiftUI `Map` (iOS 17+) | `MissionPlay.m`, `MissionBuilder.m` |

### ARKit/RealityKit 도입 검토

**결론: ARKit 전면 도입 대신 하이브리드 커스텀 방식 채택**

| 검토 항목 | ARKit/RealityKit | 커스텀 방식 (채택) |
|-----------|------------------|-------------------|
| GPS 좌표 기반 AR | ARGeoAnchor는 **특정 도시만 지원** (전 세계 불가) | CLLocation 거리/방위각 계산으로 **어디서든 동작** |
| 2D 아이템 오버레이 | 3D 렌더링 파이프라인 과도함 | SwiftUI 뷰 오버레이로 충분 |
| 디바이스 방향 추적 | ARCamera.transform 사용 | CMMotionManager.deviceMotion (pitch/roll/yaw) |
| 나침반 방위 | ARKit heading 제한적 | CLLocationManager.heading 직접 사용 |
| 카메라 피드 | ARView가 자동 제공 | AVCaptureSession으로 직접 제어 |

**커스텀 방식으로 모든 AR 기능 구현 가능 여부:**

기존 AR 시스템(`ARViewController.m` + `ARGeoViewController.m` = ~800줄)이 사용하는 기능을 하나씩 대조한 결과, **모든 기능이 커스텀 방식으로 구현 가능**하며, 오히려 소스가 간단해진다.

| 기존 AR 기능 | 기존 구현 (복잡도) | 커스텀 Swift (복잡도) | 비고 |
|-------------|-------------------|---------------------|------|
| 카메라 라이브 피드 | UIImagePickerController + 커스텀 오버레이 (~60줄) | AVCaptureSession + SwiftUI (~30줄) | **절반으로 감소** |
| GPS → 화면좌표 변환 | 수동 구면좌표 계산 (azimuth/inclination/radialDistance, ~100줄) | 동일 수학이지만 Swift로 간결 (~60줄) | atan2/cos/sin 계산 동일 |
| 나침반 방향 추적 | CLLocationManager heading delegate (~30줄) | LocationService에서 heading 공유 (~5줄 추가) | **이미 Phase 4에서 구현됨** |
| 디바이스 기울기 감지 | UIAccelerometer delegate (~40줄, deprecated) | CMMotionManager.deviceMotion (~20줄) | **절반으로 감소**, 최신 API |
| 뷰포트 투영 (3D→2D) | 수동 CGAffineTransform + 삼각함수 (~80줄) | SwiftUI offset/scale modifier (~40줄) | SwiftUI가 렌더링 단순화 |
| 거리 기반 스케일링 | CGAffineTransformMakeScale 수동 계산 (~20줄) | `.scaleEffect(scaleFactor)` (~5줄) | **대폭 간소화** |
| 아이템 표시/숨김 (ShowType) | UIView hidden/alpha 수동 제어 (~30줄) | SwiftUI 조건부 렌더링 (~10줄) | **간소화** |
| CMPopTipView 툴팁 | delegate 패턴 + 수동 배치 (~50줄) | TipKit 또는 `.popover()` (~15줄) | **대폭 간소화** |
| 레이더 뷰 | UIView + drawRect 수동 그리기 (~60줄) | SwiftUI Canvas/Shape (~40줄) | 약간 감소 |

**결론:**
- 기존 ~800줄 → 커스텀 Swift ~250줄로 **약 70% 코드 감소**
- UIAccelerometer(삭제된 API)와 UIImagePickerController 오버레이(레거시) 의존성 제거
- ARKit를 사용하지 않으므로 ARKit 프레임워크 링크 불필요 → **앱 바이너리 경량화**
- SwiftUI의 선언적 UI로 뷰포트 투영/스케일링 코드가 크게 단순해짐
- GPS 기반 AR이므로 전 세계 어디서든 동작 (ARGeoAnchor의 도시 제한 없음)

**하이브리드 AR 아키텍처:**

```swift
// AR/ARCameraView.swift — 카메라 피드 (기존 UIImagePickerController 대체)
struct ARCameraView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return view }
        session.addInput(input)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        session.startRunning()
        return view
    }
}
```

```swift
// Services/MotionService.swift — 가속도계/자이로 (기존 UIAccelerometer 대체)
import CoreMotion

@Observable
final class MotionService {
    private let motionManager = CMMotionManager()
    
    var pitch: Double = 0    // 기존 acceleration.y 대체
    var roll: Double = 0     // 기존 acceleration.x 대체
    var yaw: Double = 0
    
    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        // 기존: updateInterval = 0.25
        motionManager.deviceMotionUpdateInterval = 0.25
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            self?.pitch = motion.attitude.pitch
            self?.roll = motion.attitude.roll
            self?.yaw = motion.attitude.yaw
        }
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}
```

### 커스텀 SwiftUI 대체 컴포넌트 예시

**플립 카운터 (SBTickerView 대체):**

```swift
// Views/Components/FlipCounterView.swift
struct FlipCounterView: View {
    let value: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(digits, id: \.offset) { index, digit in
                SingleDigitFlip(digit: digit)
            }
        }
    }
    
    private var digits: [(offset: Int, element: Int)] {
        Array(String(format: "%02d", value).compactMap { $0.wholeNumberValue }.enumerated())
    }
}

struct SingleDigitFlip: View {
    let digit: Int
    
    var body: some View {
        Text("\(digit)")
            .font(.system(size: 24, weight: .bold, design: .monospaced))
            .frame(width: 24, height: 36)
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(4)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.3), value: digit)
    }
}
```

**별점 (DLStarRatingControl 대체):**

```swift
// Views/Components/StarRatingView.swift
struct StarRatingView: View {
    let rating: Double      // 0.0 ~ 5.0
    let maxStars: Int = 5
    var starSize: CGFloat = 16
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<maxStars, id: \.self) { index in
                Image(systemName: starImageName(for: index))
                    .font(.system(size: starSize))
                    .foregroundColor(.yellow)
            }
        }
    }
    
    private func starImageName(for index: Int) -> String {
        let threshold = Double(index) + 1
        if rating >= threshold { return "star.fill" }
        if rating >= threshold - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}
```

**로딩 HUD (SVProgressHUD 대체):**

```swift
// Views/Components/LoadingHUD.swift
struct LoadingHUD: ViewModifier {
    let isPresented: Bool
    let message: String
    
    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

extension View {
    func loadingHUD(isPresented: Bool, message: String = "Loading..") -> some View {
        modifier(LoadingHUD(isPresented: isPresented, message: message))
    }
}
```

### 프로젝트 구조 업데이트

기존 구조에 컴포넌트 폴더 추가:

```
PlaySpot/
├── Views/
│   ├── Components/                      ← 신규 추가
│   │   ├── FlipCounterView.swift        ← SBTickerView 대체
│   │   ├── StarRatingView.swift         ← DLStarRatingControl 대체
│   │   ├── LoadingHUD.swift             ← SVProgressHUD 대체
│   │   └── GameTooltipView.swift        ← CMPopTipView 대체 (+ TipKit 연동)
│   ...
```

### 의존성 요약

**외부 패키지 (SPM):**
- `GRDB.swift` — SQLite (FMDB 대체)

**Apple 프레임워크 (추가):**
- `CoreMotion` — CMMotionManager (UIAccelerometer 대체)
- `AVFoundation` — AVCaptureSession (UIImagePickerController 카메라 오버레이 대체)
- `TipKit` — 툴팁 (CMPopTipView 대체)

**외부 패키지 불필요 (Swift 내장/커스텀으로 대체):**
- SBJson → Swift Codable
- SBTickerView → 커스텀 SwiftUI FlipCounterView
- SVProgressHUD → 커스텀 SwiftUI LoadingHUD
- DLStarRatingControl → 커스텀 SwiftUI StarRatingView
- CMPopTipView → Apple TipKit + 커스텀 SwiftUI 뷰