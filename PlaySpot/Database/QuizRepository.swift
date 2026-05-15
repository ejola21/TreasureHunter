// Database/QuizRepository.swift
import Foundation
import GRDB

struct QuizRepository {
    private let db: DatabaseQueue

    init(db: DatabaseQueue = DatabaseManager.shared.dbQueue) {
        self.db = db
    }

    /// 기존: SELECT * FROM ItemQuiz WHERE missionID=? AND itemID=? ORDER BY seq
    func fetchAll(missionID: String, itemID: Int) throws -> [ItemQuiz] {
        try db.read { db in
            let rows = try Row.fetchAll(db,
                sql: "SELECT * FROM ItemQuiz WHERE missionID=? AND itemID=? ORDER BY seq",
                arguments: [missionID, itemID])
            return rows.map { mapRowToQuiz($0) }
        }
    }

    /// 기존: INSERT INTO ItemQuiz (...)
    func insert(_ quiz: ItemQuiz) throws {
        try db.write { db in
            try db.execute(
                sql: """
                    INSERT INTO ItemQuiz (missionID, itemID, seq, Quiz, Answer, Probability)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """,
                arguments: [
                    quiz.missionID, quiz.itemID, quiz.seq,
                    quiz.quiz, quiz.answer, quiz.probability
                ])
        }
    }

    /// 기존: UPDATE ItemQuiz SET ...
    func update(_ quiz: ItemQuiz) throws {
        try db.write { db in
            try db.execute(
                sql: """
                    UPDATE ItemQuiz SET Quiz=?, Answer=?, Probability=?
                    WHERE missionID=? AND itemID=? AND seq=?
                    """,
                arguments: [
                    quiz.quiz, quiz.answer, quiz.probability,
                    quiz.missionID, quiz.itemID, quiz.seq
                ])
        }
    }

    /// 기존: save 패턴
    func save(_ quiz: ItemQuiz) throws {
        let existing = try fetchAll(missionID: quiz.missionID, itemID: quiz.itemID)
        if existing.contains(where: { $0.seq == quiz.seq }) {
            try update(quiz)
        } else {
            try insert(quiz)
        }
    }

    /// 기존: DELETE FROM ItemQuiz WHERE missionID=? AND itemID=?
    func deleteAll(missionID: String, itemID: Int) throws {
        try db.write { db in
            try db.execute(
                sql: "DELETE FROM ItemQuiz WHERE missionID=? AND itemID=?",
                arguments: [missionID, itemID])
        }
    }

    /// 기존: DELETE FROM ItemQuiz WHERE missionID=?
    func deleteAllForMission(missionID: String) throws {
        try db.write { db in
            try db.execute(
                sql: "DELETE FROM ItemQuiz WHERE missionID=?",
                arguments: [missionID])
        }
    }

    private func mapRowToQuiz(_ row: Row) -> ItemQuiz {
        ItemQuiz(
            missionID: row["missionID"],
            itemID: row["itemID"],
            seq: row["seq"],
            quiz: row["Quiz"] ?? "",
            answer: row["Answer"] ?? "",
            probability: row["Probability"] ?? 0
        )
    }
}
