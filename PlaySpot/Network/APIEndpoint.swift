// Network/APIEndpoint.swift
import Foundation

enum APIEndpoint {
    static let baseURL = URL(string: "http://nexapp.co.kr/playspot/J_MyList.php")!
    static let rankingURL = URL(string: "http://nexapp.co.kr/playspot/mission_play_info.php")!
    static let passwordURL = URL(string: "http://nexapp.co.kr/playspot/user.php")!
    static let badgeBaseURL = "http://nexapp.co.kr/playspot/badge/"
    static let imageUploadURL = URL(string: "http://nexapp.co.kr/playspot/image_save.php")!
    static let userInfoURL = URL(string: "http://mking.elogin.co.kr/xe/user.php")!

    // 기존 트랜잭션 코드 매핑
    case missionDetail(missionID: String)              // tr=200
    case missionReviews(missionID: String)              // tr=300
    case submitReview(missionID: String, userID: String, score: Float, reply: String) // tr=400
    case playingMissions(last: Int, lang: String)       // tr=500
    case publishedMissions(last: Int, lang: String, lat: Double, lon: Double)  // tr=501
    case myDesigns(last: Int, lang: String)             // tr=502
    case tutorials(lang: String)                        // tr=503
    case designedCount(userID: String)                  // tr=600
    case playedCount(userID: String)                    // tr=601
    case currentGames(userID: String)                   // tr=602
    case uploadMission(data: String, items: String, quizzes: String) // tr=700
    case login(userID: String, passwordMD5: String)     // tr=800
    case register(userID: String, passwordMD5: String)  // tr=tr_user_reg
    case playStart(data: String)                        // tr=c_mission_play_start
    case playFinish(data: String)                       // tr=c_mission_play_finish
    case playFail(data: String)                         // tr=c_mission_play_fail
    case playRanking(missionID: String)                 // tr=c_mission_play_ranking

    var transactionCode: String {
        switch self {
        case .missionDetail: "200"
        case .missionReviews: "300"
        case .submitReview: "400"
        case .playingMissions: "500"
        case .publishedMissions: "501"
        case .myDesigns: "502"
        case .tutorials: "503"
        case .designedCount: "600"
        case .playedCount: "601"
        case .currentGames: "602"
        case .uploadMission: "700"
        case .login: "800"
        case .register: "tr_user_reg"
        case .playStart: "c_mission_play_start"
        case .playFinish: "c_mission_play_finish"
        case .playFail: "c_mission_play_fail"
        case .playRanking: "c_mission_play_ranking"
        }
    }

    var url: URL {
        switch self {
        case .playRanking: Self.rankingURL
        default: Self.baseURL
        }
    }

    /// 기존 HTTPRequest.m의 bodyObject → URL-encoded query string 변환
    var parameters: [String: String] {
        var params: [String: String] = ["tr": transactionCode]
        switch self {
        case .missionDetail(let id): params["missionID"] = id
        case .missionReviews(let id): params["missionID"] = id
        case .submitReview(let mid, let uid, let score, let reply):
            params["MID"] = mid; params["UID"] = uid
            params["Score"] = "\(score)"; params["Reply"] = reply
        case .playingMissions(let last, let lang): params["last"] = "\(last)"; params["lang"] = lang
        case .publishedMissions(let last, let lang, let lat, let lon):
            params["last"] = "\(last)"; params["lang"] = lang
            params["latitude"] = "\(lat)"; params["longitude"] = "\(lon)"
        case .myDesigns(let last, let lang): params["last"] = "\(last)"; params["lang"] = lang
        case .tutorials(let lang): params["gb"] = lang
        case .designedCount(let id): params["id"] = id
        case .playedCount(let id): params["id"] = id
        case .currentGames(let id): params["id"] = id
        case .uploadMission(let data, let items, let quizzes):
            params["mission"] = data; params["missionItem"] = items; params["itemQuiz"] = quizzes
        case .login(let id, let pwd): params["user_id"] = id; params["password"] = pwd
        case .register(let id, let pwd): params["user_id"] = id; params["password"] = pwd
        case .playStart(let data): params["mission_play"] = data
        case .playFinish(let data): params["mission_play"] = data
        case .playFail(let data): params["mission_play"] = data
        case .playRanking(let id): params["mission_id"] = id
        }
        return params
    }
}
