// Game/ItemInteraction.swift
import CoreLocation

/// 아이템 인터랙션 판정 로직 (기존 MissionPlay.m의 distanceCalc 기반)
enum ItemInteraction {
    /// 아이템 획득 가능한 거리인지 판정 (기존: item.rangeAR 이내)
    static func isInRange(
        playerLocation: CLLocation,
        item: MissionItem
    ) -> Bool {
        let distance = playerLocation.distance(from: item.location)
        return distance <= Double(item.rangeAR)
    }

    /// 아이템 타입에 따른 인터랙션 결정
    static func interactionType(for item: MissionItem) -> InteractionType {
        switch item.itemType {
        case .quiz, .quiz20:
            return .quiz
        case .start:
            return .startGame
        case .end:
            return .endGame
        case .mine:
            return .mineExplode
        case .mineNoBomb:
            return .defensePickup
        case .random:
            return .gambling
        case .timeoutStart:
            return .runStart
        case .timeoutEnd:
            return .runEnd
        case .black:
            return .darkEffect
        case .simple:
            return item.itemGame > 0 ? .miniGame : .simplePickup
        default:
            return item.itemGame > 0 ? .miniGame : .simplePickup
        }
    }
}

enum InteractionType {
    case simplePickup       // 단순 획득
    case quiz               // 퀴즈 풀기
    case miniGame           // 미니게임 (shake/touch)
    case startGame          // 미션 시작
    case endGame            // 미션 종료
    case mineExplode        // 지뢰 폭발
    case defensePickup      // 방어 아이템 획득
    case gambling           // 랜덤 박스
    case runStart           // 타임아웃 시작
    case runEnd             // 타임아웃 종료
    case darkEffect         // 어둠 효과
}
