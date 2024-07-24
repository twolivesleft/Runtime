// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Runtime",
    products: [
        .library(
            name: "Runtime",
            targets: ["AssetKit", "LuaKit", "Tools", "RuntimeKit", "CraftKit"]),
    ],
    targets: [
        .binaryTarget(
            name: "AssetKit",
            path: "./Frameworks/AssetKit.xcframework"),
        .binaryTarget(
            name: "LuaKit",
            path: "./Frameworks/LuaKit.xcframework"),
        .binaryTarget(
            name: "Tools",
            path: "./Frameworks/Tools.xcframework"),
        .binaryTarget(
            name: "RuntimeKit",
            path: "./Frameworks/RuntimeKit.xcframework"),
        .binaryTarget(
            name: "CraftKit",
            path: "./Frameworks/CraftKit.xcframework"),
    ]
)
