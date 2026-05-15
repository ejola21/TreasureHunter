// PlaySpotTests/ShowTypeTests.swift
import XCTest
@testable import PlaySpot

final class ShowTypeTests: XCTestCase {

    // MARK: - rawValue

    func testRawValues() {
        XCTAssertEqual(ShowType.transparent.rawValue, "1")
        XCTAssertEqual(ShowType.arOnly.rawValue, "2")
        XCTAssertEqual(ShowType.mapOnly.rawValue, "3")
        XCTAssertEqual(ShowType.all.rawValue, "4")
    }

    // MARK: - isVisibleOnMap

    func testAllVisibleOnMapAlways() {
        XCTAssertTrue(ShowType.all.isVisibleOnMap(hasRadarMap: false, hasRadarAll: false))
        XCTAssertTrue(ShowType.all.isVisibleOnMap(hasRadarMap: true, hasRadarAll: false))
    }

    func testMapOnlyVisibleOnMapAlways() {
        XCTAssertTrue(ShowType.mapOnly.isVisibleOnMap(hasRadarMap: false, hasRadarAll: false))
    }

    func testArOnlyHiddenOnMapWithoutRadar() {
        XCTAssertFalse(ShowType.arOnly.isVisibleOnMap(hasRadarMap: false, hasRadarAll: false))
    }

    func testArOnlyVisibleOnMapWithRadarMap() {
        XCTAssertTrue(ShowType.arOnly.isVisibleOnMap(hasRadarMap: true, hasRadarAll: false))
    }

    func testArOnlyVisibleOnMapWithRadarAll() {
        XCTAssertTrue(ShowType.arOnly.isVisibleOnMap(hasRadarMap: false, hasRadarAll: true))
    }

    func testTransparentHiddenOnMapWithoutRadar() {
        XCTAssertFalse(ShowType.transparent.isVisibleOnMap(hasRadarMap: false, hasRadarAll: false))
    }

    func testTransparentVisibleOnMapWithRadarMap() {
        XCTAssertTrue(ShowType.transparent.isVisibleOnMap(hasRadarMap: true, hasRadarAll: false))
    }

    // MARK: - isVisibleInAR

    func testAllVisibleInARAlways() {
        XCTAssertTrue(ShowType.all.isVisibleInAR(hasRadarAR: false, hasRadarAll: false))
    }

    func testArOnlyVisibleInARAlways() {
        XCTAssertTrue(ShowType.arOnly.isVisibleInAR(hasRadarAR: false, hasRadarAll: false))
    }

    func testMapOnlyHiddenInARWithoutRadar() {
        XCTAssertFalse(ShowType.mapOnly.isVisibleInAR(hasRadarAR: false, hasRadarAll: false))
    }

    func testMapOnlyVisibleInARWithRadarAR() {
        XCTAssertTrue(ShowType.mapOnly.isVisibleInAR(hasRadarAR: true, hasRadarAll: false))
    }

    func testMapOnlyVisibleInARWithRadarAll() {
        XCTAssertTrue(ShowType.mapOnly.isVisibleInAR(hasRadarAR: false, hasRadarAll: true))
    }

    func testTransparentHiddenInARWithoutRadar() {
        XCTAssertFalse(ShowType.transparent.isVisibleInAR(hasRadarAR: false, hasRadarAll: false))
    }

    func testTransparentVisibleInARWithRadarAR() {
        XCTAssertTrue(ShowType.transparent.isVisibleInAR(hasRadarAR: true, hasRadarAll: false))
    }

    // MARK: - 모든 조합 테스트

    func testAllRadarCombinations() {
        // Normal (all): 항상 모두 보임
        for map in [true, false] {
            for all in [true, false] {
                XCTAssertTrue(ShowType.all.isVisibleOnMap(hasRadarMap: map, hasRadarAll: all))
            }
            for ar in [true, false] {
                XCTAssertTrue(ShowType.all.isVisibleInAR(hasRadarAR: ar, hasRadarAll: map))
            }
        }
    }
}
