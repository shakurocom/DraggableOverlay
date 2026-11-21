// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DraggableOverlay",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "DraggableOverlay",
            targets: ["DraggableOverlay"]),
    ],
    dependencies: [
        .package(url: "https://github.com/shakurocom/CommonTypes.git", from: "1.9.6"),
    ],
    targets: [
        .target(
            name: "DraggableOverlay",
            dependencies: [
                .product(name: "CommonTypes", package: "CommonTypes"),
            ],
            path: "Source"),
    ]
)
