import XCTest

// Walks through the app with live data while the screen is recorded for the README GIF.
// Needs the network, so it only runs when DEMO_TOUR=1 is set (TEST_RUNNER_DEMO_TOUR=1 for xcodebuild).
final class DemoTourUITests: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["DEMO_TOUR"] == "1", "Set DEMO_TOUR=1 to record the demo")
        continueAfterFailure = false
    }

    @MainActor
    func testDemoTour() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo-tour"]
        app.launch()

        // Browse: scroll down the list and back.
        XCTAssertTrue(app.element(id: "pokemon-card-1").waitForExistence(timeout: 15))
        pause(1.5)
        app.swipeUp(velocity: .slow)
        pause(1)
        app.swipeDown(velocity: .slow)
        pause(1)

        // Filter by Fire, then open Charmander (zooms from its card on iOS 18+).
        app.element(id: "type-chip-fire").tapWhenReady()
        pause(1.5)
        app.element(id: "pokemon-card-4").tapWhenReady()
        pause(2)

        // Walk the evolution chain and open Charizard.
        app.element(id: "evolution-member-5").tapWhenReady()
        pause(1)
        app.element(id: "evolution-member-6").tapWhenReady()
        pause(1)
        app.element(id: "evolution-view-button").tapWhenReady()
        pause(2)

        // Add it to the team and look at the analysis.
        app.element(id: "team-toggle").tapWhenReady()
        app.element(id: "favorite-toggle").tapWhenReady()
        pause(1)
        app.tabBars.buttons["Team"].tapWhenReady()
        pause(2.5)
    }

    private func pause(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
