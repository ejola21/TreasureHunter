// Network/LegacyRemoteDataSource.swift — 레거시 /playspot/J_MyList.php 호환 백엔드
//
// @deprecated 신규 코드는 [RestRemoteDataSource](RestRemoteDataSource.swift) 사용 권장.
// 이 구현은 AppConfig.backend == .legacy 인 경우 (Settings 토글) 에만 호출된다.
// 신규 서버가 안정화되면 별도 PR 로 제거 예정 — 의존하지 말 것.
import Foundation
import CoreLocation
import os

@available(*, deprecated, message: "신규 API 로 마이그레이션됨. AppConfig.backend = .rest 권장. 회귀용으로만 유지.")
struct LegacyRemoteDataSource: MissionDataSource {
    private let client = APIClient.shared
    private static let log = Logger(subsystem: "com.ejola.playspot", category: "LegacyDS")

    private static let playRecordFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f
    }()

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

    func recordPlayStart(missionID: String, playerID: String, startTime: Date, isVirtual: Bool) async throws -> Bool {
        let payload = legacyPlayPayload(missionID: missionID, playerID: playerID, time: startTime, isVirtual: isVirtual)
        let response = try await client.request(.playStart(data: payload))
        return Self.isSuccess(response)
    }

    func recordPlayFinish(missionID: String, playerID: String, startTime: Date, endTime: Date, isVirtual: Bool) async throws -> Bool {
        // 레거시 페이로드는 단일 time 필드 — endTime 만 전송 (start 시각은 서버 측 키 매칭).
        let payload = legacyPlayPayload(missionID: missionID, playerID: playerID, time: endTime, isVirtual: isVirtual)
        let response = try await client.request(.playFinish(data: payload))
        return Self.isSuccess(response)
    }

    func recordPlayFail(missionID: String, playerID: String, startTime: Date, endTime: Date, isVirtual: Bool) async throws -> Bool {
        let payload = legacyPlayPayload(missionID: missionID, playerID: playerID, time: endTime, isVirtual: isVirtual)
        let response = try await client.request(.playFail(data: payload))
        return Self.isSuccess(response)
    }

    // MARK: - User (legacy 미지원 — 빈 응답)

    func fetchUser(userID: String) async throws -> UserRes? { nil }
    func updateUser(userID: String, patch: UserPatchReq) async throws -> Bool { false }
    func changePassword(userID: String, oldPasswordMD5: String, newPasswordMD5: String) async throws -> Bool { false }

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

    private func legacyPlayPayload(missionID: String, playerID: String, time: Date, isVirtual: Bool) -> String {
        let t = Self.playRecordFormatter.string(from: time)
        return "\(missionID),\(playerID),\(t),\(isVirtual ? 1 : 0)"
    }

    /// 레거시 서버의 응답 컨벤션: "SUCCESS" / "OK" / "1" 등을 성공으로 간주.
    private static func isSuccess(_ response: String) -> Bool {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return ["SUCCESS", "OK", "1", "TRUE"].contains(trimmed)
    }
}
