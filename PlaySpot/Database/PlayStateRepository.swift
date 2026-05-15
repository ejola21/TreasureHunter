// Database/PlayStateRepository.swift
import Foundation
import GRDB

struct PlayStateRepository {
    private let db: DatabaseQueue

    init(db: DatabaseQueue = DatabaseManager.shared.dbQueue) {
        self.db = db
    }

    // MARK: - MissionInPlay

    /// 기존: SELECT * FROM MissionInPlay WHERE MissionID=? AND PlayerID=?
    func fetchMissionInPlay(missionID: String, playerID: String) throws -> MissionInPlay? {
        try db.read { db in
            let row = try Row.fetchOne(db,
                sql: "SELECT * FROM MissionInPlay WHERE MissionID=? AND PlayerID=?",
                arguments: [missionID, playerID])
            return row.map { mapRowToMissionInPlay($0) }
        }
    }

    /// 기존: INSERT INTO MissionInPlay (...)
    func insertMissionInPlay(_ play: MissionInPlay) throws {
        try db.write { db in
            try db.execute(
                sql: """
                    INSERT INTO MissionInPlay (MissionID, PlayerID, StartYN, EndYN, StartTime, EndTime)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """,
                arguments: [
                    play.missionID, play.playerID, play.startYN,
                    play.endYN, play.startTime, play.endTime
                ])
        }
    }

    /// 기존: UPDATE MissionInPlay SET ...
    func updateMissionInPlay(_ play: MissionInPlay) throws {
        try db.write { db in
            try db.execute(
                sql: """
                    UPDATE MissionInPlay SET StartYN=?, EndYN=?, StartTime=?, EndTime=?
                    WHERE MissionID=? AND PlayerID=?
                    """,
                arguments: [
                    play.startYN, play.endYN, play.startTime, play.endTime,
                    play.missionID, play.playerID
                ])
        }
    }

    /// 기존: DELETE FROM MissionInPlay WHERE MissionID=? AND PlayerID=?
    func deleteMissionInPlay(missionID: String, playerID: String) throws {
        try db.write { db in
            try db.execute(
                sql: "DELETE FROM MissionInPlay WHERE MissionID=? AND PlayerID=?",
                arguments: [missionID, playerID])
        }
    }

    // MARK: - MissionItemInPlay

    /// 기존: SELECT ItemID, EndYN FROM MissionItemInPlay WHERE MissionID=? AND PlayerID=?
    func fetchItemStatusDict(missionID: String, playerID: String) throws -> [Int: String] {
        try db.read { db in
            var dict: [Int: String] = [:]
            let rows = try Row.fetchAll(db,
                sql: "SELECT ItemID, EndYN FROM MissionItemInPlay WHERE MissionID=? AND PlayerID=?",
                arguments: [missionID, playerID])
            for row in rows {
                dict[row["ItemID"]] = row["EndYN"]
            }
            return dict
        }
    }

    /// 기존: selectLastAcquiredItem — 지뢰 폭발 시 되돌릴 아이템 조회
    func fetchLastAcquiredItem(missionID: String, playerID: String, excludeItemID: Int) throws -> MissionItemInPlay? {
        try db.read { db in
            let row = try Row.fetchOne(db, sql: """
                SELECT itemplay.* FROM MissionItemInPlay itemplay
                INNER JOIN MissionItem I ON itemplay.missionID = I.missionID AND itemplay.itemID = I.itemID
                WHERE itemplay.missionID=? AND itemplay.playerID=?
                AND I.itemType NOT IN ('55','61','50','42')
                AND itemplay.endYN IN ('Y')
                AND itemplay.itemID <> ?
                ORDER BY itemplay.endTime DESC
                LIMIT 1
                """, arguments: [missionID, playerID, excludeItemID])
            return row.map { mapRowToItemInPlay($0) }
        }
    }

    /// 기존: missionCompleted — 필수 아이템 전부 수집 여부
    func isMissionCompleted(missionID: String, playerID: String) throws -> Bool {
        try db.read { db in
            let row = try Row.fetchOne(db, sql: """
                SELECT A.* FROM MissionItemInPlay A, MissionItem B
                WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID
                AND A.itemID = B.itemID AND B.mandatory = 1 AND A.endYN = 'N'
                """, arguments: [missionID, playerID])
            return row == nil
        }
    }

