import SwiftUI

@main
struct DeutscheVerbenApp: App {
    @State private var model = TrainerModel()
    var body: some Scene {
        #if os(macOS)
            Window("Deutsche Verben", id: "main") {
                ContentView(model: model).frame(minWidth: 540, minHeight: 560)
            }.defaultSize(width: 900, height: 850)
        #else
            WindowGroup { ContentView(model: model) }
        #endif
    }
}
