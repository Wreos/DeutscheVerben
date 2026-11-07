import SwiftUI
import VerbTrainerCore

@MainActor @Observable
final class TrainerModel {
    var state = TrainerState()
    var verbs: [Verb] = []
    private(set) var reviewSchedules: [String: ReviewSchedule] = [:]
    var error: String?
    var locked = false
    var notice: String?
    @ObservationIgnored private var visibleHelpSources: [String: (ids: [String], reference: Bool)] = [:]
    let store: FileStore
    let deterministic: Bool

    init() {
        let defaultURL = URL.applicationSupportDirectory.appending(path: "DeutscheVerben/progress.json")
        #if DEBUG
            let testPath = ProcessInfo.processInfo.environment["DV_TEST_STORE"]
            deterministic = testPath != nil
            let url = testPath.map { URL(fileURLWithPath: $0) } ?? defaultURL
        #else
            deterministic = false
            let url = defaultURL
        #endif
        store = FileStore(url: url)
        do {
            verbs = try VerbTrainerCore.Dictionary.load()
            state = try store.load(verbs: verbs)
            reviewSchedules = SpacedRepetition.schedules(state.history)
        } catch {
            locked = true
            self.error =
                "Не удалось прочитать данные. Исходный файл сохранён без изменений: \(url.path). \(error.localizedDescription)"
        }
    }
    var selectedLevel: String {
        get { state.level }
        set {
            guard newValue != state.level else { return }
            state.level = newValue
            start()
        }
    }
    var current: Verb? {
        guard let s = state.session, !s.finished else { return nil }
        return verbs.first { $0.id == s.queue[s.index] }
    }
    var mistakeCount: Int { state.progress.values.filter { $0.lastPassed == false }.count }
    var draft: Answers {
        get { state.session?.draft ?? Answers() }
        set {
            guard !locked else { return }
            state.session?.draft = newValue
            persist()
        }
    }
    func persist() {
        guard !locked else { return }
        do { try store.save(state) } catch {
            self.error =
                "Не удалось сохранить: \(error.localizedDescription). Экспортируйте результаты перед закрытием."
        }
    }
    func start(filter: String = "all", withHelp: Bool = false) {
        guard !locked else { return }
        refreshVisibleHelp()
        let queue = SpacedRepetition.queue(
            verbs: verbs, state: state, now: Date(), level: state.level,
            filter: filter, shuffled: !deterministic, includeExposed: withHelp
        )
        Training.start(&state, verbs: verbs, filter: filter, shuffled: !deterministic)
        state.session?.queue = queue
        if withHelp { state.session?.exposed = true }
        persist()
    }

    var canPracticeWithHelp: Bool {
        !SpacedRepetition.queue(
            verbs: verbs, state: state, now: Date(), level: state.level,
            filter: "all", shuffled: false, includeExposed: true
        ).isEmpty
    }

    func resume(_ id: String) {
        Training.resume(&state, id: id)
        persist()
    }
    func submit(_ kind: String) {
        refreshVisibleHelp()
        do {
            try Training.submit(&state, verbs: verbs, kind: kind, now: Date())
            reviewSchedules = SpacedRepetition.schedules(state.history)
            persist()
        } catch { self.error = error.localizedDescription }
    }
    func next() {
        Training.next(&state)
        persist()
    }
    func exposeReference(_ ids: [String]) {
        guard !locked else { return }
        visibleHelpSources["reference"] = ids.isEmpty ? nil : (ids, true)
        guard !ids.isEmpty else { return }

        let now = Date()
        let today = Training.day(now)
        let newIDs = ids.filter { state.exposures?[$0] != today }
        let marksSession = state.session.map { !$0.finished && !$0.exposed } ?? false
        guard !newIDs.isEmpty || marksSession else { return }
        Training.expose(&state, ids: newIDs.isEmpty ? ids : newIDs, kind: "reference", now: now, reference: true)
        persist()
    }

    func exposeHistory(_ verb: Verb, key: String) {
        guard !locked else { return }
        visibleHelpSources["history-" + key] = ([verb.id], true)
        Training.expose(&state, ids: [verb.id], kind: "history", now: Date(), reference: true)
        persist()
    }
    func noteVisibleFeedback(_ verb: Verb) {
        guard !locked else { return }
        visibleHelpSources["feedback"] = ([verb.id], false)
        guard state.exposures?[verb.id] != Training.day(Date()) else { return }
        Training.expose(&state, ids: [verb.id], kind: "restored-feedback", now: Date())
        persist()
    }
    func hideVisibleHelp(_ key: String) {
        refreshVisibleHelp()
        visibleHelpSources.removeValue(forKey: key)
    }
    func refreshVisibleHelp(now: Date = Date()) {
        guard !locked else { return }
        let previous = state.exposures
        for source in visibleHelpSources.values {
            Training.refreshVisibleHelp(&state, ids: source.ids, now: now, reference: source.reference)
        }
        if previous != state.exposures { persist() }
    }
    func refreshAtDayBoundaries() async {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        while !Task.isCancelled {
            let next = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
            do { try await Task.sleep(for: .seconds(max(1, next.timeIntervalSinceNow))) } catch { return }
            refreshVisibleHelp()
        }
    }
    func importFile(_ url: URL, replacing: Bool = false) {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= 20_000_000 else { throw TrainerError.invalid("Файл больше 20 МБ") }
            let data = try Data(contentsOf: url)
            let incoming = try StateCodec.decode(data, verbs: verbs)
            let merged = replacing ? incoming : try StateCodec.merged(state, importing: incoming, verbs: verbs)
            let backup = try store.backup()
            try store.save(merged)
            state = merged
            reviewSchedules = SpacedRepetition.schedules(state.history)
            locked = false
            notice =
                (replacing ? "Копия восстановлена." : "Импорт завершён. История объединена без удаления ответов.")
                + "\(backup == nil ? "" : " Резервная копия сохранена рядом с progress.json.")"
        } catch { self.error = "Импорт остановлен: \(error.localizedDescription)" }
    }
}
