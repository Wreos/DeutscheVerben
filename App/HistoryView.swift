import SwiftUI
import VerbTrainerCore

struct HistoryView: View {
    let model: TrainerModel
    var body: some View {
        List {
            Section {
                Text("Открытие ответов учитывается как подсказка.").font(.callout).foregroundStyle(.secondary)
            }
            if model.state.history.isEmpty {
                ContentUnavailableView(
                    "Пока нет результатов", systemImage: "clock",
                    description: Text("Пройди первый подход — здесь появятся ответы и примеры."))
            }
            ForEach(model.state.history.reversed(), id: \.key) { entry in
                if let verb = model.verbs.first(where: { $0.id == entry.id }) {
                    AttemptHistoryRow(model: model, entry: entry, verb: verb)
                }
            }
        }
    }
}
