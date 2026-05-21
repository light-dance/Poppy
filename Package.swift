// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacInstalls",
    platforms: [
        .macOS(.v15)
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
