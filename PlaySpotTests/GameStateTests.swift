// PlaySpotTests/GameStateTests.swift
import XCTest
@testable import PlaySpot

final class GameStateTests: XCTestCase {

    // MARK: - MissionStatus

    func testMissionStatusRawValues() {
        XCTAssertEqual(MissionStatus.designing.rawValue, "0")
        XCTAssertEqual(MissionStatus.tested.rawValue, "1")
        XCTAssertEqual(MissionStatus.serverUploaded.rawValue, "2")
        XCTAssertEqual(MissionStatus.firstDesign.rawValue, "3")
    }

    // MARK: - PlayMode

    func testPlayModeRawValues() {
        XCTAssertEqual(PlayMode.real.rawValue, 0)
        XCTAssertEqual(PlayMode.virtual.rawValue, 1)
    }

    // MARK: - MandatoryFlag

    func testMandatoryFlagRawValues() {
        XCTAssertEqual(MandatoryFlag.no.rawValue, "N")
        XCTAssertEqual(MandatoryFlag.yes.rawValue, "Y")
    }

    // MARK: - MissionInPlay

    func testMissionInPlayHasStarted() {
        let play = MissionInPlay(missionID: "m1", playerID: "p1", startYN: "Y", startTime: Date())
        XCTAssertTrue(play.hasStarted)
    }

    func testMissionInPlayNotStarted() {
        let play = MissionInPlay(missionID: "m1", playerID: "p1", startYN: "N", startTime: nil)
        XCTAssertFalse(play.hasStarted)
    }

    func testMissionInPlayHasEnded() {
        let play = MissionInPlay(missionID: "m1", playerID: "p1", startYN: "Y", startTime: Date(), endYN: "Y", endTime: Date())
        XCTAssertTrue(play.hasEnded)
    }
}
