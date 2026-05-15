// Game/GameEngine.swift
import Foundation
import CoreLocation
import Observation
import OSLog

private let engineLog = Logger(subsystem: "com.ejola.playspot", category: "GameEngine")

@Observable
final class GameEngine {
    // MARK: - 상태 (기존 MissionPlay.h 프로퍼티)
    var missionStarted = false
    var missionCompleted = false
    var isMissionEnd = false
    var isVirtualMode = false

    var dicItemEnd: [Int: String] = [:]         // itemID -> "Y"/"N"
    var dicRnPTaken: [String: Int] = [:]        // itemType.rawValue -> ableCnt

    /// Virtual 모드에서 start 아이템 → 플레이어 위치 오프셋이 적용됐는지 여부.
    /// false면 위치가 늦게 도착했을 때 reapplyVirtualOffsetIfNeeded()로 재적용해야 한다.
    private(set) var virtualOffsetApplied = false

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

    var pendingAlert: ItemAcquiredAlert?

    // MARK: - 데이터
    private(set) var mission: Mission?
    private(set) var items: [MissionItem] = []

    private let playRepo = PlayStateRepository()
    private let powerUpRepo = PowerUpRepository()
    private let dataSource: MissionDataSource

    private var playerID: String { AppState.shared.userID }
    private var timer: Timer?

    init(dataSource: MissionDataSource = AppConfig.dataSource) {
        self.dataSource = dataSource
    }

    // MARK: - 초기화 (기존: setupPlay)

    func setup(missionID: String, isNewStart: Bool, virtualMode: Bool, playerLocation: CLLocation? = nil) async throws {
        self.isVirtualMode = virtualMode

        // 1. 카탈로그 데이터(미션/아이템/퀴즈) — DEBUG: LocalDataSource(mock JSON), Release: RemoteDataSource
        let (fetchedMission, fetchedItems, fetchedQuizzes) = try await dataSource.fetchMissionDetail(missionID: missionID)
        var loadedMission = fetchedMission
        var loadedItems = fetchedItems

        // 퀴즈를 itemID 기준으로 그룹핑하여 각 item에 첨부
        let quizzesByItemID = Dictionary(grouping: fetchedQuizzes) { $0.itemID }
        for i in loadedItems.indices {
            if loadedItems[i].itemType == .quiz || loadedItems[i].itemType == .quiz20 {
                loadedItems[i].quizzes = quizzesByItemID[loadedItems[i].itemID] ?? []
            }
        }
        loadedMission.items = loadedItems

        // 2. 신규 시작이면 이전 기록 삭제
        if isNewStart {
            try playRepo.deleteAllItems(missionID: missionID, playerID: playerID)
            try playRepo.deleteMissionInPlay(missionID: missionID, playerID: playerID)
            try powerUpRepo.deleteAll(missionID: missionID, playerID: playerID)
        }

        // 3. MissionInPlay 생성 또는 로드
        var playState = try playRepo.fetchMissionInPlay(missionID: missionID, playerID: playerID)
        if playState == nil {
            let hasStart = loadedItems.contains { $0.itemType == .start }
            let newPlay = MissionInPlay(
                missionID: missionID,
                playerID: playerID,
                startYN: hasStart ? "N" : "Y",
                startTime: hasStart ? nil : Date()
            )
            try playRepo.insertMissionInPlay(newPlay)
            playState = newPlay
            missionStarted = !hasStart
            if !hasStart {
                SoundService.shared.play(.gogogo)
            }
        } else {
            missionStarted = playState?.hasStarted ?? false
        }

        if missionStarted { missionStartTime = playState?.startTime }

        // 4. 아이템 진행 상태 로드
        dicItemEnd = try playRepo.fetchItemStatusDict(missionID: missionID, playerID: playerID)

        // 파워업 상태 로드
        let powerUps = try powerUpRepo.fetchAll(missionID: missionID, playerID: playerID)
        dicRnPTaken = [:]
        for pu in powerUps {
            dicRnPTaken[pu.itemType] = pu.ableCnt
        }

        // MissionItemInPlay 초기화 (없는 아이템은 새로 생성)
        for item in loadedItems {
            if dicItemEnd[item.itemID] == nil {
                let itemPlay = MissionItemInPlay(
                    missionID: missionID, playerID: playerID, itemID: item.itemID)
                try playRepo.insertItemInPlay(itemPlay)
                dicItemEnd[item.itemID] = "N"
            }
        }

        // 5. 타임아웃 복원
        if let timeout = try playRepo.fetchActiveTimeout(missionID: missionID, playerID: playerID) {
            timeOutStartTime = timeout.endTime
            if let startItem = loadedItems.first(where: { $0.itemID == timeout.itemID }),
               let endItem = loadedItems.first(where: { $0.itemType == .timeoutEnd && $0.relationItemID == startItem.itemID }) {
                timeOutLimitTime = endItem.effectiveTime
                isTimeOutActive = true
            }
        }

        // 6. Virtual Mode 좌표 오프셋
        if virtualMode {
            let loc = playerLocation ?? AppState.shared.locationService.currentLocation
            engineLog.debug("""
                🗺 setup virtual: missionID=\(missionID, privacy: .public) \
                playerLocation=\(loc.map { "(\($0.coordinate.latitude),\($0.coordinate.longitude))" } ?? "nil", privacy: .public) \
                items=\(loadedMission.items.count, privacy: .public)
                """)
            virtualOffsetApplied = VirtualModeManager.applyOffset(
                items: &loadedMission.items,
                playerLocation: loc,
                isNewStart: isNewStart)
            engineLog.debug("🗺 virtualOffsetApplied=\(self.virtualOffsetApplied, privacy: .public)")
        } else {
            virtualOffsetApplied = true  // Real 모드는 오프셋 불필요 — 항상 적용된 것으로 간주
        }

        self.mission = loadedMission
        self.items = loadedMission.items

        // 7. 카운터 업데이트
        updateCounters()

        // 8. 타이머 시작
        startTimer()
    }

