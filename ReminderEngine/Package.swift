// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ReminderEngine",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "ReminderEngine", targets: ["ReminderEngine"]),
    ],
    targets: [
        .target(name: "ReminderEngine"),
        .testTarget(name: "ReminderEngineTests", dependencies: ["ReminderEngine"]),
    ]
)
