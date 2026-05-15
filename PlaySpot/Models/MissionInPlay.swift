// Models/MissionInPlay.swift
import Foundation

struct MissionInPlay: Codable {
    var missionID: String
    var playerID: String
    var startYN: String = "N"        // "Y" / "N"
    var endYN: String = "N"
    var startTime: Date?
    var endTime: Date?

    var hasStarted: Bool { startYN == "Y" }
    var hasEnded: Bool { endYN == "Y" }
}
