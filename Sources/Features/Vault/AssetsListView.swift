import SwiftData
import SwiftUI

/// Master prompt § 17: a possession's purchase, warranty, and insurance in
/// one place — "is this still under warranty?" answered by looking, not
/// searching.
struct AssetsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Asset> { !$0.isArchived }, sort: \Asset.createdAt, order: .reverse) private var assets: [Asset]
    @State private var isPresentingAdd = false

    var body: some View {
        Group {
            if assets.isEmpty {
                EmptyStateView(
                    symbolName: "cube",
                    title: "No possessions tracked",
                    message: "Add a vehicle, a laptop, anything worth remembering the warranty on."
                )
                .padding(.top, Metrics.spacingXXL)
            } else {
                List {
                    ForEach(assets) { asset in
                        NavigationLink {
                            AssetDetailView(asset: asset)
                        } label: {
                            HStack {
                                Image(systemName: asset.category.symbolName).foregroundStyle(Palette.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(asset.name).foregroundStyle(Palette.textPrimary)
                                    if let warranty = warrantyStatus(asset) {
                                        Text(warranty.text)
                                            .font(AeriaFont.caption)
                                            .foregroundStyle(warranty.isActive ? Palette.positive : Palette.textTertiary)
                                    }
                                }
                            }
                        }
                        .listRowBackground(Palette.canvas)
                    }
                    .onDelete { offsets in
                        for index in offsets { assets[index].isArchived = true }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Assets")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isPresentingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddAssetSheet()
        }
    }

    private func warrantyStatus(_ asset: Asset) -> (text: String, isActive: Bool)? {
        guard let expiry = asset.warrantyExpiryDate else { return nil }
        let isActive = expiry > .now
        let formatted = expiry.formatted(date: .abbreviated, time: .omitted)
        return (isActive ? "Under warranty until \(formatted)" : "Warranty ended \(formatted)", isActive)
    }
}

private struct AddAssetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var category: AssetCategory = .electronics
    @State private var hasPurchaseInfo = false
    @State private var purchaseDate = Date()
    @State private var purchasePriceText = ""
    @State private var hasWarranty = false
    @State private var warrantyExpiryDate = Date().addingTimeInterval(365 * 86400)

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Picker("Category", selection: $category) {
                    ForEach(AssetCategory.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                Section {
                    Toggle("Has purchase info", isOn: $hasPurchaseInfo)
                    if hasPurchaseInfo {
                        DatePicker("Purchased", selection: $purchaseDate, displayedComponents: .date)
                        TextField("Price", text: $purchasePriceText).keyboardType(.decimalPad)
                    }
                }
                Section {
                    Toggle("Has a warranty", isOn: $hasWarranty)
                    if hasWarranty {
                        DatePicker("Warranty ends", selection: $warrantyExpiryDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Add Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let asset = Asset(name: name, category: category)
        if hasPurchaseInfo {
            asset.purchaseDate = purchaseDate
            asset.purchasePrice = Decimal(string: purchasePriceText)
        }
        if hasWarranty {
            asset.warrantyExpiryDate = warrantyExpiryDate
            asset.warrantyAttribution = .userProvided()
        }
        modelContext.insert(asset)
        dismiss()
    }
}

struct AssetDetailView: View {
    let asset: Asset

    var body: some View {
        List {
            Section("Purchase") {
                if let date = asset.purchaseDate {
                    LabeledContent("Date", value: date.formatted(date: .abbreviated, time: .omitted))
                }
                if let price = asset.purchasePrice {
                    LabeledContent("Price", value: formatted(price, currencyCode: asset.currencyCode))
                }
                if asset.purchaseDate == nil && asset.purchasePrice == nil {
                    Text("No purchase info yet").foregroundStyle(Palette.textTertiary)
                }
            }
            Section("Warranty") {
                if let expiry = asset.warrantyExpiryDate {
                    LabeledContent("Expires", value: expiry.formatted(date: .abbreviated, time: .omitted))
                    if let attribution = asset.warrantyAttribution, attribution.confidence != .confirmed {
                        ConfidenceBadge(confidence: attribution.confidence)
                    }
                } else {
                    Text("No warranty tracked").foregroundStyle(Palette.textTertiary)
                }
            }
            if !asset.serviceHistory.isEmpty {
                Section("Service History") {
                    ForEach(asset.serviceHistory) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.summary)
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .font(AeriaFont.caption)
                                .foregroundStyle(Palette.textSecondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(asset.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatted(_ amount: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}
