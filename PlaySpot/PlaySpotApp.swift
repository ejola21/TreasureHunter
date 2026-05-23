// PlaySpotApp.swift
import SwiftUI

@main
struct PlaySpotApp: App {
    @State private var appState = AppState.shared

    init() {
        try? DatabaseManager.shared.setup()
        // 레거시 AppDelegate.locationManagerInit(:self) 패턴과 동일하게 앱 시작 시점에 위치 서비스를 즉시 기동.
        // MissionPlayView가 열리기 전에 currentLocation이 이미 픽스되어 awaitFirstLocation()이
        // 즉시 반환되도록 보장한다.
        AppState.shared.locationService.requestPermission()
        AppState.shared.locationService.startUpdating()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(appState)
                .task { await AuthBootstrap.ensureAuthenticated() }
        }
    }
}

// 기존 AppDelegate 전역 상태 → @Observable 싱글턴
@Observable
final class AppState {
    static let shared = AppState()

    let locationService = LocationService()
    let motionService = MotionService()

    var userID: String {
        get { UserDefaults.standard.string(forKey: "gUserID") ?? guestUserID }
        set { UserDefaults.standard.set(newValue, forKey: "gUserID") }
    }

    /// 사용자가 회원가입/프로필 화면에서 등록한 닉네임. 게스트는 빈 문자열.
    /// 댓글 작성 시 newly-submitted review 의 author 로도 사용.
    var userNickname: String {
        get { UserDefaults.standard.string(forKey: "gUserNickname") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "gUserNickname") }
    }

    var guestUserID: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMddhhmmssSSS"
        return "Guest@\(formatter.string(from: Date()))"
    }

    var isGuest: Bool { userID.hasPrefix("Guest@") }

    var solutionCount: Int {
        get { UserDefaults.standard.integer(forKey: "solution") }
        set { UserDefaults.standard.set(max(0, newValue), forKey: "solution") }
    }

    var timeAddCount: Int {
        get { UserDefaults.standard.integer(forKey: "timeAdd") }
        set { UserDefaults.standard.set(max(0, newValue), forKey: "timeAdd") }
    }
}
