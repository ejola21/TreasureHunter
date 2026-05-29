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

    // MARK: - 디자이너용 안내 (item_design.md)

    /// 빌더의 ItemDetailView "아이템 정보" 카드에 표시하는 친근한 설명 한 쌍.
    /// - `effect`: 게임에서 이 아이템이 어떻게 동작하는지 한 줄.
    /// - `tip`: 디자이너가 배치할 때 알아둘 점 (`💡` 박스).
    var detailGuide: (effect: String, tip: String) {
        switch self {
        case .start:
            return ("미션이 시작되는 출발점이에요. 플레이어가 이 위치를 찍어야 시간이 흐르기 시작합니다.",
                    "미션에 꼭 1개. 안내문에 \"여기서 출발하세요!\" 같은 한 줄을 넣어주면 좋아요.")
        case .end:
            return ("미션이 끝나는 도착점이에요. 필수 아이템을 모두 모은 뒤 여기에 도달하면 미션 클리어!",
                    "미션에 꼭 1개. 시작점에서 적당히 떨어진, 마지막에 들를 만한 위치에.")
        case .quiz, .quiz20:
            return ("획득하면 퀴즈 창이 떠요. 정답을 맞혀야 획득됩니다.",
                    "여러 문제를 등록하면 플레이 시 랜덤으로 출제돼요.")
        case .timeoutStart:
            return ("획득하는 순간 짧은 카운트다운이 시작돼요. 시간 안에 ‘Run End’ 아이템을 획득해야 합니다.",
                    "‘Run End’ 아이템이 자동으로 함께 생겨요. 제한 시간을 30~120초로 설정해 난이도를 조절하세요.")
        case .timeoutEnd:
            return ("Run Start 의 짝꿍이에요. 제한 시간 안에 획득하면 성공입니다.",
                    "자동으로 생성되니 따로 추가할 필요 없어요. 위치만 옮기면 됩니다.")
        case .mineNoBomb:
            return ("획득하면 지뢰 한 번의 피해를 막아주는 방어 아이템이에요.",
                    "안내문에 \"지뢰 피해를 1번 막아드려요\" 정도 넣어주세요.")
        case .solution:
            return ("획득하면 퀴즈 1개의 답을 알려줍니다.",
                    "미니게임을 추가해서 획득 난이도를 조절하세요.")
        case .radarAR:
            return ("획득 후 AR 화면에서 숨겨둔 아이템들이 보이게 돼요.",
                    "미션에 1개만. Stealth 아이템과 함께 사용하세요.")
        case .radarMap:
            return ("획득 후 지도 화면에서 숨겨둔 아이템들이 보이게 돼요.",
                    "미션에 1개만. Hidden 아이템과 함께 사용하세요.")
        case .radarMine:
            return ("획득 후 지도에 지뢰 위치와 폭발 반경이 표시돼요.",
                    "미션에 1개만. 지뢰가 많은 코스라면 꼭 하나 두는 걸 추천!")
        case .mine:
            return ("위험! 반경 안에 들어가면 폭발하면서 최근에 얻은 아이템 1개를 잃어요.",
                    "반경(rangeAR)만 설정하면 끝. 좁은 길목·핵심 동선에 두면 긴장감이 살아납니다. 지도에 빨간 원으로 표시돼요.")
        case .black:
            return ("AR 보물찾기 존이에요. 지도 반경 안에서는 아이템 표시가 안 돼요.",
                    "보물찾기 분위기를 만들고 싶은 구역에 활용하세요.")
        case .simple:
            return ("획득하면 힌트 문구가 보이는 안내 아이템이에요.",
                    "미니게임을 추가해 난이도 조절 가능해요. 미션 완료에 대한 힌트나 안내문을 표시해요.")
        case .random:
            return ("획득하면 다른 아이템 중 하나를 랜덤으로 함께 획득할 수 있어요. (행운 ✨)",
                    "미션 곳곳에 흩뿌려두면 재미가 살아나요. 안내문 한 줄과 미니게임 선택 가능.")
        case .coupon:
            return ("획득하면 쿠폰 코드/안내문이 알림으로 떠요.",
                    "'info' 칸에 실제 쿠폰 코드나 사용 안내를 적으세요. 예: \"이마트 5000원 할인 ABCD-1234\" / \"3월까지 사용 가능\".")
        case .store:
            return ("미션 중 상점 진입점으로 쓸 예정인 아이템이에요. 지금은 효과가 없습니다.",
                    "향후 결제/포인트 화면 연동 예정. 현재는 배치해도 게임 중 알림이 뜨지 않으니 사용을 미뤄주세요.")
        default:
            return ("일반 아이템이에요.",
                    "이 아이템 유형은 빌더에서 활용하지 않습니다.")
        }
    }
}
