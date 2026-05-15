// PlaySpotTests/APIClientTests.swift
import XCTest
@testable import PlaySpot

final class APIClientTests: XCTestCase {

    // MARK: - MD5 해싱 (기존 Login.m md5: 출력과 동일성 검증)

    func testMD5EmptyString() {
        let result = APIClient.md5("")
        XCTAssertEqual(result, "d41d8cd98f00b204e9800998ecf8427e")
    }

    func testMD5SimpleString() {
        let result = APIClient.md5("hello")
        XCTAssertEqual(result, "5d41402abc4b2a76b9719d911017c592")
    }

    func testMD5Password() {
        // 기존 앱에서 사용된 패턴: md5("password")
        let result = APIClient.md5("password")
        XCTAssertEqual(result, "5f4dcc3b5aa765d61d8327deb882cf99")
    }

    func testMD5KoreanString() {
        let result = APIClient.md5("비밀번호")
        // MD5는 결정적이므로 동일 입력 -> 동일 출력
        XCTAssertEqual(result.count, 32, "MD5 해시는 항상 32자")
        XCTAssertEqual(result, APIClient.md5("비밀번호"), "동일 입력 동일 출력")
    }

    func testMD5OutputFormat() {
        let result = APIClient.md5("test")
        // 소문자 16진수 32자
        XCTAssertEqual(result.count, 32)
        let hexCharSet = CharacterSet(charactersIn: "0123456789abcdef")
        XCTAssertTrue(result.unicodeScalars.allSatisfy { hexCharSet.contains($0) })
    }

    func testMD5DifferentInputsDifferentOutputs() {
        let hash1 = APIClient.md5("test1")
        let hash2 = APIClient.md5("test2")
        XCTAssertNotEqual(hash1, hash2)
    }
}
