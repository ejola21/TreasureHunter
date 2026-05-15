// Models/MissionItemInPlay.swift
import Foundation

struct MissionItemInPlay: Codable {
    var missionID: String
    var playerID: String
    var itemID: Int
    var endYN: String = "N"
    var failCnt: Int = 0
    var startTime: Date?
    var endTime: Date?
    var quizSeq: Int = 0

    var isAcquired: Bool { endYN == "Y" }
}
