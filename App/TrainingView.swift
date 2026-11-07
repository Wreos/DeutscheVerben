import SwiftUI
import VerbTrainerCore

struct TrainingView: View {
    @Bindable var model: TrainerModel
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Picker("Учебный набор", selection: $model.selectedLevel) {
                    Text("Все глаголы").tag("all")
                    Text("Базовые · A1").tag("A1")
                    Text("Повседневные · A2").tag("A2")
                    Text("Расширение · B1").tag("B1")
                }.accessibilityIdentifier("level")
                if model.state.session != nil || model.mistakeCount > 0 {
                    approachControls
                }
                if model.locked {
                    ContentUnavailableView(
                        "Данные недоступны", systemImage: "externaldrive.badge.exclamationmark",
                        description: Text(
                            "Сохранённый файл оставлен без изменений. Подробности — в сообщении об ошибке."))
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
                        Text("Начнём с десяти?").font(.title2.weight(.semibold))
                        Text(
                            "Инфинитив и перевод видны. Остальные формы нужно вспомнить. Ответы появятся после проверки."
                        )
                        Button {
                            model.start()
                        } label: {
                            Label("Начать подход", systemImage: "arrow.right").foregroundStyle(
                                colorScheme == .dark ? Color.black : Color.white)
                        }.buttonStyle(.borderedProminent).controlSize(.large)
                    }.padding(.vertical, 28)
                }
                if let paused = model.state.paused, !paused.isEmpty {
                    Divider()
                    Text("Отложенные подходы").font(.headline)
                    ForEach(paused) { session in
                        Button {
                            model.resume(session.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(
                                        "\(session.level == "all" ? "Все глаголы" : session.level) · \(session.queue.count) глаголов"
                                    )
                                    Text("Продолжить с \(session.index + 1)").font(.caption).foregroundStyle(.secondary)
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
            ContentUnavailableView("Нет ошибок в этом наборе", systemImage: "checkmark.circle")
        } else if model.canPracticeWithHelp {
            ContentUnavailableView {
                Label("Формы уже были показаны", systemImage: "book.closed")
            } description: {
                Text("Можно потренироваться с опорой или выбрать другой набор.")
            } actions: {
                Button("Повторить с опорой") { model.start(withHelp: true) }
                    .buttonStyle(.borderedProminent)
            }
        } else {
            ContentUnavailableView(
                "На сегодня всё", systemImage: "checkmark.circle",
                description: Text("Посмотри даты повторений в «Прогрессе» или вернись завтра."))
        }
    }

    @ViewBuilder private var approachButtons: some View {
        if model.state.session != nil {
            Button("Новый подход", systemImage: "plus") { model.start() }.frame(
                maxWidth: .infinity, alignment: .leading)
        }
        if model.mistakeCount > 0 {
            Button("Ошибки: \(model.mistakeCount)", systemImage: "arrow.counterclockwise") {
                model.start(filter: "mistakes")
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
