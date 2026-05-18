// Network/AppConfig.swift
import Foundation

enum AppConfig {
    // 서버 연동 검증 단계 — DEBUG 빌드에서도 RemoteDataSource 사용.
    // Mock 으로 되돌리려면 아래를 LocalDataSource() 로 변경.
    static let dataSource: MissionDataSource = RemoteDataSource()
}
