// Database/PowerUpRepository.swift
import Foundation
import GRDB

struct PowerUpRepository {
    private let db: DatabaseQueue

    init(db: DatabaseQueue = DatabaseManager.shared.dbQueue) {
        self.db = db
    }

    /// 기존: SELECT * FROM ItemRnPInPlay WHERE MissionID=? AND PlayerID=?
    func fetchAll(missionID: String, playerID: String) throws -> [ItemRnPInPlay] {
        try db.read { db in
            let rows = try Row.fetchAll(db,
                sql: "SELECT * FROM ItemRnPInPlay WHERE MissionID=? AND PlayerID=?",
                arguments: [missionID, playerID])
            return rows.map { mapRow($0) }
        }
    }

    /// 기존: SELECT * FROM ItemRnPInPlay WHERE MissionID=? AND PlayerID=? AND ItemType=?
    func fetch(missionID: String, playerID: String, itemType: String) throws -> ItemRnPInPlay? {
        try db.read { db in
            let row = try Row.fetchOne(db,
                sql: "SELECT * FROM ItemRnPInPlay WHERE MissionID=? AND PlayerID=? AND ItemType=?",
                arguments: [missionID, playerID, itemType])
            return row.map { mapRow($0) }
        }
    }

    /// 기존: INSERT INTO ItemRnPInPlay (...)
    func insert(_ item: ItemRnPInPlay) throws {
        try db.write { db in
            try db.execute(
                sql: """
                    INSERT INTO ItemRnPInPlay (MissionID, PlayerID, ItemType, AbleCnt, AbleTime, AcquiredTime)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """,
                arguments: [
                    item.missionID, item.playerID, item.itemType,
                    item.ableCnt, item.ableTime, item.acquiredTime
                ])
        }
    }

    /// 기존: UPDATE ItemRnPInPlay SET ...
    func update(_ item: ItemRnPInPlay) throws {
        try db.write { db in
            try db.execute(
                sql: """
                    UPDATE ItemRnPInPlay SET AbleCnt=?, AbleTime=?, AcquiredTime=?
                    WHERE MissionID=? AND PlayerID=? AND ItemType=?
                    """,
                arguments: [
                    item.ableCnt, item.ableTime, item.acquiredTime,
                    item.missionID, item.playerID, item.itemType
                ])
        }
    }

    /// 기존: save 패턴
    func save(_ item: ItemRnPInPlay) throws {
        if try fetch(missionID: item.missionID, playerID: item.playerID, itemType: item.itemType) != nil {
            try update(item)
        } else {
            try insert(item)
        }
    }

    /// 기존: DELETE FROM ItemRnPInPlay WHERE MissionID=? AND PlayerID=?
    func deleteAll(missionID: String, playerID: String) throws {
        try db.write { db in
            try db.execute(
                sql: "DELETE FROM ItemRnPInPlay WHERE MissionID=? AND PlayerID=?",
                arguments: [missionID, playerID])
        }
    }

    private func mapRow(_ row: Row) -> ItemRnPInPlay {
        ItemRnPInPlay(
            missionID: row["MissionID"],
            playerID: row["PlayerID"],
            itemType: row["ItemType"] ?? "",
            ableCnt: row["AbleCnt"] ?? 0,
            ableTime: row["AbleTime"],
            acquiredTime: row["AcquiredTime"]
        )
    }
}
