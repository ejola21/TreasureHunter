// PlaySpotTests/GameEngineTests.swift
import XCTest
@testable import PlaySpot

final class GameEngineTests: XCTestCase {

    // MARK: - updateCounters

    func testUpdateCountersMineCount() {
        let engine = GameEngine()
        engine.items = [
            makeMissionItem(id: 1, type: .mine),
            makeMissionItem(id: 2, type: .mine),
            makeMissionItem(id: 3, type: .quiz),
        ]
        engine.dicItemEnd = [1: "N", 2: "N", 3: "N"]

        engine.updateCounters()

        XCTAssertEqual(engine.mineCount, 2)
    }

    func testUpdateCountersMineCountWithRadar() {
        let engine = GameEngine()
        engine.items = [
            makeMissionItem(id: 1, type: .mine),
            makeMissionItem(id: 2, type: .mine),
        ]
        engine.dicItemEnd = [1: "N", 2: "N"]
        engine.dicRnPTaken = [ItemType.radarMine.rawValue: 1]

        engine.updateCounters()

        // 레이더가 있으면 지뢰 카운터는 0
        XCTAssertEqual(engine.mineCount, 0)
    }

    func testUpdateCountersMandatoryRemaining() {
        let engine = GameEngine()
        engine.items = [
            makeMissionItem(id: 1, type: .start, mandatory: true),
            makeMissionItem(id: 2, type: .quiz, mandatory: true),
            makeMissionItem(id: 3, type: .simple, mandatory: false),
        ]
        engine.dicItemEnd = [1: "Y", 2: "N", 3: "N"]

        engine.updateCounters()

        // Start는 이미 획득, Quiz만 남음
        XCTAssertEqual(engine.mandatoryRemaining, 1)
    }

    func testUpdateCountersHiddenOnMap() {
        let engine = GameEngine()
        engine.items = [
            makeMissionItem(id: 1, type: .quiz, showType: .arOnly),     // hidden on map
            makeMissionItem(id: 2, type: .simple, showType: .transparent), // hidden on map
            makeMissionItem(id: 3, type: .end, showType: .all),          // visible
        ]
        engine.dicItemEnd = [1: "N", 2: "N", 3: "N"]

        engine.updateCounters()

        XCTAssertEqual(engine.hiddenOnMapCount, 2)
    }

    func testUpdateCountersHiddenOnMapWithRadar() {
        let engine = GameEngine()
        engine.items = [
            makeMissionItem(id: 1, type: .quiz, showType: .arOnly),
        ]
        engine.dicItemEnd = [1: "N"]
        engine.dicRnPTaken = [ItemType.radarMap.rawValue: 1]

        engine.updateCounters()

        // 맵 레이더가 있으면 hidden이 보이므로 0
        XCTAssertEqual(engine.hiddenOnMapCount, 0)
    }

    func testUpdateCountersStealthOnAR() {
        let engine = GameEngine()
        engine.items = [
            makeMissionItem(id: 1, type: .quiz, showType: .mapOnly),  // stealth in AR
        ]
        engine.dicItemEnd = [1: "N"]

        engine.updateCounters()

        XCTAssertEqual(engine.stealthOnARCount, 1)
    }

    func testUpdateCountersStealthOnARWithRadar() {
        let engine = GameEngine()
        engine.items = [
            makeMissionItem(id: 1, type: .quiz, showType: .mapOnly),
        ]
        engine.dicItemEnd = [1: "N"]
        engine.dicRnPTaken = [ItemType.radarAR.rawValue: 1]

        engine.updateCounters()

        XCTAssertEqual(engine.stealthOnARCount, 0)
    }

    func testUpdateCountersAcquiredItemsExcluded() {
        let engine = GameEngine()
        engine.items = [
            makeMissionItem(id: 1, type: .mine),
            makeMissionItem(id: 2, type: .mine),
        ]
        engine.dicItemEnd = [1: "Y", 2: "N"]

        engine.updateCounters()

        // 획득한 지뢰는 카운트에서 제외
        XCTAssertEqual(engine.mineCount, 1)
    }

    // MARK: - shouldShowOnMap

    func testShouldShowOnMapNormalItem() {
        let engine = GameEngine()
        let item = makeMissionItem(id: 1, type: .quiz, showType: .all)

        XCTAssertTrue(engine.shouldShowOnMap(item))
    }

    func testShouldShowOnMapMineWithoutRadar() {
        let engine = GameEngine()
        let item = makeMissionItem(id: 1, type: .mine)

        XCTAssertFalse(engine.shouldShowOnMap(item))
    }

    func testShouldShowOnMapMineWithRadar() {
        let engine = GameEngine()
        engine.dicRnPTaken = [ItemType.radarMine.rawValue: 1]
        let item = makeMissionItem(id: 1, type: .mine)

        XCTAssertTrue(engine.shouldShowOnMap(item))
    }

    func testShouldShowOnMapHiddenWithoutRadar() {
        let engine = GameEngine()
        let item = makeMissionItem(id: 1, type: .quiz, showType: .arOnly)

        XCTAssertFalse(engine.shouldShowOnMap(item))
    }

    func testShouldShowOnMapHiddenWithRadarAll() {
        let engine = GameEngine()
        engine.dicRnPTaken = [ItemType.radarAll.rawValue: 1]
        let item = makeMissionItem(id: 1, type: .quiz, showType: .arOnly)

        XCTAssertTrue(engine.shouldShowOnMap(item))
    }

    // MARK: - Helpers

    private func makeMissionItem(
        id: Int, type: ItemType, showType: ShowType = .all, mandatory: Bool = false
    ) -> MissionItem {
        MissionItem(
            missionID: "test_mission", itemID: id, itemType: type,
            latitude: 37.4786, longitude: 126.9516,
            showType: showType, mandatoryYN: mandatory ? "Y" : "N"
        )
    }
}
