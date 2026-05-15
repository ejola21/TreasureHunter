// Database/MissionRepository.swift
import Foundation
import GRDB

struct MissionRepository {
    private let db: DatabaseQueue

    init(db: DatabaseQueue = DatabaseManager.shared.dbQueue) {
        self.db = db
    }

    /// 기존: SELECT * FROM Mission WHERE missionID=?
    func fetchByID(_ missionID: String) throws -> Mission? {
        try db.read { db in
            let row = try Row.fetchOne(db,
                sql: "SELECT * FROM Mission WHERE missionID = ?",
                arguments: [missionID])
            return row.map { mapRowToMission($0) }
        }
    }

    /// 기존: SELECT * FROM Mission WHERE Status <= ? ORDER BY WriteDate DESC
    func fetchByStatus(_ status: MissionStatus) throws -> [Mission] {
        try db.read { db in
            let rows = try Row.fetchAll(db,
                sql: "SELECT * FROM Mission WHERE Status <= ? ORDER BY WriteDate DESC",
                arguments: [status.rawValue])
            return rows.map { mapRowToMission($0) }
        }
    }

    /// 기존: INSERT INTO Mission (...)
    func insert(_ mission: Mission) throws {
        try db.write { db in
            try db.execute(
                sql: """
                    INSERT INTO Mission (missionID, Title, Description, Place, Quiz, Answer,
                        Designer, StartTime, RunLimitTime, Virtual, Status, WriteDate)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                arguments: [
                    mission.id, mission.title, mission.description, mission.place,
                    mission.quiz, mission.answer, mission.designer,
                    mission.startTime, mission.runLimitTime,
                    mission.isVirtual.rawValue, mission.status.rawValue, mission.writeDate
                ])
        }
    }

    /// 기존: save 패턴 — selectWithPK 후 있으면 update, 없으면 insert
    func save(_ mission: Mission) throws {
        if try fetchByID(mission.id) != nil {
            try update(mission)
        } else {
            try insert(mission)
        }
    }

    /// 기존: UPDATE Mission SET Title=?, ... WHERE missionID=?
    func update(_ mission: Mission) throws {
        try db.write { db in
            try db.execute(
                sql: """
                    UPDATE Mission SET Title=?, Description=?, Place=?, Quiz=?, Answer=?,
                        Designer=?, StartTime=?, RunLimitTime=?, Virtual=?, Status=?, WriteDate=?
                    WHERE missionID=?
                    """,
                arguments: [
                    mission.title, mission.description, mission.place,
                    mission.quiz, mission.answer, mission.designer,
                    mission.startTime, mission.runLimitTime,
                    mission.isVirtual.rawValue, mission.status.rawValue, Date(),
                    mission.id
                ])
        }
    }

    /// 기존: DELETE FROM Mission WHERE missionID=?
    func delete(missionID: String) throws {
        try db.write { db in
            try db.execute(sql: "DELETE FROM Mission WHERE missionID = ?", arguments: [missionID])
        }
    }

    private func mapRowToMission(_ row: Row) -> Mission {
        Mission(
            id: row["missionID"],
            title: row["Title"] ?? "",
            description: row["Description"] ?? "",
            place: row["Place"] ?? "",
            designer: row["Designer"] ?? "",
            startTime: row["StartTime"],
            runLimitTime: row["RunLimitTime"],
            quiz: row["Quiz"] ?? "",
            answer: row["Answer"] ?? "",
            status: MissionStatus(rawValue: row["Status"] ?? 0) ?? .designing,
            items: [],
            writeDate: row["WriteDate"] ?? Date(),
            isVirtual: PlayMode(rawValue: row["Virtual"] ?? 0) ?? .real,
            seq: 0,
            lang: ""
        )
    }
}
