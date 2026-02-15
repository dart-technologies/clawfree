import XCTest

final class WatchDemoFlowTest: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testDemoFlow() throws {
        // Wait for app to fully load
        sleep(2)

        // Step 1: Tap mic button to trigger first demo animation
        // This should play "Create a trip planner agent" demo
        let micButton = app.buttons["micButton"]
        XCTAssertTrue(micButton.waitForExistence(timeout: 5), "Mic button should exist")
        micButton.tap()

        // Wait for demo animation to complete
        // Animation sequence: recording (1.5s) + typewriter (~2s) + send (0.8s) = ~4.5s
        sleep(5)

        // Step 2: Tap "Create Agent" quick action
        let createAgentButton = app.buttons["createAgentButton"]
        XCTAssertTrue(createAgentButton.waitForExistence(timeout: 5), "Create Agent button should exist")
        createAgentButton.tap()

        // Wait for animation complete
        sleep(5)

        // Step 3: Tap "Plan Trip" quick action
        let planTripButton = app.buttons["planTripButton"]
        XCTAssertTrue(planTripButton.waitForExistence(timeout: 5), "Plan Trip button should exist")
        planTripButton.tap()

        // Wait for final animation complete
        sleep(5)

        // Verify we're back to idle state (mic button should be tappable)
        XCTAssertTrue(micButton.exists, "Should return to main view with mic button")

        // Success - demo flow completed
        print("✅ Demo flow completed successfully")
    }
}
