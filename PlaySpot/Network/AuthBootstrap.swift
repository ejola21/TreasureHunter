// Network/AuthBootstrap.swift
import Foundation
import os

/// 앱 진입 시 인증 부트스트랩. REST 백엔드면 토큰을 보장하고, Legacy 면 no-op.
/// PlaySpotApp.body.task 와 각 fetch 직전에 멱등하게 호출 가능.
///
/// 동시 호출 race 방지: 단일 inflight Task 를 공유한다. 두 번째 호출자는
/// 첫 번째의 결과를 await 만 한다 (게스트 중복 가입 방지).
actor AuthBootstrap {
    static let shared = AuthBootstrap()
    private static let log = Logger(subsystem: "com.ejola.playspot", category: "AuthBootstrap")
    private var inflight: Task<Void, Never>?

    static func ensureAuthenticated() async {
        await shared.ensure()
    }

    private func ensure() async {
        guard AppConfig.backend == .rest else { return }
        if await AuthSession.shared.token != nil {
            Self.log.info("ensureAuth: token already present — skip")
            return
        }

        if let inflight = inflight {
            Self.log.info("ensureAuth: inflight task exists, awaiting")
            await inflight.value
            return
        }

        let task = Task<Void, Never> {
            await Self.performBootstrap()
        }
        inflight = task
        await task.value
        inflight = nil
    }

    /// 토큰이 이미 있으면 즉시 반환. 없으면:
    /// 1) 저장된 자격증명으로 재로그인 시도
    /// 2) 실패 시 신규 게스트 register + login
    private static func performBootstrap() async {
        log.info("ensureAuth: starting bootstrap")
        let dataSource = AppConfig.dataSource

        // (1) 저장된 자격증명으로 재로그인 (평문 비밀번호 + Keychain 보호)
        if let creds = await AuthSession.shared.storedCredentials() {
            log.info("ensureAuth: trying stored credentials for \(creds.userID, privacy: .public)")
            if let ok = try? await dataSource.login(email: creds.userID, password: creds.password), ok {
                AppState.shared.userID = creds.userID
                log.info("ensureAuth: stored-cred login success")
                return
            }
            log.warning("ensureAuth: stored-cred login failed, will create new guest")
        }

        // (2) 신규 게스트 자동 가입 — 평문 비밀번호. 해싱은 서버.
        // 서버에 32자 제한이 있어 UUID 의 dash 를 제거 (8E382F47FF994ADE94C8CC36ECC0F517 = 32자).
        let guestID = AppState.shared.guestUserID
        let guestPW = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        log.info("ensureAuth: registering new guest \(guestID, privacy: .public)")
        _ = try? await dataSource.register(email: guestID, password: guestPW)
        log.info("ensureAuth: logging in new guest")
        if let ok = try? await dataSource.login(email: guestID, password: guestPW), ok {
            AppState.shared.userID = guestID
            log.info("ensureAuth: guest login success — token issued")
        } else {
            log.error("ensureAuth: guest login FAILED")
        }
    }
}
