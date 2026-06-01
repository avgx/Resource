// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Resource",
    products: [
        .library(
            name: "Resource",
            targets: ["Resource"]
        ),
    ],
    targets: [
        .target(
            name: "Resource"
        ),
        .testTarget(
            name: "ResourceTests",
            dependencies: ["Resource"]
        ),
    ]
)
