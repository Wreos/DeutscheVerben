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
            NavigationStack { TrainingView(model: model).navigationTitle(L10n.text("Practice")) }
                .tabItem { Label(L10n.text("Practice"), systemImage: "rectangle.and.pencil.and.ellipsis") }.tag(0)
            NavigationStack { ReferenceView(model: model).navigationTitle(L10n.text("Reference")) }
                .tabItem { Label(L10n.text("Reference"), systemImage: "book") }.tag(1)
            NavigationStack {
                LearningProgressView(
                    model: model,
                    onStart: {
                        model.start()
                        tab = 0
                    }
                ).navigationTitle(L10n.text("Progress"))
            }
            .tabItem { Label(L10n.text("Progress"), systemImage: "chart.bar") }.tag(2)
            NavigationStack {
                Form {
                    Section(L10n.text("Transfer progress")) {
                        Text(
                            L10n.text(
                                "Progress is stored on this device. To transfer it between iPhone and Mac, export JSON and import it on the other device."
                            )
                        )
                        Button(
                            model.locked ? L10n.text("Export original file") : L10n.text("Export JSON"),
                            systemImage: "square.and.arrow.up"
                        ) { export() }
                        Button(L10n.text("Import JSON"), systemImage: "square.and.arrow.down") {
                            replacing = false
                            confirmImport = true
                        }.disabled(model.locked)
                        Button(L10n.text("Restore from JSON backup"), systemImage: "arrow.uturn.backward") {
                            confirmRestore = true
                        }
                        Text(
                            L10n.text(
                                "Import adds history and paused sessions. Existing answers are preserved. A backup is created before importing."
                            )
                        ).font(.footnote).foregroundStyle(.secondary)
                    }
                }.formStyle(.grouped).navigationTitle(L10n.text("Data"))
            }.tabItem { Label(L10n.text("Data"), systemImage: "folder") }.tag(3)
        }
        .task { await model.refreshAtDayBoundaries() }
        .onChange(of: scenePhase) { if scenePhase == .active { model.refreshVisibleHelp() } }
        .tint(
            colorScheme == .dark ? Color(red: 0.45, green: 0.80, blue: 0.67) : Color(red: 0.13, green: 0.34, blue: 0.29)
        )
        .alert(
            L10n.text("Action failed"),
            isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })
        ) {
            Button(L10n.text("OK")) { model.error = nil }
        } message: {
            Text(model.error ?? "")
        }
        .alert(
            L10n.text("Import result"),
            isPresented: Binding(get: { model.notice != nil }, set: { if !$0 { model.notice = nil } })
        ) {
            Button(L10n.text("Done")) { model.notice = nil }
        } message: {
            Text(model.notice ?? "")
        }
        .confirmationDialog(
            L10n.text("Merge history from JSON?"), isPresented: $confirmImport, titleVisibility: .visible
        ) {
            Button(L10n.text("Choose file and merge")) { importing = true }
        } message: {
            Text(L10n.text("Your current history will be preserved. Conflicting records will stop the import."))
        }
        .confirmationDialog(
            L10n.text("Replace current state from a backup?"), isPresented: $confirmRestore, titleVisibility: .visible
        ) {
            Button(L10n.text("Choose backup to restore"), role: .destructive) {
                replacing = true
                importing = true
            }
        } message: {
            Text(
                L10n.text(
                    "Your current progress will be replaced after creating a backup. Use Import to add results to your current history."
                )
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
