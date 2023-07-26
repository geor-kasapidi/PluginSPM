// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MyTarget",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "MyTarget", targets: ["MyTarget"]),
        .executable(name: "MyTargetDemo", targets: ["MyTargetDemo"]),
        .executable(name: "MyCommand", targets: ["MyCommand"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "MyTargetDemo",
            dependencies: ["MyTarget"]
        ),
        .target(
            name: "MyTarget",
            exclude: ["Files"],
            plugins: ["MyPlugin"]
        ),
        .plugin(
            name: "MyPlugin",
            capability: .buildTool(),
            dependencies: ["MyCompiledCommand"]
        ),
        .binaryTarget(
            name: "MyCompiledCommand",
            path: "mycommand.artifactbundle.zip"
        ),
        .executableTarget(
            name: "MyCommand",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
