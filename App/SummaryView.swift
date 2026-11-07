import SwiftUI
import VerbTrainerCore

struct SummaryView: View {
    @Environment(\.colorScheme) private var colorScheme
    let model: TrainerModel
    let session: TrainingSession
    private var independent: [Attempt] { session.results.filter { !$0.assisted } }
    private var average: String {
        independent.isEmpty
            ? "—"
            : ((independent.reduce(0) { $0 + $1.result.score } / Double(independent.count) * 10).rounded() / 10)
                .formatted() + "/10"
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label(L10n.text("Session complete"), systemImage: "checkmark.circle").font(.title2.weight(.semibold))
                .accessibilityIdentifier("summary")
            Text(
                L10n.format(
                    "Independent: %@ · Assisted: %@", String(describing: independent.count),
                    String(describing: session.results.count - independent.count)))
            Text(L10n.format("Average score: %@", String(describing: average))).font(.headline)
            ForEach(session.results) { entry in
                HStack {
                    Text(entry.id).font(.headline)
                    Spacer()
                    Text(entry.assisted ? L10n.text("assisted") : "\(entry.result.score.formatted())/10")
                        .foregroundStyle(
                            .secondary)
                }
            }
            Button {
                model.start()
            } label: {
                Label(L10n.text("Another session"), systemImage: "arrow.right").foregroundStyle(
                    colorScheme == .dark ? Color.black : Color.white)
            }.buttonStyle(.borderedProminent).controlSize(.large)
        }
    }
}
