import SwiftUI
import VerbTrainerCore

struct HistoryView: View {
    let model: TrainerModel
    var body: some View {
        List {
            Section {
                Text(L10n.text("Opening answers counts as assistance.")).font(.callout).foregroundStyle(.secondary)
            }
            if model.state.history.isEmpty {
                ContentUnavailableView(
                    L10n.text("No results yet"), systemImage: "clock",
                    description: Text(L10n.text("Complete your first session to see answers and examples here.")))
            }
            ForEach(model.state.history.reversed(), id: \.key) { entry in
                if let verb = model.verbs.first(where: { $0.id == entry.id }) {
                    AttemptHistoryRow(model: model, entry: entry, verb: verb)
                }
            }
        }
    }
}
