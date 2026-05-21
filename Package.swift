// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MacInstalls",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacInstalls", targets: ["MacInstalls"])
    ],
    targets: [
        .executableTarget(
            name: "MacInstalls",
            path: "Sources/MacInstalls"
        )
    ]
)
