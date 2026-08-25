// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "facebook_share_callback",
    platforms: [
        .iOS("15.0"),
    ],
    products: [
        .library(name: "facebook-share-callback", targets: ["facebook_share_callback"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(
            url: "https://github.com/facebook/facebook-ios-sdk.git",
            .upToNextMajor(from: "18.1.0")
        ),
    ],
    targets: [
        .target(
            name: "facebook_share_callback",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "FacebookShare", package: "facebook-ios-sdk"),
            ]
        ),
    ]
)
