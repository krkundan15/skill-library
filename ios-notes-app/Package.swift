// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NotesApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "NotesShared", targets: ["NotesShared"]),
        .library(name: "NotesApp", targets: ["NotesApp"]),
        .library(name: "NotesWidget", targets: ["NotesWidget"]),
    ],
    targets: [
        // Shared models + services (used by both app and widget)
        .target(
            name: "NotesShared",
            path: "Sources/NotesShared",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        // Main app
        .target(
            name: "NotesApp",
            dependencies: ["NotesShared"],
            path: "Sources/NotesApp"
        ),
        // Widget extension
        .target(
            name: "NotesWidget",
            dependencies: ["NotesShared"],
            path: "Sources/NotesWidget"
        ),
        // Tests
        .testTarget(
            name: "NotesSharedTests",
            dependencies: ["NotesShared"],
            path: "Tests/NotesSharedTests"
        ),
    ]
)
