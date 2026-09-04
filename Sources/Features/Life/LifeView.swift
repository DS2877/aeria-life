import SwiftData
import SwiftUI

/// Master prompt § 74 Life Inbox + § 73 Loose Ends, joined into one screen:
/// capture anything with zero friction, and see what's been sitting
/// unsorted or unfinished. This is "LIFE" in the four-tab structure
/// (master prompt § 36).
struct LifeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var captureText: String = ""

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

    private var captureBar: some View {
        HStack(spacing: Metrics.spacingS) {
            TextField("Capture anything — a thought, a task, a link…", text: $captureText, axis: .vertical)
                .font(AeriaFont.body)
                .padding(.horizontal, Metrics.spacingM)
                .padding(.vertical, Metrics.spacingS + 2)
                .background(Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.controlCornerRadius, style: .continuous))
            Button {
                capture()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(captureText.trimmingCharacters(in: .whitespaces).isEmpty ? Palette.textTertiary : Palette.accent)
            }
            .disabled(captureText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
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
        case .dismiss:
            break
        }
        note.isProcessed = true
        note.updatedAt = .now
    }
}

enum InboxFileKind {
    case task, commitment, dismiss
}

private struct InboxNoteRow: View {
    let note: NoteItem
    let onFile: (InboxFileKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingS) {
            Text(note.rawText)
                .font(AeriaFont.body)
                .foregroundStyle(Palette.textPrimary)
            HStack(spacing: Metrics.spacingS) {
                filingButton("Task", systemImage: "checkmark.circle") { onFile(.task) }
                filingButton("Promise", systemImage: "text.bubble") { onFile(.commitment) }
                filingButton("Dismiss", systemImage: "xmark") { onFile(.dismiss) }
                Spacer()
            }
        }
    }

    private func filingButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AeriaFont.caption)
        }
        .buttonStyle(.bordered)
        .tint(Palette.textSecondary)
    }
}
