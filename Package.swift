// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Glitter_IOS",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Glitter_IOS",
            targets: ["Glitter_IOS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sam38124/JzOsSqlHelper",from: "2.0.1"),
        .package(url: "https://github.com/sam38124/JzOsBleHelper",from: "1.0.5"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Glitter_IOS",
            dependencies: ["JzOsSqlHelper","JzOsBleHelper"]),
        .testTarget(
            name: "Glitter_IOSTests",
            dependencies: ["Glitter_IOS","JzOsSqlHelper","JzOsSqlHelper"]),
    ]
)
