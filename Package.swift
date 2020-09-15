// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "ActionCableSwift",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "ActionCableSwift",
            targets: ["ActionCableSwift"]),
    ],
    targets: [
        .target(
            name: "ActionCableSwift"),
        .testTarget(
            name: "ActionCableSwiftTests",
            dependencies: ["ActionCableSwift"]),
    ]
)
