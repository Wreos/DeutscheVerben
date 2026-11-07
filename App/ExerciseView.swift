import SwiftUI
import VerbTrainerCore

struct ExerciseView: View {
    @Bindable var model: TrainerModel
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var colorScheme
    let verb: Verb
    let session: TrainingSession
    @FocusState private var focus: Field?
    enum Field: Hashable { case past, participle, aux }
    private var assisted: Bool { Training.assisted(model.state, id: verb.id, now: Date()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Глагол \(session.index + 1) из \(session.queue.count)").font(.subheadline).foregroundStyle(
                    .secondary)
                ProgressView(value: Double(session.index), total: Double(session.queue.count)).accessibilityLabel(
                    "Пройдено глаголов"
                ).accessibilityValue("\(session.index) из \(session.queue.count)")
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(verb.id).font(.largeTitle.bold()).accessibilityAddTraits(.isHeader).environment(
                        \.locale, Locale(identifier: "de-DE"))
                    Spacer()
                    Text(verb.level).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                }
                Text(verb.meaning).font(.title3)
                Text("Контекст: \(verb.context)").font(.callout).foregroundStyle(.secondary)
            }
            if assisted && session.checked == nil {
                Label("С опорой", systemImage: "book.closed").font(.callout).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Präteritum").font(.headline)
                    Text("Для ich / er / sie / es, без местоимения").font(.caption).foregroundStyle(.secondary)
                    TextField("Твоя форма Präteritum", text: $model.draft.past)
                        .focused($focus, equals: .past).onSubmit { focus = .participle }
                        .accessibilityIdentifier("past")
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Partizip II").font(.headline)
                    Text("Только причастие, без haben / sein").font(.caption).foregroundStyle(.secondary)
                    TextField("Твоя форма Partizip II", text: $model.draft.participle)
                        .focused($focus, equals: .participle).onSubmit { focus = .aux }
                        .accessibilityIdentifier("participle")
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Вспомогательный глагол").font(.headline)
                    Picker("Вспомогательный глагол", selection: $model.draft.aux) {
                        Text("Выбери").tag("")
                        Text("haben").tag("haben")
                        Text("sein").tag("sein")
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .focused($focus, equals: .aux)
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
                        session.index + 1 == session.queue.count ? "Посмотреть итог" : "Следующий глагол",
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
                    Label("Проверить", systemImage: "checkmark").foregroundStyle(
                        colorScheme == .dark ? Color.black : Color.white)
                }
                .buttonStyle(.borderedProminent).controlSize(.large).keyboardShortcut(.return, modifiers: [.command])
                .accessibilityIdentifier("check")
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 12) { helpButtons }.buttonStyle(.bordered).controlSize(.large)
                } else {
                    HStack { helpButtons }.buttonStyle(.bordered).controlSize(.large)
                }
                Text("Можно писать ae / oe / ue вместо ä / ö / ü и ss вместо ß.").font(.footnote).foregroundStyle(
                    .secondary)
                #if os(macOS)
                    Text("Tab — следующее поле · ⌘↵ — проверить").font(.caption).foregroundStyle(.secondary)
                #endif
            }
        }
    }
    @ViewBuilder private var helpButtons: some View {
        Button("Не знаю") {
            focus = nil
            model.submit("unknown")
        }.accessibilityIdentifier("unknown")
        Button("Изучить формы", systemImage: "eye") {
            focus = nil
            model.submit("reveal")
        }.accessibilityIdentifier("reveal")
    }
}
