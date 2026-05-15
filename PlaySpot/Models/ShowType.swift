// Models/ShowType.swift
import Foundation

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
    func isVisibleOnMap(hasRadarMap: Bool, hasRadarAll: Bool) -> Bool {
        switch self {
        case .all, .mapOnly: true
        case .arOnly, .transparent: hasRadarMap || hasRadarAll
        }
    }

    /// 레이더 보유 상태에 따른 AR 가시성 판정
    func isVisibleInAR(hasRadarAR: Bool, hasRadarAll: Bool) -> Bool {
        switch self {
        case .all, .arOnly: true
        case .mapOnly, .transparent: hasRadarAR || hasRadarAll
        }
    }
}
