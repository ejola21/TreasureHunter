// Game/VirtualModeManager.swift
import CoreLocation
import OSLog

private let vmLog = Logger(subsystem: "com.ejola.playspot", category: "VirtualMode")

enum VirtualModeManager {
    /// 기존 MissionPlay.m virtualMode: 로직 — start 아이템을 플레이어 위치에 정렬하고
    /// 나머지 아이템을 동일 오프셋으로 평행이동.
    /// - Returns: 오프셋이 실제로 적용되면 true. 플레이어 위치가 nil이거나 start 아이템이 없으면 false.
    @discardableResult
    static func applyOffset(items: inout [MissionItem], playerLocation: CLLocation?, isNewStart: Bool) -> Bool {
        guard let playerLocation else {
            vmLog.error("⛔ applyOffset: playerLocation is nil — offset NOT applied (items stay at JSON coords)")
            return false
        }
        let itemCount = items.count
        guard let startItem = items.first(where: { $0.itemType == .start }) else {
            vmLog.error("⛔ applyOffset: no start item found in \(itemCount) items — offset NOT applied")
            return false
        }

        let latOffset = playerLocation.coordinate.latitude - startItem.latitude
        let lonOffset = playerLocation.coordinate.longitude - startItem.longitude

        vmLog.debug("""
            ✅ applyOffset: \(itemCount) items
               playerGPS  = (\(playerLocation.coordinate.latitude, privacy: .public), \(playerLocation.coordinate.longitude, privacy: .public))
               startItem  = (\(startItem.latitude, privacy: .public), \(startItem.longitude, privacy: .public))
               offset     = Δlat \(latOffset, privacy: .public), Δlon \(lonOffset, privacy: .public)
            """)

        for i in items.indices {
            items[i].latitude += latOffset
            items[i].longitude += lonOffset
        }
        return true
    }
}
