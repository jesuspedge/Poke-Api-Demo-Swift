import XCTest

// Runs against the bundled fixtures (-ui-testing): Bulbasaur through Charmeleon, no network.
final class ListToDetailUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        return app
    }

    @MainActor
    func testOpeningACardShowsItsDetailAndEvolutionChain() {
        let app = launchApp()
        let card = app.element(id: "pokemon-card-1")
        XCTAssertTrue(card.waitForExistence(timeout: 10))

        card.tap()

        XCTAssertTrue(app.staticTexts["Bulbasaur"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.element(id: "evolution-member-2").waitForExistence(timeout: 5))
        XCTAssertTrue(app.element(id: "evolution-member-3").exists)
        XCTAssertFalse(app.element(id: "evolution-view-button").exists)

        app.navigationBars.buttons.firstMatch.tap()

        XCTAssertTrue(card.waitForExistence(timeout: 5))
    }

    @MainActor
    func testSelectingAnEvolutionOpensIt() {
        let app = launchApp()
        app.element(id: "pokemon-card-1").tapWhenReady()
        app.element(id: "evolution-member-2").tapWhenReady()

        let viewButton = app.element(id: "evolution-view-button")
        XCTAssertTrue(viewButton.waitForExistence(timeout: 5))
        viewButton.tap()

        XCTAssertTrue(app.staticTexts["Ivysaur"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.element(id: "evolution-view-button").exists)
    }
}

extension XCUIApplication {
    func element(id: String) -> XCUIElement {
        descendants(matching: .any)[id].firstMatch
    }
}

extension XCUIElement {
    func tapWhenReady(timeout: TimeInterval = 10) {
        XCTAssertTrue(waitForExistence(timeout: timeout), "\(self) never appeared")
        tap()
    }
}
