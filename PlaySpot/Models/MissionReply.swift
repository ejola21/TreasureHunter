// Models/MissionReply.swift
import Foundation

struct MissionReply: Codable, Identifiable {
    var id: UUID = UUID()
    var text: String
    var score: Double?       // 1.0 ~ 5.0 (서버 ReplyRes.Score)
    var nickname: String?    // 작성자 닉네임 (서버 ReplyRes.Nickname)
    var writeDate: Date?     // 작성 시각 (서버 ReplyRes.WriteDate, "yyyy-MM-dd HH:mm:ss")

    enum CodingKeys: String, CodingKey {
        case text = "MReply"
        case score = "Score"
        case nickname = "Nickname"
        case writeDate = "WriteDate"
    }

    init(text: String, score: Double? = nil, nickname: String? = nil, writeDate: Date? = nil) {
        self.text = text
        self.score = score
        self.nickname = nickname
        self.writeDate = writeDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        score = try container.decodeIfPresent(Double.self, forKey: .score)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        if let s = try container.decodeIfPresent(String.self, forKey: .writeDate), !s.isEmpty {
            writeDate = Self.parseDate(s)
        }
    }

    /// 서버 포맷 후보 — ISO 8601(밀리초+tz) / ISO 8601(plain) / "yyyy-MM-dd HH:mm:ss".
    private static func parseDate(_ s: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: s) { return d }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: s) { return d }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f.date(from: s)
    }
}

#if DEBUG
extension MissionReply {
    static var preview: MissionReply { MissionReply(text: "재밌어요!", score: 4.0, nickname: "User1", writeDate: Date()) }
    static var previewList: [MissionReply] {
        [
            MissionReply(text: "재밌어요!", score: 5.0, nickname: "민지", writeDate: Date()),
            MissionReply(text: "어려웠지만 보람있음", score: 4.0, nickname: "현우", writeDate: Date().addingTimeInterval(-3600)),
            MissionReply(text: "한 번 더 하고 싶어요", score: 4.5, nickname: "지수", writeDate: Date().addingTimeInterval(-86400)),
        ]
    }
}
#endif
