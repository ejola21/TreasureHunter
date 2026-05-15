// AR/ARCoordinate.swift
import CoreLocation
import Foundation

/// 기존 ARCoordinate.h/m + ARGeoCoordinate.h/m 통합
struct ARCoordinate {
    var radialDistance: Double = 0   // 원점으로부터의 거리 (m)
    var inclination: Double = 0     // 기울기 (라디안)
    var azimuth: Double = 0         // 방위각 (라디안)
    var title: String = ""

    /// 기존 ARGeoCoordinate.m의 calibrateUsingOrigin: 대체
    /// GPS 좌표를 원점(플레이어 위치) 기준의 구면좌표로 변환
    static func from(
        location: CLLocation,
        origin: CLLocation
    ) -> ARCoordinate {
        let distance = origin.distance(from: location)
        let bearing = Self.bearing(from: origin.coordinate, to: location.coordinate)
        return ARCoordinate(
            radialDistance: distance,
            inclination: 0,
            azimuth: bearing
        )
    }

    /// 기존 ARGeoViewController의 angleFromCoordinate:toCoordinate:
    static func bearing(
        from origin: CLLocationCoordinate2D,
        to target: CLLocationCoordinate2D
    ) -> Double {
        let lat1 = origin.latitude * .pi / 180.0
        let lon1 = origin.longitude * .pi / 180.0
        let lat2 = target.latitude * .pi / 180.0
        let lon2 = target.longitude * .pi / 180.0

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        return atan2(y, x)
    }
}
