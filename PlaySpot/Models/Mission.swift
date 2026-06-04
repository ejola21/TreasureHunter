// Models/Mission.swift
import Foundation
import CoreLocation

struct Mission: Identifiable, Codable, Hashable {
    /// SwiftUI ForEach 가 row body 를 갱신하려면 `==` 가 콘텐츠 변화까지 반영해야 한다.
    /// id 만 비교하면 제목 수정 후 목록이 갱신되지 않음 (List 행이 캐시 재사용).
    /// row 에 표시되는 필드 + 빌더 편집 대상 메타를 모두 비교한다.
    static func == (lhs: Mission, rhs: Mission) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description &&
        lhs.place == rhs.place &&
        lhs.status == rhs.status &&
        lhs.limitTime == rhs.limitTime &&
        lhs.isVirtual == rhs.isVirtual &&
        lhs.lang == rhs.lang &&
        lhs.items.count == rhs.items.count &&
        lhs.writeDate == rhs.writeDate
    }
    /// NavigationLink(value:) / Set 용. `==` 의 모든 비교 필드를 hash 에 넣을 필요는 없고
    /// 충돌이 적은 id 만으로 충분 (Hashable 계약: a==b → hash(a)==hash(b) 는 id 동일 시 성립).
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    var id: String                  // mID — "userID + timestamp" 형식
    var title: String               // mTitle
    var description: String         // mDescription
    var place: String               // mPlace
    var designer: String            // mDesigner
    var startTime: Date?            // mStartTime
    /// 미션 제한 시간 (초). 0 = 무제한.
    /// 서버 필드 `LimitTime` 은 "HH:MM:SS" 문자열 — decode/encode 시 변환.
    var limitTime: Int              // LimitTime
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
    /// 평균 별점. 서버는 `Double` 로 응답 (예: 4.5). Int 로 받으면 분수 값에서 JSON 파싱 자체가 실패해
    /// Mission 디코드 전체가 무너지므로 반드시 Double 유지.
    var recommendAvg: Double = 0
    var shortUser1: String = ""
    var shortUser2: String = ""
    var shortUser3: String = ""
    var shortRecord1: String = ""
    var shortRecord2: String = ""
    var shortRecord3: String = ""
    /// `POST /api/v1/badges?missionId=...` 응답의 fileName. nil 이면 뱃지 미설정.
    /// 다운로드 URL = `\(APIEndpoint.badgeBaseURL)\(badgeImageName)` (단, 현재 화면 노출은 보류).
    var badgeImageName: String?

    enum CodingKeys: String, CodingKey {
        case id = "MissionID"
        case title = "Title"
        case description = "Description"
        case place = "Place"
        case designer = "Designer"
        case startTime = "StartTime"
        case limitTime = "LimitTime"
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
        case badgeImageName = "BadgeImageName"
    }

    init(id: String, title: String = "", description: String = "", place: String = "",
         designer: String = "", startTime: Date? = nil, limitTime: Int = 0,
         quiz: String = "", answer: String = "", status: MissionStatus = .unpublished,
         items: [MissionItem] = [], writeDate: Date = Date(), isVirtual: PlayMode = .real,
         seq: Int = 0, lang: String = "") {
        self.id = id
        self.title = title
        self.description = description
        self.place = place
        self.designer = designer
        self.startTime = startTime
        self.limitTime = limitTime
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

        // LimitTime: 서버는 "HH:MM:SS" 문자열 (예: "00:09:00"=540초, "00:00:00"=무제한).
        // 일부 경로는 Int 초로 줄 수 있어 둘 다 수용.
        if let str = try? container.decodeIfPresent(String.self, forKey: .limitTime) {
            limitTime = TimerFormatter.parseHMS(str)
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .limitTime) {
            limitTime = max(0, intVal)
        } else {
            limitTime = 0
        }

        quiz = try container.decodeIfPresent(String.self, forKey: .quiz) ?? ""
        answer = try container.decodeIfPresent(String.self, forKey: .answer) ?? ""
        // Status: 신규 서버 Int(0/1/2), 레거시 mock 은 문자열.
        // 0=unpublished(편집), 1=testing(테스트 완료), 2=published(공개).
        // 알 수 없는 값(legacy 3 등) → .unpublished 로 흡수.
        if let intVal = try? container.decodeIfPresent(Int.self, forKey: .status) {
            status = MissionStatus(rawValue: intVal) ?? .unpublished
        } else if let strVal = try? container.decodeIfPresent(String.self, forKey: .status),
                  let intVal = Int(strVal) {
            status = MissionStatus(rawValue: intVal) ?? .unpublished
        } else {
            status = .unpublished
        }
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
        recommendAvg = try container.decodeIfPresent(Double.self, forKey: .recommendAvg) ?? 0
        shortUser1 = try container.decodeIfPresent(String.self, forKey: .shortUser1) ?? ""
        shortUser2 = try container.decodeIfPresent(String.self, forKey: .shortUser2) ?? ""
        shortUser3 = try container.decodeIfPresent(String.self, forKey: .shortUser3) ?? ""
        shortRecord1 = try container.decodeIfPresent(String.self, forKey: .shortRecord1) ?? ""
        shortRecord2 = try container.decodeIfPresent(String.self, forKey: .shortRecord2) ?? ""
        shortRecord3 = try container.decodeIfPresent(String.self, forKey: .shortRecord3) ?? ""
        badgeImageName = try container.decodeIfPresent(String.self, forKey: .badgeImageName)
    }

    /// 기존 Mission.m의 addMissionItem 대체
    mutating func addItem() -> MissionItem {
        seq += 1
        let item = MissionItem(missionID: id, itemID: seq)
        items.append(item)
        return item
    }
}

extension Mission {
    /// 뱃지 이미지 다운로드 URL. `badgeImageName` 이 비어 있으면 nil → placeholder.
    /// - 신규 흐름: `POST /api/v1/files/upload` 응답의 fileUrl 을 그대로 저장 (`https://…/file/X.png`).
    /// - 레거시 데이터: 짧은 fileName (`badge-X.png`) — `badgeBaseURL` 과 합쳐 URL 조립.
    /// http(s) 스킴이면 그대로, 아니면 prefix.
    /// 신규 흐름: `POST /api/v1/files/upload` 응답의 `fileUrl` 전체 https URL.
    /// 절대 경로: 서버가 `/badge/...` 형태로 응답하는 경우 host 만 prefix.
    /// 레거시 fileName: 짧은 `badge-X.png` — `badgeBaseURL` 과 결합.
    /// Flutter rest_api_client.dart 와 동등 (3-format 분기).
    var badgeImageURL: URL? {
        guard let name = badgeImageName, !name.isEmpty else { return nil }
        if name.hasPrefix("http://") || name.hasPrefix("https://") {
            return URL(string: name)
        }
        if name.hasPrefix("/") {
            return URL(string: "\(APIEndpoint.scheme)://\(APIEndpoint.serverHost)\(name)")
        }
        return URL(string: "\(APIEndpoint.badgeBaseURL)\(name)")
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
            status: .published,
            items: [.preview],
            isVirtual: .virtual
        )
        m.playCnt = 15
        m.recommendAvg = 4
        return m
    }
}
#endif
