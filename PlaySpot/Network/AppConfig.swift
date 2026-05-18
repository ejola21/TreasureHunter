// Network/AppConfig.swift
import Foundation

enum APIBackend: String, CaseIterable, Identifiable {
    case legacy   // /playspot/J_MyList.php 등 PHP 호환
    case rest     // /api/v1/** JSON REST

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .legacy: return "Legacy (TR=dispatcher)"
        case .rest:   return "REST (/api/v1)"
        }
    }
}

enum AppConfig {
    private static let backendKey = "apiBackend"

    /// 현재 백엔드. UserDefaults 영속. 토글은 Settings 에서.
    static var backend: APIBackend {
        get {
            UserDefaults.standard.string(forKey: backendKey).flatMap(APIBackend.init) ?? .rest
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: backendKey)
        }
    }

    /// 매 접근 시 현재 backend 에 따라 신규 인스턴스 반환. View 가 task 진입 시 캡처하면
    /// 다음 task 부터 토글 반영 (Logout 후 재진입 등).
    static var dataSource: MissionDataSource {
        switch backend {
        case .legacy: return LegacyRemoteDataSource()
        case .rest:   return RestRemoteDataSource()
        }
    }
}
