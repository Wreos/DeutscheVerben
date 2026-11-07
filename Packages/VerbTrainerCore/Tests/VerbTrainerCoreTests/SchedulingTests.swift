import Foundation
import Testing

@testable import VerbTrainerCore

struct SchedulingTests {
    let verbs = try! VerbTrainerCore.Dictionary.load()
    func date(_ day: String) -> Date { ISO8601DateFormatter().date(from: day + "T10:00:00Z")! }
    func attempt(_ day: String, id: String = "gehen", assisted: Bool = false, passed: Bool = true, typo: Bool = false)
        -> Attempt
    {
        let v = verbs.first { $0.id == id }!
        let answers =
            passed ? Answers(past: v.past, participle: v.participle + (typo ? "x" : ""), aux: v.aux) : Answers()
        return .init(
            id: id, answers: answers, result: Grading.grade(v, answers), assisted: assisted, kind: "answer",
            at: Training.timestamp(date(day)), sessionId: UUID().uuidString)
    }
    @Test func intervalsResetAndAssistance() throws {
        let a = attempt("2026-01-01")
        let b = attempt("2026-01-02")
        let c = attempt("2026-01-08")
        #expect(SpacedRepetition.schedules([a])["gehen"]?.due == "2026-01-02")
        #expect(SpacedRepetition.schedules([a, b])["gehen"]?.interval == 6)
        let s = SpacedRepetition.schedules([a, b, c])["gehen"]!
        #expect(s.interval == 17)
        #expect(s.stage == 2)
        #expect(s.due == "2026-01-25")
        #expect(SpacedRepetition.schedules([a, b, c, attempt("2026-01-25", assisted: true)])["gehen"] == s)
        let stable = SpacedRepetition.schedules([a, b, c, attempt("2026-01-25")])["gehen"]!
        #expect(stable.stage == 3)
        #expect(stable.fraction == 1)
        let failure = SpacedRepetition.schedules([a, b, c, attempt("2026-01-25", passed: false)])["gehen"]!
        #expect(failure.successes == 0)
        #expect(failure.due == "2026-01-26")
        #expect(failure.failed)
    }
    @Test func earlyReviewsSameDayAndTyposCannotInflateReadiness() {
        let a = attempt("2026-01-01")
        let b = attempt("2026-01-02")
        let s = SpacedRepetition.schedules([a, b])["gehen"]!
        #expect(SpacedRepetition.schedules([a, b, attempt("2026-01-03")])["gehen"] == s)
        #expect(SpacedRepetition.schedules([a, b, attempt("2026-01-02")])["gehen"] == s)
        let typo = SpacedRepetition.schedules([a, b, attempt("2026-01-08"), attempt("2026-01-25", typo: true)])[
            "gehen"]!
        #expect(typo.stage == 2)
        #expect(typo.fraction == 0.75)
        #expect(
            typo.ease < SpacedRepetition.schedules([a, b, attempt("2026-01-08"), attempt("2026-01-25")])["gehen"]!.ease)
    }
    @Test func queuePrioritisesDueErrorsThenDueThenNewAndSkipsFutureAndExposure() {
        var s = TrainerState()
        let history = [
            attempt("2026-01-01", id: "gehen", passed: false), attempt("2026-01-01", id: "sein"),
            attempt("2026-01-01", id: "haben"), attempt("2026-01-02", id: "haben"),
        ]
        s.history = history
        for a in history { Training.record(a, progress: &s.progress) }
        var q = SpacedRepetition.queue(
            verbs: verbs, state: s, now: date("2026-01-03"), level: "all", filter: "all", shuffled: false)
        #expect(q.prefix(2) == ["gehen", "sein"])
        #expect(!q.contains("haben"))
        s.exposures = ["gehen": "2026-01-03"]
        q = SpacedRepetition.queue(
            verbs: verbs, state: s, now: date("2026-01-03"), level: "A1", filter: "all", shuffled: false)
        #expect(!q.contains("gehen"))
        #expect(q.first == "sein")
        let withHelp = SpacedRepetition.queue(
            verbs: verbs, state: s, now: date("2026-01-03"), level: "A1",
            filter: "all", shuffled: false, includeExposed: true
        )
        #expect(withHelp.first == "gehen")
        #expect(!withHelp.contains("haben"))
        #expect(
            SpacedRepetition.queue(
                verbs: verbs, state: s, now: date("2026-01-03"), level: "all", filter: "mistakes", shuffled: false) == [
                    "gehen"
                ])
    }
    @Test func berlinCalendarDaysAndRoundTripDerivedSchedule() throws {
        let beforeDST = ISO8601DateFormatter().date(from: "2026-03-28T23:30:00Z")!
        #expect(SpacedRepetition.adding(days: 1, to: beforeDST) == "2026-03-30")
        let beforeWinter = ISO8601DateFormatter().date(from: "2026-10-24T22:30:00Z")!
        #expect(SpacedRepetition.adding(days: 1, to: beforeWinter) == "2026-10-26")
        var s = TrainerState()
        s.history = [attempt("2026-01-01"), attempt("2026-01-02")]
        #expect(
            try SpacedRepetition.schedules(StateCodec.decode(StateCodec.encode(s), verbs: verbs).history)
                == SpacedRepetition.schedules(s.history))
    }
}
