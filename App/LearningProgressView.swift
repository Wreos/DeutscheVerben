import SwiftUI
import VerbTrainerCore

struct LearningProgressView: View {
    let model: TrainerModel
    let onStart: () -> Void
    @State private var filter = "all"
    private var schedules: [String: ReviewSchedule] { model.reviewSchedules }
    private var today: String { Training.day(Date()) }
    private var rows: [Verb] {
        model.verbs.filter { verb in
            let s = schedules[verb.id] ?? ReviewSchedule()
            switch filter {
            case "due": return s.isDue(on: today) || model.state.progress[verb.id]?.lastPassed == false
            case "near": return s.stage == 2
            case "stable": return s.stage == 3
            default: return true
            }
        }.sorted {
            let a = schedules[$0.id] ?? ReviewSchedule()
            let b = schedules[$1.id] ?? ReviewSchedule()
            if a.failed != b.failed { return a.failed }
            if a.isDue(on: today) != b.isDue(on: today) { return a.isDue(on: today) }
            return $0.id < $1.id
        }
    }
    var body: some View {
        List {
            Section("Шкала изучения") {
                let points = model.verbs.reduce(0.0) { $0 + (schedules[$1.id]?.fraction ?? 0) }
                ProgressView(value: points, total: 60).accessibilityLabel("Прогресс изучения глаголов")
                    .accessibilityValue("\(Int(points / 60 * 100)) процентов этапов практики")
                Text("\(Int(points / 60 * 100))% · \(schedules.values.filter { $0.stage == 3 }.count) из 60 закреплены")
                    .font(.headline)
                Button("Начать повторение по расписанию", systemImage: "arrow.clockwise") { onStart() }
                Text(
                    "Пора повторить: \(schedules.values.filter { $0.isDue(on: today) }.count) · Близко к закреплению: \(schedules.values.filter { $0.stage == 2 }.count)"
                ).font(.callout)
            }
            Section {
                NavigationLink("История исходных ответов") {
                    HistoryView(model: model).navigationTitle("История ответов")
                }
                DisclosureGroup("Как читать шкалу") {
                    Text(
                        "0% — нет самостоятельной успешной серии. 25% — один успех, 50% — два. 75% — три, близко к закреплению. 100% — минимум четыре успеха подряд, последний без опечаток, с фактическим перерывом не меньше 14 дней перед последней проверкой."
                    )
                    Text(
                        "Ответ с подсказкой не повышает прогресс. Ошибка возвращает глагол к повторению. Досрочный успех не увеличивает интервал."
                    )
                }
                Picker("Показать", selection: $filter) {
                    Text("Все глаголы").tag("all")
                    Text("Нужно повторить").tag("due")
                    Text("Близко к закреплению").tag("near")
                    Text("Закреплены").tag("stable")
                }
            }
            Section("Глаголы · \(rows.count)") {
                ForEach(rows) { verb in
                    let s = schedules[verb.id] ?? ReviewSchedule()
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(verb.id).font(.headline)
                            Spacer()
                            Text(s.stageTitle).font(.caption).foregroundStyle(.secondary)
                        }
                        Text(verb.meaning).font(.callout)
                        ProgressView(value: s.fraction).accessibilityLabel("Этап изучения \(verb.id)")
                            .accessibilityValue(s.stageTitle)
                        Text(
                            s.due.map {
                                "\($0 <= today ? "Пора повторить" : "Следующее повторение"): \($0) · интервал \(s.interval) дн."
                            } ?? "Нужно вспомнить без подсказки"
                        ).font(.caption).foregroundStyle(.secondary)
                        if let p = model.state.progress[verb.id] {
                            Text("Самостоятельных попыток: \(p.attempts) · С опорой: \(p.assisted)").font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 8)
                }
                if rows.isEmpty { Text("В этой группе пока нет глаголов.").foregroundStyle(.secondary) }
            }
        }
    }
}
