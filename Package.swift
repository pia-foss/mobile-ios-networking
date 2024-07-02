// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NWHttpConnection",
    platforms: [
        .tvOS(.v16),
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "NWHttpConnection",
            targets: ["NWHttpConnection"]),
    ],
    targets: [
        .target(
            name: "NWHttpConnection",
            resources: [.process("Resources/")]
        ),
        .testTarget(
            name: "NWHttpConnectionTests",
            dependencies: ["NWHttpConnection"]),
    ]
)
