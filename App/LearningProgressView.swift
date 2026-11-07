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
            Section(L10n.text("Learning progress")) {
                let points = model.verbs.reduce(0.0) { $0 + (schedules[$1.id]?.fraction ?? 0) }
                ProgressView(value: points, total: 60).accessibilityLabel(L10n.text("Verb learning progress"))
                    .accessibilityValue(
                        L10n.format("%@ percent of practice stages", String(describing: Int(points / 60 * 100))))
                Text(
                    L10n.format(
                        "%@%% · %@ of 60 consolidated", String(describing: Int(points / 60 * 100)),
                        String(describing: schedules.values.filter { $0.stage == 3 }.count))
                )
                .font(.headline)
                Button(L10n.text("Start scheduled review"), systemImage: "arrow.clockwise") { onStart() }
                Text(
                    L10n.format(
                        "Due: %@ · Close to consolidation: %@",
                        String(describing: schedules.values.filter { $0.isDue(on: today) }.count),
                        String(describing: schedules.values.filter { $0.stage == 2 }.count))
                ).font(.callout)
            }
            Section {
                NavigationLink(L10n.text("Original answer history")) {
                    HistoryView(model: model).navigationTitle(L10n.text("Answer history"))
                }
                DisclosureGroup(L10n.text("How to read the scale")) {
                    Text(
                        L10n.text(
                            "0% means no current independent success streak. 25% means one success, 50% means two. 75% means three, close to consolidation. 100% requires at least four consecutive successes, an exact final answer and a gap of at least 14 days before the final review."
                        )
                    )
                    Text(
                        L10n.text(
                            "Assisted answers do not increase progress. An error returns the verb to review. An early success does not increase the interval."
                        )
                    )
                }
                Picker(L10n.text("Show"), selection: $filter) {
                    Text(L10n.text("All verbs")).tag("all")
                    Text(L10n.text("Needs review")).tag("due")
                    Text(L10n.text("Close to consolidation")).tag("near")
                    Text(L10n.text("Consolidated verbs")).tag("stable")
                }
            }
            Section(L10n.format("Verbs · %@", String(describing: rows.count))) {
                ForEach(rows) { verb in
                    let s = schedules[verb.id] ?? ReviewSchedule()
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(verb.id).font(.headline)
                            Spacer()
                            Text(s.stageTitle).font(.caption).foregroundStyle(.secondary)
                        }
                        Text(verb.localizedMeaning).font(.callout)
                        ProgressView(value: s.fraction).accessibilityLabel(
                            L10n.format("Learning stage for %@", String(describing: verb.id))
                        )
                        .accessibilityValue(s.stageTitle)
                        Text(
                            s.due.map {
                                L10n.format(
                                    "%@: %@ · interval %@ days",
                                    String(
                                        describing: $0 <= today ? L10n.text("Due for review") : L10n.text("Next review")
                                    ), String(describing: $0), String(describing: s.interval))
                            } ?? L10n.text("Recall independently first")
                        ).font(.caption).foregroundStyle(.secondary)
                        if let p = model.state.progress[verb.id] {
                            Text(
                                L10n.format(
                                    "Independent attempts: %@ · Assisted: %@", String(describing: p.attempts),
                                    String(describing: p.assisted))
                            ).font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 8)
                }
                if rows.isEmpty { Text(L10n.text("No verbs in this group yet.")).foregroundStyle(.secondary) }
            }
        }
    }
}
