// PlaySpotTests/ItemTypeTests.swift
import XCTest
@testable import PlaySpot

final class ItemTypeTests: XCTestCase {

    // MARK: - rawValue 매핑

    func testRawValueMapping() {
        XCTAssertEqual(ItemType.start.rawValue, "49")
        XCTAssertEqual(ItemType.end.rawValue, "48")
        XCTAssertEqual(ItemType.quiz.rawValue, "40")
        XCTAssertEqual(ItemType.mine.rawValue, "55")
        XCTAssertEqual(ItemType.mineNoBomb.rawValue, "61")
        XCTAssertEqual(ItemType.radarAR.rawValue, "65")
        XCTAssertEqual(ItemType.radarMap.rawValue, "66")
        XCTAssertEqual(ItemType.radarAll.rawValue, "67")
        XCTAssertEqual(ItemType.radarMine.rawValue, "68")
        XCTAssertEqual(ItemType.random.rawValue, "50")
        XCTAssertEqual(ItemType.solution.rawValue, "52")
        XCTAssertEqual(ItemType.store.rawValue, "91")
    }

    func testAllCasesDecodable() {
        for itemType in ItemType.allCases {
            let decoded = ItemType(rawValue: itemType.rawValue)
            XCTAssertEqual(decoded, itemType, "Failed for \(itemType)")
        }
    }

    // MARK: - imageFileName

    func testImageFileName() {
        XCTAssertEqual(ItemType.start.imageFileName, "start")
        XCTAssertEqual(ItemType.end.imageFileName, "end")
        XCTAssertEqual(ItemType.quiz.imageFileName, "quiz")
        XCTAssertEqual(ItemType.quiz20.imageFileName, "quiz")
        XCTAssertEqual(ItemType.mine.imageFileName, "mine")
        XCTAssertEqual(ItemType.mineNoBomb.imageFileName, "mine_nobomb")
        XCTAssertEqual(ItemType.random.imageFileName, "random_box")
        XCTAssertEqual(ItemType.solution.imageFileName, "genius")
        XCTAssertEqual(ItemType.simple.imageFileName, "simple")
        XCTAssertEqual(ItemType.timeoutStart.imageFileName, "time_start")
        XCTAssertEqual(ItemType.timeoutEnd.imageFileName, "time_end")
        XCTAssertEqual(ItemType.coupon.imageFileName, "coupon")
    }

    // MARK: - mapIcon / arIcon

    func testMapIconOptional() {
        XCTAssertEqual(ItemType.quiz.mapIcon(mandatory: false), "i_quiz")
        XCTAssertEqual(ItemType.quiz.mapIcon(mandatory: true), "in_quiz")
    }

    func testArIconOptional() {
        XCTAssertEqual(ItemType.mine.arIcon(mandatory: false), "ar_mine")
        XCTAssertEqual(ItemType.mine.arIcon(mandatory: true), "arn_mine")
    }

    func testMapAndArIconConsistency() {
        for itemType in ItemType.allCases {
            let mapOptional = itemType.mapIcon(mandatory: false)
            let mapMandatory = itemType.mapIcon(mandatory: true)
            XCTAssertTrue(mapOptional.hasPrefix("i_"), "\(itemType) map optional should start with i_")
            XCTAssertTrue(mapMandatory.hasPrefix("in_"), "\(itemType) map mandatory should start with in_")

            let arOptional = itemType.arIcon(mandatory: false)
            let arMandatory = itemType.arIcon(mandatory: true)
            XCTAssertTrue(arOptional.hasPrefix("ar_"), "\(itemType) ar optional should start with ar_")
            XCTAssertTrue(arMandatory.hasPrefix("arn_"), "\(itemType) ar mandatory should start with arn_")
        }
    }

    // MARK: - 분류 프로퍼티

    func testIsMine() {
        XCTAssertTrue(ItemType.mine.isMine)
        XCTAssertTrue(ItemType.mineNoBomb.isMine)
        XCTAssertFalse(ItemType.quiz.isMine)
        XCTAssertFalse(ItemType.start.isMine)
    }

    func testIsRadar() {
        XCTAssertTrue(ItemType.radarAR.isRadar)
        XCTAssertTrue(ItemType.radarMap.isRadar)
        XCTAssertTrue(ItemType.radarAll.isRadar)
        XCTAssertTrue(ItemType.radarMine.isRadar)
        XCTAssertFalse(ItemType.mine.isRadar)
        XCTAssertFalse(ItemType.quiz.isRadar)
    }

    func testIsTimeout() {
        XCTAssertTrue(ItemType.timeoutStart.isTimeout)
        XCTAssertTrue(ItemType.timeoutEnd.isTimeout)
        XCTAssertFalse(ItemType.start.isTimeout)
        XCTAssertFalse(ItemType.end.isTimeout)
    }

    func testExcludedFromLastAcquired() {
        XCTAssertTrue(ItemType.mine.excludedFromLastAcquired)
        XCTAssertTrue(ItemType.mineNoBomb.excludedFromLastAcquired)
        XCTAssertTrue(ItemType.random.excludedFromLastAcquired)
        XCTAssertTrue(ItemType.timeoutStart.excludedFromLastAcquired)
        XCTAssertFalse(ItemType.quiz.excludedFromLastAcquired)
        XCTAssertFalse(ItemType.end.excludedFromLastAcquired)
    }

    func testExcludedFromRandom() {
        XCTAssertTrue(ItemType.end.excludedFromRandom)
        XCTAssertTrue(ItemType.random.excludedFromRandom)
        XCTAssertTrue(ItemType.black.excludedFromRandom)
        XCTAssertFalse(ItemType.quiz.excludedFromRandom)
        XCTAssertFalse(ItemType.simple.excludedFromRandom)
    }
}
