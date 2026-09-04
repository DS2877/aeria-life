import SwiftUI

/// Master prompt § 51–52: minimal setup, one unforgettable moment at the
/// end. Permissions are asked one at a time with context, never dumped on
/// one screen; the "magic moment" summary is built from whatever was
/// actually granted, never fabricated.
struct OnboardingView: View {
    @EnvironmentObject private var environment: AppEnvironment
    let onFinish: () -> Void

    private enum Step: Int, CaseIterable, Equatable {
        case welcome, focus, calendarPermission, reminderPermission, locationPermission, magicMoment
    }

    @State private var step: Step = .welcome
    @State private var selectedFocuses: Set<String> = []

    private let focusOptions = ["Organization", "Time", "Money", "Things I own", "Travel", "Goals", "Everything"]

    var body: some View {
        Group {
            switch step {
            case .welcome:
                welcomeStep
            case .focus:
                focusStep
            case .calendarPermission:
                PermissionStepView(
                    symbolName: "calendar",
                    title: "Connect your calendar",
                    explanation: "Aeria reads your calendar to build Today and find good times for things. Nothing leaves your device without your say-so.",
                    requestLabel: "Connect Calendar",
                    onRequest: { _ = await environment.calendarProvider.requestAccess() },
                    onSkip: { advance() },
                    onContinue: { advance() }
                )
            case .reminderPermission:
                PermissionStepView(
                    symbolName: "checklist",
                    title: "Connect Reminders",
                    explanation: "So Today and Loose Ends stay complete — Aeria won't create a second task list, just read the one you already have.",
                    requestLabel: "Connect Reminders",
                    onRequest: { _ = await environment.reminderProvider.requestAccess() },
                    onSkip: { advance() },
                    onContinue: { advance() }
                )
            case .locationPermission:
                PermissionStepView(
                    symbolName: "location",
                    title: "Add location context",
                    explanation: "Aeria uses this for things like travel time and local weather — never for tracking.",
                    requestLabel: "Enable Location",
                    onRequest: { environment.locationProvider.requestAccess() },
                    onSkip: { advance() },
                    onContinue: { advance() }
                )
            case .magicMoment:
                MagicMomentView(onFinish: onFinish)
            }
        }
        .animation(Motion.standard, value: step)
        .appThemeBackground()
    }

    private func advance() {
        if let next = Step(rawValue: step.rawValue + 1) {
            step = next
        } else {
            onFinish()
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: Metrics.spacingXL) {
            Spacer()
            Image("AeriaMark")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
            VStack(spacing: Metrics.spacingS) {
                Text("Welcome to Aeria")
                    .font(AeriaFont.display)
                    .foregroundStyle(Palette.textPrimary)
                Text("Aeria understands your life and helps you run it.")
                    .font(AeriaFont.body)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Button("Continue") { advance() }
                .buttonStyle(AeriaPrimaryButtonStyle())
                .frame(maxWidth: .infinity)
        }
        .padding(Metrics.spacingXL)
    }

    private var focusStep: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingL) {
            Spacer(minLength: Metrics.spacingXXL)
            Text("What should Aeria help with?")
                .font(AeriaFont.title)
                .foregroundStyle(Palette.textPrimary)
            Text("This just helps Aeria know what to pay attention to first — you can change it anytime.")
                .font(AeriaFont.subheadline)
                .foregroundStyle(Palette.textSecondary)

            FlowLayout(spacing: Metrics.spacingS) {
                ForEach(focusOptions, id: \.self) { option in
                    let isSelected = selectedFocuses.contains(option)
                    Button {
                        if isSelected { selectedFocuses.remove(option) } else { selectedFocuses.insert(option) }
                    } label: {
                        Text(option)
                            .font(AeriaFont.body)
                            .padding(.horizontal, Metrics.spacingM)
                            .padding(.vertical, Metrics.spacingS)
                            .background(isSelected ? Palette.accent : Palette.surface)
                            .foregroundStyle(isSelected ? Palette.canvas : Palette.textPrimary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
            Button("Continue") { advance() }
                .buttonStyle(AeriaPrimaryButtonStyle())
                .frame(maxWidth: .infinity)
        }
        .padding(Metrics.spacingXL)
    }
}

/// Minimal wrapping "chip" layout for the focus-selection step.
private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var origin = CGPoint.zero
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x + size.width > maxWidth, origin.x > 0 {
                origin.x = 0
                origin.y += rowHeight + spacing
                totalHeight += rowHeight + spacing
                rowHeight = 0
            }
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x + size.width > bounds.maxX, origin.x > bounds.minX {
                origin.x = bounds.minX
                origin.y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: origin, proposal: .unspecified)
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
