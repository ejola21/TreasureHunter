// PlaySpotTests/ARCoordinateTests.swift
import XCTest
import CoreLocation
@testable import PlaySpot

final class ARCoordinateTests: XCTestCase {

    // MARK: - bearing 수학 검증

    func testBearingNorth() {
        // 서울역 -> 정북방향 (같은 경도, 위도 증가)
        let origin = CLLocationCoordinate2D(latitude: 37.5547, longitude: 126.9706)
        let target = CLLocationCoordinate2D(latitude: 37.5647, longitude: 126.9706)

        let bearing = ARCoordinate.bearing(from: origin, to: target)

        // 정북 = 0 라디안 (atan2 기준)
        XCTAssertEqual(bearing, 0, accuracy: 0.01)
    }

    func testBearingEast() {
        // 같은 위도, 경도 증가 -> 동쪽
        let origin = CLLocationCoordinate2D(latitude: 37.5547, longitude: 126.9706)
        let target = CLLocationCoordinate2D(latitude: 37.5547, longitude: 126.9806)

        let bearing = ARCoordinate.bearing(from: origin, to: target)

        // 동쪽 = π/2 라디안
        XCTAssertEqual(bearing, .pi / 2, accuracy: 0.01)
    }

    func testBearingSouth() {
        let origin = CLLocationCoordinate2D(latitude: 37.5547, longitude: 126.9706)
        let target = CLLocationCoordinate2D(latitude: 37.5447, longitude: 126.9706)

        let bearing = ARCoordinate.bearing(from: origin, to: target)

        // 정남 = π 또는 -π 라디안
        XCTAssertEqual(abs(bearing), .pi, accuracy: 0.01)
    }

    func testBearingWest() {
        let origin = CLLocationCoordinate2D(latitude: 37.5547, longitude: 126.9706)
        let target = CLLocationCoordinate2D(latitude: 37.5547, longitude: 126.9606)

        let bearing = ARCoordinate.bearing(from: origin, to: target)

        // 서쪽 = -π/2 라디안
        XCTAssertEqual(bearing, -.pi / 2, accuracy: 0.01)
    }

    func testBearingSameLocation() {
        let coord = CLLocationCoordinate2D(latitude: 37.5547, longitude: 126.9706)
        let bearing = ARCoordinate.bearing(from: coord, to: coord)

        // 동일 좌표 => 0
        XCTAssertEqual(bearing, 0, accuracy: 0.001)
    }

    // MARK: - from(location:origin:) 변환

    func testFromLocationDistance() {
        let origin = CLLocation(latitude: 37.5547, longitude: 126.9706)
        let target = CLLocation(latitude: 37.5647, longitude: 126.9706)

        let coord = ARCoordinate.from(location: target, origin: origin)

        // 위도 0.01도 ≈ 1.11km
        XCTAssertEqual(coord.radialDistance, origin.distance(from: target), accuracy: 1.0)
        XCTAssertEqual(coord.inclination, 0)
        XCTAssertEqual(coord.azimuth, 0, accuracy: 0.01)
    }

    func testFromLocationAzimuthMatchesBearing() {
        let origin = CLLocation(latitude: 37.4750, longitude: 126.9570)  // 관악구
        let target = CLLocation(latitude: 37.4800, longitude: 126.9620)

        let coord = ARCoordinate.from(location: target, origin: origin)
        let expectedBearing = ARCoordinate.bearing(from: origin.coordinate, to: target.coordinate)

        XCTAssertEqual(coord.azimuth, expectedBearing, accuracy: 0.001)
    }

    // MARK: - 기존 angleFromCoordinate 호환성

    func testBearingSeoulToGwanak() {
        // 관악구 내 두 지점 — 기존 앱에서 사용된 좌표 근처
        let origin = CLLocationCoordinate2D(latitude: 37.478573, longitude: 126.951601)
        let target = CLLocationCoordinate2D(latitude: 37.480273, longitude: 126.953124)

        let bearing = ARCoordinate.bearing(from: origin, to: target)

        // 북동 방향이어야 함 (0 < bearing < π/2)
        XCTAssertGreaterThan(bearing, 0)
        XCTAssertLessThan(bearing, .pi / 2)
    }
}
