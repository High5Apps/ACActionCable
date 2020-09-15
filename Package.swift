// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "ACActionCable",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "ACActionCable",
            targets: ["ACActionCable"]),
    ],
    targets: [
        .target(
            name: "ACActionCable"),
        .testTarget(
            name: "ACActionCableTests",
            dependencies: ["ACActionCable"]),
    ]
)
