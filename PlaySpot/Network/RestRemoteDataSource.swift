// Network/RestRemoteDataSource.swift — 신규 /api/v1/** REST 백엔드
// Phase 3-4 에서 메서드별로 실제 호출 구현. 현재는 fetch/플레이 기록만 구현.
import Foundation
import os

struct RestRemoteDataSource: MissionDataSource {
    private let client = RestAPIClient.shared
    private static let log = Logger(subsystem: "com.ejola.playspot", category: "RestDS")

    // 신규 API 가 "yyyy-MM-dd HH:mm:ss" (KST) 를 권장 (api_client.md §0).
    private static let kstFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f
    }()

    // MARK: - 미션 목록

    func fetchMissionList(cursor: Int, lang: String) async throws -> [Mission] {
        do {
            return try await client.get("/api/v1/missions", query: ["page": "\(cursor)"])
        } catch {
            Self.log.error("fetchMissionList: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func fetchPublishedMissions(cursor: Int, lang: String, latitude: Double, longitude: Double) async throws -> [Mission] {
        do {
            return try await client.get("/api/v1/missions/nearby", query: [
                "page": "\(cursor)",
                "latitude": "\(latitude)",
                "longitude": "\(longitude)"
            ])
        } catch {
            Self.log.error("fetchPublishedMissions: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func fetchTutorialMissions(region: String) async throws -> [Mission] {
        do {
            return try await client.get("/api/v1/missions/tutorial", query: ["lang": region])
        } catch {
            Self.log.error("fetchTutorialMissions: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func fetchMyDesigned(userID: String) async throws -> [Mission] {
        do {
            return try await client.get("/api/v1/users/\(urlEncode(userID))/missions/designed")
        } catch {
            Self.log.error("fetchMyDesigned: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func fetchMyPlayed(userID: String) async throws -> [Mission] {
        do {
            return try await client.get("/api/v1/users/\(urlEncode(userID))/missions/played")
        } catch {
            Self.log.error("fetchMyPlayed: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func fetchCurrentGames(userID: String) async throws -> [Mission] {
        do {
            return try await client.get("/api/v1/users/\(urlEncode(userID))/missions/playing")
        } catch {
            Self.log.error("fetchCurrentGames: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    // MARK: - 미션 상세 / 리뷰

    func fetchMissionDetail(missionID: String) async throws -> (Mission, [MissionItem], [ItemQuiz]) {
        let res: MissionDetailRes = try await client.get("/api/v1/missions/\(urlEncode(missionID))")
        // 신규 API quiz 항목은 ItemID 포함 — 정상 그룹핑.
        // 한 Quiz/Quiz20 아이템에 여러 variant(Seq=1,2,...) 또는 여러 Quiz 아이템 모두 지원.
        let quizzes = res.quizzes.map { q in
            ItemQuiz(missionID: missionID, itemID: q.ItemID, seq: q.Seq,
                     quiz: q.Quiz, answer: q.Answer, probability: q.Probability ?? 100)
        }
        return (res.mission, res.items, quizzes)
    }

    func fetchReplies(missionID: String) async throws -> [MissionReply] {
        do {
            let rows: [ReplyRes] = try await client.get("/api/v1/missions/\(urlEncode(missionID))/replies")
            return rows.compactMap { r in
                guard let text = r.MReply, !text.isEmpty else { return nil }
                let date = (r.WriteDate.flatMap { Self.parseReplyDate($0) })
                return MissionReply(text: text, score: r.Score, nickname: r.Nickname, writeDate: date)
            }
        } catch {
            Self.log.error("fetchReplies: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    /// 서버 `WriteDate` 포맷 — 현재 `"2026-05-18T09:55:40.000+00:00"` (ISO 8601 + 밀리초 + tz).
    /// `"yyyy-MM-dd HH:mm:ss"` 도 대비해 fallback 체인 구성.
    private static func parseReplyDate(_ s: String) -> Date? {
        // 1) ISO 8601 + fractional seconds + tz
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: s) { return d }
        // 2) ISO 8601 without fractional
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: s) { return d }
        // 3) "yyyy-MM-dd HH:mm:ss" KST
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f.date(from: s)
    }

    func submitReview(missionID: String, userID: String, score: Float, reply: String) async throws -> Bool {
        let body = ReplyReq(userId: userID, score: score, reply: reply)
        do {
            try await client.send(.POST, "/api/v1/missions/\(urlEncode(missionID))/replies", body: body)
            return true
        } catch { return false }
    }

    // MARK: - 랭킹

    func fetchRanking(missionID: String) async throws -> [RankingEntry] {
        do {
            let r: RankingRes = try await client.get("/api/v1/missions/\(urlEncode(missionID))/ranking")
            var entries: [RankingEntry] = []
            let pairs = [
                (1, r.ShortUser1, r.ShortRecord1),
                (2, r.ShortUser2, r.ShortRecord2),
                (3, r.ShortUser3, r.ShortRecord3),
            ]
            for (idx, user, record) in pairs {
                guard let u = user, !u.isEmpty else { continue }
                entries.append(RankingEntry(id: idx, userName: u, record: record ?? ""))
            }
            return entries
        } catch {
            Self.log.error("fetchRanking: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    // MARK: - 인증

    func login(email: String, password: String) async throws -> Bool {
        // password 는 평문 — 서버가 해싱 책임. HTTPS 가 전송 보호.
        do {
            let res: LoginRes = try await client.send(.POST, "/api/v1/auth/login",
                                                      body: LoginReq(userId: email, password: password))
            await AuthSession.shared.setToken(res.token)
            await AuthSession.shared.saveCredentials(userID: email, password: password)
            return true
        } catch {
            Self.log.error("login: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func register(email: String, password: String) async throws -> Bool {
        do {
            try await client.send(.POST, "/api/v1/auth/register",
                                  body: RegisterReq(userId: email, password: password))
            return true
        } catch let APIError.server(code, _, _, _) where code == "DUPLICATE_DATA" {
            // 이미 가입된 사용자 — register 실패지만 login 으로 진행 가능.
            return true
        } catch {
            Self.log.error("register: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    // MARK: - 빌더

    /// @deprecated — 3-string 페이로드는 legacy 호환용. 신규 코드는 createMission 사용.
    func uploadMission(missionJSON: String, itemsJSON: String, quizzesJSON: String) async throws -> Bool {
        Self.log.warning("uploadMission: legacy 3-string payload not supported on REST backend — use createMission(_:) instead")
        return false
    }

    /// `POST /api/v1/missions` (plan_designer.md §5.2).
    /// 서버 미준비 시 404/501 발생 → 호출자가 backend 토글(.legacy) 로 폴백 권장.
    func createMission(_ req: BuilderMissionReq) async throws -> String {
        do {
            let res: BuilderMissionCreatedRes = try await client.send(.POST, "/api/v1/missions", body: req)
            return res.missionId
        } catch {
            Self.log.error("createMission: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    /// `PATCH /api/v1/missions/{id}` — 전체 교체.
    /// 실패 시 `APIError` rethrow — 호출자는 `error.isNotFound` / `isForbidden` / `isValidationError` 로 분기.
    func updateMission(missionID: String, _ req: BuilderMissionReq) async throws -> Bool {
        do {
            try await client.send(.PATCH, "/api/v1/missions/\(urlEncode(missionID))", body: req)
            return true
        } catch {
            Self.log.error("updateMission: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    /// `DELETE /api/v1/missions/{id}`.
    /// 실패 시 `APIError` rethrow — `isNotFound` (이미 삭제됨) / `isForbidden` / `isNotDeletable` (Status=2) 분기.
    func deleteMission(missionID: String) async throws -> Bool {
        do {
            try await client.send(.DELETE, "/api/v1/missions/\(urlEncode(missionID))")
            return true
        } catch {
            Self.log.error("deleteMission: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    /// `POST /api/v1/badges` (multipart `file`).
    /// 응답 fileName 을 받아서 호출자가 createMission/updateMission payload 의 `BadgeImageName` 에 사용.
    /// 실패 시 nil 로 삼키지 않고 throw — 호출자가 PATCH 단계 진입 전에 차단할 수 있도록.
    func uploadBadgeImage(pngData: Data) async throws -> String? {
        do {
            let res: BadgeUploadRes = try await client.uploadFile(
                "/api/v1/badges",
                fieldName: "file",
                fileName: "badge-\(UUID().uuidString.prefix(8)).png",
                mimeType: "image/png",
                data: pngData
            )
            return res.fileName
        } catch {
            Self.log.error("uploadBadgeImage: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    /// `POST /api/v1/files/upload` (multipart `file`) — 일반 파일 업로드.
    /// 파라미터명 `pngData` 는 historical — 실제로는 PNG/JPEG 등 어떤 바이너리든 가능.
    /// MIME 타입은 fileName 확장자에서 추론. 실패 시 throw.
    func uploadFile(pngData: Data, fileName: String) async throws -> FileUploadRes? {
        let mime: String
        let lower = fileName.lowercased()
        if lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") { mime = "image/jpeg" }
        else if lower.hasSuffix(".webp") { mime = "image/webp" }
        else { mime = "image/png" }   // 기본 + .png
        do {
            let res: FileUploadRes = try await client.uploadFile(
                "/api/v1/files/upload",
                fieldName: "file",
                fileName: fileName,
                mimeType: mime,
                data: pngData
            )
            return res
        } catch {
            Self.log.error("uploadFile: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    // MARK: - 플레이 기록

    func recordPlayStart(missionID: String, playerID: String, startTime: Date, isVirtual: Bool) async throws -> Bool {
        let body = PlayReq(playerId: playerID,
                           startTime: Self.kstFormatter.string(from: startTime),
                           endTime: nil,
                           isVirtual: isVirtual ? 1 : 0)
        do {
            let _: PlayResultRes = try await client.send(.POST, "/api/v1/missions/\(urlEncode(missionID))/plays/start", body: body)
            return true
        } catch {
            // 200 + {result:SUCCESS} 가 아닌 204 응답 가능성도 흡수.
            do {
                try await client.send(.POST, "/api/v1/missions/\(urlEncode(missionID))/plays/start", body: body)
                return true
            } catch {
                Self.log.error("recordPlayStart: \(error.localizedDescription, privacy: .public)")
                return false
            }
        }
    }

    func recordPlayFinish(missionID: String, playerID: String, startTime: Date, endTime: Date, isVirtual: Bool) async throws -> Bool {
        let body = PlayReq(playerId: playerID,
                           startTime: Self.kstFormatter.string(from: startTime),
                           endTime: Self.kstFormatter.string(from: endTime),
                           isVirtual: isVirtual ? 1 : 0)
        do {
            try await client.send(.POST, "/api/v1/missions/\(urlEncode(missionID))/plays/finish", body: body)
            return true
        } catch {
            Self.log.error("recordPlayFinish: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func recordPlayFail(missionID: String, playerID: String, startTime: Date, endTime: Date, isVirtual: Bool) async throws -> Bool {
        let body = PlayReq(playerId: playerID,
                           startTime: Self.kstFormatter.string(from: startTime),
                           endTime: Self.kstFormatter.string(from: endTime),
                           isVirtual: isVirtual ? 1 : 0)
        do {
            try await client.send(.POST, "/api/v1/missions/\(urlEncode(missionID))/plays/fail", body: body)
            return true
        } catch {
            Self.log.error("recordPlayFail: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    // MARK: - User

    func fetchUser(userID: String) async throws -> UserRes? {
        do {
            return try await client.get("/api/v1/users/\(urlEncode(userID))")
        } catch {
            Self.log.error("fetchUser: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func updateUser(userID: String, patch: UserPatchReq) async throws -> Bool {
        do {
            try await client.send(.PATCH, "/api/v1/users/\(urlEncode(userID))", body: patch)
            return true
        } catch {
            Self.log.error("updateUser: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func changePassword(userID: String, oldPasswordMD5: String, newPasswordMD5: String) async throws -> Bool {
        let body = PasswordChangeReq(oldPassword: oldPasswordMD5, newPassword: newPasswordMD5)
        do {
            try await client.send(.PATCH, "/api/v1/users/\(urlEncode(userID))/password", body: body)
            return true
        } catch {
            Self.log.error("changePassword: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    // MARK: - utility

    private func urlEncode(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? s
    }
}
