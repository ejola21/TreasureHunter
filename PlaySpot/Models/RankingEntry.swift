// Models/RankingEntry.swift
import Foundation

struct RankingEntry: Codable, Identifiable {
    var id: Int
    var userName: String
    var record: String
}
