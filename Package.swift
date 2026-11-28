// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Photochem",
    defaultLocalization: "ru",
    platforms: [
        .iOS(.v18),
    ],
    products: [
        .library(
            name: "PhotochemModule",
            targets: ["PhotochemModule"]
        ),
        .library(
            name: "PhotochemCore",
            targets: ["PhotochemCore"]
        ),
        .library(
            name: "PhotochemWidgetsUI",
            targets: ["PhotochemWidgetsUI"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/Swinject/Swinject",
            from: "2.10.0"
        ),
        .package(
            url: "https://github.com/Swinject/SwinjectAutoregistration",
            from: "2.9.1"
        ),
        .package(
            url: "https://github.com/djachenko/justkit-swift",
            .upToNextMinor(from: "0.1.0")
        ),
    ],
    targets: [
        .target(
            name: "PhotochemCore",
            path: "PhotochemModule/Core/Sources/PhotochemCore"
        ),
        .target(
            name: "PhotochemActivity",
            path: "PhotochemModule/Activity"
        ),
        .target(
            name: "PhotochemModule",
            dependencies: [
                "PhotochemCore",
                "PhotochemActivity",
                "Swinject",
                "SwinjectAutoregistration",
                .product(
                    name: "JustKitDI",
                    package: "justkit-swift"
                ),
                .product(
                    name: "ParaMap",
                    package: "justkit-swift"
                ),
            ],
            path: "PhotochemModule",
            exclude: ["Core", "Activity", "Widgets", "Tests", "Scripts"],
            sources: [
                "PhotochemModule.swift",
                "Constants.swift",
                "DI",
                "Model",
                "Preview",
                "Service",
                "View",
            ],
            resources: [
                .copy(
                    "Resources/Config"
                ),
                .process(
                    "Resources/Strings/Localizable.xcstrings"
                ),
                .process(
                    "Resources/Sounds"
                ),
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ]
        ),
        .target(
            name: "PhotochemWidgetsUI",
            dependencies: ["PhotochemActivity"],
            path: "PhotochemModule/Widgets",
            sources: [
                "DevelopmentActivityWidget.swift"
            ],
            resources: [
                .process("../Resources/Strings/Localizable.xcstrings")
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        ),
        .testTarget(
            name: "PhotochemCoreTests",
            dependencies: ["PhotochemCore"],
            path: "PhotochemModule/Core/Tests/PhotochemCoreTests"
        ),
    ]
)
