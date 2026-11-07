import Foundation
import Testing

@testable import VerbTrainerCore

struct CombinedAnswerTests {
    let verbs = try! VerbTrainerCore.Dictionary.load()

    @Test func combinedAnswersMatchLegacyGradesForEveryVerb() {
        for verb in verbs {
            let old = Answers(past: verb.past, participle: verb.participle, aux: verb.aux)
            let auxiliary = verb.aux == "sein" ? "ist" : "hat"
            for prefix in [auxiliary, verb.aux] {
                let raw = "  \(prefix.uppercased())   \(verb.participle.uppercased()).  "
                let answer = Answers(past: verb.past, perfect: raw)
                #expect(answer.perfectInput == raw)
                #expect(answer.complete)
                #expect(Grading.grade(verb, answer) == Grading.grade(verb, old))
            }
            #expect(old.perfectInput == "\(auxiliary) \(verb.participle)")
        }
    }

    @Test func missingWrongAndMistypedAuxiliariesAreGraded() {
        let verb = verbs.first { $0.id == "gehen" }!
        for raw in ["gegangen", "hat gegangen", "hst gegangen"] {
            let answer = Answers(past: "ging", perfect: raw)
            let grade = Grading.grade(verb, answer)
            #expect(answer.complete)
            #expect(grade.participle.score == 10)
            #expect(grade.aux.score == 0)
            #expect(!grade.passed)
        }
        let typo = Grading.grade(verb, Answers(past: "ging", perfect: "ist geganggen"))
        #expect(typo.participle.score == 9)
        #expect(typo.aux.score == 10)
        #expect(typo.passed)
        #expect(!Answers(past: "ging", perfect: "  ").complete)
        let partial = Answers(past: "ging", perfect: "ist")
        #expect(Grading.grade(verb, partial).participle.score == 0)
        #expect(Grading.grade(verb, partial).aux.score == 10)
    }

    @Test func rawCombinedDraftAndHistorySurviveStorageAndMerge() throws {
        var state = TrainerState()
        Training.start(&state, verbs: verbs, shuffled: false)
        state.session?.queue = ["gehen"]
        let raw = "  SEIN   gegangen.  "
        state.session?.draft = Answers(past: "ging", perfect: raw)
        state = try StateCodec.decode(StateCodec.encode(state), verbs: verbs)
        #expect(state.session?.draft.perfectInput == raw)
        try Training.submit(&state, verbs: verbs, kind: "answer", now: Date())
        let restored = try StateCodec.decode(StateCodec.encode(state), verbs: verbs)
        #expect(restored == state)
        #expect(restored.history[0].answers.perfect == raw)
        let merged = try StateCodec.merged(TrainerState(), importing: restored, verbs: verbs)
        #expect(merged.history == restored.history)
        #expect(try StateCodec.merged(merged, importing: restored, verbs: verbs) == merged)
    }

    @Test func legacyDraftsRemainEditableAndInconsistentCombinedDataIsRejected() throws {
        var state = TrainerState()
        Training.start(&state, verbs: verbs, shuffled: false)
        state.session?.queue = ["gehen"]
        state.session?.draft = Answers(past: "ging", participle: "gegangen", aux: "sein")
        let legacy = try StateCodec.decode(StateCodec.encode(state), verbs: verbs)
        #expect(legacy.session?.draft.perfect == nil)
        #expect(legacy.session?.draft.perfectInput == "ist gegangen")
        state.session?.draft.perfectInput = "hat gemacht"
        #expect(state.session?.draft.aux == "haben")
        #expect(state.session?.draft.participle == "gemacht")
        state.session?.draft.aux = "sein"
        #expect(throws: (any Error).self) { try StateCodec.decode(StateCodec.encode(state), verbs: verbs) }
    }
}
