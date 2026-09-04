import Foundation

/// Master prompt § 28 Predictions / § 20 Smart Calendar: "identify
/// conflicts." Two timed events that overlap are worth surfacing —
/// deliberately narrow in scope (no fuzzy "your day looks busy" heuristics
/// here, that's `PriorityEngine`'s "busy day" branch in `TodayView`); this
/// only ever reports genuine time overlaps.
struct SchedulingConflict {
    let id: String
    let firstTitle: String
    let secondTitle: String
    let overlapStart: Date
}

enum SchedulingConflictScanner {
    static func findConflicts(in events: [CalendarEvent]) -> [SchedulingConflict] {
        let timed = events.filter { !$0.isAllDay }.sorted { $0.startDate < $1.startDate }
        guard timed.count > 1 else { return [] }

        var conflicts: [SchedulingConflict] = []
        for i in timed.indices {
            for j in timed.index(after: i)..<timed.endIndex {
                guard timed[j].startDate < timed[i].endDate else { break }
                conflicts.append(SchedulingConflict(
                    id: "\(timed[i].id)-\(timed[j].id)",
                    firstTitle: timed[i].title,
                    secondTitle: timed[j].title,
                    overlapStart: timed[j].startDate
                ))
            }
        }
        return conflicts
    }
}
