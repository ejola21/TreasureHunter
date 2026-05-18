// Network/RestAPIDTO.swift — /api/v1/** 요청/응답 DTO
import Foundation

// MARK: - Auth

struct LoginReq: Encodable {
    let userId: String
    let password: String   // MD5
}

struct LoginRes: Decodable {
    let token: String
}

struct RegisterReq: Encodable {
    let userId: String
    let password: String   // MD5
}

// MARK: - Mission detail

/// `GET /api/v1/missions/{missionId}` 응답.
/// `mission` / `items` / `quizzes` 3-part. 기존 모델(Mission/MissionItem/ItemQuiz) 의
/// CodingKeys 가 PascalCase 그대로라 디코딩 호환됨.
struct MissionDetailRes: Decodable {
    let mission: Mission
    let items: [MissionItem]
    let quizzes: [MissionDetailQuiz]
}

/// 신규 API 의 quizzes 항목 — MissionID 는 path 에서 알 수 있으므로 생략, ItemID 는 포함.
/// 서버 응답 예: `{"ItemID":3, "Seq":1, "Quiz":"...", "Answer":"...", "Probability":100}`
struct MissionDetailQuiz: Decodable {
    let ItemID: Int
    let Seq: Int
    let Quiz: String
    let Answer: String
    let Probability: Int?
}

// MARK: - Replies (댓글/평점)

struct ReplyRes: Decodable {
    let UserID: String?
    let Nickname: String?
    let Score: Double?
    let MReply: String?
}

struct ReplyReq: Encodable {
    let userId: String
    let score: Float?
    let reply: String?
}

// MARK: - Play 기록

struct PlayReq: Encodable {
    let playerId: String
    let startTime: String       // "yyyy-MM-dd HH:mm:ss" KST
    let endTime: String?        // finish/fail 만 사용
    let isVirtual: Int          // 0/1
}

struct PlayResultRes: Decodable {
    let result: String?
}

// MARK: - Ranking

struct RankingRes: Decodable {
    let ShortUser1: String?
    let ShortRecord1: String?
    let ShortUser2: String?
    let ShortRecord2: String?
    let ShortUser3: String?
    let ShortRecord3: String?
}

// MARK: - User

struct UserRes: Decodable {
    let userId: String
    let email: String?
    let phone: String?
    let nickname: String?
    let isGuest: Int?
    let solutionCount: Int?
    let timeAddCount: Int?
    let lastLoginAt: String?
}

struct UserPatchReq: Encodable {
    var nickname: String? = nil
    var phone: String? = nil
    var email: String? = nil
    var password: String? = nil    // MD5 (선택)
}

struct PasswordChangeReq: Encodable {
    let oldPassword: String   // MD5
    let newPassword: String   // MD5
}

// MARK: - Badge / Mission upload (이미지/스키마는 후속)

struct BadgeUploadRes: Decodable {
    let fileName: String
    let url: String
}
