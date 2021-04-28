//
//  scool_journalUITests.swift
//  scool_journal
//
//  Created by отмеченные on 20/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import XCTest

func isRuLocale() -> Bool {
    let langCode = Locale.current.languageCode
    return langCode == "ru-RU" || langCode == "ru"
}

extension XCUIElement {
    func forceTap() {
        if self.isHittable {
            self.tap()
        } else {
            let coordinate: XCUICoordinate = self.coordinate(
                withNormalizedOffset: CGVector(dx: 0.0, dy: 0.0)
            )
            coordinate.tap()
        }
    }

    func forceDoubleTap() {
        if self.isHittable {
            doubleTap()
        } else {
            let coordinate: XCUICoordinate = self.coordinate(
                withNormalizedOffset: CGVector(dx: 0.0, dy: 0.0)
            )
            coordinate.doubleTap()
        }
    }

    func setText(_ text: String) {
        UIPasteboard.general.string = text
        sleep(1)
        forceTap()
        sleep(1)
        forceTap()
        sleep(1)
        let app = XCUIApplication()
        app.menuItems[isRuLocale() ? "Вставить" : "Paste"].tap()
        sleep(1)
    }
}

class scool_journalUITests: XCTestCase {
    override func setUp() {
        super.setUp()

        continueAfterFailure = false
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments = ["-FASTLANE_SNAPSHOT"]
        app.launch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    private func waitElement(element: XCUIElement, timeout: TimeInterval = 100.0) -> XCUIElement {
        let exists = NSPredicate(format: "exists == 1")

        expectation(for: exists, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: timeout, handler: nil)

        return element
    }

    private func cancelAlert() {
        sleep(1)
        let app = XCUIApplication()
        app.descendants(matching: .any).element(boundBy: 0).tap()
        let alert = app.alerts.element(boundBy: 0)
        let button = alert.buttons.element(boundBy: 0)
        button.tap()
        sleep(2)
    }

    private func tapHamburger() {
        let app = XCUIApplication()
        app.navigationBars.element(boundBy: 0).buttons["ic side menu"].tap()
    }

    func testScreenshots() {
        let authSchool = "api-test-2"
        let authUsername = "parent355"
        let authPassword = "scool_journal2019"
        let waitShort = UInt32(4)
        let waitLong = UInt32(12)

        let isRu = isRuLocale()
        let titleSchool = isRu ? "Школа" : "School"
        let titleLogIn = isRu ? "Войти" : "Log in"
        let titleUpdates = isRu ? "Обновления" : "Updates"
        let titleFinalMarks = isRu ? "Итоговые оценки" : "Final marks"
        let titleMarks = isRu ? "Оценки" : "Marks"
        let titleMessages = isRu ? "Сообщения" : "Messages"
        let titleAnnouncements = isRu ? "Объявления" : "Announcements"

        let app = XCUIApplication()

        sleep(waitLong)
        snapshot("0 Login")

        // Авторизация
        app.descendants(matching: .any)[titleSchool].tap()
        sleep(waitShort)
        app.searchFields.element(boundBy: 0).setText(authSchool)
        sleep(waitLong)
        app.tables.staticTexts[authSchool].tap()
        sleep(waitShort)

        let login = app.textFields.element(boundBy: 0)
        login.setText(authUsername)
        let password = app.secureTextFields.element(boundBy: 0)
        password.setText(authPassword)
        if app.buttons[titleLogIn].exists {
            app.buttons[titleLogIn].tap()
        }
        sleep(20)

        snapshot("1 Register")

        self.tapHamburger()
        app.tables.staticTexts[titleUpdates].tap()
        sleep(waitLong)
        snapshot("2 Updates")

        self.tapHamburger()
        app.tables.staticTexts[titleFinalMarks].tap()
        sleep(waitLong)
        snapshot("3 Finals")

        self.tapHamburger()
        app.tables.staticTexts[titleMarks].tap()
        sleep(waitLong)
        snapshot("4 Marks")

        self.tapHamburger()
        app.tables.staticTexts[titleMessages].tap()
        sleep(waitLong)
        sleep(waitLong)
        snapshot("5 Messages")

        self.tapHamburger()
        app.tables.staticTexts[titleAnnouncements].tap()
        sleep(50)
        snapshot("6 Announcements")
    }

    // func testLaunchPerformance() {
    //     if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
    //         measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
    //             XCUIApplication().launch()
    //         }
    //     }
    // }
}
