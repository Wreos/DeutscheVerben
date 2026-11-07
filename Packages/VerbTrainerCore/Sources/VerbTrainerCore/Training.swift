import Foundation

public enum Training {
    public static func day(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Europe/Berlin")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
    public static func timestamp(_ date: Date) -> String { ISO8601DateFormatter().string(from: date) }
    public static func queue(
        _ verbs: [Verb], progress: [String: Progress], level: String = "all", filter: String = "all",
        shuffled: Bool = true
    ) -> [String] {
        let pool = verbs.filter {
            (level == "all" || $0.level == level) && (filter != "mistakes" || progress[$0.id]?.lastPassed == false)
        }
        let randomized = shuffled ? pool.shuffled() : pool
        func priority(_ v: Verb) -> Int {
            progress[v.id]?.lastPassed == false ? 0 : (progress[v.id]?.attempts ?? 0) == 0 ? 1 : 2
        }
        return randomized.enumerated().sorted {
            priority($0.element) == priority($1.element)
                ? $0.offset < $1.offset : priority($0.element) < priority($1.element)
        }.prefix(10).map(\.element.id)
    }
    public static func pause(_ state: inout TrainerState) {
        guard let s = state.session, !s.finished, !s.results.isEmpty || !s.draft.isEmpty else { return }
        state.paused = (state.paused ?? []).filter { $0.id != s.id } + [s]
    }
    public static func start(_ state: inout TrainerState, verbs: [Verb], filter: String = "all", shuffled: Bool = true)
    {
        pause(&state)
        var s = TrainingSession()
        s.level = state.level
        s.filter = filter
        s.queue = queue(verbs, progress: state.progress, level: state.level, filter: filter, shuffled: shuffled)
        state.session = s
    }
    public static func resume(_ state: inout TrainerState, id: String) {
        guard let target = state.paused?.first(where: { $0.id == id }) else { return }
        state.paused?.removeAll { $0.id == id }
        pause(&state)
        state.session = target
        state.level = target.level
    }
    public static func assisted(_ state: TrainerState, id: String, now: Date) -> Bool {
        state.session?.exposed == true || state.exposures?[id] == day(now)
    }
    public static func expose(
        _ state: inout TrainerState, ids: [String], kind: String, now: Date, reference: Bool = false
    ) {
        if reference, state.session?.finished == false { state.session?.exposed = true }
        if state.exposures == nil { state.exposures = [:] }
        for id in ids { state.exposures?[id] = day(now) }
        if state.helpEvents == nil { state.helpEvents = [] }
        state.helpEvents?.append(
            .init(id: UUID().uuidString, at: timestamp(now), kind: kind, verbIDs: ids, sessionId: state.session?.id))
    }
    public static func refreshVisibleHelp(
        _ state: inout TrainerState, ids: [String], now: Date, reference: Bool = false
    ) {
        let stale = ids.filter { state.exposures?[$0] != day(now) }
        guard !stale.isEmpty else { return }
        expose(&state, ids: stale, kind: "visible-day-refresh", now: now, reference: reference)
    }
    public static func record(_ attempt: Attempt, progress: inout [String: Progress]) {
        var p = progress[attempt.id] ?? Progress()
        if attempt.assisted {
            p.assisted += 1
        } else {
            p.attempts += 1
            p.passed += attempt.result.passed ? 1 : 0
            p.lastPassed = attempt.result.passed
        }
        p.lastAt = attempt.at
        progress[attempt.id] = p
    }
    public static func submit(_ state: inout TrainerState, verbs: [Verb], kind: String, now: Date) throws {
        guard let s = state.session, !s.finished, s.checked == nil,
            let verb = verbs.first(where: { $0.id == s.queue[s.index] })
        else { return }
        guard kind != "answer" || s.draft.complete else {
            throw TrainerError.invalid(
                L10n.text(
                    "Fill in Präteritum and Partizip II with hat or ist. If you cannot recall them, tap I don't know."))
        }
        let entry = Attempt(
            id: verb.id, answers: s.draft, result: Grading.grade(verb, s.draft),
            assisted: kind == "reveal" || assisted(state, id: verb.id, now: now), kind: kind, at: timestamp(now),
            sessionId: s.id)
        expose(&state, ids: [verb.id], kind: kind == "reveal" ? "reveal" : "feedback", now: now)
        record(entry, progress: &state.progress)
        state.history.append(entry)
        state.session?.results.append(entry)
    }
    public static func next(_ state: inout TrainerState) {
        guard state.session?.checked != nil else { return }
        state.session?.index += 1
        state.session?.draft = Answers()
    }
}
