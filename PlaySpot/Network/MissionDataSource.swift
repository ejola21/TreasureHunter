// Network/MissionDataSource.swift
import Foundation
import CoreLocation

protocol MissionDataSource {
    /// TR=500 — 공개 미션 전체 (All)
    func fetchMissionList(cursor: Int, lang: String) async throws -> [Mission]
    /// TR=501 — 위치 기반 근처 미션 (Near Me)
    func fetchPublishedMissions(cursor: Int, lang: String, latitude: Double, longitude: Double) async throws -> [Mission]
    /// TR=200 — 미션 상세 (mission + items + quizzes)
    func fetchMissionDetail(missionID: String) async throws -> (Mission, [MissionItem], [ItemQuiz])
    /// TR=300 — 미션 리뷰/댓글
    func fetchReplies(missionID: String) async throws -> [MissionReply]
    /// TR=400 — 리뷰 등록
    func submitReview(missionID: String, userID: String, score: Float, reply: String) async throws -> Bool
    /// TR=503 — 튜토리얼 목록
    func fetchTutorialMissions(region: String) async throws -> [Mission]
    /// TR=502 — 내가 디자인한 미션 (legacy 호환: TR=600 도 동일하게 list 반환)
    func fetchMyDesigned(userID: String) async throws -> [Mission]
    /// TR=601 — 내가 플레이한 미션
    func fetchMyPlayed(userID: String) async throws -> [Mission]
    /// TR=602 — 현재 플레이 중인 미션
    func fetchCurrentGames(userID: String) async throws -> [Mission]
    /// c_mission_play_ranking — 미션 별 랭킹 (서버 응답은 {ShortUser1, ShortRecord1, ...} 객체)
    func fetchRanking(missionID: String) async throws -> [RankingEntry]
    /// TR=800 — 로그인. password 는 평문. 해싱은 서버 책임.
    /// Legacy 백엔드는 내부에서 MD5 변환하여 전송.
    func login(email: String, password: String) async throws -> Bool
    /// TR=tr_user_reg — 회원가입. password 는 평문.
    func register(email: String, password: String) async throws -> Bool
    /// TR=700 — 미션 빌더 업로드 (mission, items, quizzes JSON 문자열 묶음).
    /// @deprecated Legacy 호환. 신규 코드는 `createMission(_:)` / `updateMission(_:_:)` 사용.
    func uploadMission(missionJSON: String, itemsJSON: String, quizzesJSON: String) async throws -> Bool

    // MARK: - 빌더 신규 API (POST/PATCH/DELETE /api/v1/missions)

    /// `POST /api/v1/missions` — 미션 생성. 응답에서 서버 발급 MissionID 반환.
    /// Legacy 백엔드에서는 내부에서 `}}` 구분자 페이로드로 변환 후 TR=700 호출.
    func createMission(_ req: BuilderMissionReq) async throws -> String

    /// `PATCH /api/v1/missions/{id}` — 미션 편집 (전체 교체).
    /// Legacy 백엔드에서는 미지원 — `NotSupportedError` throw.
    func updateMission(missionID: String, _ req: BuilderMissionReq) async throws -> Bool

    /// `DELETE /api/v1/missions/{id}` — 미션 삭제. CASCADE 로 items/quizzes 도 함께 삭제.
    /// Legacy 백엔드에서는 미지원 — `NotSupportedError` throw.
    func deleteMission(missionID: String) async throws -> Bool

    /// `POST /api/v1/badges` (multipart `file`) — 뱃지 이미지 업로드. 응답 fileName 반환.
    /// 받은 fileName 은 호출자가 mission payload 의 `BadgeImageName` 에 담아 create/update 로 연결한다.
    /// (서버에 `?missionId=...` 옵션도 있으나 어차피 PATCH 가 같은 작업을 하므로 미사용.)
    /// Legacy 백엔드에서는 `/playspot/image_save.php` multipart `userfile` 호출.
    func uploadBadgeImage(pngData: Data) async throws -> String?

    /// `POST /api/v1/files/upload` (multipart `file`) — 일반 파일 업로드 (api_client.md §7).
    /// 응답: `{id, fileName, fileUrl}`. fileUrl 은 S3 다이렉트라 화면 노출은 다운로드 전략 확정 대기.
    /// Legacy/Local 백엔드는 미지원 — nil 반환.
    func uploadFile(pngData: Data, fileName: String) async throws -> FileUploadRes?
    /// TR=c_mission_play_start / finish / fail — 플레이 기록 (legacy: 콤마 페이로드, rest: 구조화 인자)
    func recordPlayStart(missionID: String, playerID: String, startTime: Date, isVirtual: Bool) async throws -> Bool
    func recordPlayFinish(missionID: String, playerID: String, startTime: Date, endTime: Date, isVirtual: Bool) async throws -> Bool
    func recordPlayFail(missionID: String, playerID: String, startTime: Date, endTime: Date, isVirtual: Bool) async throws -> Bool

    // MARK: - User 정보 (신규 API 전용)

    /// GET /api/v1/users/{id} — Legacy 백엔드에서는 미지원.
    func fetchUser(userID: String) async throws -> UserRes?
    /// PATCH /api/v1/users/{id} — Legacy 백엔드에서는 미지원.
    func updateUser(userID: String, patch: UserPatchReq) async throws -> Bool
    /// PATCH /api/v1/users/{id}/password — Legacy 백엔드에서는 미지원.
    func changePassword(userID: String, oldPasswordMD5: String, newPasswordMD5: String) async throws -> Bool
}

enum DataSourceError: Error {
    case fileNotFound(String)
    case decodingFailed
}
