// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-bridge",
    platforms: [
        .macOS(.v15) // Ensure alignment with your build.rs minimum target string
    ],
    products: [
        .library(
            name: "swift-bridge",
            type: .static,
            targets: ["SwiftBridge"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Brendonovich/swift-rs", from: "1.0.6")
    ],
    targets: [
        .target(
            name: "SwiftBridge",
            dependencies: [
                .product(
                    name: "SwiftRs",
                    package: "swift-rs"
                )
            ],
        )
    ],
    swiftLanguageModes: [.v6]
)
