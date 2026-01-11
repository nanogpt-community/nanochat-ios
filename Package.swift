// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NanoChat",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "NanoChat",
            targets: ["NanoChat"])
    ],
    dependencies: [
        // Add external dependencies here if needed
    ],
    targets: [
        .target(
            name: "NanoChat",
            dependencies: [],
            path: "NanoChat",
            resources: [
                .process("Assets.xcassets")
            ]
        ),

    ]
)
