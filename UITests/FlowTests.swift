import XCTest

#if os(macOS)
    import AppKit
#endif

final class FlowTests: XCTestCase {
    @MainActor func testCompleteRestoreAndAssistance() throws {
        let app = localizedApp("ru")
        app.launchEnvironment["DV_TEST_STORE"] = NSTemporaryDirectory() + "dv-ui-\(UUID().uuidString).json"
        app.launch()
        app.buttons["Начать подход"].tap()
        XCTAssertTrue(app.textFields["past"].waitForExistence(timeout: 10))
        capture(app, "exercise")
        app.textFields["past"].tap()
        enter("war", field: app.textFields["past"], app: app)
        app.terminate()
        app.launch()
        XCTAssertEqual(app.textFields["past"].value as? String, "war")
        app.textFields["participle"].tap()
        enter("gewesen", field: app.textFields["participle"], app: app)
        #if os(macOS)
            app.radioButtons["sein"].tap()
        #else
            app.buttons["sein"].tap()
        #endif
        reveal(app.buttons["check"], app: app)
        app.buttons["check"].tap()
        XCTAssertTrue(app.staticTexts["score"].waitForExistence(timeout: 5))
        capture(app, "feedback")
        reveal(app.buttons["next"], app: app)
        app.buttons["next"].tap()
        for _ in 1..<10 {
            let unknown = app.buttons["unknown"]
            reveal(unknown, app: app)
            unknown.tap()
            let next = app.buttons["next"]
            reveal(next, app: app)
            next.tap()
        }
        XCTAssertTrue(app.staticTexts["summary"].waitForExistence(timeout: 5))
        capture(app, "summary")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["summary"].waitForExistence(timeout: 5))
    }
    #if os(macOS)
        @MainActor func testMacLaunchScreenshot() throws {
            let app = localizedApp("ru")
            app.launchEnvironment["DV_TEST_STORE"] = NSTemporaryDirectory() + "dv-mac-capture-\(UUID().uuidString).json"
            app.launch()
            XCTAssertTrue(app.buttons["Начать подход"].exists)
            capture(app, "mac-launch")
        }
    #endif
    #if os(iOS)
        @MainActor func testReferenceSearchByDisplayedForm() {
            let app = localizedApp("ru")
            app.launchEnvironment["DV_TEST_STORE"] = NSTemporaryDirectory() + "dv-search-\(UUID().uuidString).json"
            app.launch()
            selectTab("Таблица", app: app)
            let search = app.searchFields.firstMatch
            XCTAssertTrue(search.waitForExistence(timeout: 5))
            search.tap()
            search.typeText("ist gegangen")
            XCTAssertTrue(app.buttons["reference-gehen"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["reference-haben"].exists)
        }

        @MainActor func testDraftSurvivesCrossGroupResume() {
            let app = localizedApp("ru")
            app.launchEnvironment["DV_TEST_STORE"] = NSTemporaryDirectory() + "dv-pause-\(UUID().uuidString).json"
            app.launch()
            app.buttons["Начать подход"].tap()
            let past = app.textFields["past"]
            past.tap()
            past.typeText("saved draft")
            app.swipeDown()
            app.buttons["level"].tap()
            app.buttons["Повседневные · A2"].tap()
            if !app.buttons["resume"].isHittable { app.swipeUp() }
            app.buttons["resume"].tap()
            XCTAssertEqual(app.textFields["past"].value as? String, "saved draft")
            app.terminate()
            app.launch()
            XCTAssertEqual(app.textFields["past"].value as? String, "saved draft")
        }
    #endif
    @MainActor func testBrowsingTableLeavesUnseenVerbsAvailable() throws {
        let app = localizedApp("ru")
        let path = NSTemporaryDirectory() + "dv-browse-\(UUID().uuidString).json"
        app.launchEnvironment["DV_TEST_STORE"] = path
        app.launch()
        selectTab("Таблица", app: app)
        XCTAssertTrue(app.buttons["reference-sein"].waitForExistence(timeout: 5))
        app.buttons["Правила"].tap()
        XCTAssertTrue(app.buttons["Готово"].waitForExistence(timeout: 5))
        app.buttons["Готово"].tap()
        selectTab("Тренировка", app: app)
        app.buttons["Начать подход"].tap()
        XCTAssertTrue(app.textFields["past"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["С опорой"].exists)
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let state = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let exposures = try XCTUnwrap(state["exposures"] as? [String: String])
        XCTAssertNotNil(exposures["sein"])
        XCTAssertLessThan(exposures.count, 60)
        capture(app, "practice-after-reference")

        selectTab("Таблица", app: app)
        XCTAssertTrue(app.buttons["Показать формы"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["reference-sein"].exists)
        app.buttons["Правила"].tap()
        app.buttons["Готово"].tap()
        selectTab("Тренировка", app: app)
        XCTAssertTrue(app.textFields["past"].exists)
        XCTAssertFalse(app.staticTexts["С опорой"].exists)

        selectTab("Таблица", app: app)
        app.buttons["Показать формы"].tap()
        XCTAssertTrue(app.buttons["reference-sein"].waitForExistence(timeout: 5))
        selectTab("Тренировка", app: app)
        XCTAssertTrue(app.staticTexts["С опорой"].waitForExistence(timeout: 5))
    }

    @MainActor func testProgressRulesAndHistory() throws {
        let app = localizedApp("ru")
        let path = NSTemporaryDirectory() + "dv-ui-synthetic-\(UUID().uuidString).json"
        let fixture = Bundle(for: Self.self).url(forResource: "synthetic-progress", withExtension: "json")!
        try Data(contentsOf: fixture).write(to: URL(fileURLWithPath: path))
        app.launchEnvironment["DV_TEST_STORE"] = path
        app.launch()
        selectTab("Прогресс", app: app)
        XCTAssertTrue(app.staticTexts["62% · 20 из 60 закреплены"].waitForExistence(timeout: 10))
        capture(app, "progress-synthetic")
        app.buttons["История исходных ответов"].tap()
        XCTAssertTrue(app.staticTexts["Открытие ответов учитывается как подсказка."].waitForExistence(timeout: 10))
        selectTab("Таблица", app: app)
        #if os(macOS)
            // macOS presents this navigation title as the window title, not StaticText.
            XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 10))
        #else
            XCTAssertTrue(app.staticTexts["Таблица"].firstMatch.waitForExistence(timeout: 10))
        #endif
        capture(app, "reference")
        let verbRow = app.buttons["reference-gehen"]
        XCTAssertTrue(verbRow.waitForExistence(timeout: 5))
        XCTAssertTrue(verbRow.label.contains("ist gegangen"))
        verbRow.tap()
        XCTAssertTrue(app.staticTexts["Ich bin nach Hause gegangen."].waitForExistence(timeout: 5))
        app.buttons["Готово"].tap()
        selectTab("Данные", app: app)
        XCTAssertTrue(app.buttons["Импортировать JSON"].exists)
        XCTAssertTrue(app.buttons["Восстановить из JSON-копии"].exists)
        capture(app, "data")
    }
    @MainActor func testSystemLanguageEnglish() {
        verifyLanguage("en", reference: "Reference", start: "Start session", meaning: "be")
    }

    @MainActor func testSystemLanguageGerman() {
        verifyLanguage("de", reference: "Tabelle", start: "Runde starten", meaning: "existieren")
    }

    @MainActor func testSystemLanguageRussian() {
        verifyLanguage("ru", reference: "Таблица", start: "Начать подход", meaning: "быть")
    }

    @MainActor func testUnsupportedLanguageFallsBackToEnglish() {
        verifyLanguage("fr", reference: "Reference", start: "Start session", meaning: "be")
    }

    @MainActor private func localizedApp(_ language: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(\(language))", "-AppleLocale",
            language == "en" ? "en_US" : "\(language)_\(language.uppercased())",
        ]
        return app
    }

    @MainActor private func verifyLanguage(
        _ language: String, reference: String, start: String, meaning: String
    ) {
        let app = localizedApp(language)
        app.launchEnvironment["DV_TEST_STORE"] = NSTemporaryDirectory() + "dv-language-\(UUID().uuidString).json"
        app.launch()
        XCTAssertTrue(app.buttons[start].waitForExistence(timeout: 10))
        selectTab(reference, app: app)
        let row = app.buttons["reference-sein"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains(meaning))
        if language == "en" {
            capture(app, "readme-reference")
        }
        row.tap()
        XCTAssertTrue(app.staticTexts["Ich bin gestern zu Hause gewesen."].waitForExistence(timeout: 5))
        let labels: (practice: String, done: String, error: String)
        switch language {
        case "de": labels = ("Training", "Fertig", "Aktion fehlgeschlagen")
        case "ru": labels = ("Тренировка", "Готово", "Не удалось выполнить действие")
        default: labels = ("Practice", "Done", "Action failed")
        }
        app.buttons[labels.done].tap()
        selectTab(labels.practice, app: app)
        app.buttons[start].tap()
        reveal(app.buttons["check"], app: app)
        app.buttons["check"].tap()
        XCTAssertTrue(app.staticTexts[labels.error].waitForExistence(timeout: 5))
        app.terminate()
    }

    @MainActor private func selectTab(_ title: String, app: XCUIApplication) {
        #if os(macOS)
            app.radioButtons[title].tap()
        #else
            app.tabBars.buttons[title].tap()
        #endif
    }
    @MainActor private func enter(_ text: String, field: XCUIElement, app: XCUIApplication) {
        #if os(macOS)
            let board = NSPasteboard.general
            let old = (board.pasteboardItems ?? []).map { item in
                let copy = NSPasteboardItem()
                for type in item.types { if let data = item.data(forType: type) { copy.setData(data, forType: type) } }
                return copy
            }
            defer {
                board.clearContents()
                board.writeObjects(old)
            }
            board.clearContents()
            board.setString(text, forType: .string)
            app.typeKey("v", modifierFlags: .command)
        #else
            field.typeText(text)
        #endif
    }
    @MainActor private func reveal(_ element: XCUIElement, app: XCUIApplication) {
        if !element.isHittable {
            #if os(macOS)
                app.scrollViews.firstMatch.scroll(byDeltaX: 0, deltaY: -600)
            #else
                app.swipeUp()
            #endif
        }
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        #if os(macOS)
            let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        #else
            let attachment = XCTAttachment(screenshot: app.screenshot())
        #endif
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
