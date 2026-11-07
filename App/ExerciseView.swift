import SwiftUI
import VerbTrainerCore

struct ExerciseView: View {
    @Bindable var model: TrainerModel
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var colorScheme
    let verb: Verb
    let session: TrainingSession
    @FocusState private var focus: Field?
    enum Field: Hashable { case past, participle }
    private var assisted: Bool { Training.assisted(model.state, id: verb.id, now: Date()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(
                    L10n.format(
                        "Verb %@ of %@", String(describing: session.index + 1), String(describing: session.queue.count))
                ).font(.subheadline).foregroundStyle(
                    .secondary)
                ProgressView(value: Double(session.index), total: Double(session.queue.count)).accessibilityLabel(
                    L10n.text("Verbs completed")
                ).accessibilityValue(
                    L10n.format("%@ of %@", String(describing: session.index), String(describing: session.queue.count)))
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(verb.id).font(.largeTitle.bold()).accessibilityAddTraits(.isHeader).environment(
                        \.locale, Locale(identifier: "de-DE"))
                    Spacer()
                    Text(verb.level).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                }
                Text(verb.localizedMeaning).font(.title3)
                Text(L10n.format("Context: %@", String(describing: verb.localizedContext))).font(.callout)
                    .foregroundStyle(.secondary)
            }
            if assisted && session.checked == nil {
                Label(L10n.text("Assisted"), systemImage: "book.closed").font(.callout).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Präteritum").font(.headline)
                    Text(L10n.text("For ich / er / sie / es, without the pronoun")).font(.caption).foregroundStyle(
                        .secondary)
                    TextField(L10n.text("Your Präteritum form"), text: $model.draft.past)
                        .focused($focus, equals: .past).onSubmit { focus = .participle }
                        .accessibilityIdentifier("past")
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Partizip II").font(.headline)
                    Text(L10n.text("Include hat or ist before Partizip II. You can also use haben or sein.")).font(
                        .caption
                    ).foregroundStyle(.secondary)
                    TextField(L10n.text("hat / ist + Partizip II"), text: $model.draft.perfectInput)
                        .focused($focus, equals: .participle)
                        .accessibilityIdentifier("participle")
                }

            }
            .textFieldStyle(.roundedBorder).controlSize(.large).autocorrectionDisabled()
            #if os(iOS)
                .textInputAutocapitalization(.never)
            #endif
            .disabled(session.checked != nil)

            if let entry = session.checked {
                FeedbackView(entry: entry, verb: verb).onAppear { model.noteVisibleFeedback(verb) }.onDisappear {
                    model.hideVisibleHelp("feedback")
                }
                Button {
                    model.next()
                } label: {
                    Label(
                        session.index + 1 == session.queue.count ? L10n.text("View summary") : L10n.text("Next verb"),
                        systemImage: "arrow.right"
                    ).foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                }
                .buttonStyle(.borderedProminent).controlSize(.large).keyboardShortcut(.return, modifiers: [])
                .accessibilityIdentifier("next")
            } else {
                Button {
                    focus = nil
                    model.submit("answer")
                } label: {
                    Label(L10n.text("Check"), systemImage: "checkmark").foregroundStyle(
                        colorScheme == .dark ? Color.black : Color.white)
                }
                .buttonStyle(.borderedProminent).controlSize(.large).keyboardShortcut(.return, modifiers: [.command])
                .accessibilityIdentifier("check")
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 12) { helpButtons }.buttonStyle(.bordered).controlSize(.large)
                } else {
                    HStack { helpButtons }.buttonStyle(.bordered).controlSize(.large)
                }
                Text(L10n.text("You can use ae / oe / ue for ä / ö / ü and ss for ß.")).font(.footnote).foregroundStyle(
                    .secondary)
                #if os(macOS)
                    Text(L10n.text("Tab — next field · ⌘↵ — check")).font(.caption).foregroundStyle(.secondary)
                #endif
            }
        }
    }
    @ViewBuilder private var helpButtons: some View {
        Button(L10n.text("I don't know")) {
            focus = nil
            model.submit("unknown")
        }.accessibilityIdentifier("unknown")
        Button(L10n.text("Study forms"), systemImage: "eye") {
            focus = nil
            model.submit("reveal")
        }.accessibilityIdentifier("reveal")
    }
}
