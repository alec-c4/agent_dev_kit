// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MinimalSwift",
    targets: [
        .target(name: "MinimalSwift"),
        .testTarget(name: "MinimalSwiftTests", dependencies: ["MinimalSwift"]),
    ]
)
