// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StatusOverlayKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "StatusOverlayKit", targets: ["StatusOverlayKit"]),
    ],
    targets: [
        .target(
            name: "StatusOverlayKit",
            path: "Sources/StatusOverlayKit"
        ),
    ]
)
