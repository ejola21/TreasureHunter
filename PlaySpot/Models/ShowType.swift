// Models/ShowType.swift
import Foundation

enum ShowType: String, Codable {
    case transparent = "1"  // 지도·AR 모두 숨김 — 레이더로만 발견
    case arOnly = "2"       // 지도에서 숨김, AR 에서 정상 표시 ("Hidden")
    case mapOnly = "3"      // 지도에 표시, AR 거리·방향 정보 숨김 ("Stealth")
    case all = "4"          // 지도·AR 모두 표시 ("Visible")

    /// 표시 방식 라벨 — 디자이너 picker / 플레이 화면 공통 단일 진실 출처.
    var displayName: String {
        switch self {
        case .all: "Visible"
        case .arOnly: "Hidden"
        case .mapOnly: "Stealth"
        case .transparent: "Hidden+Stealth"
        }
    }

    /// 라벨 보조 설명 — picker 하단 안내 문구.
    var helpText: String {
        switch self {
        case .all: "지도와 AR 화면에서 모두 표시"
        case .arOnly: "지도에서 숨김 (AR 에서는 정상 표시)"
        case .mapOnly: "지도에는 표시, AR 화면의 거리·방향 정보 숨김"
        case .transparent: "지도와 AR 모두 숨김 (레이더 필요)"
        }
    }

    /// 디자이너 picker 에 노출하는 케이스 (transparent=1 은 미사용).
    static let selectableCases: [ShowType] = [.all, .arOnly, .mapOnly]

    /// 레이더 보유 상태에 따른 지도 가시성 판정.
    /// Stealth(.mapOnly) 는 지도에 표시됨 — AR 거리·방향 정보만 숨김.
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
