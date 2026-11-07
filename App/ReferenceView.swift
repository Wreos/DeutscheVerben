import SwiftUI
import VerbTrainerCore

struct ReferenceView: View {
    let model: TrainerModel
    @State private var query = ""
    @State private var level = "all"
    @State private var detail: Verb?
    @State private var showingRules = false
    @State private var visibleRows: Set<String> = []
    @State private var isVisible = false
    @State private var revealedSessionID: String?
    @Environment(\.dynamicTypeSize) private var typeSize

    private var rows: [Verb] {
        let search = Grading.comparable(query)
        return model.verbs.filter { verb in
            guard level == "all" || verb.level == level else { return false }
            let terms =
                [verb.id, verb.localizedMeaning, verb.past, verb.participle, verb.aux, perfectForm(verb)]
                + (verb.pastAlternatives ?? [])
            return search.isEmpty || Grading.comparable(terms.joined(separator: " ")).contains(search)
        }
    }

    private var hidesForms: Bool {
        guard let session = model.state.session else { return false }
        return !session.finished && !session.exposed && revealedSessionID != session.id
    }

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 720 && !typeSize.isAccessibilitySize
            let tableWidth = max(0, geometry.size.width - 40)
            let titles =
                wide
                ? ["Infinitiv", L10n.text("Meaning"), "Präteritum", "Partizip II"]
                : ["Infinitiv", "Präteritum", "Partizip II"]
            let ratios: [CGFloat] = wide ? [0.17, 0.25, 0.21, 0.37] : [0.32, 0.27, 0.41]
            let widths = ratios.map { max(0, tableWidth - CGFloat(titles.count - 1) * 10) * $0 }

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            groupPicker
                            Spacer()
                            rulesButton
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            groupPicker
                            rulesButton
                        }
                    }
                    if !hidesForms {
                        Text(L10n.text("Viewing forms counts as assistance.")).font(.footnote).foregroundStyle(
                            .secondary)
                    }
                }.padding(.horizontal, 20).padding(.vertical, 12)
                Divider()
                if hidesForms {
                    ContentUnavailableView {
                        Label(L10n.text("Session in progress"), systemImage: "book.closed")
                    } description: {
                        Text(L10n.text("Revealing forms will mark the rest of this session as assisted."))
                    } actions: {
                        Button(L10n.text("Reveal forms")) { revealedSessionID = model.state.session?.id }
                            .buttonStyle(.borderedProminent)
                    }
                } else if rows.isEmpty {
                    ContentUnavailableView.search(text: query).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            Section {
                                ForEach(rows) { verb in
                                    Button {
                                        detail = verb
                                    } label: {
                                        row(verb, wide: wide, widths: widths)
                                            .padding(.horizontal, 20).padding(.vertical, 10)
                                            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(accessibleRow(verb))
                                    .accessibilityHint(L10n.text("Open context and example"))
                                    .accessibilityIdentifier("reference-\(verb.id)")
                                    .onScrollVisibilityChange(threshold: 0.01) { visible in
                                        if visible { visibleRows.insert(verb.id) } else { visibleRows.remove(verb.id) }
                                    }
                                    Divider().padding(.horizontal, 20)
                                }
                            } header: {
                                VStack(spacing: 0) {
                                    HStack(spacing: 10) {
                                        ForEach(titles.indices, id: \.self) { index in
                                            column(widths[index]) {
                                                Text(titles[index]).font(.caption.weight(.semibold)).foregroundStyle(
                                                    .secondary)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20).padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    Divider()
                                }
                                .background(.background)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(titles.joined(separator: ", "))
                                .accessibilityAddTraits(.isHeader)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $query, prompt: L10n.text("Verb, form or meaning"))
        .sheet(item: $detail, onDismiss: { updateExposure() }) { verb in
            referenceSheet(verb.id) {
                Text(verb.localizedMeaning).font(.title3)
                LabeledContent(L10n.text("Group"), value: verb.level)
                LabeledContent("Präteritum", value: pastForms(verb))
                LabeledContent("Partizip II") { participleText(verb) }
                Text(verb.localizedContext)
                Text(verb.example).italic().environment(\.locale, Locale(identifier: "de-DE"))
            }
            .onAppear { model.exposeReference([verb.id]) }
        }
        .sheet(isPresented: $showingRules) {
            referenceSheet(L10n.text("Rules")) { RulesView() }
        }
        .onAppear {
            isVisible = true
            updateExposure()
        }
        .onDisappear {
            isVisible = false
            model.hideVisibleHelp("reference")
        }
        .onChange(of: visibleRows) { updateExposure() }
        .onChange(of: hidesForms) {
            if hidesForms { model.hideVisibleHelp("reference") } else { updateExposure() }
        }
        .onChange(of: query) { updateExposure() }
        .onChange(of: level) { updateExposure() }
    }

    private func updateExposure() {
        guard isVisible, !hidesForms, detail == nil else { return }
        model.exposeReference(rows.map(\.id).filter(visibleRows.contains))
    }

    private var groupPicker: some View {
        Picker(L10n.text("Group"), selection: $level) {
            Text(L10n.text("All groups")).tag("all")
            Text("A1").tag("A1")
            Text("A2").tag("A2")
            Text("B1").tag("B1")
        }.fixedSize(horizontal: true, vertical: false)
    }

    private var rulesButton: some View {
        Button(L10n.text("Rules"), systemImage: "book") { showingRules = true }
            .buttonStyle(.bordered)
    }

    private func column<V: View>(_ width: CGFloat, @ViewBuilder content: () -> V) -> some View {
        content().fixedSize(horizontal: false, vertical: true).frame(width: width, alignment: .leading)
    }

    private func row(_ verb: Verb, wide: Bool, widths: [CGFloat]) -> some View {
        HStack(alignment: .top, spacing: 10) {
            column(widths[0]) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(verb.id).font(.body.weight(.semibold)).foregroundStyle(Color.accentColor)
                    if !wide { Text(verb.localizedMeaning).font(.caption).foregroundStyle(.secondary) }
                }
            }
            if wide { column(widths[1]) { Text(verb.localizedMeaning).font(.callout) } }
            column(widths[wide ? 2 : 1]) { Text(pastForms(verb)).font(.callout) }
            column(widths[wide ? 3 : 2]) {
                participleText(verb).font(.callout)
            }
        }
    }

    private func pastForms(_ verb: Verb) -> String {
        ([verb.past] + (verb.pastAlternatives ?? [])).joined(separator: " / ")
    }

    private func auxiliary(_ verb: Verb) -> String { verb.aux == "sein" ? "ist" : "hat" }

    private func perfectForm(_ verb: Verb) -> String { "\(auxiliary(verb)) \(verb.participle)" }

    private func participleText(_ verb: Verb) -> Text {
        Text("\(Text(auxiliary(verb)).foregroundStyle(.secondary)) \(verb.participle)")
    }

    private func accessibleRow(_ verb: Verb) -> String {
        L10n.format(
            "%@, %@. Präteritum: %@. Partizip II: %@. With auxiliary: %@.", String(describing: verb.id),
            String(describing: verb.localizedMeaning), String(describing: pastForms(verb)),
            String(describing: verb.participle), String(describing: perfectForm(verb)))
    }

    private func referenceSheet<V: View>(_ title: String, @ViewBuilder content: () -> V) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16, content: content)
                    .frame(maxWidth: 580, alignment: .leading).padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("Done")) {
                        detail = nil
                        showingRules = false
                    }
                }
            }
        }
        #if os(macOS)
            .frame(minWidth: 460, minHeight: 360)
        #endif
    }
}
