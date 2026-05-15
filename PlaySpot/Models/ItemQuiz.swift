// Models/ItemQuiz.swift
import Foundation

struct ItemQuiz: Identifiable, Codable {
    var id: String { "\(missionID)_\(itemID)_\(seq)" }
    var missionID: String
    var itemID: Int
    var seq: Int
    var quiz: String
    var answer: String
    var probability: Int = 0

    enum CodingKeys: String, CodingKey {
        case missionID = "MissionID"
        case itemID = "ItemID"
        case seq = "Seq"
        case quiz = "Quiz"
        case answer = "Answer"
        case probability = "Probability"
    }

    init(missionID: String = "", itemID: Int = 0, seq: Int = 0,
         quiz: String = "", answer: String = "", probability: Int = 0) {
        self.missionID = missionID
        self.itemID = itemID
        self.seq = seq
        self.quiz = quiz
        self.answer = answer
        self.probability = probability
    }
}
