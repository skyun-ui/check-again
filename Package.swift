// swift-tools-version: 6.0
// Swift Package Manager는 저장소 맨 위의 Package.swift를 읽는다. 소스는 ReminderEngine/ 아래에 둔다.
import PackageDescription

let package = Package(
    name: "ReminderEngine",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "ReminderEngine", targets: ["ReminderEngine"]),
    ],
    targets: [
        .target(name: "ReminderEngine", path: "ReminderEngine/Sources/ReminderEngine"),
        .testTarget(
            name: "ReminderEngineTests",
            dependencies: ["ReminderEngine"],
            path: "ReminderEngine/Tests/ReminderEngineTests"
        ),
    ]
)
