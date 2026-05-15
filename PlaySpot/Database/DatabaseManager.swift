// Database/DatabaseManager.swift
import Foundation
import GRDB

final class DatabaseManager {
    static let shared = DatabaseManager()

    private(set) var dbQueue: DatabaseQueue!

    /// 기존 TreasureHunterAppDelegate.m의 initDatabase 로직 그대로
    func setup() throws {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dbURL = documentsURL.appendingPathComponent("treasure.sqlite")

        // 번들에서 Documents로 복사 (최초 1회) — 기존 로직 동일
        if !fileManager.fileExists(atPath: dbURL.path) {
            guard let bundleDB = Bundle.main.url(forResource: "treasure", withExtension: "sqlite") else {
                throw DatabaseError.bundleNotFound
            }
            try fileManager.copyItem(at: bundleDB, to: dbURL)
        }

        dbQueue = try DatabaseQueue(path: dbURL.path)
    }

    enum DatabaseError: Error {
        case bundleNotFound
    }
}
