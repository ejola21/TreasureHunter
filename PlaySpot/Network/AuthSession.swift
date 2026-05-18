// Network/AuthSession.swift
import Foundation

/// JWT 토큰 + 게스트 자동 가입용 자격증명 관리.
/// 단일 actor 로 동시 set/clear 경합 방지.
actor AuthSession {
    static let shared = AuthSession()

    private static let tokenAccount = "jwt.token"
    private static let userIDAccount = "credential.userID"
    private static let passwordAccount = "credential.passwordMD5"

    private var cachedToken: String?

    private init() {
        cachedToken = KeychainStore.get(account: Self.tokenAccount)
    }

    // MARK: - Token

    var token: String? { cachedToken }

    func setToken(_ token: String) {
        cachedToken = token
        KeychainStore.set(token, account: Self.tokenAccount)
    }

    func clearToken() {
        cachedToken = nil
        KeychainStore.delete(account: Self.tokenAccount)
    }

    // MARK: - 저장된 자격증명 (재로그인용)

    /// 다음 401 발생 시 자동 재로그인을 위해 비밀번호(MD5) 와 UserID 를 저장.
    /// 게스트 사용자는 register 시점에 자동 호출.
    func saveCredentials(userID: String, passwordMD5: String) {
        KeychainStore.set(userID, account: Self.userIDAccount)
        KeychainStore.set(passwordMD5, account: Self.passwordAccount)
    }

    func storedCredentials() -> (userID: String, passwordMD5: String)? {
        guard let uid = KeychainStore.get(account: Self.userIDAccount),
              let pw = KeychainStore.get(account: Self.passwordAccount) else { return nil }
        return (uid, pw)
    }

    func clearCredentials() {
        KeychainStore.delete(account: Self.userIDAccount)
        KeychainStore.delete(account: Self.passwordAccount)
    }

    // MARK: - 전체 초기화 (Logout)

    func reset() {
        clearToken()
        clearCredentials()
    }
}
