// Models/ItemType.swift
import SwiftUI

enum ItemType: String, Codable, CaseIterable {
    // 수집 아이템 (00~10)
    case num00 = "00", num01 = "01", num02 = "02", num03 = "03", num04 = "04"
    case num05 = "05", num06 = "06", num07 = "07", num08 = "08", num09 = "09"
    case alphabet = "10"

    // 퀴즈 (40~43)
    case quiz = "40"
    case quiz20 = "41"
    case timeoutStart = "42"
    case timeoutEnd = "43"

    // 미션 필수 (48~49)
    case end = "48"
    case start = "49"

    // 특수 아이템 (50~56, 61)
    case random = "50"
    case simple = "51"       // Hint
    case solution = "52"
    case penaltyRemove = "54"
    case mine = "55"
    case black = "56"        // Dark
    case coupon = "59"
    case mineNoBomb = "61"   // Defence

    // 레이더 (65~69)
    case radarAR = "65"      // Stealth Radar
    case radarMap = "66"     // Map Radar
    case radarAll = "67"
    case radarMine = "68"
    case radarBlack = "69"

    // 상점
    case store = "91"

    // MARK: - 분류 프로퍼티

    /// 레거시 AppDelegate.itemTypeObjects 와 동일. AR 화면 좌측 라벨 등에서 String 으로 사용.
    var displayLabel: String {
        switch self {
        case .start: "Start"
        case .end: "End"
        case .simple: "Hint"
        case .quiz, .quiz20: "Quiz"
        case .random: "Gambling"
        case .timeoutStart: "Run Start"
        case .timeoutEnd: "Run End"
        case .mine: "Mine"
        case .black: "Dark"
        case .mineNoBomb: "Defense"
        case .solution: "Solution"
        case .radarAR: "Stealth Radar"
        case .radarMap: "Map Radar"
        case .radarAll: "All Radar"
        case .radarMine: "Mine Radar"
        case .coupon: "Coupon"
        case .store: "Store"
        default: "Item"
        }
    }

    var displayName: LocalizedStringKey { LocalizedStringKey(displayLabel) }

    /// 기존 itemTypeFiles 배열 대체 — 리소스 이미지 파일명 접두사
    var imageFileName: String {
        switch self {
        case .start: "start"
        case .end: "end"
        case .simple: "simple"
        case .quiz, .quiz20: "quiz"
        case .random: "random_box"
        case .timeoutStart: "time_start"
        case .timeoutEnd: "time_end"
        case .mine: "mine"
        case .black: "black"
        case .mineNoBomb: "mine_nobomb"
        case .solution: "genius"
        case .radarAR: "radar_ar"
        case .radarMap: "radar_map"
        case .radarMine: "radar_mine"
        case .radarAll: "radar_all"
        case .coupon: "coupon"
        case .store: "store"
        default: "original"
        }
    }

    /// 기존 itemMapFile: / itemARFile: 대체
    func mapIcon(mandatory: Bool) -> String {
        mandatory ? "Items/in_\(imageFileName)" : "Items/i_\(imageFileName)"
    }

    func arIcon(mandatory: Bool) -> String {
        mandatory ? "AR/arn_\(imageFileName)" : "AR/ar_\(imageFileName)"
    }

    var isMine: Bool { self == .mine || self == .mineNoBomb }
    var isRadar: Bool { [.radarAR, .radarMap, .radarAll, .radarMine].contains(self) }
    var isTimeout: Bool { self == .timeoutStart || self == .timeoutEnd }

    /// mineBlast에서 제외되는 타입 — selectLastAcquiredItem 쿼리의 NOT IN ('55','61','50','42')
    var excludedFromLastAcquired: Bool {
        [.mine, .mineNoBomb, .random, .timeoutStart].contains(self)
    }

    /// selectRand에서 제외 — NOT IN ('48','50','56')
    var excludedFromRandom: Bool {
        [.end, .random, .black].contains(self)
    }
}
