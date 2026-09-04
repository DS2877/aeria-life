import SwiftData
import SwiftUI

/// Master prompt § 8, § 66: one universal entry point, phrased as answers
/// and actions rather than a chat transcript.
struct AskAeriaView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = AskAeriaViewModel()
    @FocusState private var isInputFocused: Bool

    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]

    private let suggestions = [
        "What's next?",
        "Find me a free evening",
        "What am I forgetting?",
        "How much are my subscriptions costing me?",
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.spacingL) {
                if let response = viewModel.response {
                    AeriaResponseCard(
                        response: response,
                        onConfirmAction: handleAction,
                        onDismissAction: { viewModel.clear() }
                    )
                } else if viewModel.isThinking {
                    HStack(spacing: Metrics.spacingS) {
                        ProgressView().tint(Palette.accent)
                        Text("Thinking…").foregroundStyle(Palette.textSecondary)
                    }
                    .padding(.top, Metrics.spacingXXL)
                } else {
                    startState
                }
            }
            .padding(Metrics.screenPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaInset(edge: .bottom) {
            inputBar
        }
        .navigationTitle("Ask Aeria")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var startState: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingM) {
            Image(systemName: "sparkle")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Palette.accent)
                .padding(.top, Metrics.spacingXXL)
            Text("What should Aeria help with?")
                .font(AeriaFont.title)
                .foregroundStyle(Palette.textPrimary)

            VStack(alignment: .leading, spacing: Metrics.spacingS) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        viewModel.inputText = suggestion
                        Task { await ask() }
                    } label: {
                        Text(suggestion)
                            .font(AeriaFont.body)
                            .foregroundStyle(Palette.textPrimary)
                            .padding(.horizontal, Metrics.spacingM)
                            .padding(.vertical, Metrics.spacingS)
                            .background(Palette.surface)
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(Palette.hairline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: Metrics.spacingS) {
            TextField("Ask Aeria anything about your life…", text: $viewModel.inputText, axis: .vertical)
                .focused($isInputFocused)
                .font(AeriaFont.body)
                .foregroundStyle(Palette.textPrimary)
                .padding(.horizontal, Metrics.spacingM)
                .padding(.vertical, Metrics.spacingS + 2)
                .onSubmit { Task { await ask() } }

            Button {
                Task { await ask() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(viewModel.inputText.isEmpty ? Palette.textTertiary : Palette.accent)
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, Metrics.spacingS)
        .background(GlassPanel { Color.clear }.padding(.horizontal, -Metrics.spacingS))
        .padding(Metrics.screenPadding)
    }

    private func ask() async {
        isInputFocused = false
        let context = buildContext()
        await viewModel.ask(environment: environment, context: context)
    }

    private func buildContext() -> AeriaContextBundle {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        let events = environment.calendarProvider.isAuthorized
            ? environment.calendarProvider.events(from: now, to: endOfDay)
            : []
        let freeIntervals = environment.calendarProvider.isAuthorized
            ? environment.calendarProvider.freeIntervals(from: now, to: endOfDay, minimumDuration: 30 * 60)
            : []
        let monthlyTotal = subscriptions
            .filter { $0.isActive }
            .reduce(Decimal(0)) { $0 + $1.monthlyEquivalentCost }

        return AeriaContextBundle(
            now: now,
            currentMode: environment.manualLifeModeOverride ?? .home,
            todaysEvents: events,
            openTaskTitles: [],
            relevantMemories: [],
            freeIntervals: freeIntervals,
            subscriptionMonthlyTotal: monthlyTotal == 0 ? nil : monthlyTotal,
            subscriptionCurrencyCode: subscriptions.first?.currencyCode ?? Locale.current.currency?.identifier ?? "USD"
        )
    }

    private func handleAction(_ action: AeriaSuggestedAction) {
        switch action.kind {
        case .createReminder:
            try? environment.reminderProvider.createReminder(title: action.title, dueDate: action.proposedDate)
        case .createTask:
            modelContext.insert(TaskItem(title: action.title, dueDate: action.proposedDate, provenance: .userProvided))
        case .createEvent, .none:
            break
        }
        viewModel.clear()
    }
}
