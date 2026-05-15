// Network/MissionDTO.swift
import Foundation

struct MissionDTO {
    /// 기존 MissionListDetailController.m의 didReceiveFinished: 파싱 로직
    /// 응답 형식: M{미션JSON}^I{아이템JSON}^Q{퀴즈JSON}
    static func parse(response: String) -> (mission: Mission, items: [MissionItem], quizzes: [ItemQuiz])? {
        let sections = response.components(separatedBy: "^")
        guard sections.count >= 3 else { return nil }

        // "M" prefix 제거 후 JSON 파싱 — 기존 SBJsonParser 대체
        let missionJSON = String(sections[0].dropFirst())   // "M" 제거
        let itemsJSON = String(sections[1].dropFirst())     // "I" 제거
        let quizzesJSON = String(sections[2].dropFirst())   // "Q" 제거

        let decoder = JSONDecoder()
        guard let missionData = missionJSON.data(using: .utf8),
              let itemsData = itemsJSON.data(using: .utf8),
              let quizzesData = quizzesJSON.data(using: .utf8) else { return nil }

        do {
            let mission = try decoder.decode(Mission.self, from: missionData)
            let items = try decoder.decode([MissionItem].self, from: itemsData)
            let quizzes = try decoder.decode([ItemQuiz].self, from: quizzesData)
            return (mission, items, quizzes)
        } catch {
            return nil
        }
    }
}
