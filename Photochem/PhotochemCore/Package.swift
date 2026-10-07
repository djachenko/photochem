// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PhotochemCore",
    platforms: [.iOS(.v18), .macOS(.v13)],
    products: [
        .library(name: "PhotochemCore", targets: ["PhotochemCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint", from: "0.62.2"),
    ],
    targets: [
        .target(
            name: "PhotochemCore",
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "PhotochemCoreTests",
            dependencies: ["PhotochemCore"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
    ]
)
