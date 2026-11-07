import SwiftUI
import UniformTypeIdentifiers
import VerbTrainerCore

struct ContentView: View {
    @Bindable var model: TrainerModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = 0
    @State private var importing = false
    @State private var exporting = false
    @State private var confirmImport = false
    @State private var confirmRestore = false
    @State private var replacing = false
    @State private var document = ResultsDocument(data: Data())

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { TrainingView(model: model).navigationTitle("Тренировка") }
                .tabItem { Label("Тренировка", systemImage: "rectangle.and.pencil.and.ellipsis") }.tag(0)
            NavigationStack { ReferenceView(model: model).navigationTitle("Таблица") }
                .tabItem { Label("Таблица", systemImage: "book") }.tag(1)
            NavigationStack {
                LearningProgressView(
                    model: model,
                    onStart: {
                        model.start()
                        tab = 0
                    }
                ).navigationTitle("Прогресс")
            }
            .tabItem { Label("Прогресс", systemImage: "chart.bar") }.tag(2)
            NavigationStack {
                Form {
                    Section("Перенос прогресса") {
                        Text(
                            "Прогресс хранится на этом устройстве. Для переноса между iPhone и Mac экспортируй JSON и импортируй его на другом устройстве."
                        )
                        Button(
                            model.locked ? "Экспортировать исходный файл" : "Экспортировать JSON",
                            systemImage: "square.and.arrow.up"
                        ) { export() }
                        Button("Импортировать JSON", systemImage: "square.and.arrow.down") {
                            replacing = false
                            confirmImport = true
                        }.disabled(model.locked)
                        Button("Восстановить из JSON-копии", systemImage: "arrow.uturn.backward") {
                            confirmRestore = true
                        }
                        Text(
                            "Импорт добавляет историю и отложенные подходы. Существующие ответы сохраняются. Перед импортом создаётся резервная копия."
                        ).font(.footnote).foregroundStyle(.secondary)
                    }
                }.formStyle(.grouped).navigationTitle("Данные")
            }.tabItem { Label("Данные", systemImage: "folder") }.tag(3)
        }
        .task { await model.refreshAtDayBoundaries() }
        .onChange(of: scenePhase) { if scenePhase == .active { model.refreshVisibleHelp() } }
        .tint(
            colorScheme == .dark ? Color(red: 0.45, green: 0.80, blue: 0.67) : Color(red: 0.13, green: 0.34, blue: 0.29)
        )
        .alert(
            "Не удалось выполнить действие",
            isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })
        ) {
            Button("Понятно") { model.error = nil }
        } message: {
            Text(model.error ?? "")
        }
        .alert(
            "Результат импорта",
            isPresented: Binding(get: { model.notice != nil }, set: { if !$0 { model.notice = nil } })
        ) {
            Button("Готово") { model.notice = nil }
        } message: {
            Text(model.notice ?? "")
        }
        .confirmationDialog("Объединить историю из JSON?", isPresented: $confirmImport, titleVisibility: .visible) {
            Button("Выбрать файл и объединить") { importing = true }
        } message: {
            Text("Текущая история будет сохранена. Конфликтующие записи не заменяются.")
        }
        .confirmationDialog(
            "Заменить текущее состояние из копии?", isPresented: $confirmRestore, titleVisibility: .visible
        ) {
            Button("Выбрать копию для восстановления", role: .destructive) {
                replacing = true
                importing = true
            }
        } message: {
            Text(
                "Текущий прогресс будет заменён. Перед восстановлением сохраним его резервную копию. Для добавления результатов без замены используй импорт."
            )
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url): model.importFile(url, replacing: replacing)
            case .failure(let error): model.error = error.localizedDescription
            }
        }
        .fileExporter(
            isPresented: $exporting, document: document, contentType: .json,
            defaultFilename: "deutsche-verben-\(Training.day(Date()))"
        ) { result in
            if case .failure(let error) = result { model.error = error.localizedDescription }
        }
    }
    private func export() {
        do {
            document = ResultsDocument(
                data: try model.locked ? Data(contentsOf: model.store.url) : StateCodec.encode(model.state))
            exporting = true
        } catch { model.error = error.localizedDescription }
    }
}
