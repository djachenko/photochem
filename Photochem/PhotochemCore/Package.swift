// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PhotochemCore",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "PhotochemCore", targets: ["PhotochemCore"])
    ],
    targets: [
        .target(name: "PhotochemCore"),
        .testTarget(name: "PhotochemCoreTests", dependencies: ["PhotochemCore"]),
    ]
)
