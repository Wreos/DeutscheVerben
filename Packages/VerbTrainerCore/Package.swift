// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VerbTrainerCore", platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "VerbTrainerCore", targets: ["VerbTrainerCore"])],
    targets: [
        .target(name: "VerbTrainerCore", resources: [.process("Resources")]),
        .testTarget(name: "VerbTrainerCoreTests", dependencies: ["VerbTrainerCore"], resources: [.process("Fixtures")]),
    ])
