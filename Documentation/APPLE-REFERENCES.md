# Compatibility checks

The third-party agent skills are advisory, not evidence of API availability. The implementation is compiled against the installed Xcode 27.2 SDKs with iOS 18 and macOS 15 minimum targets. It runs in the installed iOS 26.5 Simulator; no iOS 27-only APIs are required.

Relevant official references checked:

- [SwiftUI Observation migration](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro): Observation support starts below this project's minimum targets. The UI model uses @MainActor @Observable with @State ownership and @Bindable projections.
- [Apple: Windows](https://developer.apple.com/documentation/swiftui/windows): platform scene behavior matters. The Mac app uses a single Window; the iPhone app uses WindowGroup. A Mac-only scene is never compiled for iOS.
- [Apple: WindowGroup](https://developer.apple.com/documentation/swiftui/windowgroup): standard platform scene/window ownership is retained.

A suggested speech-language view modifier was not accepted by the installed SDK and was removed. Dynamic Type, semantic labels and explicit progress accessibility values remain; German text receives a German locale environment. No claim of native VoiceOver user validation is made.

SwiftUI Pro's default iOS 27 deployment advice is intentionally not followed: stable APIs meet the product requirements and work with available simulator runtimes. test-modernizer explicitly excludes new test suites; new core tests use Swift Testing and UI automation uses XCTest.
