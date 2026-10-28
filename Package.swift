// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Nudge",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "NudgeCore", targets: ["NudgeCore"]),
        .executable(name: "Nudge", targets: ["Nudge"]),
    ],
    targets: [
        .target(name: "NudgeCore"),
        .executableTarget(name: "Nudge", dependencies: ["NudgeCore"]),
        .testTarget(name: "NudgeCoreTests", dependencies: ["NudgeCore"]),
    ]
)
