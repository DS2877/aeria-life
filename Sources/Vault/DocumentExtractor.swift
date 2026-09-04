import Foundation
import Vision

/// What `DocumentExtractor` could read off a scanned document. Master
/// prompt § 15: extract everything reasonable, but never hide that a field
/// is a guess — `confidence` drives whether the Vault UI shows this as
/// settled or asks the user to confirm (§ 55).
struct ExtractedDocumentFields {
    var documentDate: Date?
    var expiryDate: Date?
    var amount: Decimal?
    var currencyCode: String?
    var suggestedCategory: DocumentCategory
    var confidence: ConfidenceLevel
    var rawText: String
}

/// On-device OCR + heuristic field extraction via Vision. No network call,
/// no third-party document-intelligence service — everything about a
/// person's receipts and contracts stays on the device (master prompt § 34).
///
/// The extraction heuristics here are intentionally simple pattern matching
/// (date detector, currency regex, keyword search) rather than a model.
/// That's a deliberate MVP choice: it's transparent (easy to explain why a
/// field was guessed), has no false sense of intelligence, and its
/// confidence score is just "how many independent signals agreed" — which
/// is honest about what it is.
enum DocumentExtractor {
    static func extract(from cgImage: CGImage) async throws -> ExtractedDocumentFields {
        let text = try await recognizeText(in: cgImage)
        return analyze(text: text)
    }

    private static func recognizeText(in cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private static func analyze(text: String) -> ExtractedDocumentFields {
        let lowered = text.lowercased()
        var signalsFound = 0

        var category: DocumentCategory = .document
        if lowered.contains("insurance") || lowered.contains("policy") {
            category = .insurance
            signalsFound += 1
        } else if lowered.contains("warranty") {
            category = .warranty
            signalsFound += 1
        } else if lowered.contains("receipt") || lowered.contains("total") {
            category = .receipt
            signalsFound += 1
        } else if lowered.contains("contract") || lowered.contains("agreement") {
            category = .contract
            signalsFound += 1
        }

        var expiryDate: Date?
        for keyword in ["expir", "valid until", "renew"] {
            guard let range = lowered.range(of: keyword) else { continue }
            let after = String(text[range.upperBound...])
            if let found = detectDates(in: after).first {
                expiryDate = found
                signalsFound += 1
                break
            }
        }

        let allDates = detectDates(in: text)
        let documentDate = allDates.first { $0 != expiryDate }
        if documentDate != nil { signalsFound += 1 }

        let amount = detectAmount(in: text)
        if amount != nil { signalsFound += 1 }
        let currencyCode = amount != nil ? detectCurrencyCode(in: text) : nil

        return ExtractedDocumentFields(
            documentDate: documentDate,
            expiryDate: expiryDate,
            amount: amount,
            currencyCode: currencyCode,
            suggestedCategory: category,
            confidence: ConfidenceLevel(score: signalsFound >= 2 ? 0.9 : 0.4),
            rawText: text
        )
    }

    private static func detectDates(in text: String) -> [Date] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return []
        }
        let range = NSRange(text.startIndex..., in: text)
        return detector.matches(in: text, range: range).compactMap(\.date)
    }

    private static func detectAmount(in text: String) -> Decimal? {
        let pattern = #"(?:[$€£]|SEK|USD|EUR|GBP)\s?([0-9]+(?:[.,][0-9]{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let numberRange = Range(match.range(at: 1), in: text) else { return nil }
        let numberString = text[numberRange].replacingOccurrences(of: ",", with: ".")
        return Decimal(string: numberString)
    }

    private static func detectCurrencyCode(in text: String) -> String? {
        let upper = text.uppercased()
        for code in ["SEK", "USD", "EUR", "GBP"] where upper.contains(code) { return code }
        if text.contains("$") { return "USD" }
        if text.contains("€") { return "EUR" }
        if text.contains("£") { return "GBP" }
        return nil
    }
}
