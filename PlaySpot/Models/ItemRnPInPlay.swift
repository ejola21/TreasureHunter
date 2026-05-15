// Models/ItemRnPInPlay.swift
import Foundation

struct ItemRnPInPlay: Codable {
    var missionID: String
    var playerID: String
    var itemType: String             // ItemType.rawValue
    var ableCnt: Int = 0
    var ableTime: Date?
    var acquiredTime: Date?
}
