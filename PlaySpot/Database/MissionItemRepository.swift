// Database/MissionItemRepository.swift
import Foundation
import GRDB

struct MissionItemRepository {
    private let db: DatabaseQueue

    init(db: DatabaseQueue = DatabaseManager.shared.dbQueue) {
        self.db = db
    }

    /// 기존: SELECT * FROM MissionItem WHERE missionID=? ORDER BY itemID
    func fetchAll(missionID: String) throws -> [MissionItem] {
        try db.read { db in
            let rows = try Row.fetchAll(db,
                sql: "SELECT * FROM MissionItem WHERE missionID=? ORDER BY itemID",
                arguments: [missionID])
            return rows.map { mapRowToItem($0) }
        }
    }

    /// 기존: SELECT * FROM MissionItem WHERE missionID=? AND itemID=?
    func fetchByID(missionID: String, itemID: Int) throws -> MissionItem? {
        try db.read { db in
            let row = try Row.fetchOne(db,
                sql: "SELECT * FROM MissionItem WHERE missionID=? AND itemID=?",
                arguments: [missionID, itemID])
            return row.map { mapRowToItem($0) }
        }
    }

    /// 기존: INSERT INTO MissionItem (...)
    func insert(_ item: MissionItem) throws {
        try db.write { db in
            try db.execute(
                sql: """
                    INSERT INTO MissionItem (missionID, itemID, Mandatory, ItemType,
                        Latitude, Longitude, BlackCnt, BlackTime, RangeAR, ShowType,
                        EffectiveRange, EffectiveTime, ItemGame, Info, RelationItemID, WriteDate)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                arguments: [
                    item.missionID, item.itemID, item.mandatory.rawValue,
                    item.itemType.rawValue, item.latitude, item.longitude,
                    item.blackCnt, item.blackTime, item.rangeAR,
                    item.showType.rawValue, item.effectiveRange, item.effectiveTime,
                    item.itemGame, item.info, item.relationItemID, Date()
                ])
        }
    }

    /// 기존: UPDATE MissionItem SET ... WHERE missionID=? AND itemID=?
    func update(_ item: MissionItem) throws {
        try db.write { db in
            try db.execute(
                sql: """
                    UPDATE MissionItem SET Mandatory=?, ItemType=?, Latitude=?, Longitude=?,
                        BlackCnt=?, BlackTime=?, RangeAR=?, ShowType=?,
                        EffectiveRange=?, EffectiveTime=?, ItemGame=?, Info=?,
                        RelationItemID=?, WriteDate=?
                    WHERE missionID=? AND itemID=?
                    """,
                arguments: [
                    item.mandatory.rawValue, item.itemType.rawValue,
                    item.latitude, item.longitude, item.blackCnt, item.blackTime,
                    item.rangeAR, item.showType.rawValue,
                    item.effectiveRange, item.effectiveTime,
                    item.itemGame, item.info, item.relationItemID, Date(),
                    item.missionID, item.itemID
                ])
        }
    }

    /// 기존: save 패턴
    func save(_ item: MissionItem) throws {
        if try fetchByID(missionID: item.missionID, itemID: item.itemID) != nil {
            try update(item)
        } else {
            try insert(item)
        }
    }

    /// 기존: DELETE FROM MissionItem WHERE missionID=?
    func deleteAll(missionID: String) throws {
        try db.write { db in
            try db.execute(sql: "DELETE FROM MissionItem WHERE missionID=?", arguments: [missionID])
        }
    }

    /// 기존: DELETE FROM MissionItem WHERE missionID=? AND itemID=?
    func delete(missionID: String, itemID: Int) throws {
        try db.write { db in
            try db.execute(sql: "DELETE FROM MissionItem WHERE missionID=? AND itemID=?",
                           arguments: [missionID, itemID])
        }
    }

    private func mapRowToItem(_ row: Row) -> MissionItem {
        var item = MissionItem(missionID: row["missionID"], itemID: row["itemID"])
        item.mandatory = MandatoryFlag(rawValue: row["Mandatory"] ?? 0) ?? .optional
        item.itemType = ItemType(rawValue: row["ItemType"] ?? "51") ?? .simple
        item.latitude = row["Latitude"] ?? 0
        item.longitude = row["Longitude"] ?? 0
        item.blackCnt = row["BlackCnt"] ?? 5
        item.blackTime = row["BlackTime"] ?? 300
        item.rangeAR = row["RangeAR"] ?? 30
        item.showType = ShowType(rawValue: row["ShowType"] ?? "4") ?? .all
        item.effectiveRange = row["EffectiveRange"] ?? 0
        item.effectiveTime = row["EffectiveTime"] ?? 0
        item.itemGame = row["ItemGame"] ?? 0
        item.info = row["Info"] ?? ""
        item.relationItemID = row["RelationItemID"] ?? 0
        return item
    }
}
