// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "clipboard-history-mac",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "AquaPaste",
            targets: ["clipboard_history_mac"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "clipboard_history_mac",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ]
)
