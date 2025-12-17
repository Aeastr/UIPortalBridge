// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "UIPortalBridge",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "UIPortalBridge",
            targets: ["UIPortalBridge"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Aeastr/Obfuscate.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "UIPortalBridge",
            dependencies: [
                .product(name: "Obfuscate", package: "Obfuscate")
            ]
        ),
    ]
)
