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
    /// TR=800 — 로그인 (response="SUCCESS")
    func login(email: String, passwordMD5: String) async throws -> Bool
    /// TR=tr_user_reg — 회원가입
    func register(email: String, passwordMD5: String) async throws -> Bool
    /// TR=700 — 미션 빌더 업로드 (mission, items, quizzes JSON 문자열 묶음)
    func uploadMission(missionJSON: String, itemsJSON: String, quizzesJSON: String) async throws -> Bool
    /// TR=c_mission_play_start / finish / fail — 플레이 기록 (JSON 페이로드)
    func recordPlayStart(playJSON: String) async throws -> Bool
    func recordPlayFinish(playJSON: String) async throws -> Bool
    func recordPlayFail(playJSON: String) async throws -> Bool
}

enum DataSourceError: Error {
    case fileNotFound(String)
    case decodingFailed
}
