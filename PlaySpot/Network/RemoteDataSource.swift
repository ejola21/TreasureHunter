// Network/RemoteDataSource.swift — 서버 (43.201.188.35:8080) 연동 구현
import Foundation
import CoreLocation
import os

struct RemoteDataSource: MissionDataSource {
    private let client = APIClient.shared
    private static let log = Logger(subsystem: "com.ejola.playspot", category: "RemoteDS")

    // MARK: - 미션 목록

    func fetchMissionList(cursor: Int, lang: String) async throws -> [Mission] {
        let response = try await client.request(.playingMissions(last: cursor, lang: lang))
        return decodeMissions(response, label: "TR=500")
    }

    func fetchPublishedMissions(cursor: Int, lang: String, latitude: Double, longitude: Double) async throws -> [Mission] {
        let response = try await client.request(.publishedMissions(last: cursor, lang: lang, lat: latitude, lon: longitude))
        return decodeMissions(response, label: "TR=501")
    }

    func fetchTutorialMissions(region: String) async throws -> [Mission] {
        let response = try await client.request(.tutorials(lang: region))
        return decodeMissions(response, label: "TR=503")
    }

    func fetchMyDesigned(userID: String) async throws -> [Mission] {
        // 신규 서버에서 TR=502 가 mission 배열을 반환 (TR=600 도 동일)
        let response = try await client.request(.myDesigns(last: 0, lang: ""))
        return decodeMissions(response, label: "TR=502")
    }

    func fetchMyPlayed(userID: String) async throws -> [Mission] {
        let response = try await client.request(.playedCount(userID: userID))
        return decodeMissions(response, label: "TR=601")
    }

    func fetchCurrentGames(userID: String) async throws -> [Mission] {
        let response = try await client.request(.currentGames(userID: userID))
        return decodeMissions(response, label: "TR=602")
    }

    // MARK: - 미션 상세 / 리뷰

    func fetchMissionDetail(missionID: String) async throws -> (Mission, [MissionItem], [ItemQuiz]) {
        let response = try await client.request(.missionDetail(missionID: missionID))
        guard let result = MissionDTO.parse(response: response) else {
            Self.log.error("TR=200 parse failed for \(missionID)")
            throw DataSourceError.decodingFailed
        }
        return result
    }

    func fetchReplies(missionID: String) async throws -> [MissionReply] {
        let response = try await client.request(.missionReviews(missionID: missionID))
        guard let data = response.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([MissionReply].self, from: data)) ?? []
    }

    func submitReview(missionID: String, userID: String, score: Float, reply: String) async throws -> Bool {
        let response = try await client.request(.submitReview(missionID: missionID, userID: userID, score: score, reply: reply))
        return Self.isSuccess(response)
    }

    // MARK: - 랭킹

    func fetchRanking(missionID: String) async throws -> [RankingEntry] {
        // 서버 응답: {ShortUser1, ShortRecord1, ShortUser2, ShortRecord2, ShortUser3, ShortRecord3}
        let response = try await client.request(.playRanking(missionID: missionID))
        guard let data = response.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return []
        }
        var entries: [RankingEntry] = []
        for i in 1...3 {
            let user = obj["ShortUser\(i)"] ?? ""
            let record = obj["ShortRecord\(i)"] ?? ""
            guard !user.isEmpty else { continue }
            entries.append(RankingEntry(id: i, userName: user, record: record))
        }
        return entries
    }

    // MARK: - 인증

    func login(email: String, passwordMD5: String) async throws -> Bool {
        let response = try await client.request(.login(userID: email, passwordMD5: passwordMD5))
        return Self.isSuccess(response)
    }

    func register(email: String, passwordMD5: String) async throws -> Bool {
        let response = try await client.request(.register(userID: email, passwordMD5: passwordMD5))
        return Self.isSuccess(response)
    }

    // MARK: - 빌더 / 플레이 기록

    func uploadMission(missionJSON: String, itemsJSON: String, quizzesJSON: String) async throws -> Bool {
        let response = try await client.requestSync(.uploadMission(data: missionJSON, items: itemsJSON, quizzes: quizzesJSON))
        return Self.isSuccess(response)
    }

    func recordPlayStart(playJSON: String) async throws -> Bool {
        let response = try await client.request(.playStart(data: playJSON))
        return Self.isSuccess(response)
    }

    func recordPlayFinish(playJSON: String) async throws -> Bool {
        let response = try await client.request(.playFinish(data: playJSON))
        return Self.isSuccess(response)
    }

    func recordPlayFail(playJSON: String) async throws -> Bool {
        let response = try await client.request(.playFail(data: playJSON))
        return Self.isSuccess(response)
    }

    // MARK: - 유틸

    private func decodeMissions(_ response: String, label: String) -> [Mission] {
        guard let data = response.data(using: .utf8) else { return [] }
        do {
            return try JSONDecoder().decode([Mission].self, from: data)
        } catch {
            Self.log.error("\(label) decode failed: \(error.localizedDescription)")
            return []
        }
    }

    /// 레거시 서버의 응답 컨벤션: "SUCCESS" / "OK" / "1" 등을 성공으로 간주.
    private static func isSuccess(_ response: String) -> Bool {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return ["SUCCESS", "OK", "1", "TRUE"].contains(trimmed)
    }
}
