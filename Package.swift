// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GossipStone",
    platforms: [.macOS(.v14), .iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "GossipStone", targets: ["GossipStone"]),
    ],
    targets: [
        .target(
            name: "GossipStone",
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
        .testTarget(name: "GossipStoneTests", dependencies: ["GossipStone"]),
    ]
)
