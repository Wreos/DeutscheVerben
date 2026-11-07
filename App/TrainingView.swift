import SwiftUI
import VerbTrainerCore

struct TrainingView: View {
    @Bindable var model: TrainerModel
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Picker(L10n.text("Study group"), selection: $model.selectedLevel) {
                    Text(L10n.text("All verbs")).tag("all")
                    Text(L10n.text("Basics · A1")).tag("A1")
                    Text(L10n.text("Everyday · A2")).tag("A2")
                    Text(L10n.text("Extended · B1")).tag("B1")
                }.accessibilityIdentifier("level")
                if model.state.session != nil || model.mistakeCount > 0 {
                    approachControls
                }
                if model.locked {
                    ContentUnavailableView(
                        L10n.text("Data unavailable"), systemImage: "externaldrive.badge.exclamationmark",
                        description: Text(
                            L10n.text("The saved file has been preserved. See the error message for details.")))
                } else if let session = model.state.session {
                    if session.queue.isEmpty {
                        emptyQueue(session)
                    } else if session.finished {
                        SummaryView(model: model, session: session)
                    } else if let verb = model.current {
                        ExerciseView(model: model, verb: verb, session: session).id(
                            session.id + "-" + String(session.index))
                    }
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(L10n.text("Ready for ten verbs?")).font(.title2.weight(.semibold))
                        Text(
                            L10n.text(
                                "The infinitive and meaning are shown. Recall the other forms. Answers appear after checking."
                            )
                        )
                        Button {
                            model.start()
                        } label: {
                            Label(L10n.text("Start session"), systemImage: "arrow.right").foregroundStyle(
                                colorScheme == .dark ? Color.black : Color.white)
                        }.buttonStyle(.borderedProminent).controlSize(.large)
                    }.padding(.vertical, 28)
                }
                if let paused = model.state.paused, !paused.isEmpty {
                    Divider()
                    Text(L10n.text("Paused sessions")).font(.headline)
                    ForEach(paused) { session in
                        Button {
                            model.resume(session.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(
                                        L10n.format(
                                            "%@ · %@ verbs",
                                            String(
                                                describing: session.level == "all"
                                                    ? L10n.text("All verbs") : session.level),
                                            String(describing: session.queue.count))
                                    )
                                    Text(L10n.format("Continue from %@", String(describing: session.index + 1))).font(
                                        .caption
                                    ).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "play")
                            }
                        }.buttonStyle(.bordered).controlSize(.large).accessibilityIdentifier("resume")
                    }
                }
            }.padding(24).frame(maxWidth: 720, alignment: .leading).frame(maxWidth: .infinity)
        }.disabled(model.locked)
    }
    @ViewBuilder private var approachControls: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) { approachButtons }
                .buttonStyle(.bordered).controlSize(.large)
        } else {
            HStack { approachButtons }.buttonStyle(.bordered).controlSize(.large)
        }
    }

    @ViewBuilder private func emptyQueue(_ session: TrainingSession) -> some View {
        if session.filter == "mistakes" {
            ContentUnavailableView(L10n.text("No mistakes in this group"), systemImage: "checkmark.circle")
        } else if model.canPracticeWithHelp {
            ContentUnavailableView {
                Label(L10n.text("Forms already shown"), systemImage: "book.closed")
            } description: {
                Text(L10n.text("Practise with assistance or choose another group."))
            } actions: {
                Button(L10n.text("Practise with assistance")) { model.start(withHelp: true) }
                    .buttonStyle(.borderedProminent)
            }
        } else {
            ContentUnavailableView(
                L10n.text("All done for today"), systemImage: "checkmark.circle",
                description: Text(L10n.text("Check review dates in Progress or come back tomorrow.")))
        }
    }

    @ViewBuilder private var approachButtons: some View {
        if model.state.session != nil {
            Button(L10n.text("New session"), systemImage: "plus") { model.start() }.frame(
                maxWidth: .infinity, alignment: .leading)
        }
        if model.mistakeCount > 0 {
            Button(
                L10n.format("Mistakes: %@", String(describing: model.mistakeCount)),
                systemImage: "arrow.counterclockwise"
            ) {
                model.start(filter: "mistakes")
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
