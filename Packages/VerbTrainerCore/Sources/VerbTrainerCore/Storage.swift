import Foundation

public enum StateCodec {
    public static func encode(_ state: TrainerState) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(state)
    }
    public static func decode(_ data: Data, verbs: [Verb]) throws -> TrainerState {
        guard data.count <= 20_000_000 else { throw TrainerError.invalid(L10n.text("File exceeds 20 MB")) }
        let state = try JSONDecoder().decode(TrainerState.self, from: data)
        try validate(state, verbs: verbs)
        return state
    }
    public static func validate(_ state: TrainerState, verbs: [Verb]) throws {
        let ids = Set(verbs.map(\.id))
        let levels = ["all", "A1", "A2", "B1"]
        func require(_ value: Bool, _ message: String) throws { if !value { throw TrainerError.invalid(message) } }
        try require(state.version == 1 && (state.nativeVersion ?? 1) == 1, L10n.text("Unknown file version"))
        try require(levels.contains(state.level), L10n.text("Unknown group"))
        func dateValid(_ s: String) -> Bool {
            let f = ISO8601DateFormatter()
            if f.date(from: s) != nil { return true }
            f.formatOptions.insert(.withFractionalSeconds)
            return f.date(from: s) != nil
        }
        func checkAttempt(_ a: Attempt) throws {
            try require(
                ids.contains(a.id) && !a.sessionId.isEmpty && dateValid(a.at)
                    && ["answer", "unknown", "reveal"].contains(a.kind), L10n.text("Invalid answer record"))
            try require(a.answers.hasConsistentPerfect, L10n.text("Combined answer does not match its components"))
            guard let verb = verbs.first(where: { $0.id == a.id }) else { return }
            try require(
                a.result == Grading.grade(verb, a.answers),
                L10n.format("Grade does not match the original answer: %@", String(describing: a.id)))
            try require(a.kind != "reveal" || a.assisted, L10n.text("A revealed answer must be marked as assisted"))
        }
        for (id, p) in state.progress {
            try require(
                ids.contains(id) && p.attempts >= 0 && p.passed >= 0 && p.passed <= p.attempts && p.assisted >= 0
                    && p.attempts <= 10_000_000 && p.assisted <= 10_000_000, L10n.text("Invalid progress"))
            if let at = p.lastAt { try require(dateValid(at), L10n.text("Invalid progress date")) }
        }
        try require(Set(state.history.map(\.key)).count == state.history.count, L10n.text("Duplicate history records"))
        for a in state.history { try checkAttempt(a) }
        let history = historyByKey(state.history)
        let sessions = (state.paused ?? []) + [state.session].compactMap { $0 }
        try require(Set(sessions.map(\.id)).count == sessions.count, L10n.text("Duplicate sessions"))
        for s in sessions {
            try require(
                !s.id.isEmpty && levels.contains(s.level) && ["all", "mistakes"].contains(s.filter)
                    && s.queue.count <= 10 && Set(s.queue).count == s.queue.count && s.queue.allSatisfy(ids.contains)
                    && s.index >= 0 && s.index <= s.queue.count
                    && (s.results.count == s.index || (s.index < s.queue.count && s.results.count == s.index + 1)),
                L10n.text("Invalid session"))
            try require(
                ["", "haben", "sein"].contains(s.draft.aux) && s.draft.hasConsistentPerfect,
                L10n.text("Invalid draft"))
            for (i, a) in s.results.enumerated() {
                try checkAttempt(a)
                try require(
                    a.id == s.queue[i] && a.sessionId == s.id && history[a.key] == a,
                    L10n.text("Session does not match history"))
            }
            if let checked = s.checked {
                try require(s.draft == checked.answers, L10n.text("Original answer does not match the draft"))
            }
        }
        for (id, day) in state.exposures ?? [:] {
            try require(
                ids.contains(id) && day.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil,
                L10n.text("Invalid assistance date"))
        }
        try require(
            Set((state.helpEvents ?? []).map(\.id)).count == (state.helpEvents ?? []).count,
            L10n.text("Duplicate assistance events"))
        for e in state.helpEvents ?? [] {
            try require(dateValid(e.at) && e.verbIDs.allSatisfy(ids.contains), L10n.text("Invalid assistance history"))
        }
    }
    private static func historyByKey(_ entries: [Attempt]) -> [String: Attempt] {
        Swift.Dictionary(uniqueKeysWithValues: entries.map { ($0.key, $0) })
    }

    /// Append-only import. Conflicting records or branches require explicit resolution, never silent overwrite.
    public static func merged(_ current: TrainerState, importing incoming: TrainerState, verbs: [Verb]) throws
        -> TrainerState
    {
        try validate(current, verbs: verbs)
        try validate(incoming, verbs: verbs)
        var result = current
        let known = historyByKey(current.history)
        for a in incoming.history {
            if let old = known[a.key], old != a {
                throw TrainerError.invalid(L10n.text("Conflicting original answer. Keep both exports separately."))
            }
            if known[a.key] == nil {
                result.history.append(a)
                Training.record(a, progress: &result.progress)
            }
        }
        result.history = result.history.enumerated().sorted {
            let a = SpacedRepetition.parse($0.element.at) ?? .distantPast
            let b = SpacedRepetition.parse($1.element.at) ?? .distantPast
            return a == b ? $0.offset < $1.offset : a < b
        }.map(\.element)
        // Rebuild fields from the combined chronology, preserving legacy counters absent from history.
        for id in Set(result.history.map(\.id)) {
            let entries = result.history.filter { $0.id == id }
            if let last = entries.last { result.progress[id]?.lastAt = last.at }
            if let last = entries.last(where: { !$0.assisted }) { result.progress[id]?.lastPassed = last.result.passed }
        }
        // Reject incomplete legacy histories instead of losing aggregate-only evidence.
        for (id, p) in incoming.progress {
            let history = incoming.history.filter { $0.id == id }
            if p.attempts != history.filter({ !$0.assisted }).count || p.assisted != history.filter(\.assisted).count {
                throw TrainerError.invalid(
                    L10n.format(
                        "The file contains counters without a full history (%@). Merge stopped. The original file is preserved.",
                        String(describing: id))
                )
            }
        }
        var sessions = (result.paused ?? []) + [result.session].compactMap { $0 }
        for s in (incoming.paused ?? []) + [incoming.session].compactMap({ $0 }) {
            if let old = sessions.first(where: { $0.id == s.id }) {
                guard old == s else {
                    throw TrainerError.invalid(
                        L10n.text("Two different versions of the same session. Merge stopped. Export both versions."))
                }
            } else if !s.finished {
                sessions.append(s)
            }
        }
        if result.session == nil { result.session = incoming.session }
        result.paused = sessions.filter { $0.id != result.session?.id }
        if result.exposures == nil { result.exposures = [:] }
        for (id, day) in incoming.exposures ?? [:] {
            let latest = max(result.exposures?[id] ?? "", day)
            result.exposures?[id] = latest
        }
        let events = result.helpEvents ?? []
        for e in incoming.helpEvents ?? [] {
            if let old = events.first(where: { $0.id == e.id }), old != e {
                throw TrainerError.invalid(L10n.text("Conflicting assistance history"))
            }
        }
        result.helpEvents =
            events + (incoming.helpEvents ?? []).filter { e in !events.contains(where: { $0.id == e.id }) }
        try validate(result, verbs: verbs)
        return result
    }
}

public struct FileStore: Sendable {
    public let url: URL
    public init(url: URL) { self.url = url }
    public func load(verbs: [Verb]) throws -> TrainerState {
        guard FileManager.default.fileExists(atPath: url.path) else { return TrainerState() }
        return try StateCodec.decode(Data(contentsOf: url), verbs: verbs)
    }
    public func save(_ state: TrainerState) throws {
        let data = try StateCodec.encode(state)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: url.path) {
            let old = try Data(contentsOf: url)
            try old.write(to: url.appendingPathExtension("previous"), options: .atomic)
        }
        try data.write(to: url, options: .atomic)
    }
    public func backup() throws -> URL? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let target = url.deletingLastPathComponent().appendingPathComponent("before-import-\(UUID().uuidString).json")
        try FileManager.default.copyItem(at: url, to: target)
        return target
    }
}