    /// Virtual 모드에서 setup 당시 currentLocation이 nil이었으면 오프셋이 미적용된 상태로 남는다.
    /// 위치 픽스가 늦게 들어왔을 때 이 메서드로 재반영 (start 아이템을 현재 플레이어 위치로 다시 정렬).
    /// - Returns: 이번 호출에서 새로 적용되었으면 true.
    @discardableResult
    func reapplyVirtualOffsetIfNeeded() -> Bool {
        guard isVirtualMode, !virtualOffsetApplied else { return false }
        var copy = items
        let applied = VirtualModeManager.applyOffset(
            items: &copy,
            playerLocation: AppState.shared.locationService.currentLocation,
            isNewStart: true)
        if applied {
            items = copy
            mission?.items = copy
            virtualOffsetApplied = true
            return true
        }
        return false
    }

    // MARK: - 타이머 (기존: updatePassedTime:)

    func startTimer() {
        // setup()이 async라 await 이후 백그라운드 스레드에서 재개될 수 있다.
        // scheduledTimer는 RunLoop.current 에 등록되므로, 백그라운드 큐에선 fire되지 않음 →
        // 명시적으로 RunLoop.main(.common)에 등록해 항상 메인 스레드에서 tick하도록 보장.
        // .common 모드는 스크롤 중에도 일시중지되지 않음.
        stopTimer()
        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(newTimer, forMode: .common)
        self.timer = newTimer
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard missionStarted, let startTime = missionStartTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime)

