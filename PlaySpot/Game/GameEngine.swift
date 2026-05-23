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
    /// 현재 활성 Run Start 의 itemID. Run End 의 relationItemID 매칭 검증용.
    /// 레거시 caller.isTimeOutS 와 동일.
    var activeTimeoutStartID: Int?

    var elapsedTime: TimeInterval = 0
    var remainingRunTime: TimeInterval = 0

    /// 미션 전체 제한 시간 (초). 0 = 무제한. mission.limitTime 에서 설정.
    var missionLimitSeconds: Int = 0
    /// 미션 제한 시간 기준 남은 시간 (초). 제한 없으면 의미 없음.
    var remainingMissionTime: TimeInterval = 0
    /// 미션 제한 시간 초과 여부 — true 면 UI 가 종료 팝업을 띄운다.
    var missionTimedOut = false

    var mineCount = 0
    var mandatoryRemaining = 0
    var hiddenOnMapCount = 0
    var stealthOnARCount = 0

    /// 현재 화면에 표시되는 알림 (overlay 의 단일 슬롯).
    var pendingAlert: ItemAcquiredAlert?

    /// 다음 알림 큐. random 효과처럼 한 acquireItem 호출에서 여러 alert 가 발생하는 경우
    /// 사용자가 OK 누를 때마다 큐에서 하나씩 꺼내 표시.
    private var pendingAlertQueue: [ItemAcquiredAlert] = []

    /// 획득 순서 추적 (FIFO append, 마지막이 가장 최근). mine 폭발 시 lost 후보 결정용.
    /// PlayStateRepository 의 fetchLastAcquiredItem SQL 이 INNER JOIN MissionItem 인데
    /// 신규 포트는 카탈로그를 DB 에 저장 안 함 (CLAUDE.md 의 DB 정책) → JOIN 결과 빈 배열.
    /// 따라서 메모리 큐로 순서 추적.
    private var acquisitionOrder: [Int] = []

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

    // MARK: - 서버 플레이 기록 (c_mission_play_start / finish / fail)

    private static let playRecordFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f
    }()

    /// 서버 기록은 best-effort — 네트워크 실패가 게임 흐름을 막지 않음.
    /// 신규 API: 구조화 인자로 호출. 레거시는 DataSource 내부에서 콤마 페이로드로 변환.
    private func recordPlay(action: PlayRecordAction, time: Date) {
        guard let missionID = mission?.id else { return }
        let pid = playerID
        let virt = isVirtualMode
        let startTime = missionStartTime ?? time
        let ds = dataSource
        Task.detached {
            switch action {
            case .start:
                _ = try? await ds.recordPlayStart(missionID: missionID, playerID: pid, startTime: time, isVirtual: virt)
            case .finish:
                _ = try? await ds.recordPlayFinish(missionID: missionID, playerID: pid, startTime: startTime, endTime: time, isVirtual: virt)
            case .fail:
                _ = try? await ds.recordPlayFail(missionID: missionID, playerID: pid, startTime: startTime, endTime: time, isVirtual: virt)
            }
        }
    }

    private enum PlayRecordAction { case start, finish, fail }

    // MARK: - 초기화 (기존: setupPlay)

    func setup(missionID: String, isNewStart: Bool, virtualMode: Bool, playerLocation: CLLocation? = nil) async throws {
        self.isVirtualMode = virtualMode

        // REST 백엔드면 토큰 보장 후 호출
        await AuthBootstrap.ensureAuthenticated()

        // 1. 카탈로그 데이터(미션/아이템/퀴즈) — REST: /api/v1/missions/{id}, Legacy: TR=200
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
        acquisitionOrder = []  // 획득 순서 큐 초기화

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
                // Start 아이템이 없으면 setup 시점에 바로 미션 시작 — 서버 기록.
                recordPlay(action: .start, time: newPlay.startTime ?? Date())
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
        self.missionLimitSeconds = loadedMission.limitTime
        self.missionTimedOut = false
        self.remainingMissionTime = Double(loadedMission.limitTime)

        // 진단: 각 아이템의 itemType 디코딩 결과 출력 (mine/black/Defense 구별 검증).
        for item in loadedMission.items {
            engineLog.debug("📦 item ID=\(item.itemID, privacy: .public) type=\(item.itemType.rawValue, privacy: .public) (\(item.itemType.displayLabel, privacy: .public)) showType=\(item.showType.rawValue, privacy: .public) rangeAR=\(item.rangeAR, privacy: .public) mandatory=\(item.isMandatory, privacy: .public)")
        }

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

        // 미션 전체 제한 시간 (0 = 무제한). 초과 시 미션 종료 처리.
        if missionLimitSeconds > 0, !missionTimedOut, !missionCompleted {
            remainingMissionTime = Double(missionLimitSeconds) - elapsedTime
            if remainingMissionTime <= 0 {
                remainingMissionTime = 0
                missionTimedOut = true
                stopTimer()
                SoundService.shared.play(.timeOver)
                recordPlay(action: .fail, time: Date())
            }
        }

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
        // 레거시 mineBlast:1276 — 이미 endYN="Y" 면 중복 폭발 방지
        guard dicItemEnd[item.itemID] != "Y" else { return }

        // 레거시 mineBlast:1277-1287 흐름: Defense 유무 무관하게
        // (1) 진동 + (2) 지뢰 endYN="Y" 처리 + (3) 폭발음 s_explosion.mp3 항상 실행.
        // 1. 진동
        HapticService.shared.vibrate()
        // 2. 지뢰 자체 endYN="Y" (지뢰는 항상 "처리됨" — Defense 사용해도 동일)
        dicItemEnd[item.itemID] = "Y"
        var minePlay = MissionItemInPlay(
            missionID: missionID, playerID: playerID, itemID: item.itemID)
        minePlay.endYN = "Y"
        minePlay.endTime = Date()
        try playRepo.updateItemInPlay(minePlay)
        // 3. 폭발음 (Defense 사용해도 폭발음은 들림)
        SoundService.shared.play(.explosion)

        // 4. Defence 파워업 확인 — 보유 시 ableCnt 차감 + 알림 후 종료 (데미지 없음)
        if let defenseCount = dicRnPTaken[ItemType.mineNoBomb.rawValue], defenseCount > 0 {
            dicRnPTaken[ItemType.mineNoBomb.rawValue] = defenseCount - 1
            let rnp = ItemRnPInPlay(
                missionID: missionID, playerID: playerID,
                itemType: ItemType.mineNoBomb.rawValue, ableCnt: defenseCount - 1)
            try powerUpRepo.update(rnp)
            enqueueAlert(ItemAcquiredAlert(
                title: "A mine has exploded!",
                message: "Mine did not damage using Defense item",
                itemIconName: item.arIconName))
            updateCounters()
            return
        }

        // 5. 최근 획득 아이템 되돌리기 (메모리 헬퍼 사용 — DB JOIN 불가)
        var lostItemTypeName: String?
        if let lostMissionItem = memoryLastAcquiredItem(excludeItemID: item.itemID) {
            dicItemEnd[lostMissionItem.itemID] = "N"
            var revert = MissionItemInPlay(
                missionID: missionID, playerID: playerID, itemID: lostMissionItem.itemID)
            revert.endYN = "N"
            try playRepo.updateItemInPlay(revert)
            // 다음 폭발 시 같은 아이템이 또 잡히지 않도록 큐에서 제거
            acquisitionOrder.removeAll { $0 == lostMissionItem.itemID }
            lostItemTypeName = lostMissionItem.itemType.displayLabel

            // 레거시 MissionPlay.m:1359-1370 — 상실 아이템이 START 면
            // MissionInPlay.startYN="N", startTime=nil 복원 + missionStarted=NO 복귀.
            if lostMissionItem.itemType == .start {
                missionStarted = false
                missionStartTime = nil
                let revertedPlay = MissionInPlay(
                    missionID: missionID, playerID: playerID,
                    startYN: "N", startTime: nil)
                try? playRepo.updateMissionInPlay(revertedPlay)
            }
        }

        // 4. 타임아웃 중이면 취소
        if isTimeOutActive {
            isTimeOutActive = false
            activeTimeoutStartID = nil
            lostItemTypeName = lostItemTypeName ?? "Run Start"
        }

        updateCounters()
        // 진동/폭발음은 함수 시작에서 이미 실행됨 (Defense 유무 무관 — 레거시 일치)

        if let lostName = lostItemTypeName {
            enqueueAlert(ItemAcquiredAlert(
                title: "A mine has exploded!",
                message: "The most recently acquired \(lostName) item has been lost.",
                itemIconName: item.arIconName))
        } else {
            enqueueAlert(ItemAcquiredAlert(
                title: "A mine has exploded!",
                message: "Mine has exploded!",
                itemIconName: item.arIconName))
        }
    }

    // MARK: - 아이템 획득 (기존: getItem:)

    func acquireItem(_ item: MissionItem) throws {
        guard let missionID = mission?.id else { return }

        // 레거시 ARViewController.m:637-653 — Run End 사전 검사.
        // (1) 활성 Run Start 가 없으면 거부 (obtain_fail_message_0 "Run Start item has not been acquired.")
        // (2) 활성은 있지만 짝(relationItemID) 이 다르면 거부 (obtain_fail_message_1)
        if item.itemType == .timeoutEnd {
            if !isTimeOutActive {
                enqueueAlert(ItemAcquiredAlert(
                    title: NSLocalizedString("obtain_fail", comment: ""),
                    message: NSLocalizedString("obtain_fail_message_0", comment: ""),
                    itemIconName: item.arIconName))
                return
            }
            if let activeID = activeTimeoutStartID, item.relationItemID != activeID {
                enqueueAlert(ItemAcquiredAlert(
                    title: NSLocalizedString("obtain_fail", comment: ""),
                    message: NSLocalizedString("obtain_fail_message_1", comment: ""),
                    itemIconName: item.arIconName))
                return
            }
        }

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

        // Gambling 처리 — 미보유 후보 중 1개를 랜덤 선택해 자동 획득.
        // 메모리 기반 헬퍼 사용 (DB 카탈로그 비어 있어 SQL JOIN 불가).
        // 추가: 활성 타임어택 중이면 Run Start(timeoutStart) 도 후보에서 제외 (레거시 ARViewController.m:855-857).
        var randomBonus: MissionItem?
        if item.itemType == .random {
            var candidates = memoryRandomCandidates(excludeItemID: item.itemID)
            if isTimeOutActive {
                candidates.removeAll { $0.itemType == .timeoutStart }
            }
            if let lucky = candidates.randomElement() {
                try acquireItem(lucky)
                randomBonus = lucky
            }
        }

        // Start 아이템 -> 미션 시작
        if item.itemType == .start && !missionStarted {
            missionStarted = true
            missionStartTime = Date()
            let play = MissionInPlay(missionID: missionID, playerID: playerID, startYN: "Y", startTime: Date())
            try playRepo.updateMissionInPlay(play)
            SoundService.shared.play(.gogogo)
            recordPlay(action: .start, time: missionStartTime ?? Date())
        }

        // Run Start -> 타임아웃 시작
        if item.itemType == .timeoutStart {
            timeOutStartTime = Date()
            if let endItem = items.first(where: { $0.itemType == .timeoutEnd && $0.relationItemID == item.itemID }) {
                timeOutLimitTime = endItem.effectiveTime
                isTimeOutActive = true
                activeTimeoutStartID = item.itemID
            }
        }

        // Run End -> 타임아웃 종료. 짝 Run Start 도 endYN="Y" 로 마무리 (레거시 :679-682).
        if item.itemType == .timeoutEnd {
            isTimeOutActive = false
            activeTimeoutStartID = nil
        }

        // End 아이템 -> 미션 완료 확인. 어느 경우든 게임 타이머는 중지(레거시 동작).
        // 메모리 기반 검사 (DB SQL 은 JOIN 이라 빈 결과). dicItemEnd[end.itemID] 도 위에서 "Y" 됐으니
        // 모든 mandatory 가 Y 면 완료.
        if item.itemType == .end {
            stopTimer()
            if isMissionCompletedInMemory {
                missionCompleted = true
                isMissionEnd = true
                SoundService.shared.play(.gameFinish)
                recordPlay(action: .finish, time: Date())
            }
        }

        // 획득 순서 큐에 추가 (mine 폭발 시 lost 후보 결정용)
        acquisitionOrder.append(item.itemID)

        updateCounters()
        if !missionCompleted {
            SoundService.shared.play(.itemGet)
        }

        // 획득 팝업 설정. random 의 경우 lucky 정보를 메시지에 포함하여
        // 사용자가 무엇을 추가로 얻었는지 인지하게 함 (레거시는 알림 2단계인데
        // SwiftUI overlay 단일 슬롯이라 한 번에 표시).
        setAcquiredAlert(for: item, bonus: randomBonus)
    }

    // MARK: - Mine 자동 폭발 감지

    /// 레거시 [`MissionPlay.m:1463-1473`](Classes/MissionPlay.m#L1463-L1473) — CLLocationManager 위치 갱신
    /// 콜백에서 missionStarted 일 때 모든 mine 의 rangeAR 안 진입 검사하여 자동 폭발.
    /// Map 화면 / AR 화면 모두에서 동일하게 발동되어야 함.
    /// - Parameter playerLocation: 현재 플레이어 GPS 위치
    func detectMineProximity(playerLocation: CLLocation) {
        guard missionStarted, !missionCompleted else { return }
        for item in items {
            guard item.itemType == .mine,
                  dicItemEnd[item.itemID] != "Y" else { continue }
            if playerLocation.distance(from: item.location) <= Double(item.rangeAR) {
                try? handleMineBlast(item: item)
                return  // 한 위치 갱신에 하나의 mine 만
            }
        }
    }

    // MARK: - 알림 큐

    /// 알림을 표시한다. 기존 알림이 있으면 큐에 추가.
    /// - Parameter prepend: true 면 현재 알림보다 먼저 보여줌 (현재 알림은 큐 앞으로 이동).
    ///   Random 효과 시 lucky 알림이 먼저 set 되었지만 사용자가 "Gambling acquired!" 를 먼저 봐야
    ///   자연스러우므로 random 의 setAcquiredAlert 에서 prepend=true 로 호출.
    private func enqueueAlert(_ alert: ItemAcquiredAlert, prepend: Bool = false) {
        if prepend, let current = pendingAlert {
            pendingAlertQueue.insert(current, at: 0)
            pendingAlert = alert
        } else if pendingAlert == nil {
            pendingAlert = alert
        } else {
            pendingAlertQueue.append(alert)
        }
    }

    /// 현재 알림을 닫고 큐에서 다음 알림 꺼내 표시. ItemAcquiredPopup 의 OK 핸들러에서 호출.
    func dismissCurrentAlert() {
        if pendingAlertQueue.isEmpty {
            pendingAlert = nil
        } else {
            pendingAlert = pendingAlertQueue.removeFirst()
        }
    }

    // MARK: - 메모리 기반 SQL 대체 헬퍼
    // 신규 PlaySpot 의 DB 는 사용자 플레이 상태 전용이라 MissionItem 카탈로그 행이 없음.
    // PlayStateRepository 의 INNER JOIN SQL 들은 빈 결과를 반환하므로 메모리(items, dicItemEnd)
    // 기반으로 동등한 결과를 계산하는 헬퍼들.

    /// 미션 완료 검사 — 모든 mandatory 가 endYN="Y" 인가.
    /// 레거시 [`MissionItemInPlayDao missionCompleted`](Classes/Dao/MissionItemInPlayDao.m#L376) SQL 의 메모리 버전.
    private var isMissionCompletedInMemory: Bool {
        items.allSatisfy { !$0.isMandatory || dicItemEnd[$0.itemID] == "Y" }
    }

    /// Random/Gambling 효과의 lucky 후보 — 미획득 + End/Random/Black 제외.
    /// 레거시 [`fetchRandomCandidates`](Classes/Dao/MissionItemInPlayDao.m#L289) SQL 의 메모리 버전.
    private func memoryRandomCandidates(excludeItemID: Int) -> [MissionItem] {
        items.filter { item in
            item.itemID != excludeItemID &&
            dicItemEnd[item.itemID] != "Y" &&
            ![.end, .random, .black].contains(item.itemType)
        }
    }

    /// Mine 폭발 시 lost 후보 — 가장 최근 획득 + Mine/Defense/Random/RunStart 제외.
    /// 레거시 [`fetchLastAcquiredItem`](Classes/Dao/MissionItemInPlayDao.m#L85) SQL 의 메모리 버전.
    private func memoryLastAcquiredItem(excludeItemID: Int) -> MissionItem? {
        for itemID in acquisitionOrder.reversed() where itemID != excludeItemID {
            guard let item = items.first(where: { $0.itemID == itemID }),
                  dicItemEnd[item.itemID] == "Y",
                  ![.mine, .mineNoBomb, .random, .timeoutStart].contains(item.itemType)
            else { continue }
            return item
        }
        return nil
    }

    // MARK: - 퀴즈 페널티 (레거시 QuizPlayAlert.m:106-142, 226-237 포팅)

    /// 현재 아이템의 퀴즈 누적 실패 횟수 조회. failCnt 0=힌트 없음, 1=글자수, 2+=첫 글자.
    func quizFailCount(for item: MissionItem) -> Int {
        guard let missionID = mission?.id else { return 0 }
        return (try? playRepo.fetchItemInPlay(
            missionID: missionID, playerID: playerID, itemID: item.itemID))?.failCnt ?? 0
    }

    /// 퀴즈 오답 시 호출. failCnt += 1, MissionItemInPlay update.
    /// 레거시는 endYN="N" + endTime=현재 도 갱신하지만, 우리는 endYN 은 미획득 상태로 유지.
    func recordQuizFailure(for item: MissionItem, quizSeq: Int) throws {
        guard let missionID = mission?.id else { return }
        let current = (try playRepo.fetchItemInPlay(
            missionID: missionID, playerID: playerID, itemID: item.itemID))
        var updated = MissionItemInPlay(
            missionID: missionID, playerID: playerID, itemID: item.itemID)
        updated.endYN = "N"
        updated.failCnt = (current?.failCnt ?? 0) + 1
        updated.quizSeq = quizSeq
        updated.endTime = Date()  // 레거시 동일
        try playRepo.updateItemInPlay(updated)
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

            // 레거시 MissionPlay.m updatePlayInfo: I_MINE 만 카운트 (mineNoBomb 제외)
            if item.itemType == .mine && !hasRadarMine { mineCount += 1 }
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

        // 레거시 MissionPlay.m:2097-2110 은 I_MINE 단독으로 Mine Radar 검사.
        // mineNoBomb(Defense)는 일반 showType 분기로 가야 하므로 == .mine 로 좁힘.
        if item.itemType == .mine {
            engineLog.debug("🗺 mine itemID=\(item.itemID, privacy: .public) hasRadarMine=\(hasRadarMine, privacy: .public) dicRnPTakenKeys=\(self.dicRnPTaken.keys.joined(separator: ","), privacy: .public) → \(hasRadarMine ? "표시" : "숨김", privacy: .public)")
            return hasRadarMine
        }

        // 레거시 MissionPlay.m:901 은 black 도 mine 처럼 별도 MKCircle overlay 로만 표현.
        // 핀 아이콘 자체는 Map 에 그리지 않고 다크존 영역(검은 반투명 원)만 보이게 한다.
        if item.itemType == .black {
            return false
        }

        // F-7: 미획득 다크존(black) 안에 있는 아이템은 지도에서 숨김.
        // 레거시 MissionPlay.m:2128-2134 의 분기 — _tmpItem 자신이 endYN!="Y" 일 때만 검사.
        // 즉 **이미 획득한 아이템은 다크존 안에 있어도 가려지지 않음** (회색 핀으로 정상 표시).
        // start 와 black 자신도 예외.
        if item.itemType != .start,
           item.itemType != .black,
           dicItemEnd[item.itemID] != "Y",
           isInsideUnacquiredDarkZone(item) {
            return false
        }

        // 획득한 아이템은 showType(.mapOnly 등) 와 무관하게 지도에 회색 핀으로 표시.
        // (위 mine/black 분기에서 이미 걸러진 타입은 여기 도달하지 않음.)
        // 사용자 피드백: 갬블링으로 자동 획득된 Hint(MAP 숨김) 가 안 보였던 버그 수정.
        if dicItemEnd[item.itemID] == "Y" {
            return true
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

    private func setAcquiredAlert(for item: MissionItem, bonus: MissionItem? = nil) {
        let icon = item.arIconName
        switch item.itemType {
        case .start:
            let msg = item.info.isEmpty ? "If you touch OK, the item will be released Mission." : item.info
            enqueueAlert(ItemAcquiredAlert(title: "Start Item acquired!", message: msg, itemIconName: icon))

        case .simple where item.itemGame == 0:
            let msg = item.info.isEmpty ? "Lose the draw!! No hint." : item.info
            enqueueAlert(ItemAcquiredAlert(title: "Hint Item acquired!", message: msg, itemIconName: icon))

        case .timeoutStart:
            let msg = item.info.isEmpty ? "Acquire Run End Item in time limit" : item.info
            enqueueAlert(ItemAcquiredAlert(title: "Run Start Item acquired!", message: msg, itemIconName: icon))

        case .timeoutEnd:
            let msg = item.info.isEmpty ? "Run time ended successfully." : item.info
            enqueueAlert(ItemAcquiredAlert(title: "Run End Item acquired!", message: msg, itemIconName: icon))

        case .solution:
            let msg = item.info.isEmpty ? "You can get an answer if you win mission quiz or quiz item." : item.info
            enqueueAlert(ItemAcquiredAlert(title: "Solution Item acquired!", message: msg, itemIconName: icon))

        case .radarAR:
            let msg = item.info.isEmpty ? "Stealth items are now visible in AR." : item.info
            enqueueAlert(ItemAcquiredAlert(title: "Stealth Radar Item acquired!", message: msg, itemIconName: icon))

        case .radarMap:
            let msg = item.info.isEmpty ? "Hidden items are now visible on the map." : item.info
            enqueueAlert(ItemAcquiredAlert(title: "Map Radar Item acquired!", message: msg, itemIconName: icon))

        case .radarMine:
            let msg = item.info.isEmpty ? "Mine explosion radius is now shown on the map." : item.info
            enqueueAlert(ItemAcquiredAlert(title: "Mine Radar Item acquired!", message: msg, itemIconName: icon))

        case .radarAll:
            let msg = item.info.isEmpty ? "All hidden items are now revealed." : item.info
            enqueueAlert(ItemAcquiredAlert(title: "All Radar Item acquired!", message: msg, itemIconName: icon))

        case .mineNoBomb:
            let msg = item.info.isEmpty ? "Mine damage can be avoided using this Defence item." : item.info
            enqueueAlert(ItemAcquiredAlert(title: "Defence Item acquired!", message: msg, itemIconName: icon))

        case .coupon:
            // 쿠폰 획득 — `info` 필드의 쿠폰 코드/안내문을 알림으로 표시.
            // 레거시 MissionPlay.m 엔 처리 없었음 (placeholder). 신규에서 명시 구현.
            let msg = item.info.isEmpty ? "Coupon acquired. Check details with the designer." : item.info
            enqueueAlert(ItemAcquiredAlert(title: "Coupon acquired!", message: msg, itemIconName: icon))

        case .random:
            // 레거시 ARViewController.m:1015-1023 — Gambling 알림 후 lucky 알림 순차 표시.
            // 우리는 큐에 prepend=true 로 push 하여 lucky 알림보다 먼저 보여주고,
            // 사용자 OK → 큐에서 lucky 알림 pop → 표시.
            let message: String
            if let bonus = bonus {
                message = "You won: \(bonus.itemType.displayLabel)!"
            } else {
                message = "Gambling failed — no items left to win."
            }
            enqueueAlert(
                ItemAcquiredAlert(title: "Gambling acquired!", message: message, itemIconName: icon),
                prepend: true)

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
