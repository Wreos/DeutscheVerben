import Foundation

/// Deterministic SM-2 adaptation, reconstructed from immutable answer history.
/// Product policy: one independent scheduling result/day, no promotions before due,
/// assistance excluded, failures reset; no probability-of-recall or CEFR claim.
public struct ReviewSchedule: Equatable, Sendable {
    public init() {}
    public var successes = 0
    public var interval = 0
    public var ease = 2.5
    public var due: String?
    public var lastReview: String?
    public var lastGap = 0
    public var failed = false
    public var lastExact = false
    public var stage: Int {
        successes == 0 ? 0 : successes < 3 ? 1 : successes >= 4 && lastGap >= 14 && lastExact ? 3 : 2
    }
    public var fraction: Double { successes == 0 ? 0 : stage == 3 ? 1 : Double(min(successes, 3)) / 4 }
    public var stageTitle: String {
        failed ? "Повторить" : ["Не изучен", "В изучении", "Близко к закреплению", "Закреплён"][stage]
    }
    public func isDue(on day: String) -> Bool { due.map { $0 <= day } ?? false }
}

public enum SpacedRepetition {
    public static func parse(_ value: String) -> Date? {
        let f = ISO8601DateFormatter()
        if let date = f.date(from: value) { return date }
        f.formatOptions.insert(.withFractionalSeconds)
        return f.date(from: value)
    }
    private static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return c
    }
    public static func adding(days: Int, to date: Date) -> String {
        Training.day(calendar.date(byAdding: .day, value: days, to: date)!)
    }
    public static func schedules(_ history: [Attempt]) -> [String: ReviewSchedule] {
        var schedules: [String: ReviewSchedule] = [:]
        var counted: Set<String> = []
        let sorted = history.enumerated().sorted {
            let a = parse($0.element.at) ?? .distantPast
            let b = parse($1.element.at) ?? .distantPast
            return a == b ? $0.offset < $1.offset : a < b
        }
        for (_, attempt) in sorted where !attempt.assisted {
            guard let date = parse(attempt.at) else { continue }
            let day = Training.day(date)
            let key = attempt.id + "|" + day
            guard counted.insert(key).inserted else { continue }
            var s = schedules[attempt.id] ?? ReviewSchedule()
            if attempt.result.passed, let due = s.due, day < due { continue }
            if let previous = s.lastReview, let prior = parse(previous) {
                s.lastGap =
                    calendar.dateComponents(
                        [.day], from: calendar.startOfDay(for: prior), to: calendar.startOfDay(for: date)
                    ).day ?? 0
            }
            let quality = attempt.result.exact ? 5.0 : attempt.result.passed ? 4.0 : 1.0
            if attempt.result.passed {
                s.successes += 1
                s.interval =
                    s.successes == 1 ? 1 : s.successes == 2 ? 6 : min(365, Int(ceil(Double(s.interval) * s.ease)))
            } else {
                s.successes = 0
                s.interval = 1
            }
            s.ease = max(1.3, s.ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
            s.due = adding(days: s.interval, to: date)
            s.lastReview = attempt.at
            s.failed = !attempt.result.passed
            s.lastExact = attempt.result.exact
            schedules[attempt.id] = s
        }
        return schedules
    }
    public static func queue(
        verbs: [Verb], state: TrainerState, now: Date, level: String, filter: String, shuffled: Bool = true,
        includeExposed: Bool = false
    ) -> [String] {
        let schedules = schedules(state.history)
        let today = Training.day(now)
        let eligible = verbs.filter { verb in
            guard level == "all" || verb.level == level else { return false }
            if filter == "mistakes" { return state.progress[verb.id]?.lastPassed == false }
            // Manual mistakes practice is always available; normal practice respects spacing.
            guard includeExposed || state.exposures?[verb.id] != today else { return false }
            return schedules[verb.id]?.due == nil || schedules[verb.id]!.isDue(on: today)
        }
        let pool = shuffled ? eligible.shuffled() : eligible
        func rank(_ v: Verb) -> Int {
            if state.progress[v.id]?.lastPassed == false { return 0 }
            return schedules[v.id]?.due != nil ? 1 : 2
        }
        return pool.enumerated().sorted {
            let a = $0.element
            let b = $1.element
            if rank(a) != rank(b) { return rank(a) < rank(b) }
            let ad = schedules[a.id]?.due ?? "9999"
            let bd = schedules[b.id]?.due ?? "9999"
            return ad == bd ? $0.offset < $1.offset : ad < bd
        }.prefix(10).map(\.element.id)
    }
}
