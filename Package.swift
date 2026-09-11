// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DesignPatternsInSwift",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "DesignPatterns",
            targets: ["DesignPatterns"]
        )
    ],
    targets: [
        .target(name: "DesignPatterns"),
        .testTarget(
            name: "DesignPatternsTests",
            dependencies: ["DesignPatterns"]
        )
    ]
)
