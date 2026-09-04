import XCTest
@testable import Aeria

final class LooseEndsScannerTests: XCTestCase {
    func testUnfulfilledOldCommitmentSurfaces() {
        let now = Date()
        let commitment = Commitment(text: "Send Anna the document", createdAt: now.addingTimeInterval(-4 * 86400))
        let results = LooseEndsScanner.scan(
            now: now, commitments: [commitment], documents: [], upcomingPayments: [], unprocessedNotes: []
        )
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].summary.contains("Send Anna"))
    }

    func testRecentCommitmentDoesNotSurfaceYet() {
        let now = Date()
        let commitment = Commitment(text: "Call the dentist", createdAt: now.addingTimeInterval(-3600))
        let results = LooseEndsScanner.scan(
            now: now, commitments: [commitment], documents: [], upcomingPayments: [], unprocessedNotes: []
        )
        XCTAssertTrue(results.isEmpty)
    }

    func testDocumentExpiringWithin30DaysSurfaces() {
        let now = Date()
        let document = DocumentRecord(title: "Car Insurance", category: .insurance, storageFileName: "x.jpg")
        document.expiryDate = now.addingTimeInterval(19 * 86400)
        let results = LooseEndsScanner.scan(
            now: now, commitments: [], documents: [document], upcomingPayments: [], unprocessedNotes: []
        )
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].relatedEntityType, .document)
    }

    func testFarFutureExpiryDoesNotSurface() {
        let now = Date()
        let document = DocumentRecord(title: "Warranty", category: .warranty, storageFileName: "x.jpg")
        document.expiryDate = now.addingTimeInterval(200 * 86400)
        let results = LooseEndsScanner.scan(
            now: now, commitments: [], documents: [document], upcomingPayments: [], unprocessedNotes: []
        )
        XCTAssertTrue(results.isEmpty)
    }

    func testUnpaidPaymentDueSoonSurfaces() {
        let now = Date()
        let payment = PaymentItem(title: "Electric bill", amount: 500, dueDate: now.addingTimeInterval(2 * 86400), category: .utility)
        let results = LooseEndsScanner.scan(
            now: now, commitments: [], documents: [], upcomingPayments: [payment], unprocessedNotes: []
        )
        XCTAssertEqual(results.count, 1)
    }

    func testArchivedRecordsAreExcluded() {
        let now = Date()
        let commitment = Commitment(text: "Old promise", createdAt: now.addingTimeInterval(-10 * 86400))
        commitment.isArchived = true
        let results = LooseEndsScanner.scan(
            now: now, commitments: [commitment], documents: [], upcomingPayments: [], unprocessedNotes: []
        )
        XCTAssertTrue(results.isEmpty)
    }
}
