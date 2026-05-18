// Network/MissionDTO.swift
import Foundation

struct MissionDTO {
    /// 신규 서버 TR=200 응답 형식: `^M[mission_arr]^I[items_arr]^Q[quizzes_arr]`
    /// — `^M`/`^I`/`^Q` 는 리터럴 2바이트(0x5E + 문자) 구분자.
    /// — mission 은 단일 객체가 아닌 1-요소 배열로 내려옴.
    static func parse(response: String) -> (mission: Mission, items: [MissionItem], quizzes: [ItemQuiz])? {
        // "^" 기준 split 후 각 섹션의 앞 글자(M/I/Q) 제거.
        // 응답이 "^M..."로 시작하므로 sections[0] 은 빈 문자열, 실제 데이터는 1/2/3 인덱스.
        let sections = response.components(separatedBy: "^")
        guard sections.count >= 3 else { return nil }

        // 누락 시 빈 배열 처리 — 인덱스 안전성
        func payload(at idx: Int) -> String {
            guard idx < sections.count, !sections[idx].isEmpty else { return "[]" }
            return String(sections[idx].dropFirst()) // M/I/Q 한 글자 제거
        }
        let missionJSON  = payload(at: 1)
        let itemsJSON    = payload(at: 2)
        let quizzesJSON  = payload(at: 3)

        let decoder = JSONDecoder()
        guard let missionData  = missionJSON.data(using: .utf8),
              let itemsData    = itemsJSON.data(using: .utf8),
              let quizzesData  = quizzesJSON.data(using: .utf8) else { return nil }

        do {
            // 서버는 단일 미션도 배열로 wrapping ([{...}])
            let missions = try decoder.decode([Mission].self, from: missionData)
            guard let mission = missions.first else { return nil }
            let items   = try decoder.decode([MissionItem].self, from: itemsData)
            let quizzes = (try? decoder.decode([ItemQuiz].self, from: quizzesData)) ?? []
            return (mission, items, quizzes)
        } catch {
            return nil
        }
    }
}
