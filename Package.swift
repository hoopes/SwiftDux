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
  // The library builds clean in the Swift 6 language mode, and its tests build in it. It ships
  // in the Swift 5 mode for now, so it adds none of Swift 6's runtime isolation checks to an app
  // that has not moved yet; the compile-time annotations are the same either way.
  targets: [
    .target(
      name: "SwiftDux",
      dependencies: [],
      swiftSettings: [.swiftLanguageMode(.v5)]),
    .target(
      name: "SwiftDuxExtras",
      dependencies: ["SwiftDux"],
      swiftSettings: [.swiftLanguageMode(.v5)]),
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
