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
                    ? "Формы для изучения · с опорой"
                    : entry.result.exact
                        ? "Все формы верны" : entry.result.passed ? "Верно, есть опечатка" : "Сверим формы"
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
                Text("Также принимается: \(alternatives.joined(separator: ", "))").font(.callout)
            }
            Text(verb.example).font(.body.italic()).environment(\.locale, Locale(identifier: "de-DE"))
            if !entry.assisted && !entry.result.passed {
                Text("Добавлено в повторение ошибок.").font(.callout).foregroundStyle(.secondary)
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
            Text("Твой ответ: \(answer.isEmpty ? "не заполнено" : answer)").font(.callout)
            if !assisted {
                Text(
                    result.status == "correct"
                        ? "Верно · 10/10" : result.status == "typo" ? "Опечатка · 9/10" : "Неверно · 0/10"
                ).font(.caption).foregroundStyle(.secondary)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
