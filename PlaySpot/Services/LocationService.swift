// Services/LocationService.swift
import CoreLocation
import Observation
import OSLog

private let locLog = Logger(subsystem: "com.ejola.playspot", category: "LocationService")

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

    /// 첫 위치 픽스가 들어올 때까지 폴링 대기. Virtual 모드 setup 전 호출하여
    /// VirtualModeManager.applyOffset이 nil 위치로 동작하는 것을 방지.
    /// 권한 다이얼로그 응답 시간 + 시뮬레이터 위치 부팅을 감안하여 기본 8초로 넉넉히.
    /// 타임아웃돼도 nil 반환만 할 뿐, 호출 측은 onChange 옵저버로 늦은 도착에 대응한다.
    func awaitFirstLocation(timeoutSeconds: Double = 8.0) async -> CLLocation? {
        if let current = currentLocation {
            locLog.debug("📍 awaitFirstLocation: immediate hit (\(current.coordinate.latitude, privacy: .public), \(current.coordinate.longitude, privacy: .public))")
            return current
        }
        locLog.warning("📍 awaitFirstLocation: currentLocation is nil — polling up to \(timeoutSeconds, privacy: .public)s")
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while Date() < deadline {
            if let current = currentLocation {
                locLog.debug("📍 awaitFirstLocation: polled hit (\(current.coordinate.latitude, privacy: .public), \(current.coordinate.longitude, privacy: .public))")
                return current
            }
            if Task.isCancelled {
                locLog.warning("📍 awaitFirstLocation: task cancelled — returning nil")
                return nil
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }
        locLog.error("📍 awaitFirstLocation: timed out — currentLocation=\(self.currentLocation.map { "(\($0.coordinate.latitude),\($0.coordinate.longitude))" } ?? "nil", privacy: .public)")
        return currentLocation
    }

    /// 기존 MissionPlay.m의 distanceCalc: 대체
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let current = currentLocation else { return nil }
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return current.distance(from: target)
    }

    /// 기존 ARGeoViewController의 angleFromCoordinate:toCoordinate: 대체
    func bearing(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let current = currentLocation else { return nil }
        let lat1 = current.coordinate.latitude.radians
        let lon1 = current.coordinate.longitude.radians
        let lat2 = coordinate.latitude.radians
        let lon2 = coordinate.longitude.radians

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        return atan2(y, x)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        // 권한이 늦게 도착한 경우(startUpdating은 이미 호출됨) CoreLocation이 실제 업데이트를
        // 시작하지 않는 케이스가 있어, 권한 grant 시점에 한 번 더 명시적으로 재시작한다.
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            manager.startUpdatingHeading()
        default:
            break
        }
    }
}

private extension CLLocationDegrees {
    var radians: Double { self * .pi / 180.0 }
}
