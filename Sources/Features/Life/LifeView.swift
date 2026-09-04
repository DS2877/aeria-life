import SwiftData
import SwiftUI

/// Master prompt § 74 Life Inbox + § 73 Loose Ends, joined into one screen:
/// capture anything with zero friction, and see what's been sitting
/// unsorted or unfinished. This is "LIFE" in the four-tab structure
/// (master prompt § 36).
struct LifeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var captureText: String = ""
    @StateObject private var voiceCapture = VoiceCaptureRecorder()

    @Query(sort: \NoteItem.createdAt, order: .reverse) private var allNotes: [NoteItem]
    @Query(filter: #Predicate<Commitment> { !$0.isArchived }) private var commitments: [Commitment]
    @Query(filter: #Predicate<DocumentRecord> { !$0.isArchived }) private var documents: [DocumentRecord]
    @Query(filter: #Predicate<PaymentItem> { !$0.isArchived }) private var payments: [PaymentItem]

    private var unsortedNotes: [NoteItem] { allNotes.filter { !$0.isProcessed } }

    private var looseEnds: [LooseEnd] {
        LooseEndsScanner.scan(
            commitments: commitments,
            documents: documents,
            upcomingPayments: payments,
            unprocessedNotes: allNotes
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.spacingXL) {
                captureBar

                NavigationLink {
                    LifeSearchView()
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search your life")
                        Spacer()
                    }
                    .font(AeriaFont.body)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, Metrics.spacingM)
                    .padding(.vertical, Metrics.spacingS + 2)
                    .background(Palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.controlCornerRadius, style: .continuous))
                }

                NavigationLink {
                    LooseEndsView()
                } label: {
                    SurfaceCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Check my life")
                                    .font(AeriaFont.headline)
                                    .foregroundStyle(Palette.textPrimary)
                                Text(looseEnds.isEmpty
                                     ? "Nothing looks unfinished right now."
                                     : "\(looseEnds.count) thing\(looseEnds.count == 1 ? "" : "s") worth a look.")
                                    .font(AeriaFont.subheadline)
                                    .foregroundStyle(Palette.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Palette.textTertiary)
                        }
                    }
                }
                .buttonStyle(.plain)

                lifeSectionsGrid

                if !unsortedNotes.isEmpty {
                    VStack(alignment: .leading, spacing: Metrics.spacingM) {
                        SectionHeader(title: "Inbox")
                        SurfaceCard {
                            VStack(alignment: .leading, spacing: Metrics.spacingM) {
                                ForEach(Array(unsortedNotes.enumerated()), id: \.element.id) { index, note in
                                    if index > 0 { Divider().overlay(Palette.hairline) }
                                    InboxNoteRow(note: note, onFile: { file(note, as: $0) })
                                }
                            }
                        }
                    }
                } else {
                    EmptyStateView(
                        symbolName: "tray",
                        title: "Your inbox is clear",
                        message: "Capture a thought above — Aeria will help you sort it later."
                    )
                }
            }
            .padding(Metrics.screenPadding)
        }
        .navigationTitle("Life")
    }

    private struct LifeSection: Identifiable {
        let id: String
        let title: String
        let symbolName: String
    }

    private static let sections: [LifeSection] = [
        LifeSection(id: "promises", title: "Promises", symbolName: "text.bubble"),
        LifeSection(id: "goals", title: "Goals", symbolName: "target"),
        LifeSection(id: "habits", title: "Habits", symbolName: "repeat"),
        LifeSection(id: "moments", title: "Moments", symbolName: "sparkles"),
        LifeSection(id: "people", title: "People", symbolName: "person"),
        LifeSection(id: "places", title: "Places", symbolName: "mappin.circle"),
        LifeSection(id: "decisions", title: "Decisions", symbolName: "arrow.left.arrow.right"),
        LifeSection(id: "simulator", title: "What If", symbolName: "wand.and.stars"),
        LifeSection(id: "routines", title: "Routines", symbolName: "repeat.circle"),
    ]

    private var lifeSectionsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: Metrics.spacingM)], spacing: Metrics.spacingM) {
            ForEach(Self.sections) { section in
                NavigationLink {
                    destination(for: section.id)
                } label: {
                    VStack(spacing: Metrics.spacingS) {
                        Image(systemName: section.symbolName)
                            .font(.system(size: 18))
                            .foregroundStyle(Palette.accent)
                        Text(section.title)
                            .font(AeriaFont.caption)
                            .foregroundStyle(Palette.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Metrics.spacingM)
                    .background(Palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func destination(for sectionID: String) -> some View {
        switch sectionID {
        case "promises": PromisesView()
        case "goals": GoalsListView()
        case "habits": HabitsListView()
        case "moments": MomentsListView()
        case "people": PeopleListView()
        case "places": PlacesListView()
        case "decisions": DecisionsListView()
        case "simulator": LifeSimulatorView()
        case "routines": RoutinesListView()
        default: EmptyView()
        }
    }

    private var captureBar: some View {
        HStack(spacing: Metrics.spacingS) {
            TextField("Capture anything — a thought, a task, a link…", text: $captureText, axis: .vertical)
                .font(AeriaFont.body)
                .padding(.horizontal, Metrics.spacingM)
                .padding(.vertical, Metrics.spacingS + 2)
                .background(Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.controlCornerRadius, style: .continuous))
                .disabled(voiceCapture.isRecording)

            Button {
                Task { await toggleVoiceCapture() }
            } label: {
                Image(systemName: voiceCapture.isRecording ? "mic.fill" : "mic")
                    .font(.system(size: 20))
                    .foregroundStyle(voiceCapture.isRecording ? Palette.critical : Palette.textSecondary)
                    .frame(width: 32, height: 32)
            }

            Button {
                capture()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(captureText.trimmingCharacters(in: .whitespaces).isEmpty ? Palette.textTertiary : Palette.accent)
            }
            .disabled(captureText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .onChange(of: voiceCapture.transcript) { _, newValue in
            if voiceCapture.isRecording { captureText = newValue }
        }
    }

    private func toggleVoiceCapture() async {
        if voiceCapture.isRecording {
            voiceCapture.stopRecording()
            return
        }
        guard await voiceCapture.requestAuthorization() else { return }
        try? voiceCapture.startRecording()
    }

    private func capture() {
        let text = captureText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        modelContext.insert(NoteItem(rawText: text, sourceKind: .text))
        captureText = ""
    }

    private func file(_ note: NoteItem, as kind: InboxFileKind) {
        switch kind {
        case .task:
            let task = TaskItem(title: note.rawText, provenance: .userProvided)
            modelContext.insert(task)
            note.resultingEntityType = .task
            note.resultingEntityID = task.id.uuidString
        case .commitment:
            let commitment = Commitment(text: note.rawText, provenance: .userProvided)
            modelContext.insert(commitment)
            note.resultingEntityType = .commitment
            note.resultingEntityID = commitment.id.uuidString
        case .document:
            let title = note.rawText.trimmingCharacters(in: .whitespacesAndNewlines)
            let document = DocumentRecord(
                title: title.isEmpty ? "Shared Document" : String(title.prefix(60)),
                category: .document,
                storageFileName: note.attachmentFileName ?? "",
                provenance: .imported
            )
            document.notes = note.rawText
            modelContext.insert(document)
            note.resultingEntityType = .document
            note.resultingEntityID = document.id.uuidString
        case .dismiss:
            break
        }
        note.isProcessed = true
        note.updatedAt = .now
    }
}

enum InboxFileKind {
    case task, commitment, document, dismiss
}

private struct InboxNoteRow: View {
    let note: NoteItem
    let onFile: (InboxFileKind) -> Void

    private var looksLikeCommitment: Bool {
        CommitmentExtractor.looksLikeCommitment(note.rawText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingS) {
            Text(note.rawText)
                .font(AeriaFont.body)
                .foregroundStyle(Palette.textPrimary)
            if note.sourceKind == .shareSheet {
                Label("Shared into Aeria", systemImage: "square.and.arrow.up")
                    .font(AeriaFont.caption)
                    .foregroundStyle(Palette.textTertiary)
            }
            if looksLikeCommitment {
                Label("Sounds like a promise", systemImage: "sparkle")
                    .font(AeriaFont.caption)
                    .foregroundStyle(Palette.accent)
            }
            HStack(spacing: Metrics.spacingS) {
                filingButton("Task", systemImage: "checkmark.circle") { onFile(.task) }
                filingButton("Promise", systemImage: "text.bubble", isHighlighted: looksLikeCommitment) { onFile(.commitment) }
                if note.attachmentFileName != nil {
                    filingButton("Vault", systemImage: "lock.shield") { onFile(.document) }
                }
                filingButton("Dismiss", systemImage: "xmark") { onFile(.dismiss) }
                Spacer()
            }
        }
    }

    private func filingButton(_ title: String, systemImage: String, isHighlighted: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AeriaFont.caption)
        }
        .buttonStyle(.bordered)
        .tint(isHighlighted ? Palette.accent : Palette.textSecondary)
    }
}
