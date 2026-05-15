// Network/MissionDataSource.swift
import Foundation
import CoreLocation

protocol MissionDataSource {
    func fetchMissionList(cursor: Int, lang: String) async throws -> [Mission]
    func fetchMissionDetail(missionID: String) async throws -> (Mission, [MissionItem], [ItemQuiz])
    func fetchReplies(missionID: String) async throws -> [MissionReply]
    func fetchTutorialMissions(region: String) async throws -> [Mission]
    func fetchMyDesigned(userID: String) async throws -> [Mission]
    func fetchMyPlayed(userID: String) async throws -> [Mission]
    func fetchCurrentGames(userID: String) async throws -> [Mission]
    func fetchRanking(missionID: String) async throws -> [RankingEntry]
    func login(email: String, passwordMD5: String) async throws -> Bool
}

enum DataSourceError: Error {
    case fileNotFound(String)
    case decodingFailed
}
