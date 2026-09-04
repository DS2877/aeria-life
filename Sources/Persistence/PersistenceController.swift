import Foundation
import SwiftData

/// Builds the app's SwiftData `ModelContainer`.
///
/// **Local-first by design** (master prompt § 61–62): the container below is
/// local-only (`cloudKitDatabase: .none`). Aeria's core functionality must
/// work fully offline, and shipping local-only first means the very first
/// build a person runs on their Mac just works — no iCloud container, no
/// paid-account capability, no provisioning surprises.
///
/// To turn on CloudKit sync later:
/// 1. In Xcode: target *Aeria* → Signing & Capabilities → **+ Capability** →
///    add **iCloud**, tick **CloudKit**, and create/select a container
///    (e.g. `iCloud.com.aeria.life`).
/// 2. Add an `Aeria.entitlements` file (XcodeGen `info.properties` for the
///    `Aeria` target in `project.yml`, mirroring how Aeria+ does it) with
///    `com.apple.developer.icloud-services: [CloudKit]` and
///    `com.apple.developer.icloud-container-identifiers`.
/// 3. Change `cloudKitDatabase: .none` below to
///    `.private("iCloud.com.aeria.life")`.
/// 4. Every model's optional properties must stay optional and every
///    relationship must have a default — SwiftData+CloudKit requires this.
///    The schema in this file already follows that rule.
enum PersistenceController {
    /// A single shared container reused by the SwiftUI app *and* by App
    /// Intents (Sources/App/AppIntents) — App Intents are invoked by the
    /// system outside the normal app lifecycle (from Shortcuts/Siri, maybe
    /// without the app UI ever launching), so they can't reach
    /// `AppEnvironment`. Both call sites need the same on-disk store, or a
    /// task created via Shortcuts wouldn't show up in the app.
    static let shared = makeContainer()

    static let schema = Schema([
        Person.self,
        Organization.self,
        Place.self,
        TaskItem.self,
        Commitment.self,
        DocumentRecord.self,
        Asset.self,
        Subscription.self,
        PaymentItem.self,
        Goal.self,
        Habit.self,
        Moment.self,
        NoteItem.self,
        Routine.self,
        MemoryFact.self,
        LifeRelationship.self,
    ])

    /// The real, on-disk container the app runs against.
    static func makeContainer() -> ModelContainer {
        let configuration = ModelConfiguration(
            "AeriaStore",
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // A corrupt store should never hard-crash Aeria on launch — that
            // would turn one bad write into total data loss from the user's
            // point of view. Fall back to a fresh in-memory container so the
            // app still opens; the on-disk file is left untouched for
            // inspection/recovery rather than deleted automatically.
            assertionFailure("Falling back to an in-memory store — on-disk store failed to load: \(error)")
            let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
            // swiftlint:disable:next force_try
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }

    /// In-memory container for previews and unit tests — same schema, never
    /// touches disk.
    static func makePreviewContainer() -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: [configuration])
    }
}
