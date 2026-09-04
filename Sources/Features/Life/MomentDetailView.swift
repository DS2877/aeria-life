import SwiftData
import SwiftUI

/// Linking a task or document here writes a `LifeRelationship` edge
/// (`task --relatedTo--> moment`) rather than a foreign key on either
/// model — see docs/ARCHITECTURE.md § The Life Graph. This is the one
/// screen in the app where that graph is directly visible.
struct MomentDetailView: View {
    let moment: Moment

    @Environment(\.modelContext) private var modelContext
    @Query private var relationships: [LifeRelationship]
    @Query(filter: #Predicate<TaskItem> { !$0.isArchived }) private var allTasks: [TaskItem]
    @Query(filter: #Predicate<DocumentRecord> { !$0.isArchived }) private var allDocuments: [DocumentRecord]

    @State private var isPickingTask = false
    @State private var isPickingDocument = false

    private var momentID: String { moment.id.uuidString }

    private var linkedTaskIDs: Set<String> {
        Set(relationships
            .filter { $0.objectID == momentID && $0.objectType == .moment && $0.subjectType == .task }
            .map(\.subjectID))
    }

    private var linkedDocumentIDs: Set<String> {
        Set(relationships
            .filter { $0.objectID == momentID && $0.objectType == .moment && $0.subjectType == .document }
            .map(\.subjectID))
    }

    private var linkedTasks: [TaskItem] { allTasks.filter { linkedTaskIDs.contains($0.id.uuidString) } }
    private var linkedDocuments: [DocumentRecord] { allDocuments.filter { linkedDocumentIDs.contains($0.id.uuidString) } }

    var body: some View {
        List {
            if !moment.summary.isEmpty {
                Section {
                    Text(moment.summary).foregroundStyle(Palette.textSecondary)
                }
                .listRowBackground(Palette.canvas)
            }

            Section("Tasks") {
                ForEach(linkedTasks) { task in
                    Text(task.title).foregroundStyle(Palette.textPrimary)
                }
                Button("Link a task") { isPickingTask = true }
                    .foregroundStyle(Palette.accent)
            }
            .listRowBackground(Palette.canvas)

            Section("Documents") {
                ForEach(linkedDocuments) { document in
                    Text(document.title).foregroundStyle(Palette.textPrimary)
                }
                Button("Link a document") { isPickingDocument = true }
                    .foregroundStyle(Palette.accent)
            }
            .listRowBackground(Palette.canvas)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationTitle(moment.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPickingTask) {
            EntityPickerSheet(
                title: "Link a Task",
                items: allTasks.filter { !linkedTaskIDs.contains($0.id.uuidString) },
                label: { $0.title },
                onPick: { link(subjectID: $0.id.uuidString, subjectType: .task) }
            )
        }
        .sheet(isPresented: $isPickingDocument) {
            EntityPickerSheet(
                title: "Link a Document",
                items: allDocuments.filter { !linkedDocumentIDs.contains($0.id.uuidString) },
                label: { $0.title },
                onPick: { link(subjectID: $0.id.uuidString, subjectType: .document) }
            )
        }
    }

    private func link(subjectID: String, subjectType: LifeEntityType) {
        modelContext.insert(LifeRelationship(
            subjectID: subjectID,
            subjectType: subjectType,
            predicate: .relatedTo,
            objectID: momentID,
            objectType: .moment,
            provenance: .userProvided
        ))
    }
}
