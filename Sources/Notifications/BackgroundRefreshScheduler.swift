import BackgroundTasks
import Foundation
import SwiftData

/// Master prompt § 29 "Proactive Aeria": periodically re-runs Loose Ends in
/// the background and — only if `InterruptionBudget` says the interruption
/// is worth it — fires a single local notification. This is the one place
/// in the app that can send a notification with nobody having tapped
/// anything; every other notification-adjacent path (Reminders, Calendar)
/// is Apple's own.
///
/// `register()` must be called once, early (before the app finishes
/// launching) — see `AeriaApp.init()`. Simulator testing needs an LLDB
/// command, not a real 2-hour wait; see docs/ARCHITECTURE.md.
enum BackgroundRefreshScheduler {
    static let taskIdentifier = "com.aeria.life.refresh"

    private static let lastNotifiedAtKey = "aeria.notifications.lastSentAt"
    private static let notifiedTodayCountKey = "aeria.notifications.countForDay"
    private static let notifiedTodayDateKey = "aeria.notifications.countDate"

    /// `BGTaskScheduler.register` crashes immediately — not a thrown Swift
    /// error, an uncatchable one — if `taskIdentifier` isn't listed in
    /// Info.plist's `BGTaskSchedulerPermittedIdentifiers`, and this runs as
    /// the very first thing the app does (`AeriaApp.init()`). Checking the
    /// identifier is actually declared before calling register turns a
    /// possible instant launch crash into, at worst, background refresh
    /// silently not working — never something that blocks the app opening.
    static func register() {
        print("BackgroundRefreshScheduler.register(): checking Info.plist for '\(taskIdentifier)'…")
        let permitted = Bundle.main.object(forInfoDictionaryKey: "BGTaskSchedulerPermittedIdentifiers") as? [String] ?? []
        guard permitted.contains(taskIdentifier) else {
            print("BackgroundRefreshScheduler.register(): '\(taskIdentifier)' is NOT in BGTaskSchedulerPermittedIdentifiers (found \(permitted)) — skipping registration so this can't crash launch.")
            return
        }
        _ = BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handle(refreshTask)
        }
        print("BackgroundRefreshScheduler.register(): registered successfully.")
    }

    static func scheduleNext() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        // A "check every couple of hours" cadence — frequent enough that a
        // renewal or a kept-too-long loose end gets noticed same-day,
        // infrequent enough to respect the interruption budget doing the
        // real filtering downstream.
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(_ task: BGAppRefreshTask) {
        // Always schedule the follow-up first — if this run gets cut off,
        // the chain shouldn't die with it.
        scheduleNext()

        let work = Task {
            await performCheck()
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = {
            work.cancel()
        }
    }

    @MainActor
    private static func performCheck() async {
        let context = PersistenceController.shared.mainContext
        let commitments = (try? context.fetch(FetchDescriptor<Commitment>())) ?? []
        let documents = (try? context.fetch(FetchDescriptor<DocumentRecord>())) ?? []
        let payments = (try? context.fetch(FetchDescriptor<PaymentItem>())) ?? []
        let notes = (try? context.fetch(FetchDescriptor<NoteItem>())) ?? []

        let looseEnds = LooseEndsScanner.scan(
            commitments: commitments.filter { !$0.isArchived },
            documents: documents.filter { !$0.isArchived },
            upcomingPayments: payments.filter { !$0.isArchived },
            unprocessedNotes: notes
        )
        guard let top = looseEnds.first else { return }

        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: .now)
        let storedDay = defaults.object(forKey: notifiedTodayDateKey) as? Date
        let sentToday = (storedDay.map { Calendar.current.isDate($0, inSameDayAs: today) } ?? false)
            ? defaults.integer(forKey: notifiedTodayCountKey)
            : 0
        let lastSentAt = defaults.object(forKey: lastNotifiedAtKey) as? Date

        // A loose end existing at all clears the bar most of the time —
        // the budget (max/day, spacing) is what actually keeps this rare.
        guard InterruptionDecision.shouldNotify(score: 0.7, sentToday: sentToday, lastSentAt: lastSentAt) else { return }

        let scheduler = NotificationScheduler()
        guard await scheduler.requestAuthorization() else { return }
        scheduler.scheduleNearImmediate(title: "Worth knowing", body: top.summary, identifier: "looseEnd-\(top.id)")

        defaults.set(Date(), forKey: lastNotifiedAtKey)
        defaults.set(today, forKey: notifiedTodayDateKey)
        defaults.set(sentToday + 1, forKey: notifiedTodayCountKey)
    }
}
