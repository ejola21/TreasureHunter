// Models/MissionItem.swift
import CoreLocation

struct MissionItem: Identifiable, Codable {
    var id: String { "\(missionID)_\(itemID)" }

    var missionID: String
    var itemID: Int
    var mandatory: MandatoryFlag = .optional
    var itemType: ItemType = .simple
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    var blackCnt: Int = 5              // 기본값 5 (기존 init에서 설정)
    var blackTime: Int = 300           // 기본값 300초 = 5분
    var rangeAR: Int = 30              // 기본값 30m
    var showType: ShowType = .all
    var effectiveRange: Int = 0
    var effectiveTime: Int = 0
    var itemGame: Int = 0
    var info: String = ""
    var relationItemID: Int = 0
    var quizSeq: Int = 1               // 기본값 1
    var rnpSeq: Int = 0
    var quizzes: [ItemQuiz] = []

    enum CodingKeys: String, CodingKey {
        case missionID = "MissionID"
        case itemID = "ItemID"
        case mandatory = "Mandatory"
        case itemType = "ItemType"
        case latitude = "Latitude"
        case longitude = "Longitude"
        case blackCnt = "BlackCnt"
        case blackTime = "BlackTime"
        case rangeAR = "RangeAR"
        case showType = "ShowType"
        case effectiveRange = "EffectiveRange"
        case effectiveTime = "EffectiveTime"
        case itemGame = "ItemGame"
        case info = "Info"
        case relationItemID = "RelationItemID"
        case quizSeq
        case rnpSeq
        case quizzes
    }

    init(missionID: String, itemID: Int) {
        self.missionID = missionID
        self.itemID = itemID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        missionID = try container.decodeIfPresent(String.self, forKey: .missionID) ?? ""
        itemID = try container.decode(Int.self, forKey: .itemID)
        mandatory = try container.decodeIfPresent(MandatoryFlag.self, forKey: .mandatory) ?? .optional
        itemType = try container.decodeIfPresent(ItemType.self, forKey: .itemType) ?? .simple
        latitude = try container.decodeIfPresent(CLLocationDegrees.self, forKey: .latitude) ?? 0
        longitude = try container.decodeIfPresent(CLLocationDegrees.self, forKey: .longitude) ?? 0
        blackCnt = try container.decodeIfPresent(Int.self, forKey: .blackCnt) ?? 5
        blackTime = try container.decodeIfPresent(Int.self, forKey: .blackTime) ?? 300
        rangeAR = try container.decodeIfPresent(Int.self, forKey: .rangeAR) ?? 30
        showType = try container.decodeIfPresent(ShowType.self, forKey: .showType) ?? .all
        effectiveRange = try container.decodeIfPresent(Int.self, forKey: .effectiveRange) ?? 0
        effectiveTime = try container.decodeIfPresent(Int.self, forKey: .effectiveTime) ?? 0
        itemGame = try container.decodeIfPresent(Int.self, forKey: .itemGame) ?? 0
        info = try container.decodeIfPresent(String.self, forKey: .info) ?? ""
        relationItemID = try container.decodeIfPresent(Int.self, forKey: .relationItemID) ?? 0
        quizSeq = try container.decodeIfPresent(Int.self, forKey: .quizSeq) ?? 1
        rnpSeq = try container.decodeIfPresent(Int.self, forKey: .rnpSeq) ?? 0
        quizzes = try container.decodeIfPresent([ItemQuiz].self, forKey: .quizzes) ?? []
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    var isMandatory: Bool { mandatory == .mandatory }

    /// 미니게임 여부 — type=simple(51)이면서 itemGame>0이면 miniGame.
    /// 레거시와 동일하게 아이콘은 힌트(i_simple) 그대로, 인터랙션만 shake/touch로 분기된다.
    var isMiniGame: Bool { itemType == .simple && itemGame > 0 }

    var mapIconName: String { itemType.mapIcon(mandatory: isMandatory) }

    var arIconName: String { itemType.arIcon(mandatory: isMandatory) }
}

#if DEBUG
extension MissionItem {
    /// SwiftUI #Preview용 데모 인스턴스 (quiz 타입, mandatory).
    static var preview: MissionItem {
        var it = MissionItem(missionID: "tutorial001", itemID: 1)
        it.itemType = .quiz
        it.mandatory = .mandatory
        it.latitude = 37.4850
        it.longitude = 126.8078
        it.rangeAR = 50
        it.showType = .all
        it.quizzes = [ItemQuiz(missionID: "tutorial001", itemID: 1, seq: 1,
                               quiz: "대한민국의 수도는?", answer: "서울", probability: 100)]
        return it
    }
}
#endif
