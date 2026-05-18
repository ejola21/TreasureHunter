// Models/Mission.swift
import Foundation
import CoreLocation

struct Mission: Identifiable, Codable, Hashable {
    static func == (lhs: Mission, rhs: Mission) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    var id: String                  // mID — "userID + timestamp" 형식
    var title: String               // mTitle
    var description: String         // mDescription
    var place: String               // mPlace
    var designer: String            // mDesigner
    var startTime: Date?            // mStartTime
    var runLimitTime: Date?         // mRunLimitTime
    var quiz: String                // mQuiz
    var answer: String              // mAnswer
    var status: MissionStatus       // mStatus (0~3)
    var items: [MissionItem]        // mItems
    var writeDate: Date             // mWriteDate
    var isVirtual: PlayMode         // mVirtual
    var seq: Int                    // mSeq — 아이템 ID 시퀀서
    var lang: String                // mLang

    // 서버에서 내려오는 추가 필드
    var playCnt: Int = 0
    var failCnt: Int = 0
    var recommendCnt: Int = 0
    var recommendAvg: Int = 0
    var shortUser1: String = ""
    var shortUser2: String = ""
    var shortUser3: String = ""
    var shortRecord1: String = ""
    var shortRecord2: String = ""
    var shortRecord3: String = ""

    enum CodingKeys: String, CodingKey {
        case id = "MissionID"
        case title = "Title"
        case description = "Description"
        case place = "Place"
        case designer = "Designer"
        case startTime = "StartTime"
        case runLimitTime = "RunLimitTime"
        case quiz = "Quiz"
        case answer = "Answer"
        case status = "Status"
        case items
        case writeDate = "WriteDate"
        case isVirtual = "Virtual"
        case seq
        case lang
        case playCnt = "PlayCnt"
        case failCnt = "FailCnt"
        case recommendCnt = "RecommendCnt"
        case recommendAvg = "RecommendAvg"
        case shortUser1 = "ShortUser1"
        case shortUser2 = "ShortUser2"
        case shortUser3 = "ShortUser3"
        case shortRecord1 = "ShortRecord1"
        case shortRecord2 = "ShortRecord2"
        case shortRecord3 = "ShortRecord3"
    }

    init(id: String, title: String = "", description: String = "", place: String = "",
         designer: String = "", startTime: Date? = nil, runLimitTime: Date? = nil,
         quiz: String = "", answer: String = "", status: MissionStatus = .designing,
         items: [MissionItem] = [], writeDate: Date = Date(), isVirtual: PlayMode = .real,
         seq: Int = 0, lang: String = "") {
        self.id = id
        self.title = title
        self.description = description
        self.place = place
        self.designer = designer
        self.startTime = startTime
        self.runLimitTime = runLimitTime
        self.quiz = quiz
        self.answer = answer
        self.status = status
        self.items = items
        self.writeDate = writeDate
        self.isVirtual = isVirtual
        self.seq = seq
        self.lang = lang
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    /// 서버는 ISO8601("...+00:00"), 단순 ISO("yyyy-MM-dd'T'HH:mm:ss"),
    /// 또는 "yyyy-MM-dd"(레거시/Mock) 모두 사용. 세 포맷 모두 수용.
    private static func parseDate(_ str: String) -> Date? {
        iso8601Formatter.date(from: str)
            ?? dateTimeFormatter.date(from: str)
            ?? dateFormatter.date(from: str)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        place = try container.decodeIfPresent(String.self, forKey: .place) ?? ""
        designer = try container.decodeIfPresent(String.self, forKey: .designer) ?? ""

        // Date 필드 — 서버/Mock 모두 문자열로 올 수 있음
        if let str = try? container.decodeIfPresent(String.self, forKey: .startTime) {
            startTime = Self.parseDate(str)
        } else {
            startTime = try? container.decodeIfPresent(Date.self, forKey: .startTime)
        }

        // RunLimitTime: 신규 서버는 Int 초 (900 등), 레거시 mock 은 "HH:mm:ss" 문자열.
        // Date? 타입 유지 — 정수는 일단 무시(별도 정수 필드 도입 시 갱신).
        if let str = try? container.decodeIfPresent(String.self, forKey: .runLimitTime) {
            runLimitTime = Self.parseDate(str)
        } else {
            runLimitTime = try? container.decodeIfPresent(Date.self, forKey: .runLimitTime)
        }

        quiz = try container.decodeIfPresent(String.self, forKey: .quiz) ?? ""
        answer = try container.decodeIfPresent(String.self, forKey: .answer) ?? ""
        status = try container.decodeIfPresent(MissionStatus.self, forKey: .status) ?? .designing
        items = try container.decodeIfPresent([MissionItem].self, forKey: .items) ?? []

        if let str = try? container.decodeIfPresent(String.self, forKey: .writeDate) {
            writeDate = Self.parseDate(str) ?? Date()
        } else {
            writeDate = (try? container.decodeIfPresent(Date.self, forKey: .writeDate)) ?? Date()
        }

        // Virtual: 신규 서버 TR=500은 Bool, TR=200은 Int — 둘 다 수용
        if let intVal = try? container.decodeIfPresent(Int.self, forKey: .isVirtual) {
            isVirtual = PlayMode(rawValue: intVal) ?? .real
        } else if let boolVal = try? container.decodeIfPresent(Bool.self, forKey: .isVirtual) {
            isVirtual = boolVal ? .virtual : .real
        } else {
            isVirtual = .real
        }
        seq = try container.decodeIfPresent(Int.self, forKey: .seq) ?? 0
        lang = try container.decodeIfPresent(String.self, forKey: .lang) ?? ""
        playCnt = try container.decodeIfPresent(Int.self, forKey: .playCnt) ?? 0
        failCnt = try container.decodeIfPresent(Int.self, forKey: .failCnt) ?? 0
        recommendCnt = try container.decodeIfPresent(Int.self, forKey: .recommendCnt) ?? 0
        recommendAvg = try container.decodeIfPresent(Int.self, forKey: .recommendAvg) ?? 0
        shortUser1 = try container.decodeIfPresent(String.self, forKey: .shortUser1) ?? ""
        shortUser2 = try container.decodeIfPresent(String.self, forKey: .shortUser2) ?? ""
        shortUser3 = try container.decodeIfPresent(String.self, forKey: .shortUser3) ?? ""
        shortRecord1 = try container.decodeIfPresent(String.self, forKey: .shortRecord1) ?? ""
        shortRecord2 = try container.decodeIfPresent(String.self, forKey: .shortRecord2) ?? ""
        shortRecord3 = try container.decodeIfPresent(String.self, forKey: .shortRecord3) ?? ""
    }

    /// 기존 Mission.m의 addMissionItem 대체
    mutating func addItem() -> MissionItem {
        seq += 1
        let item = MissionItem(missionID: id, itemID: seq)
        items.append(item)
        return item
    }
}

#if DEBUG
extension Mission {
    /// SwiftUI #Preview용 데모 인스턴스.
    static var preview: Mission {
        var m = Mission(
            id: "tutorial001",
            title: "튜토리얼: 기본 미션",
            description: "Play Spot의 기본 사용법을 배우는 튜토리얼",
            place: "튜토리얼 광장",
            designer: "playspot",
            status: .serverUpload,
            items: [.preview],
            isVirtual: .virtual
        )
        m.playCnt = 15
        m.recommendAvg = 4
        return m
    }
}
#endif