        if isTimeOutActive, let timeoutStart = timeOutStartTime {
            remainingRunTime = Double(timeOutLimitTime) - Date().timeIntervalSince(timeoutStart)
            if remainingRunTime <= 0 {
                isTimeOutActive = false
                SoundService.shared.play(.timeOver)
            }
        }
    }

    // MARK: - 지뢰 폭발 (기존: mineBlast:)

    func handleMineBlast(item: MissionItem) throws {
        guard let missionID = mission?.id else { return }

        // 1. Defence 파워업 확인
        if let defenseCount = dicRnPTaken[ItemType.mineNoBomb.rawValue], defenseCount > 0 {
            dicRnPTaken[ItemType.mineNoBomb.rawValue] = defenseCount - 1
            let rnp = ItemRnPInPlay(
                missionID: missionID, playerID: playerID,
                itemType: ItemType.mineNoBomb.rawValue, ableCnt: defenseCount - 1)
            try powerUpRepo.update(rnp)
            SoundService.shared.play(.itemGet)
            pendingAlert = ItemAcquiredAlert(
                title: "A mine has exploded!",
                message: "Mine did not damage using Defense item",
                itemIconName: item.arIconName)
            return
        }

        // 2. 지뢰 수집 처리
        dicItemEnd[item.itemID] = "Y"
        var minePlay = MissionItemInPlay(
            missionID: missionID, playerID: playerID, itemID: item.itemID)
        minePlay.endYN = "Y"
        minePlay.endTime = Date()
        try playRepo.updateItemInPlay(minePlay)

        // 3. 최근 획득 아이템 되돌리기
        var lostItemTypeName: String?
        if let lastItem = try playRepo.fetchLastAcquiredItem(
            missionID: missionID, playerID: playerID, excludeItemID: item.itemID) {
            dicItemEnd[lastItem.itemID] = "N"
            var revert = lastItem
            revert.endYN = "N"
            try playRepo.updateItemInPlay(revert)
            lostItemTypeName = items.first(where: { $0.itemID == lastItem.itemID })
                .map { String(describing: $0.itemType.displayName) }
        }

        // 4. 타임아웃 중이면 취소
        if isTimeOutActive {
            isTimeOutActive = false
            lostItemTypeName = lostItemTypeName ?? "Run Start"
        }

        updateCounters()
        SoundService.shared.play(.explosion)
        HapticService.shared.vibrate()

        if let lostName = lostItemTypeName {
            pendingAlert = ItemAcquiredAlert(
                title: "A mine has exploded!",
                message: "The most recently acquired \(lostName) item has been lost.",
                itemIconName: item.arIconName)
        } else {
            pendingAlert = ItemAcquiredAlert(
                title: "A mine has exploded!",
                message: "Mine has exploded!",
                itemIconName: item.arIconName)
        }
    }

    // MARK: - 아이템 획득 (기존: getItem:)

    func acquireItem(_ item: MissionItem) throws {
        guard let missionID = mission?.id else { return }

        dicItemEnd[item.itemID] = "Y"
        var itemPlay = MissionItemInPlay(
            missionID: missionID, playerID: playerID, itemID: item.itemID)
        itemPlay.endYN = "Y"
        itemPlay.endTime = Date()
        try playRepo.updateItemInPlay(itemPlay)

        // 파워업 처리
        if item.itemType.isRadar || item.itemType == .mineNoBomb || item.itemType == .solution {
            let rnp = ItemRnPInPlay(
                missionID: missionID, playerID: playerID,
                itemType: item.itemType.rawValue, ableCnt: 1, acquiredTime: Date())
            try powerUpRepo.save(rnp)
            dicRnPTaken[item.itemType.rawValue] = (dicRnPTaken[item.itemType.rawValue] ?? 0) + 1
            if item.itemType.isRadar {
                SoundService.shared.play(.radar)
            }
        }

        // Gambling 처리
        if item.itemType == .random {
            let candidates = try playRepo.fetchRandomCandidates(
                missionID: missionID, playerID: playerID)
            if let lucky = candidates.randomElement() {
                try acquireItem(lucky)
            }
        }

        // Start 아이템 -> 미션 시작
        if item.itemType == .start && !missionStarted {
            missionStarted = true
            missionStartTime = Date()
            let play = MissionInPlay(missionID: missionID, playerID: playerID, startYN: "Y", startTime: Date())
            try playRepo.updateMissionInPlay(play)
            SoundService.shared.play(.gogogo)
        }

        // Run Start -> 타임아웃 시작
        if item.itemType == .timeoutStart {
            timeOutStartTime = Date()
            if let endItem = items.first(where: { $0.itemType == .timeoutEnd && $0.relationItemID == item.itemID }) {
                timeOutLimitTime = endItem.effectiveTime
                isTimeOutActive = true
            }
        }

        // Run End -> 타임아웃 종료
        if item.itemType == .timeoutEnd { isTimeOutActive = false }

        // End 아이템 -> 미션 완료 확인. 어느 경우든 게임 타이머는 중지(레거시 동작).
        if item.itemType == .end {
            stopTimer()
            if try playRepo.isMissionCompleted(missionID: missionID, playerID: playerID) {
                missionCompleted = true
                isMissionEnd = true
                SoundService.shared.play(.gameFinish)
            }
        }

        updateCounters()
        if !missionCompleted {
            SoundService.shared.play(.itemGet)
        }

        // 획득 팝업 설정
        setAcquiredAlert(for: item)
    }

    // MARK: - 카운터 업데이트

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

    // MARK: - 가시성 판정

    func shouldShowOnMap(_ item: MissionItem) -> Bool {
        // 미션 시작 전에는 start 아이템만 표시
        if !missionStarted, item.itemType != .start {
            return false
        }

        // end 아이템은 필수 아이템이 1개 초과 남아 있으면 숨김 (1개 = end 자신)
        if item.itemType == .end, mandatoryRemaining > 1 {
            return false
        }

        let hasRadarMap = dicRnPTaken[ItemType.radarMap.rawValue] != nil
        let hasRadarAll = dicRnPTaken[ItemType.radarAll.rawValue] != nil
        let hasRadarMine = dicRnPTaken[ItemType.radarMine.rawValue] != nil

        if item.itemType.isMine {
            return hasRadarMine
        }

        // F-7: 미획득 다크존(black) 안에 있는 아이템은 지도에서 숨김.
        // 레거시 MissionPlay.m:2128-2157 의 black 원 내 아이콘 nil 처리 포팅.
        // start 와 black 자신은 예외.
        if item.itemType != .start, item.itemType != .black, isInsideUnacquiredDarkZone(item) {
            return false
        }

        return item.showType.isVisibleOnMap(hasRadarMap: hasRadarMap, hasRadarAll: hasRadarAll)
    }

    /// 아이템이 미획득 black 아이템의 rangeAR 원 안에 있는지 검사.
    private func isInsideUnacquiredDarkZone(_ item: MissionItem) -> Bool {
        for blackItem in items where blackItem.itemType == .black {
            guard dicItemEnd[blackItem.itemID] != "Y" else { continue }
            let distance = blackItem.location.distance(from: item.location)
            if distance <= Double(blackItem.rangeAR) {
                return true
            }
        }
        return false
    }

    // MARK: - 아이템 획득 팝업

    private func setAcquiredAlert(for item: MissionItem) {
        let icon = item.arIconName
        switch item.itemType {
        case .start:
            let msg = item.info.isEmpty ? "If you touch OK, the item will be released Mission." : item.info
            pendingAlert = ItemAcquiredAlert(title: "Start Item acquired!", message: msg, itemIconName: icon)

        case .simple where item.itemGame == 0:
            let msg = item.info.isEmpty ? "Lose the draw!! No hint." : item.info
            pendingAlert = ItemAcquiredAlert(title: "Hint Item acquired!", message: msg, itemIconName: icon)

        case .timeoutStart:
            let msg = item.info.isEmpty ? "Acquire Run End Item in time limit" : item.info
            pendingAlert = ItemAcquiredAlert(title: "Run Start Item acquired!", message: msg, itemIconName: icon)

        case .timeoutEnd:
            let msg = item.info.isEmpty ? "Run time ended successfully." : item.info
            pendingAlert = ItemAcquiredAlert(title: "Run End Item acquired!", message: msg, itemIconName: icon)

        case .solution:
            let msg = item.info.isEmpty ? "You can get an answer if you win mission quiz or quiz item." : item.info
            pendingAlert = ItemAcquiredAlert(title: "Solution Item acquired!", message: msg, itemIconName: icon)

        case .radarAR:
            let msg = item.info.isEmpty ? "Stealth items are now visible in AR." : item.info
            pendingAlert = ItemAcquiredAlert(title: "Stealth Radar Item acquired!", message: msg, itemIconName: icon)

        case .radarMap:
            let msg = item.info.isEmpty ? "Hidden items are now visible on the map." : item.info
            pendingAlert = ItemAcquiredAlert(title: "Map Radar Item acquired!", message: msg, itemIconName: icon)

        case .radarMine:
            let msg = item.info.isEmpty ? "Mine explosion radius is now shown on the map." : item.info
            pendingAlert = ItemAcquiredAlert(title: "Mine Radar Item acquired!", message: msg, itemIconName: icon)

        case .radarAll:
            let msg = item.info.isEmpty ? "All hidden items are now revealed." : item.info
            pendingAlert = ItemAcquiredAlert(title: "All Radar Item acquired!", message: msg, itemIconName: icon)

        case .mineNoBomb:
            let msg = item.info.isEmpty ? "Mine damage can be avoided using this Defence item." : item.info
            pendingAlert = ItemAcquiredAlert(title: "Defence Item acquired!", message: msg, itemIconName: icon)

        case .random:
            pendingAlert = ItemAcquiredAlert(
                title: "Gambling acquired!",
                message: "You can get one of the items that are not yet won at random",
                itemIconName: icon)

        default:
            break
        }
    }

    deinit { timer?.invalidate() }
}

// MARK: - ItemAcquiredAlert

struct ItemAcquiredAlert {
    let title: String
    let message: String
    let itemIconName: String
}
