import SwiftUI
import VerbTrainerCore

struct FeedbackView: View {
    let entry: Attempt
    let verb: Verb
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider()
            Text(
                entry.assisted
                    ? L10n.text("Forms to study · assisted")
                    : entry.result.exact
                        ? L10n.text("All forms correct")
                        : entry.result.passed ? L10n.text("Correct, with a typo") : L10n.text("Let's check the forms")
            ).font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
            if !entry.assisted {
                Text("\(entry.result.score.formatted())/10").font(.title2.bold()).monospacedDigit()
                    .accessibilityIdentifier("score")
            }
            FormFeedbackRow(
                title: "Präteritum", answer: entry.answers.past, result: entry.result.past, assisted: entry.assisted)
            FormFeedbackRow(
                title: "Partizip II", answer: entry.answers.participle, result: entry.result.participle,
                assisted: entry.assisted)
            FormFeedbackRow(
                title: "Perfekt", answer: entry.answers.aux, result: entry.result.aux, assisted: entry.assisted)
            if let alternatives = verb.pastAlternatives, !alternatives.isEmpty {
                Text(L10n.format("Also accepted: %@", String(describing: alternatives.joined(separator: ", ")))).font(
                    .callout)
            }
            Text(verb.example).font(.body.italic()).environment(\.locale, Locale(identifier: "de-DE"))
            if !entry.assisted && !entry.result.passed {
                Text(L10n.text("Added to mistake review.")).font(.callout).foregroundStyle(.secondary)
            }
        }.textSelection(.enabled)
    }
}

private struct FormFeedbackRow: View {
    let title, answer: String
    let result: FormResult
    let assisted: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(result.expected).font(.headline).environment(\.locale, Locale(identifier: "de-DE"))
            Text(
                L10n.format("Your answer: %@", String(describing: answer.isEmpty ? L10n.text("not filled in") : answer))
            ).font(.callout)
            if !assisted {
                Text(
                    result.status == "correct"
                        ? L10n.text("Correct · 10/10")
                        : result.status == "typo" ? L10n.text("Typo · 9/10") : L10n.text("Incorrect · 0/10")
                ).font(.caption).foregroundStyle(.secondary)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
