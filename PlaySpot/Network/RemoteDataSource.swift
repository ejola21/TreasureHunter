// Network/RemoteDataSource.swift — 서버 준비 후 전환
import Foundation
import CoreLocation

struct RemoteDataSource: MissionDataSource {
    private let client = APIClient.shared

    func fetchMissionList(cursor: Int, lang: String) async throws -> [Mission] {
        let response = try await client.request(.playingMissions(last: cursor, lang: lang))
        return try JSONDecoder().decode([Mission].self, from: Data(response.utf8))
    }

    func fetchMissionDetail(missionID: String) async throws -> (Mission, [MissionItem], [ItemQuiz]) {
        let response = try await client.request(.missionDetail(missionID: missionID))
        guard let result = MissionDTO.parse(response: response) else {
            throw DataSourceError.decodingFailed
        }
        return result
    }

    func fetchReplies(missionID: String) async throws -> [MissionReply] {
        let response = try await client.request(.missionReviews(missionID: missionID))
        return try JSONDecoder().decode([MissionReply].self, from: Data(response.utf8))
    }

    func fetchTutorialMissions(region: String) async throws -> [Mission] {
        let response = try await client.request(.tutorials(lang: region))
        return try JSONDecoder().decode([Mission].self, from: Data(response.utf8))
    }

    func fetchMyDesigned(userID: String) async throws -> [Mission] {
        let response = try await client.request(.designedCount(userID: userID))
        return try JSONDecoder().decode([Mission].self, from: Data(response.utf8))
    }

    func fetchMyPlayed(userID: String) async throws -> [Mission] {
        let response = try await client.request(.playedCount(userID: userID))
        return try JSONDecoder().decode([Mission].self, from: Data(response.utf8))
    }

    func fetchCurrentGames(userID: String) async throws -> [Mission] {
        let response = try await client.request(.currentGames(userID: userID))
        return try JSONDecoder().decode([Mission].self, from: Data(response.utf8))
    }

    func fetchRanking(missionID: String) async throws -> [RankingEntry] {
        let response = try await client.request(.playRanking(missionID: missionID))
        return try JSONDecoder().decode([RankingEntry].self, from: Data(response.utf8))
    }

    func login(email: String, passwordMD5: String) async throws -> Bool {
        let response = try await client.request(.login(userID: email, passwordMD5: passwordMD5))
        return response.trimmingCharacters(in: .whitespacesAndNewlines) == "SUCCESS"
    }
}
