import XCTest
@testable import Aeria

final class PriorityEngineTests: XCTestCase {
    func testOverdueItemScoresHigherThanFarFutureItem() {
        let now = Date()
        let overdue = PriorityInput(
            id: "overdue", title: "Overdue", dueDate: now.addingTimeInterval(-3600),
            baseImportance: 0.3, isUserPinned: false, isRelevantToCurrentLocation: false,
            confidence: .confirmed, entityType: .task
        )
        let farFuture = PriorityInput(
            id: "future", title: "Future", dueDate: now.addingTimeInterval(60 * 60 * 24 * 30),
            baseImportance: 0.3, isUserPinned: false, isRelevantToCurrentLocation: false,
            confidence: .confirmed, entityType: .task
        )
        XCTAssertGreaterThan(PriorityEngine.score(overdue, now: now), PriorityEngine.score(farFuture, now: now))
    }

    func testLowConfidenceIsDampened() {
        let now = Date()
        let base = PriorityInput(
            id: "a", title: "A", dueDate: nil, baseImportance: 0.6, isUserPinned: false,
            isRelevantToCurrentLocation: false, confidence: .confirmed, entityType: .document
        )
        let lowConfidence = PriorityInput(
            id: "b", title: "B", dueDate: nil, baseImportance: 0.6, isUserPinned: false,
            isRelevantToCurrentLocation: false, confidence: .low, entityType: .document
        )
        XCTAssertLessThan(PriorityEngine.score(lowConfidence, now: now), PriorityEngine.score(base, now: now))
    }

    func testItemsBelowThresholdAreSuppressed() {
        let quiet = PriorityInput(
            id: "quiet", title: "Quiet", dueDate: nil, baseImportance: 0.05, isUserPinned: false,
            isRelevantToCurrentLocation: false, confidence: .confirmed, entityType: .habit
        )
        XCTAssertTrue(PriorityEngine.rank([quiet]).isEmpty)
    }

    func testOneThingRequiresDecisiveLead() {
        let now = Date()
        let close1 = PriorityInput(
            id: "1", title: "One", dueDate: nil, baseImportance: 0.8, isUserPinned: false,
            isRelevantToCurrentLocation: false, confidence: .confirmed, entityType: .commitment
        )
        let close2 = PriorityInput(
            id: "2", title: "Two", dueDate: nil, baseImportance: 0.78, isUserPinned: false,
            isRelevantToCurrentLocation: false, confidence: .confirmed, entityType: .commitment
        )
        XCTAssertNil(PriorityEngine.oneThing([close1, close2], now: now))

        let dominant = PriorityInput(
            id: "3", title: "Dominant", dueDate: nil, baseImportance: 0.9, isUserPinned: true,
            isRelevantToCurrentLocation: false, confidence: .confirmed, entityType: .commitment
        )
        let minor = PriorityInput(
            id: "4", title: "Minor", dueDate: nil, baseImportance: 0.4, isUserPinned: false,
            isRelevantToCurrentLocation: false, confidence: .confirmed, entityType: .task
        )
        XCTAssertEqual(PriorityEngine.oneThing([dominant, minor], now: now)?.id, "3")
    }
}
