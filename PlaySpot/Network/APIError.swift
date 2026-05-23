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

    /// HTTP status code (server case 전용).
    var httpStatus: Int? {
        if case .server(_, _, let status, _) = self { return status }
        return nil
    }

    /// 신규 v1 API 의 의미적 분류 헬퍼.
    /// 호출자가 do-catch 안에서 `if let apiErr = error as? APIError, apiErr.isNotFound { … }` 로 분기.

    /// 404 + `DATA_NOT_FOUND` (서버) / 또는 `MISSION_NOT_FOUND` (사양).
    /// 의미: 요청한 리소스가 더 이상 존재하지 않음. 다른 디바이스에서 삭제됐을 가능성.
    var isNotFound: Bool {
        guard case .server(let code, _, let status, _) = self else { return false }
        return status == 404 || code == "DATA_NOT_FOUND" || code == "MISSION_NOT_FOUND"
    }

    /// 403 + `FORBIDDEN`. 의미: 본인이 작성자가 아님.
    var isForbidden: Bool {
        guard case .server(let code, _, let status, _) = self else { return false }
        return status == 403 || code == "FORBIDDEN"
    }

    /// 409 + `MISSION_NOT_DELETABLE` (api_designer.md §1.4.2 / §4.3).
    /// 의미: 공개된 (Status=2) 미션을 삭제하려고 함. 먼저 공개 해제 필요.
    var isNotDeletable: Bool {
        guard case .server(let code, _, let status, _) = self else { return false }
        return code == "MISSION_NOT_DELETABLE" || status == 409
    }

    /// 400 + `VALIDATION_ERROR` / `VALIDATION_FAILED`. 의미: 필드/비즈니스 룰 위반.
    var isValidationError: Bool {
        guard case .server(let code, _, let status, _) = self else { return false }
        return status == 400 || code == "VALIDATION_ERROR" || code == "VALIDATION_FAILED"
    }

    /// 인증 실패 (401 `UNAUTHORIZED` 또는 403 `FORBIDDEN` — auth 엔드포인트 한정).
    var isUnauthorized: Bool {
        guard case .server(let code, _, let status, _) = self else { return false }
        return status == 401 || code == "UNAUTHORIZED"
    }

    /// 사용자에게 보일 한국어 안내문 매핑 (분류별 fallback). 서버 message 보다 명확한 라벨 필요 시 사용.
    var userFacingMessage: String {
        if isNotFound      { return "미션을 찾을 수 없어요. 다른 디바이스에서 삭제됐을 수 있습니다." }
        if isForbidden     { return "이 미션을 수정/삭제할 권한이 없어요." }
        if isNotDeletable  { return "공개된 미션은 바로 삭제할 수 없어요. 먼저 ‘공개 해제’ 한 뒤 시도해주세요." }
        if isValidationError { return errorDescription ?? "입력값을 확인해주세요." }
        if isUnauthorized  { return "로그인이 필요합니다." }
        return errorDescription ?? "요청 처리 중 오류가 발생했습니다."
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
