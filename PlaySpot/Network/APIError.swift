// Network/APIError.swift
import Foundation

/// 신규 /api/v1/** API 에러. 서버 응답의 {code, message, details} 를 그대로 보존.
enum APIError: Error, LocalizedError {
    case server(code: String, message: String, status: Int, details: [ValidationDetail])
    case transport(URLError)
    case unexpected(String)

    var errorDescription: String? {
        switch self {
        case .server(_, let message, _, _): return message
        case .transport(let err): return err.localizedDescription
        case .unexpected(let msg): return msg
        }
    }

    var code: String? {
        if case .server(let code, _, _, _) = self { return code }
        return nil
    }
}

struct ValidationDetail: Decodable, Sendable {
    let field: String
    let reason: String
}

/// 서버 에러 응답 본문. errorBody 디코딩에 사용.
struct APIErrorBody: Decodable {
    let code: String
    let message: String
    let details: [ValidationDetail]?
}
