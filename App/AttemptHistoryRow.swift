import SwiftUI
import VerbTrainerCore

struct AttemptHistoryRow: View {
    let model: TrainerModel
    let entry: Attempt
    let verb: Verb
    @State private var expanded = false
    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            FeedbackView(entry: entry, verb: verb)
            if let date = SpacedRepetition.parse(entry.at) {
                Text(date, format: .dateTime.day().month().year().hour().minute())
                    .font(.caption).foregroundStyle(.secondary)
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.id).font(.headline)
                Text(entry.assisted ? "С опорой" : "\(entry.result.score.formatted())/10").font(.callout)
                    .foregroundStyle(.secondary)
            }.padding(.vertical, 4)
        }
        .onAppear { if expanded { model.exposeHistory(verb, key: entry.key) } }
        .onDisappear { if expanded { model.hideVisibleHelp("history-" + entry.key) } }
        .onChange(of: expanded) {
            if expanded {
                model.exposeHistory(verb, key: entry.key)
            } else {
                model.hideVisibleHelp("history-" + entry.key)
            }
        }
    }
}
