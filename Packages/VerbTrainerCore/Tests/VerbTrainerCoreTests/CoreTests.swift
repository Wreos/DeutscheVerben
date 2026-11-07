import Foundation
import Testing

@testable import VerbTrainerCore

struct CoreTests {
    let verbs = try! VerbTrainerCore.Dictionary.load()
    func verb(_ id: String) -> Verb { verbs.first { $0.id == id }! }
    func date(_ s: String) -> Date { ISO8601DateFormatter().date(from: s)! }
    func fixture(_ name: String) throws -> Data {
        try Data(contentsOf: Bundle.module.url(forResource: name, withExtension: "json")!)
    }

    @Test func dictionaryAndWebParity() throws {
        #expect(verbs.count == 60)
        #expect(Set(verbs.map(\.id)).count == 60)
        struct Case: Decodable {
            let id: String
            let answers: Answers
            let result: Grade
        }
        let cases = try JSONDecoder().decode([Case].self, from: fixture("web-grades"))
        #expect(cases.count > 300)
        for c in cases { #expect(Grading.grade(verb(c.id), c.answers) == c.result) }
        #expect(verb("ziehen").aux == "sein")
        #expect(verb("gefallen").aux == "haben")
    }
    @Test(arguments: [
        ("  GEFAHREN.  ", "gefahren", 10), ("ging .", "ging", 10), ("ass", "aß", 10), ("haette", "hätte", 10),
        ("hatte", "hätte", 9), ("fing   an", "fing an", 10), ("geganggen", "gegangen", 9), ("gangen", "gegangen", 0),
        ("", "ging", 0), ("anfing", "fing an", 0), ("gegangenx", "gegangen", 9), ("ha\u{308}tte", "hätte", 10),
    ])
    func normalization(_ input: String, _ expected: String, _ score: Int) {
        #expect(Grading.assess(input, expected: expected).score == score)
    }

    @Test func queueAndAssistance() throws {
        var s = TrainerState()
        s.level = "A1"
        Training.start(&s, verbs: verbs, shuffled: false)
        #expect(s.session?.queue.count == 10)
        s.session?.queue = ["gehen"]
        try Training.submit(&s, verbs: verbs, kind: "unknown", now: date("2026-11-04T10:00:00Z"))
        #expect(s.progress["gehen"]?.lastPassed == false)
        Training.start(&s, verbs: verbs, filter: "mistakes", shuffled: false)
        #expect(s.session?.queue == ["gehen"])
        s.session?.draft = Answers(past: "ging", participle: "gegangen", aux: "sein")
        try Training.submit(&s, verbs: verbs, kind: "answer", now: date("2026-11-04T11:00:00Z"))
        #expect(s.history.last?.assisted == true)
        #expect(s.progress["gehen"]?.attempts == 1)
        #expect(s.progress["gehen"]?.lastPassed == false)
        #expect(s.helpEvents?.count == 2)
    }
    @Test func berlinBoundaryAndReferencePersistence() throws {
        #expect(Training.day(date("2026-03-29T22:00:00Z")) == "2026-03-30")
        #expect(Training.day(date("2026-10-25T23:00:00Z")) == "2026-10-26")
        var s = TrainerState()
        Training.start(&s, verbs: verbs, shuffled: false)
        Training.expose(&s, ids: ["sein"], kind: "reference", now: date("2026-11-04T22:59:59Z"), reference: true)
        #expect(Training.assisted(s, id: "sein", now: date("2026-11-04T23:00:00Z")))
        s.session?.exposed = false
        #expect(Training.assisted(s, id: "sein", now: date("2026-11-04T22:59:59Z")))
        #expect(!Training.assisted(s, id: "sein", now: date("2026-11-04T23:00:00Z")))
    }
    @Test func draftsPauseUnknownRevealAndRoundTrip() throws {
        var s = TrainerState()
        Training.start(&s, verbs: verbs, shuffled: false)
        s.session?.draft = Answers(past: "My ORIGINAL Answer!")
        let original = s.session!
        Training.start(&s, verbs: verbs, filter: "mistakes")
        #expect(s.paused?.count == 1)
        Training.resume(&s, id: original.id)
        #expect(s.session == original)
        s = try StateCodec.decode(StateCodec.encode(s), verbs: verbs)
        #expect(s.session?.draft.past == "My ORIGINAL Answer!")
        try Training.submit(&s, verbs: verbs, kind: "unknown", now: Date())
        #expect(s.history[0].answers.past == "My ORIGINAL Answer!")
        #expect(s.history[0].result.participle.score == 0)
        #expect(s.history[0].result.aux.score == 0)
        let data = try StateCodec.encode(s)
        #expect(try StateCodec.decode(data, verbs: verbs) == s)
        Training.next(&s)
        try Training.submit(&s, verbs: verbs, kind: "reveal", now: Date())
        #expect(s.history.last?.assisted == true)
    }
    @Test func webImportMergeAndConflict() throws {
        let web = try StateCodec.decode(fixture("web-export"), verbs: verbs)
        #expect(web.history[0].answers.past == "ging")
        let imported = try StateCodec.merged(TrainerState(), importing: web, verbs: verbs)
        #expect(imported.history == web.history)
        #expect(imported.session == web.session)
        #expect(try StateCodec.merged(imported, importing: web, verbs: verbs) == imported)
        var conflict = web
        conflict.session?.draft.past = "different"
        #expect(throws: (any Error).self) { try StateCodec.decode(StateCodec.encode(conflict), verbs: verbs) }
        var unknownVersion = web
        unknownVersion.version = 2
        #expect(throws: (any Error).self) { try StateCodec.decode(StateCodec.encode(unknownVersion), verbs: verbs) }
        var badID = web
        badID.session?.queue = ["missing"]
        #expect(throws: (any Error).self) { try StateCodec.decode(StateCodec.encode(badID), verbs: verbs) }
        #expect(throws: (any Error).self) { try StateCodec.decode(Data("{}".utf8), verbs: verbs) }
    }
    @Test func visibleHelpCrossesMidnightWithoutRewritingOriginalAnswer() throws {
        var s = TrainerState()
        Training.start(&s, verbs: verbs, shuffled: false)
        s.session?.queue = ["gehen"]
        s.session?.draft = Answers(past: "ging", participle: "gegangen", aux: "sein")
        try Training.submit(&s, verbs: verbs, kind: "answer", now: date("2026-11-04T22:59:59Z"))
        let original = s.history[0]
        Training.refreshVisibleHelp(&s, ids: ["gehen"], now: date("2026-11-04T23:00:00Z"))
        #expect(s.exposures?["gehen"] == "2026-11-05")
        #expect(s.history[0] == original)
        Training.start(&s, verbs: verbs, shuffled: false)
        s.session?.queue = ["gehen"]
        s.session?.draft = original.answers
        try Training.submit(&s, verbs: verbs, kind: "answer", now: date("2026-11-04T23:00:01Z"))
        #expect(s.history.last?.assisted == true)
        #expect(s.progress["gehen"]?.attempts == 1)
        let before = s.helpEvents?.count
        Training.refreshVisibleHelp(&s, ids: ["gehen"], now: date("2026-11-04T23:00:02Z"), reference: true)
        #expect(s.helpEvents?.count == before)
    }
    @Test func incompleteDoesNotRecordAndTomorrowIsIndependent() throws {
        var s = TrainerState()
        Training.start(&s, verbs: verbs, shuffled: false)
        s.session?.queue = ["gehen"]
        s.session?.draft.past = "ging"
        #expect(throws: (any Error).self) { try Training.submit(&s, verbs: verbs, kind: "answer", now: Date()) }
        #expect(s.history.isEmpty)
        #expect(s.session?.draft.past == "ging")
        try Training.submit(&s, verbs: verbs, kind: "unknown", now: date("2026-11-04T22:59:59Z"))
        #expect(s.history.last?.result.past.score == 10)
        Training.start(&s, verbs: verbs, filter: "mistakes", shuffled: false)
        s.session?.draft = Answers(past: "ging", participle: "gegangen", aux: "sein")
        try Training.submit(&s, verbs: verbs, kind: "answer", now: date("2026-11-04T23:00:00Z"))
        #expect(s.history.last?.assisted == false)
        #expect(s.progress["gehen"]?.attempts == 2)
        #expect(s.progress["gehen"]?.lastPassed == true)
    }
    @Test func importBranchesAndNativeExport() throws {
        let web = try StateCodec.decode(fixture("web-export"), verbs: verbs)
        var branch = web
        branch.session?.index = 1
        branch.session?.draft = Answers(past: "original branch")
        try StateCodec.validate(branch, verbs: verbs)
        #expect(throws: (any Error).self) { try StateCodec.merged(web, importing: branch, verbs: verbs) }
        var native = web
        Training.expose(&native, ids: ["sein"], kind: "reference", now: date("2026-11-04T12:00:00Z"), reference: true)
        let data = try StateCodec.encode(native)
        #expect(try StateCodec.decode(data, verbs: verbs) == native)
        if let path = ProcessInfo.processInfo.environment["DV_VERIFY_EXPORT"] {
            try data.write(to: URL(fileURLWithPath: path))
        }
    }
    @Test func fileRecoveryAndTenCardFlow() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = FileStore(url: folder.appendingPathComponent("progress.json"))
        var s = TrainerState()
        Training.start(&s, verbs: verbs, shuffled: false)
        for _ in 0..<10 {
            let v = verb(s.session!.queue[s.session!.index])
            s.session?.draft = Answers(past: v.past, participle: v.participle, aux: v.aux)
            try Training.submit(&s, verbs: verbs, kind: "answer", now: Date())
            try store.save(s)
            s = try store.load(verbs: verbs)
            Training.next(&s)
        }
        try store.save(s)
        #expect(try store.load(verbs: verbs) == s)
        #expect(s.session?.finished == true)
        #expect(s.history.count == 10)
        #expect(s.history.allSatisfy { !$0.assisted && $0.result.score == 10 })
        #expect(try store.backup() != nil)
        try Data("corrupt".utf8).write(to: store.url)
        #expect(throws: (any Error).self) { try store.load(verbs: verbs) }
        #expect(try Data(contentsOf: store.url) == Data("corrupt".utf8))
    }
}
