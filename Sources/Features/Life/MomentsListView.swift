import SwiftData
import SwiftUI

/// Master prompt § 24: a temporary context cluster — a trip, a move, a
/// renovation. This screen is also the one place in the app that visibly
/// exercises the Life Graph (`LifeRelationship`): linking a task or
/// document to a Moment writes a `.relatedTo` edge rather than a foreign key
/// on either model, exactly as designed in docs/ARCHITECTURE.md.
struct MomentsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Moment> { !$0.isArchived }, sort: \Moment.createdAt, order: .reverse) private var moments: [Moment]
    @State private var isPresentingAdd = false

    var body: some View {
        Group {
            if moments.isEmpty {
                EmptyStateView(symbolName: "sparkles", title: "No moments yet", message: "A trip, a move, a renovation — Aeria gathers everything related in one place.")
                    .padding(.top, Metrics.spacingXXL)
            } else {
                List {
                    ForEach(moments) { moment in
                        NavigationLink {
                            MomentDetailView(moment: moment)
                        } label: {
                            HStack {
                                Image(systemName: moment.category.symbolName).foregroundStyle(Palette.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(moment.title).foregroundStyle(Palette.textPrimary)
                                    if let start = moment.startDate {
                                        Text(dateRange(start: start, end: moment.endDate))
                                            .font(AeriaFont.caption)
                                            .foregroundStyle(Palette.textSecondary)
                                    }
                                }
                            }
                        }
                        .listRowBackground(Palette.canvas)
                    }
                    .onDelete { offsets in
                        for index in offsets { moments[index].isArchived = true }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Moments")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isPresentingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddMomentSheet()
        }
    }

    private func dateRange(start: Date, end: Date?) -> String {
        guard let end else { return start.formatted(date: .abbreviated, time: .omitted) }
        return "\(start.formatted(date: .abbreviated, time: .omitted)) – \(end.formatted(date: .abbreviated, time: .omitted))"
    }
}

private struct AddMomentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var category: MomentCategory = .trip
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3 * 86400)
    @State private var hasDates = true

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                Picker("Category", selection: $category) {
                    ForEach(MomentCategory.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                Toggle("Has dates", isOn: $hasDates)
                if hasDates {
                    DatePicker("Starts", selection: $startDate, displayedComponents: .date)
                    DatePicker("Ends", selection: $endDate, displayedComponents: .date)
                }
            }
            .navigationTitle("New Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        modelContext.insert(Moment(
                            title: title,
                            category: category,
                            startDate: hasDates ? startDate : nil,
                            endDate: hasDates ? endDate : nil
                        ))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
