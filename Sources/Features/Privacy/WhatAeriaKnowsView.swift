import SwiftData
import SwiftUI

/// Master prompt § 10, § 34: a direct, unfiltered view over `MemoryFact` —
/// inspect, correct, forget, or disable a whole category. Nothing here is a
/// summary that could drift from what's actually stored.
struct WhatAeriaKnowsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MemoryFact.createdAt, order: .reverse) private var facts: [MemoryFact]

    private var grouped: [(kind: MemoryKind, facts: [MemoryFact])] {
        MemoryKind.allCases.compactMap { kind in
            let matching = facts.filter { $0.kind == kind }
            return matching.isEmpty ? nil : (kind, matching)
        }
    }

    var body: some View {
        Group {
            if facts.isEmpty {
                EmptyStateView(
                    symbolName: "brain",
                    title: "Aeria doesn't know anything about you yet",
                    message: "Tell it something in Ask Aeria — \"Remember that…\" — and it'll show up here."
                )
                .padding(.top, Metrics.spacingXXL)
            } else {
                List {
                    ForEach(grouped, id: \.kind) { group in
                        Section(group.kind.displayName) {
                            ForEach(group.facts) { fact in
                                factRow(fact)
                            }
                            .onDelete { offsets in
                                for index in offsets { modelContext.delete(group.facts[index]) }
                            }
                        }
                        .listRowBackground(Palette.surface)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("What Aeria Knows")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func factRow(_ fact: MemoryFact) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(fact.content)
                    .foregroundStyle(fact.isEnabled ? Palette.textPrimary : Palette.textTertiary)
                Text(fact.category.capitalized)
                    .font(AeriaFont.caption)
                    .foregroundStyle(Palette.textTertiary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { fact.isEnabled },
                set: { fact.isEnabled = $0; fact.updatedAt = .now }
            ))
            .labelsHidden()
        }
    }
}
