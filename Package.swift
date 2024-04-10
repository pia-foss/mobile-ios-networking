// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NWHttpConnection",
    platforms: [
        .tvOS(.v17),
        .iOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "NWHttpConnection",
            targets: ["mobile-ios-networking"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "mobile-ios-networking"),
        .testTarget(
            name: "mobile-ios-networkingTests",
            dependencies: ["mobile-ios-networking"]),
    ]
)
