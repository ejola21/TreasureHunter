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
    let WriteDate: String?   // "yyyy-MM-dd HH:mm:ss" (KST) — 서버 R6.1 보강 필요
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

/// `POST /api/v1/files/upload` 응답 — 일반 파일 업로드 (api_client.md §7).
/// `fileUrl` 은 S3 다이렉트 URL (현재 화면 노출은 보류 — 다운로드 전략 확정 대기).
struct FileUploadRes: Decodable {
    let id: Int?
    let fileName: String
    let fileUrl: String
}

struct BadgeUploadRes: Decodable {
    let fileName: String
    let url: String
}

// MARK: - Builder (POST /api/v1/missions 신규)

/// `POST /api/v1/missions` / `PATCH /api/v1/missions/{id}` 요청 body.
/// 서버 미준비 상태 — 합의 후 활성화 (plan_designer.md §5.2).
struct BuilderMissionReq: Encodable {
    let mission: BuilderMissionFields
    let items: [BuilderItemFields]
    let quizzes: [BuilderQuizFields]
}

struct BuilderMissionFields: Encodable {
    let Title: String
    let Description: String
    let Place: String
    let LimitTime: String      // "HH:MM:SS" — "00:00:00" = 무제한
    let Status: Int
    let Virtual: Int           // 0 / 1
    let Lang: String
    let BadgeImageName: String?
    // MissionID / Designer / WriteDate 는 서버 발급 — 요청 body 에 포함하지 않음.
}

struct BuilderItemFields: Encodable {
    let ItemID: Int
    let Mandatory: Int         // 0 / 1
    let ItemType: String       // "49" 등
    let Latitude: Double
    let Longitude: Double
    let BlackCnt: Int
    let BlackTime: Int
    let RangeAR: Int
    let ShowType: String       // "1"~"4"
    let EffectiveRange: Int
    let EffectiveTime: Int
    let ItemGame: Int          // 0~3
    let Info: String
    let RelationItemID: Int
}

struct BuilderQuizFields: Encodable {
    let ItemID: Int
    let Seq: Int
    let Quiz: String
    let Answer: String
    let Probability: Int
}

/// `POST /api/v1/missions` 응답.
struct BuilderMissionCreatedRes: Decodable {
    let missionId: String
}
