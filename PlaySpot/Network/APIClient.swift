// Network/APIClient.swift
import Foundation
import CryptoKit

actor APIClient {
    static let shared = APIClient()

    /// 기존 HTTPRequest.requestUrl:bodyObject: (비동기) 대체
    func request(_ endpoint: APIEndpoint) async throws -> String {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "POST"
        request.timeoutInterval = 5.0

        let body = endpoint.parameters
            .map { "\($0.key.urlEncoded)=\($0.value.urlEncoded)" }
            .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// 기존 HTTPRequest.requestUrlsync:bodyObject: (동기, timeout 30초) 대체
    func requestSync(_ endpoint: APIEndpoint) async throws -> String {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30.0

        let body = endpoint.parameters
            .map { "\($0.key.urlEncoded)=\($0.value.urlEncoded)" }
            .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

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
