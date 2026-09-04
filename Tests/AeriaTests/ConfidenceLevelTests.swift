import XCTest
@testable import Aeria

final class ConfidenceLevelTests: XCTestCase {
    func testHighScoreMapsToHighConfidence() {
        XCTAssertEqual(ConfidenceLevel(score: 0.9), .high)
        XCTAssertEqual(ConfidenceLevel(score: 0.85), .high)
    }

    func testLowScoreMapsToLowConfidence() {
        XCTAssertEqual(ConfidenceLevel(score: 0.84), .low)
        XCTAssertEqual(ConfidenceLevel(score: 0.1), .low)
    }

    func testConfirmedNeverHedges() {
        XCTAssertEqual(ConfidenceLevel.confirmed.hedgePrefix, "")
    }

    func testLowConfidenceAlwaysHedges() {
        XCTAssertFalse(ConfidenceLevel.low.hedgePrefix.isEmpty)
    }

    func testOrderingReflectsTrust() {
        XCTAssertLessThan(ConfidenceLevel.low, ConfidenceLevel.high)
        XCTAssertLessThan(ConfidenceLevel.high, ConfidenceLevel.confirmed)
    }
}
