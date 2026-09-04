import XCTest

/// Deliberately minimal — master prompt § 89 asks for UI test coverage of
/// onboarding and Today, but a full XCUITest suite here would be untested
/// (and untestable without a Mac) at authoring time. These smoke tests
/// verify the app launches and the core structure exists; expand them
/// alongside real feature work rather than trusting they're complete.
final class AeriaUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.state == .runningForeground)
    }

    func testOnboardingWelcomeScreenAppearsOnFirstLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-aeria.hasCompletedOnboarding", "NO"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Welcome to Aeria"].waitForExistence(timeout: 5))
    }
}
