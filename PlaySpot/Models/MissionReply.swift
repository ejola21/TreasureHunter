// Models/MissionReply.swift
import Foundation

struct MissionReply: Codable, Identifiable {
    var id: UUID = UUID()
    var text: String

    enum CodingKeys: String, CodingKey {
        case text = "MReply"
    }

    init(text: String) {
        self.text = text
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
    }
}

#if DEBUG
extension MissionReply {
    static var preview: MissionReply { MissionReply(text: "재밌어요!") }
    static var previewList: [MissionReply] {
        ["재밌어요!", "어려웠지만 보람있음", "한 번 더 하고 싶어요"]
            .map(MissionReply.init(text:))
    }
}
#endif
