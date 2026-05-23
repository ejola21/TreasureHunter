// Models/GameState.swift
import Foundation

/// 미션 공개 상태.
/// - `unpublished` (0): 비공개 — Missions 탭(공개 목록)에 노출되지 않음. 본인 디자인 목록에만 보임.
/// - `published`   (2): 공개 — Missions 탭에 노출.
///
/// 과거 값 `1`(TESTED) / `3`(FIRST_DESIGN) 은 폐기됨. 서버에서 1·3 이 내려오면
/// 디코딩 측(Mission.swift)에서 `.unpublished` 로 흡수한다.
enum MissionStatus: Int, Codable {
    case unpublished = 0
    case published = 2
}

enum PlayMode: Int, Codable {
    case real = 0           // REAL_MODE
    case virtual = 1        // VIRTUAL_MODE
}

enum MandatoryFlag: Int, Codable {
    case optional = 0       // MANDATORY_N
    case mandatory = 1      // MANDATORY_Y
}
