import CoreGraphics
import SwiftData
import SwiftUI

/// Master prompt § 15–19: the Vault. Scan/import documents, browse by
/// category, and keep an eye on recurring cost — presented as a calm
/// personal record, not a filing cabinet.
struct VaultView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<DocumentRecord> { !$0.isArchived }) private var documents: [DocumentRecord]

    @State private var isPresentingScanner = false
    @State private var pendingScan: PendingScanBox?
    @State private var isExtracting = false
    @State private var selectedCategory: DocumentCategory?

    private var countsByCategory: [DocumentCategory: Int] {
        Dictionary(grouping: documents, by: \.category).mapValues(\.count)
    }

    private var needsReviewCount: Int {
        documents.filter(\.needsReview).count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.spacingXL) {
                Button {
                    isPresentingScanner = true
                } label: {
                    Label("Scan a document", systemImage: "doc.viewfinder")
                        .font(AeriaFont.bodyEmphasized)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AeriaPrimaryButtonStyle())
                .overlay {
                    if isExtracting {
                        ProgressView().tint(Palette.canvas)
                    }
                }
                .disabled(isExtracting)

                if needsReviewCount > 0 {
                    SurfaceCard(isElevated: true) {
                        HStack {
                            Image(systemName: "sparkle").foregroundStyle(Palette.notice)
                            Text("\(needsReviewCount) document\(needsReviewCount == 1 ? "" : "s") need\(needsReviewCount == 1 ? "s" : "") your confirmation")
                                .font(AeriaFont.body)
                                .foregroundStyle(Palette.textPrimary)
                            Spacer()
                        }
                    }
                }

                NavigationLink {
                    SubscriptionListView()
                } label: {
                    SurfaceCard {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(Palette.accent)
                            Text("Subscriptions")
                                .font(AeriaFont.bodyEmphasized)
                                .foregroundStyle(Palette.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Palette.textTertiary)
                        }
                    }
                }
                .buttonStyle(.plain)

                if documents.isEmpty {
                    EmptyStateView(
                        symbolName: "lock.shield",
                        title: "Your Vault is empty",
                        message: "Scan a receipt, warranty, or contract and Aeria will read what it can."
                    )
                    .padding(.top, Metrics.spacingXL)
                } else {
                    VStack(alignment: .leading, spacing: Metrics.spacingM) {
                        SectionHeader(title: "Categories")
                        VaultCategoryGrid(counts: countsByCategory) { category in
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(Metrics.screenPadding)
        }
        .navigationTitle("Vault")
        .navigationDestination(item: $selectedCategory) { category in
            VaultCategoryDetailView(category: category, documents: documents.filter { $0.category == category })
        }
        .sheet(isPresented: $isPresentingScanner) {
            DocumentScannerView(
                onScan: { image in
                    isPresentingScanner = false
                    Task { await extract(image) }
                },
                onCancel: { isPresentingScanner = false }
            )
            .ignoresSafeArea()
        }
        .sheet(item: $pendingScan) { box in
            DocumentReviewSheet(cgImage: box.image, extracted: box.extracted)
        }
    }

    private func extract(_ image: CGImage) async {
        isExtracting = true
        defer { isExtracting = false }
        if let fields = try? await DocumentExtractor.extract(from: image) {
            pendingScan = PendingScanBox(image: image, extracted: fields)
        }
    }
}

/// `Identifiable` wrapper so the extracted-fields tuple can drive a `.sheet(item:)`.
private struct PendingScanBox: Identifiable {
    let id = UUID()
    let image: CGImage
    let extracted: ExtractedDocumentFields
}

private struct VaultCategoryDetailView: View {
    let category: DocumentCategory
    let documents: [DocumentRecord]

    var body: some View {
        List(documents) { document in
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(document.title).foregroundStyle(Palette.textPrimary)
                    if let expiry = document.expiryDate {
                        Text("Expires \(expiry.formatted(date: .abbreviated, time: .omitted))")
                            .font(AeriaFont.caption)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
                Spacer()
                if document.needsReview {
                    Image(systemName: "sparkle").foregroundStyle(Palette.notice)
                }
            }
            .listRowBackground(Palette.canvas)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationTitle(category.displayName)
    }
}
