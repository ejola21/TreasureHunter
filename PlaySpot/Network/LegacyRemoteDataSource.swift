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

    func login(email: String, password: String) async throws -> Bool {
        // Legacy 서버는 MD5 기대 — 내부에서 변환.
        let md5 = APIClient.md5(password)
        let response = try await client.request(.login(userID: email, passwordMD5: md5))
        return Self.isSuccess(response)
    }

    func register(email: String, password: String) async throws -> Bool {
        let md5 = APIClient.md5(password)
        let response = try await client.request(.register(userID: email, passwordMD5: md5))
        return Self.isSuccess(response)
    }

    // MARK: - 빌더 / 플레이 기록

    func uploadMission(missionJSON: String, itemsJSON: String, quizzesJSON: String) async throws -> Bool {
        let response = try await client.requestSync(.uploadMission(data: missionJSON, items: itemsJSON, quizzes: quizzesJSON))
        return Self.isSuccess(response)
    }

    /// 신규 BuilderMissionReq 를 받아 legacy `}}` 구분자 페이로드로 변환 후 TR=700 호출.
    /// MissionID 는 클라가 발급 — "<userID>_<yyyyMMddHHmmss>" 형식.
    /// 응답에 ID 가 없어서 발급된 ID 를 그대로 반환.
    func createMission(_ req: BuilderMissionReq) async throws -> String {
        let userID = await AuthSession.shared.storedCredentials()?.userID ?? "anonymous"
        let now = Date()
        let mID = legacyMissionID(userID: userID, date: now)
        let writeDate = Self.payloadDateFormatter.string(from: now)

        // mission row: 12 필드 (legacy MissionBuilderList.m:124-220 / plan_designer §1.3)
        let mFields: [String] = [
            mID,
            req.mission.Title,
            req.mission.Description,
            req.mission.Place,
            userID,                                        // Designer
            req.mission.LimitTime,                          // "HH:MM:SS"
            "\(req.mission.Status)",
            "",                                            // Quiz (미션 레벨 — 미사용)
            "",                                            // Answer (동일)
            "\(req.mission.Virtual)",
            req.mission.Lang,
            writeDate
        ]
        let missionPayload = mFields.map(Self.escapeLegacy).joined(separator: "}}")

        // missionItem rows: 16 필드 (** 행 구분)
        let itemRows: [String] = req.items.map { it in
            let f: [String] = [
                mID,
                "\(it.ItemID)",
                "\(it.Mandatory)",
                it.ItemType,
                "\(it.Latitude)",
                "\(it.Longitude)",
                "\(it.BlackCnt)",
                "\(it.BlackTime)",
                "\(it.RangeAR)",
                it.ShowType,
                "\(it.EffectiveRange)",
                "\(it.EffectiveTime)",
                "\(it.ItemGame)",
                it.Info,
                "\(it.RelationItemID)",
                writeDate
            ]
            return f.map(Self.escapeLegacy).joined(separator: "}}")
        }
        let itemsPayload = itemRows.joined(separator: "**")

        // itemQuiz rows: 6 필드
        let quizRows: [String] = req.quizzes.map { q in
            let f: [String] = [
                mID,
                "\(q.ItemID)",
                "\(q.Seq)",
                q.Quiz,
                q.Answer,
                "\(q.Probability)"
            ]
            return f.map(Self.escapeLegacy).joined(separator: "}}")
        }
        let quizzesPayload = quizRows.joined(separator: "**")

        let ok = try await uploadMission(missionJSON: missionPayload, itemsJSON: itemsPayload, quizzesJSON: quizzesPayload)
        if !ok {
            throw DataSourceError.decodingFailed
        }
        return mID
    }

    /// Legacy 백엔드는 PATCH 미지원 — 업로드를 다시 호출하면 신규 MissionID 가 발급되어 의미 불일치.
    /// 호출자가 backend=.rest 로 전환해야 함.
    func updateMission(missionID: String, _ req: BuilderMissionReq) async throws -> Bool {
        Self.log.warning("updateMission: legacy backend 미지원 — backend=.rest 로 전환 필요")
        throw DataSourceError.decodingFailed
    }

    func deleteMission(missionID: String) async throws -> Bool {
        Self.log.warning("deleteMission: legacy backend 미지원")
        throw DataSourceError.decodingFailed
    }

    /// Legacy 뱃지 업로드 — `/playspot/image_save.php` multipart `userfile` 필드.
    /// 응답: 파일명 평문 또는 빈 문자열.
    func uploadBadgeImage(pngData: Data) async throws -> String? {
        var req = URLRequest(url: APIEndpoint.imageUploadURL)
        req.httpMethod = "POST"
        req.timeoutInterval = 30
        let boundary = "----PlaySpot\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"userfile\"; filename=\"badge.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(pngData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return text.isEmpty ? nil : text
        } catch {
            Self.log.error("uploadBadgeImage(legacy): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// 신규 `/files/upload` 엔드포인트는 레거시 백엔드에 없음 — nil.
    func uploadFile(pngData: Data, fileName: String) async throws -> FileUploadRes? { nil }

    // MARK: - Legacy 페이로드 유틸

    private static let payloadDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let missionIDFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMddHHmmss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private func legacyMissionID(userID: String, date: Date) -> String {
        "\(userID)_\(Self.missionIDFormatter.string(from: date))"
    }

    /// `}}` / `**` 가 필드 안에 들어있으면 충돌 — 안전한 치환자로 변환.
    /// 레거시 빌더가 정확히 같은 방식으로 escape 하지는 않았지만, 데이터 손실 방지 차원.
    private static func escapeLegacy(_ s: String) -> String {
        s.replacingOccurrences(of: "}}", with: "}_}")
         .replacingOccurrences(of: "**", with: "*_*")
         .replacingOccurrences(of: "\n", with: " ")
         .replacingOccurrences(of: "\r", with: " ")
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
