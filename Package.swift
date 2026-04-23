// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Caesar",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(name: "CaesarCore", targets: ["CaesarCore"]),
        .executable(name: "Caesar", targets: ["Caesar"])
    ],
    targets: [
        .target(name: "CaesarCore"),
        .executableTarget(
            name: "Caesar",
            dependencies: ["CaesarCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CaesarTests",
            dependencies: ["CaesarCore"]
        )
    ],
    swiftLanguageModes: [.v6]
)
