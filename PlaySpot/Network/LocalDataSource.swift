// Network/LocalDataSource.swift — 로컬 JSON 파일 기반 Mock 구현
import Foundation
import CoreLocation

struct LocalDataSource: MissionDataSource {

    func fetchMissionList(cursor: Int, lang: String) async throws -> [Mission] {
        try loadJSON("mock_mission_list")
    }

    func fetchPublishedMissions(cursor: Int, lang: String, latitude: Double, longitude: Double) async throws -> [Mission] {
        try loadJSON("mock_mission_list")
    }

    func submitReview(missionID: String, userID: String, score: Float, reply: String) async throws -> Bool {
        true
    }

    func register(email: String, passwordMD5: String) async throws -> Bool {
        true
    }

    func uploadMission(missionJSON: String, itemsJSON: String, quizzesJSON: String) async throws -> Bool {
        true
    }

    func recordPlayStart(playJSON: String) async throws -> Bool { true }
    func recordPlayFinish(playJSON: String) async throws -> Bool { true }
    func recordPlayFail(playJSON: String) async throws -> Bool { true }

    func fetchMissionDetail(missionID: String) async throws -> (Mission, [MissionItem], [ItemQuiz]) {
        // 미션 ID별 파일이 있으면 사용, 없으면 기본 파일 사용
        let mission: Mission
        if let specific: Mission = try? loadJSON("mock_mission_\(missionID)") {
            mission = specific
        } else if let first = (try loadJSON("mock_mission_list") as [Mission]).first {
            mission = first
        } else {
            mission = Mission(id: missionID)
        }
        let items: [MissionItem] = (try? loadJSON("mock_items_\(missionID)")) ?? []
        let quizzes: [ItemQuiz] = (try? loadJSON("mock_quizzes_\(missionID)")) ?? []
        return (mission, items, quizzes)
    }

    func fetchReplies(missionID: String) async throws -> [MissionReply] {
        try loadJSON("mock_replies")
    }

    func fetchTutorialMissions(region: String) async throws -> [Mission] {
        try loadJSON("mock_tutorials")
    }

    func fetchMyDesigned(userID: String) async throws -> [Mission] {
        try loadJSON("mock_my_designed")
    }

    func fetchMyPlayed(userID: String) async throws -> [Mission] {
        try loadJSON("mock_my_played")
    }

    func fetchCurrentGames(userID: String) async throws -> [Mission] {
        try loadJSON("mock_current_games")
    }

    func fetchRanking(missionID: String) async throws -> [RankingEntry] {
        try loadJSON("mock_ranking")
    }

    func login(email: String, passwordMD5: String) async throws -> Bool {
        true // Mock에서는 항상 로그인 성공
    }

    // MARK: - JSON 로더
    private func loadJSON<T: Decodable>(_ name: String) throws -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "MockData") else {
            throw DataSourceError.fileNotFound(name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
