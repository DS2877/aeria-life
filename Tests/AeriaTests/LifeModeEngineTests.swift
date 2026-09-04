import XCTest
@testable import Aeria

final class LifeModeEngineTests: XCTestCase {
    private func date(hour: Int, weekday: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        var components = DateComponents()
        // 2024-01-01 was a Monday (weekday 2 in Foundation's 1=Sunday scheme).
        let dayOffset = weekday - 2
        components.year = 2024
        components.month = 1
        components.day = 1 + dayOffset
        components.hour = hour
        return calendar.date(from: components)!
    }

    func testManualOverrideAlwaysWins() {
        let now = date(hour: 14, weekday: 3)
        let mode = LifeModeEngine.inferMode(now: now, todaysEvents: [], nearestPlaceCategory: .work, manualOverride: .focus)
        XCTAssertEqual(mode, .focus)
    }

    func testEarlyHourIsMorning() {
        let now = date(hour: 7, weekday: 3)
        let mode = LifeModeEngine.inferMode(now: now, todaysEvents: [], nearestPlaceCategory: nil, manualOverride: nil)
        XCTAssertEqual(mode, .morning)
    }

    func testLateHourIsEvening() {
        let now = date(hour: 22, weekday: 3)
        let mode = LifeModeEngine.inferMode(now: now, todaysEvents: [], nearestPlaceCategory: nil, manualOverride: nil)
        XCTAssertEqual(mode, .evening)
    }

    func testWeekendMiddayIsWeekend() {
        let saturday = date(hour: 13, weekday: 7)
        let mode = LifeModeEngine.inferMode(now: saturday, todaysEvents: [], nearestPlaceCategory: nil, manualOverride: nil)
        XCTAssertEqual(mode, .weekend)
    }

    func testWeekdayNearWorkIsWork() {
        let now = date(hour: 13, weekday: 3)
        let mode = LifeModeEngine.inferMode(now: now, todaysEvents: [], nearestPlaceCategory: .work, manualOverride: nil)
        XCTAssertEqual(mode, .work)
    }
}
