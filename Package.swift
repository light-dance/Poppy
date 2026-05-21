// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Poppy",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "Poppy", targets: ["Poppy"])
    ],
    targets: [
        .executableTarget(
            name: "Poppy",
            path: "Sources/Poppy"
        )
    ]
)
