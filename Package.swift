// swift-tools-version: 5.7

import PackageDescription

// Version: 2.0.0
// Mte Version: 4.1.0

let package = Package(
    name: "SocketXClient",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "SocketXClient",
            targets: ["SocketXClient", "mte", "Mte", "Core", "MKE", "Kyber"]),
    ],
    targets: [
        .target(
            name: "SocketXClient",
            dependencies: [
                .target(name: "Mte"),
                .target(name: "Core"),
                .target(name: "MKE"),
                .target(name: "Kyber"),
            ],
            path: "SocketXClient"
        ),
        .binaryTarget(
            name: "mte",
            path: "Mte/mte.xcframework"
        ),
        .target(
            name: "Mte",
            dependencies: [
                .target(name: "mte")
            ],
            path: "Mte",
            exclude: ["mte.xcframework"]
        ),
        .target(
            name: "Core",
            dependencies: [
                .target(name: "Mte")
            ],
            path: "Core",
            swiftSettings: [
                .define("MTE_SWIFT_PACKAGE_MANAGER")
            ]
        ),
        .target(
            name: "MKE",
            dependencies: [
                .target(name: "Core")
            ],
            path: "MKE",
            swiftSettings: [
                .define("MTE_SWIFT_PACKAGE_MANAGER")
            ]
        ),
        .target(
            name: "Kyber",
            dependencies: [
                .target(name: "Mte"),
                .target(name: "Core"),
            ],
            path: "Kyber",
            swiftSettings: [
                .define("MTE_SWIFT_PACKAGE_MANAGER")
            ]
        ),
    ]
)
