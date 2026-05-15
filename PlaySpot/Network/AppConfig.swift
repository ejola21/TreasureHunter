// Network/AppConfig.swift
import Foundation

enum AppConfig {
    #if DEBUG
    static let dataSource: MissionDataSource = LocalDataSource()
    #else
    static let dataSource: MissionDataSource = RemoteDataSource()
    #endif
}
