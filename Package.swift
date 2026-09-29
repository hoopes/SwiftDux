// swift-tools-version:6.0

import PackageDescription

let package = Package(
  name: "SwiftDux",
  platforms: [
    .iOS(.v14),
    .macOS(.v11),
  ],
  products: [
    .library(
      name: "SwiftDux",
      targets: ["SwiftDux", "SwiftDuxExtras"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.8.2")
  ],
  targets: [
    .target(
      name: "SwiftDux",
      dependencies: []),
    .target(
      name: "SwiftDuxExtras",
      dependencies: ["SwiftDux"]),
    .testTarget(
      name: "SwiftDuxTests",
      dependencies: [
        "SwiftDux",
        "SwiftDuxExtras",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
      ],
      exclude: ["UI/__Snapshots__"]),
  ]
)
