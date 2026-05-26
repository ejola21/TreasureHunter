// Game/MissionValidator.swift — 빌더 dataCheck 14 규칙 통합
// 참고: plan_designer.md §4 / 레거시 Classes/MissionBuilder.m:380-650
import Foundation

enum ValidationFieldRef: Equatable {
    case mission(String)       // "title" / "description" / ...
    case items                 // items 전체에 대한 위반
    case item(Int)             // item.itemID
    case itemQuiz(Int, Int)    // (itemID, seq)
}

struct ValidationError: Identifiable, Equatable {
    let id = UUID()
    let messageKey: String          // Localizable: data_check_message_*
    let fallbackMessage: String     // 키가 없을 때 사용
    let field: ValidationFieldRef
    let isBlocking: Bool            // false = 경고만 (Save 차단 X)
}

enum MissionValidator {

    /// `MissionBuilderViewModel` 상태 기반 검증. 결과는 `Save` 버튼 활성화/메시지/스크롤 타깃에 사용.
    ///
    /// 장소(Place)는 검증하지 않는다 — Start 아이템 배치 시 좌표로 자동 채워지며,
    /// 비어 있어도 저장을 막지 않는다 (MissionBuilderViewModel.placeItem 참조).
    static func validate(
        title: String,
        description: String,
        items: [MissionItem],
        quizzesByItem: [Int: [ItemQuiz]]   // key=itemID
    ) -> [ValidationError] {
        var errors: [ValidationError] = []

        // — 미션 레벨
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.init(messageKey: "data_check_message_0",
                                fallbackMessage: "미션 제목을 입력하세요.",
                                field: .mission("title"), isBlocking: true))
        }
        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.init(messageKey: "data_check_message_1",
                                fallbackMessage: "미션 설명을 입력하세요.",
                                field: .mission("description"), isBlocking: true))
        }
        if items.count < 3 {
            errors.append(.init(messageKey: "data_check_message_3",
                                fallbackMessage: "아이템은 3개 이상 배치하세요.",
                                field: .items, isBlocking: true))
        }
        let starts = items.filter { $0.itemType == .start }
        let ends = items.filter { $0.itemType == .end }
        if starts.count != 1 {
            errors.append(.init(messageKey: "data_check_message_4",
                                fallbackMessage: "Start 아이템은 정확히 1개여야 합니다.",
                                field: .items, isBlocking: true))
        }
        if ends.count != 1 {
            errors.append(.init(messageKey: "data_check_message_5",
                                fallbackMessage: "End 아이템은 정확히 1개여야 합니다.",
                                field: .items, isBlocking: true))
        }
        let runStarts = items.filter { $0.itemType == .timeoutStart }
        let runEnds = items.filter { $0.itemType == .timeoutEnd }
        if runStarts.count != runEnds.count {
            errors.append(.init(messageKey: "data_check_message_6",
                                fallbackMessage: "Run Start 와 Run End 는 짝이 맞아야 합니다.",
                                field: .items, isBlocking: true))
        } else {
            // 페어 매칭 — 어느 한 방향이라도 링크되어 있으면 통과.
            // 서버 응답이 Run End → Run Start 단방향만 채워주는 경우가 있어 (legacy 데이터),
            // AND 로 검사하면 사용자가 페어를 정상 배치했는데도 오류로 표시됨.
            // 반대 방향(End → Start) 의 완전성은 아래 rule 14 (data_check_message_13) 가 별도로 보장.
            for s in runStarts {
                guard runEnds.contains(where: {
                    $0.itemID == s.relationItemID || $0.relationItemID == s.itemID
                }) else {
                    errors.append(.init(messageKey: "data_check_message_6",
                                        fallbackMessage: "Run Start (#\(s.itemID)) 의 페어가 없습니다.",
                                        field: .item(s.itemID), isBlocking: true))
                    break
                }
            }
        }
        if items.filter({ $0.isMandatory }).isEmpty {
            errors.append(.init(messageKey: "data_check_message_7",
                                fallbackMessage: "필수 아이템이 최소 1개 필요합니다.",
                                field: .items, isBlocking: true))
        }
        // Radar 종류(65/66/67/68/69) 각각 ≤ 1
        let radarCodes: Set<String> = ["65", "66", "67", "68", "69"]
        var radarCount: [String: Int] = [:]
        for it in items where radarCodes.contains(it.itemType.rawValue) {
            radarCount[it.itemType.rawValue, default: 0] += 1
        }
        if radarCount.values.contains(where: { $0 > 1 }) {
            errors.append(.init(messageKey: "data_check_message_8",
                                fallbackMessage: "각 레이더 종류는 1개만 배치 가능합니다.",
                                field: .items, isBlocking: true))
        }

        // — 아이템 레벨 (10~14)
        for it in items {
            let quizzes = quizzesByItem[it.itemID] ?? []
            if it.itemType == .quiz || it.itemType == .quiz20 {
                if quizzes.isEmpty {
                    errors.append(.init(messageKey: "data_check_message_9",
                                        fallbackMessage: "Quiz 아이템 (#\(it.itemID)) 은 최소 1개의 퀴즈 변형이 필요합니다.",
                                        field: .item(it.itemID), isBlocking: true))
                }
                for q in quizzes {
                    if q.quiz.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || q.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        errors.append(.init(messageKey: "data_check_message_10",
                                            fallbackMessage: "Quiz 변형 (#\(it.itemID) seq \(q.seq)) 의 질문/정답을 입력하세요.",
                                            field: .itemQuiz(it.itemID, q.seq), isBlocking: true))
                    }
                }
            }
            // info 비어있으면 경고 (차단 X). 미션 '설명' 이 아니라 '아이템별 안내문' 을 가리킨다.
            if [.simple, .mineNoBomb, .random, .coupon].contains(it.itemType)
                && it.info.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append(.init(messageKey: "data_check_message_11",
                                    fallbackMessage: "#\(it.itemID) \(it.itemType.displayLabel) 아이템의 안내문이 비어 있어요 (선택).",
                                    field: .item(it.itemID), isBlocking: false))
            }
            // 13 — Run End 의 effectiveTime > 0
            if it.itemType == .timeoutEnd && it.effectiveTime <= 0 {
                errors.append(.init(messageKey: "data_check_message_12",
                                    fallbackMessage: "Run End (#\(it.itemID)) 의 제한 시간을 1초 이상으로 설정하세요.",
                                    field: .item(it.itemID), isBlocking: true))
            }
            // 14 — Run End 의 relationItemID 가 실제 Run Start 인지
            if it.itemType == .timeoutEnd {
                let paired = items.contains { $0.itemType == .timeoutStart && $0.itemID == it.relationItemID }
                if !paired {
                    errors.append(.init(messageKey: "data_check_message_13",
                                        fallbackMessage: "Run End (#\(it.itemID)) 의 페어 (Run Start) 가 없습니다.",
                                        field: .item(it.itemID), isBlocking: true))
                }
            }
        }

        return errors
    }

    /// 차단(blocking) 에러만 — Save 버튼 disabled 판정용.
    static func hasBlockingError(_ errors: [ValidationError]) -> Bool {
        errors.contains { $0.isBlocking }
    }
}