    /// 기존: missionCompletedExceptEndItem — End 아이템 제외 완료 여부
    func isMissionCompletedExceptEnd(missionID: String, playerID: String) throws -> Bool {
        try db.read { db in
            let row = try Row.fetchOne(db, sql: """
                SELECT A.* FROM MissionItemInPlay A, MissionItem B
                WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID
                AND A.itemID = B.itemID AND B.mandatory = 1 AND B.itemType <> '48'
                AND A.endYN = 'N'
                """, arguments: [missionID, playerID])
            return row == nil
        }
    }

    /// 기존: selectRand — Gambling 아이템이 줄 랜덤 미획득 아이템 목록
    func fetchRandomCandidates(missionID: String, playerID: String) throws -> [MissionItem] {
        try db.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT B.* FROM MissionItemInPlay A, MissionItem B
                WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID
                AND A.itemID = B.itemID AND A.EndYN = 'N'
                AND B.itemType NOT IN ('48','50','56')
                """, arguments: [missionID, playerID])
            return rows.map { mapRowToMissionItem($0) }
        }
    }

    /// 기존: selectLastStartedTimeOut — 활성 타임아웃 조회 (type 42)
    func fetchActiveTimeout(missionID: String, playerID: String) throws -> MissionItemInPlay? {
        try db.read { db in
            let row = try Row.fetchOne(db, sql: """
                SELECT A.* FROM MissionItemInPlay A, MissionItem B
                WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID
                AND A.itemID = B.itemID AND B.itemType='42' AND A.endYN='N'
                AND A.endTime IS NOT NULL
                ORDER BY A.endTime DESC
                LIMIT 1
                """, arguments: [missionID, playerID])
            return row.map { mapRowToItemInPlay($0) }
        }
    }

    /// 기존: INSERT INTO MissionItemInPlay (...)
    func insertItemInPlay(_ item: MissionItemInPlay) throws {
        try db.write { db in
            try db.execute(sql: """
                INSERT INTO MissionItemInPlay (MissionID, PlayerID, ItemID, EndYN, FailCnt, StartTime, EndTime, QuizSeq)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, arguments: [
                    item.missionID, item.playerID, item.itemID,
                    item.endYN, item.failCnt, item.startTime, item.endTime, item.quizSeq
                ])
        }
    }

    /// 기존: UPDATE MissionItemInPlay SET EndYN=?, ...
    func updateItemInPlay(_ item: MissionItemInPlay) throws {
        try db.write { db in
            try db.execute(sql: """
                UPDATE MissionItemInPlay SET EndYN=?, FailCnt=?, StartTime=?, EndTime=?, QuizSeq=?
                WHERE MissionID=? AND PlayerID=? AND ItemID=?
                """, arguments: [
                    item.endYN, item.failCnt, item.startTime, item.endTime, item.quizSeq,
                    item.missionID, item.playerID, item.itemID
                ])
        }
    }

    /// 기존: DELETE FROM MissionItemInPlay WHERE MissionID=? AND PlayerID=?
    func deleteAllItems(missionID: String, playerID: String) throws {
        try db.write { db in
            try db.execute(
                sql: "DELETE FROM MissionItemInPlay WHERE MissionID=? AND PlayerID=?",
                arguments: [missionID, playerID])
        }
    }

    // MARK: - Row Mapping

    private func mapRowToMissionInPlay(_ row: Row) -> MissionInPlay {
        MissionInPlay(
            missionID: row["MissionID"],
            playerID: row["PlayerID"],
            startYN: row["StartYN"] ?? "N",
            endYN: row["EndYN"] ?? "N",
            startTime: row["StartTime"],
            endTime: row["EndTime"]
        )
    }

    private func mapRowToItemInPlay(_ row: Row) -> MissionItemInPlay {
        MissionItemInPlay(
            missionID: row["MissionID"] ?? row["missionID"],
            playerID: row["PlayerID"] ?? row["playerID"],
            itemID: row["ItemID"] ?? row["itemID"],
            endYN: row["EndYN"] ?? row["endYN"] ?? "N",
            failCnt: row["FailCnt"] ?? 0,
            startTime: row["StartTime"],
            endTime: row["EndTime"],
            quizSeq: row["QuizSeq"] ?? 0
        )
    }

    private func mapRowToMissionItem(_ row: Row) -> MissionItem {
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
