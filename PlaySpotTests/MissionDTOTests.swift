// PlaySpotTests/MissionDTOTests.swift
import XCTest
@testable import PlaySpot

final class MissionDTOTests: XCTestCase {

    // MARK: - ^M^I^Q 구분자 파싱

    func testParseValidResponse() {
        let missionJSON = """
        {"missionID":"m001","title":"테스트 미션","missionDesc":"설명","place":"관악구","latitude":37.4786,"longitude":126.9516,"missionStatus":"1","badgeImg":"badge01","playCount":5,"starRate":4.5,"timeLimit":600,"missionQuiz":"수도?","quizAnswer":"서울","virtualMode":"Y","designUser":"user1","designDate":"2024-01-01"}
        """
        let itemsJSON = """
        [{"missionID":"m001","itemID":1,"itemType":"49","latitude":37.4786,"longitude":126.9516,"showType":"4","mandatoryYN":"Y"}]
        """
        let quizzesJSON = """
        [{"missionID":"m001","itemID":1,"quizNo":1,"question":"무시로의 가수?","answer":"나훈아"}]
        """

        let response = "M\(missionJSON)^I\(itemsJSON)^Q\(quizzesJSON)"
        let result = MissionDTO.parse(response: response)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.mission.id, "m001")
        XCTAssertEqual(result?.mission.title, "테스트 미션")
        XCTAssertEqual(result?.items.count, 1)
        XCTAssertEqual(result?.items.first?.itemType, .start)
        XCTAssertEqual(result?.quizzes.count, 1)
        XCTAssertEqual(result?.quizzes.first?.answer, "나훈아")
    }

    func testParseInsufficientSections() {
        let response = "M{\"missionID\":\"m001\"}^I[]"
        let result = MissionDTO.parse(response: response)

        XCTAssertNil(result, "2개 섹션만 있으면 nil 반환")
    }

    func testParseEmptyResponse() {
        let result = MissionDTO.parse(response: "")
        XCTAssertNil(result)
    }

    func testParseInvalidJSON() {
        let response = "MinvalidJSON^I[]^Q[]"
        let result = MissionDTO.parse(response: response)
        XCTAssertNil(result)
    }

    func testParsePrefixRemoval() {
        // M, I, Q 접두사가 제대로 제거되는지 확인
        let missionJSON = """
        {"missionID":"m002","title":"Test","missionDesc":"","place":"","latitude":0,"longitude":0,"missionStatus":"0","badgeImg":"","playCount":0,"starRate":0,"timeLimit":300,"missionQuiz":"","quizAnswer":"","virtualMode":"N","designUser":"","designDate":""}
        """

        let response = "M\(missionJSON)^I[]^Q[]"
        let result = MissionDTO.parse(response: response)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.mission.id, "m002")
        XCTAssertEqual(result?.items.count, 0)
        XCTAssertEqual(result?.quizzes.count, 0)
    }
}
