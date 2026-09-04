import CoreGraphics
import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Master prompt § 15, § 55: after extraction, always show the fields for
/// confirmation — this sheet is that step. Low-confidence fields carry a
/// visible badge rather than being silently accepted as fact.
struct DocumentReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let cgImage: CGImage
    let extracted: ExtractedDocumentFields

    @State private var title: String
    @State private var category: DocumentCategory
    @State private var documentDate: Date
    @State private var hasExpiry: Bool
    @State private var expiryDate: Date
    @State private var hasAmount: Bool
    @State private var amountText: String

    init(cgImage: CGImage, extracted: ExtractedDocumentFields) {
        self.cgImage = cgImage
        self.extracted = extracted
        _title = State(initialValue: extracted.suggestedCategory.displayName)
        _category = State(initialValue: extracted.suggestedCategory)
        _documentDate = State(initialValue: extracted.documentDate ?? .now)
        _hasExpiry = State(initialValue: extracted.expiryDate != nil)
        _expiryDate = State(initialValue: extracted.expiryDate ?? .now)
        _hasAmount = State(initialValue: extracted.amount != nil)
        _amountText = State(initialValue: extracted.amount.map { "\($0)" } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                if extracted.confidence == .low {
                    Section {
                        HStack {
                            Image(systemName: "sparkle")
                            Text("Aeria wasn't fully sure about these fields — please check them.")
                        }
                        .font(AeriaFont.subheadline)
                        .foregroundStyle(Palette.notice)
                    }
                }

                Section("Title") {
                    TextField("Title", text: $title)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(DocumentCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }

                Section("Dates") {
                    DatePicker("Document date", selection: $documentDate, displayedComponents: .date)
                    Toggle("Has an expiry or renewal date", isOn: $hasExpiry)
                    if hasExpiry {
                        DatePicker("Expires", selection: $expiryDate, displayedComponents: .date)
                    }
                }

                Section("Amount") {
                    Toggle("Has an amount", isOn: $hasAmount)
                    if hasAmount {
                        TextField("Amount", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Review Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        guard let imageData = uiImageData(from: cgImage) else { dismiss(); return }
        guard let fileName = try? VaultStorage.save(data: imageData, suggestedExtension: "jpg") else {
            dismiss()
            return
        }

        let record = DocumentRecord(
            title: title.isEmpty ? category.displayName : title,
            category: category,
            storageFileName: fileName,
            currencyCode: extracted.currencyCode ?? Locale.current.currency?.identifier ?? "USD",
            provenance: .imported
        )
        record.documentDate = documentDate
        record.thumbnailData = imageData
        if hasExpiry {
            record.expiryDate = expiryDate
            record.expiryAttribution = .inferred(confidence: extracted.confidence, sourceIDs: [fileName])
        }
        if hasAmount, let amount = Decimal(string: amountText) {
            record.amount = amount
            record.amountAttribution = .inferred(confidence: extracted.confidence, sourceIDs: [fileName])
        }
        record.needsReview = extracted.confidence == .low

        modelContext.insert(record)
        dismiss()
    }

    private func uiImageData(from cgImage: CGImage) -> Data? {
        #if canImport(UIKit)
        UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.85)
        #else
        nil
        #endif
    }
}
