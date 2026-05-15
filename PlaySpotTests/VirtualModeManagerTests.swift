// PlaySpotTests/VirtualModeManagerTests.swift
import XCTest
import CoreLocation
@testable import PlaySpot

final class VirtualModeManagerTests: XCTestCase {

    // MARK: - 좌표 오프셋 적용

    func testApplyOffsetShiftsAllItems() {
        var items = makeTestItems()

        let playerLocation = CLLocation(latitude: 37.5000, longitude: 127.0000)
        VirtualModeManager.applyOffset(items: &items, playerLocation: playerLocation, isNewStart: true)

        // Start 아이템이 플레이어 위치로 이동해야 함
        let startItem = items.first { $0.itemType == .start }!
        XCTAssertEqual(startItem.latitude, playerLocation.coordinate.latitude, accuracy: 0.0001)
        XCTAssertEqual(startItem.longitude, playerLocation.coordinate.longitude, accuracy: 0.0001)
    }

    func testApplyOffsetMaintainsRelativeDistances() {
        var items = makeTestItems()

        let originalDeltaLat = items[1].latitude - items[0].latitude
        let originalDeltaLon = items[1].longitude - items[0].longitude

        let playerLocation = CLLocation(latitude: 37.5000, longitude: 127.0000)
        VirtualModeManager.applyOffset(items: &items, playerLocation: playerLocation, isNewStart: true)

        let newDeltaLat = items[1].latitude - items[0].latitude
        let newDeltaLon = items[1].longitude - items[0].longitude

        // 상대 거리가 유지되어야 함
        XCTAssertEqual(originalDeltaLat, newDeltaLat, accuracy: 0.0001)
        XCTAssertEqual(originalDeltaLon, newDeltaLon, accuracy: 0.0001)
    }

    func testApplyOffsetNoopWithoutPlayerLocation() {
        var items = makeTestItems()
        let originalLat = items[0].latitude

        VirtualModeManager.applyOffset(items: &items, playerLocation: nil, isNewStart: true)

        XCTAssertEqual(items[0].latitude, originalLat, accuracy: 0.0001)
    }

    func testApplyOffsetNoopWithoutStartItem() {
        var items = [MissionItem(
            missionID: "m1", itemID: 1, itemType: .quiz,
            latitude: 37.4786, longitude: 126.9516, showType: .all
        )]
        let originalLat = items[0].latitude

        let playerLocation = CLLocation(latitude: 37.5, longitude: 127.0)
        VirtualModeManager.applyOffset(items: &items, playerLocation: playerLocation, isNewStart: true)

        XCTAssertEqual(items[0].latitude, originalLat, accuracy: 0.0001)
    }

    // MARK: - Helpers

    private func makeTestItems() -> [MissionItem] {
        [
            MissionItem(missionID: "m1", itemID: 0, itemType: .start,
                        latitude: 37.4786, longitude: 126.9516, showType: .all),
            MissionItem(missionID: "m1", itemID: 1, itemType: .quiz,
                        latitude: 37.4796, longitude: 126.9526, showType: .all),
            MissionItem(missionID: "m1", itemID: 2, itemType: .end,
                        latitude: 37.4806, longitude: 126.9536, showType: .all),
        ]
    }
}
