// Network/RestAPIClient.swift — 신규 /api/v1/** JSON REST 클라이언트
import Foundation
import os

actor RestAPIClient {
    static let shared = RestAPIClient()

    private static let baseURL = URL(string: "http://43.201.188.35:8080")!
    private static let log = Logger(subsystem: "com.ejola.playspot", category: "RestAPI")

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        // Date 디코딩은 Mission 모델 자체가 다중 포맷 흡수 (Mission.swift). 여기서는 기본 ISO.
        return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    enum Method: String { case GET, POST, PATCH, DELETE, PUT }

    // MARK: - 공개 API

    /// Body 없이 요청 (GET/DELETE). 응답 JSON 을 T 로 디코딩.
    func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        try await request(method: .GET, path: path, query: query, body: Optional<Empty>.none, decode: T.self)
    }

    /// Body 있는 요청 (POST/PATCH/PUT). 응답 JSON 을 T 로 디코딩.
    func send<Body: Encodable, T: Decodable>(_ method: Method, _ path: String, body: Body) async throws -> T {
        try await request(method: method, path: path, query: [:], body: body, decode: T.self)
    }

    /// Body 있는 요청 + 응답 본문 무시 (204 등).
    func send<Body: Encodable>(_ method: Method, _ path: String, body: Body) async throws {
        _ = try await request(method: method, path: path, query: [:], body: body, decode: EmptyResponse.self)
    }

    /// Body 없는 요청 + 응답 본문 무시.
    func send(_ method: Method, _ path: String, query: [String: String] = [:]) async throws {
        _ = try await request(method: method, path: path, query: query, body: Optional<Empty>.none, decode: EmptyResponse.self)
    }

    /// multipart/form-data 파일 업로드. 단일 파일 필드 전용.
    /// `POST /api/v1/badges` / `/api/v1/files/upload` 등 이미지 업로드용. 401/403 자동 재로그인 동일하게 적용.
    func uploadFile<T: Decodable>(
        _ path: String,
        fieldName: String,
        fileName: String,
        mimeType: String,
        data: Data
    ) async throws -> T {
        let urlRequest = try await buildMultipartRequest(path: path, fieldName: fieldName, fileName: fileName, mimeType: mimeType, data: data)
        let (resp, response) = try await perform(urlRequest)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 || status == 403 {
            Self.log.info("\(status, privacy: .public) on multipart \(path, privacy: .public) — auto re-login")
            if await tryReLogin() {
                let retry = try await buildMultipartRequest(path: path, fieldName: fieldName, fileName: fileName, mimeType: mimeType, data: data)
                let (r2, resp2) = try await perform(retry)
                return try decodeOrThrow(data: r2, response: resp2, type: T.self)
            }
        }
        return try decodeOrThrow(data: resp, response: response, type: T.self)
    }

    private func buildMultipartRequest(
        path: String,
        fieldName: String,
        fileName: String,
        mimeType: String,
        data: Data
    ) async throws -> URLRequest {
        let url = Self.baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 30
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = await AuthSession.shared.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = "----PlaySpot\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body
        return req
    }

    // MARK: - 핵심 — 단일 요청 + 401 인터셉터 + 자동 재로그인

    private func request<Body: Encodable, T: Decodable>(
        method: Method,
        path: String,
        query: [String: String],
        body: Body?,
        decode: T.Type
    ) async throws -> T {
        let urlRequest = try await buildRequest(method: method, path: path, query: query, body: body)
        let (data, response) = try await perform(urlRequest)
        let httpResponse = response as? HTTPURLResponse
        let status = httpResponse?.statusCode ?? 0

        // 401/403 자동 재로그인 1회 시도. Spring Security 는 invalid JWT 를 403 으로 응답하는
        // 경우가 있어 둘 다 토큰 만료로 간주한다 (저장된 자격증명이 있는 경우만).
        //
        // 단 /auth/login, /auth/register 는 인증 자체를 시도하는 엔드포인트이므로
        // 401 = "사용자 자격증명 오류"로 해석. 자동 재로그인하면 다른 사용자(저장된 게스트)
        // 자격증명으로 토큰을 갱신해버려 원본 호출 의도와 불일치.
        let isAuthEndpoint = path.hasPrefix("/api/v1/auth/")
        if (status == 401 || status == 403) && !isAuthEndpoint {
            Self.log.info("\(status, privacy: .public) received on \(path, privacy: .public) — attempting auto re-login")
            if await tryReLogin() {
                let retryReq = try await buildRequest(method: method, path: path, query: query, body: body)
                let (data2, resp2) = try await perform(retryReq)
                return try decodeOrThrow(data: data2, response: resp2, type: T.self)
            }
        }

        return try decodeOrThrow(data: data, response: response, type: T.self)
    }

    private func buildRequest<Body: Encodable>(
        method: Method,
        path: String,
        query: [String: String],
        body: Body?
    ) async throws -> URLRequest {
        var components = URLComponents(
            url: Self.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var req = URLRequest(url: components.url!)
        req.httpMethod = method.rawValue
        req.timeoutInterval = 15
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = await AuthSession.shared.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body, !(body is Empty) {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try encoder.encode(body)
        }
        return req
    }

    private func perform(_ req: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: req)
        } catch let urlError as URLError {
            throw APIError.transport(urlError)
        }
    }

    private func decodeOrThrow<T: Decodable>(data: Data, response: URLResponse, type: T.Type) throws -> T {
        let http = response as? HTTPURLResponse
        let status = http?.statusCode ?? 0

        // 204 / 200 + 빈 body 또는 EmptyResponse 요청.
        if status == 204 || data.isEmpty {
            if let empty = EmptyResponse() as? T { return empty }
        }

        if (200..<300).contains(status) {
            // EmptyResponse 가 요구되면 본문이 있어도 무시.
            if T.self == EmptyResponse.self, let empty = EmptyResponse() as? T { return empty }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                Self.log.error("decode \(T.self) failed: \(error.localizedDescription, privacy: .public)")
                throw APIError.unexpected("decode failed: \(error.localizedDescription)")
            }
        }

        // 에러 응답 본문 파싱.
        if let body = try? decoder.decode(APIErrorBody.self, from: data) {
            throw APIError.server(code: body.code, message: body.message, status: status, details: body.details ?? [])
        }
        let bodyText = String(data: data, encoding: .utf8) ?? ""
        throw APIError.server(code: "HTTP_\(status)", message: bodyText.isEmpty ? "request failed" : bodyText, status: status, details: [])
    }

    // MARK: - 401 → 재로그인 핸들러

    /// 저장된 자격증명으로 /auth/login 재호출. 성공 시 토큰 갱신.
    private func tryReLogin() async -> Bool {
        guard let creds = await AuthSession.shared.storedCredentials() else {
            Self.log.warning("auto re-login skipped: no stored credentials")
            return false
        }
        Self.log.info("auto re-login: attempting for \(creds.userID, privacy: .public)")
        // 현재 (잘못된) 토큰을 일단 폐기. 새 토큰 발급 후 setToken 호출하므로 race 없음.
        await AuthSession.shared.clearToken()
        do {
            let req = LoginReq(userId: creds.userID, password: creds.password)
            let urlReq = try await buildRequest(method: .POST, path: "/api/v1/auth/login", query: [:], body: req)
            let (data, response) = try await perform(urlReq)
            let res: LoginRes = try decodeOrThrow(data: data, response: response, type: LoginRes.self)
            await AuthSession.shared.setToken(res.token)
            Self.log.info("auto re-login: SUCCESS — new token issued")
            return true
        } catch {
            Self.log.error("auto re-login failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}

/// 빈 body sentinel — Encodable 제약을 만족하기 위해 사용.
struct Empty: Encodable {}

/// 빈 응답 sentinel — 204 / 본문 무시 응답을 받기 위해 사용.
struct EmptyResponse: Decodable {}
