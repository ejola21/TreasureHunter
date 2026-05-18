// Network/AuthBootstrap.swift
import Foundation

/// 앱 진입 시 인증 부트스트랩. REST 백엔드면 토큰을 보장하고, Legacy 면 no-op.
/// PlaySpotApp.body.task 와 각 fetch 직전에 멱등하게 호출 가능.
enum AuthBootstrap {

    /// 토큰이 이미 있으면 즉시 반환. 없으면:
    /// 1) 저장된 자격증명으로 재로그인 시도
    /// 2) 실패 시 신규 게스트 register + login
    static func ensureAuthenticated() async {
        guard AppConfig.backend == .rest else { return }
        if await AuthSession.shared.token != nil { return }

        let dataSource = AppConfig.dataSource

        // (1) 저장된 자격증명으로 재로그인
        if let creds = await AuthSession.shared.storedCredentials() {
            if let ok = try? await dataSource.login(email: creds.userID, passwordMD5: creds.passwordMD5), ok {
                AppState.shared.userID = creds.userID
                return
            }
        }

        // (2) 신규 게스트 자동 가입
        let guestID = AppState.shared.guestUserID
        let md5PW = APIClient.md5(UUID().uuidString)
        _ = try? await dataSource.register(email: guestID, passwordMD5: md5PW)
        if let ok = try? await dataSource.login(email: guestID, passwordMD5: md5PW), ok {
            AppState.shared.userID = guestID
        }
    }
}
