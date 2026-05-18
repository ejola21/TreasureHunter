// Network/APIClient.swift
import Foundation
import CryptoKit

actor APIClient {
    static let shared = APIClient()

    /// 기존 HTTPRequest.requestUrl:bodyObject: (비동기) 대체
    func request(_ endpoint: APIEndpoint) async throws -> String {
        try await send(endpoint, timeout: 5.0)
    }

    /// 기존 HTTPRequest.requestUrlsync:bodyObject: (동기, timeout 30초) 대체
    func requestSync(_ endpoint: APIEndpoint) async throws -> String {
        try await send(endpoint, timeout: 30.0)
    }

    private func send(_ endpoint: APIEndpoint, timeout: TimeInterval) async throws -> String {
        let query = endpoint.parameters
            .map { "\($0.key.urlEncoded)=\($0.value.urlEncoded)" }
            .joined(separator: "&")

        // 신규 서버는 POST + 쿼리스트링(URL) 방식 — 레거시 호환 (PHP $_REQUEST 가 둘 다 수용)
        var components = URLComponents(url: endpoint.url, resolvingAgainstBaseURL: false)!
        components.percentEncodedQuery = query
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.httpBody = Data()

        let (data, _) = try await URLSession.shared.data(for: request)
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// 기존 Login.m의 md5: 대체 — CC_MD5 → CryptoKit
    static func md5(_ string: String) -> String {
        let data = Data(string.utf8)
        return Insecure.MD5.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

private extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
