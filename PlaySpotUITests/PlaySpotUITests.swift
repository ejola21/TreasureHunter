// PlaySpotUITests/PlaySpotUITests.swift
import XCTest

final class PlaySpotUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    // MARK: - 로그인

    func testLoginScreenAppears() {
        // 앱 시작 시 로그인 화면이 표시되어야 함
        XCTAssertTrue(app.textFields["email"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.secureTextFields["password"].exists)
    }

    func testGuestLoginFlow() {
        let guestButton = app.buttons["guest_login"]
        if guestButton.waitForExistence(timeout: 5) {
            guestButton.tap()
            // 게스트 로그인 후 미션 목록이 표시되어야 함
            XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
        }
    }

    func testLoginFailureShowsAlert() {
        let emailField = app.textFields["email"]
        guard emailField.waitForExistence(timeout: 5) else { return }

        emailField.tap()
        emailField.typeText("invalid@test.com")
        app.secureTextFields["password"].tap()
        app.secureTextFields["password"].typeText("wrong")
        app.buttons["login_button"].tap()

        // 실패 알림이 표시되어야 함
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 10))
    }

    // MARK: - 미션 목록

    func testMissionListSegmentedControl() {
        loginAsGuest()

        let segmented = app.segmentedControls.firstMatch
        guard segmented.waitForExistence(timeout: 5) else { return }

        // 세그먼트 전환
        segmented.buttons.element(boundBy: 1).tap()
        segmented.buttons.element(boundBy: 2).tap()
        segmented.buttons.element(boundBy: 0).tap()
    }

    // MARK: - 미션 빌더

    func testMissionBuilderTabExists() {
        loginAsGuest()

        let designTab = app.tabBars.buttons.element(boundBy: 2)
        guard designTab.waitForExistence(timeout: 5) else { return }
        designTab.tap()

        // 디자인 화면이 나타나야 함
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
    }

    // MARK: - 설정

    func testSettingsTabExists() {
        loginAsGuest()

        let settingsTab = app.tabBars.buttons.element(boundBy: 4)
        guard settingsTab.waitForExistence(timeout: 5) else { return }
        settingsTab.tap()
    }

    // MARK: - Helpers

    private func loginAsGuest() {
        let guestButton = app.buttons["guest_login"]
        if guestButton.waitForExistence(timeout: 5) {
            guestButton.tap()
        }
    }
}
