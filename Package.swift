// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// swiftlint:disable:next explicit_top_level_acl explicit_acl
let package = Package(
  name: "SyntaxKit",
  platforms: [
    .macOS(.v13),
    .iOS(.v13),
    .watchOS(.v6),
    .tvOS(.v13),
    .visionOS(.v1)
  ],
  products: [
    .library(
      name: "SyntaxKit",
      targets: ["SyntaxKit"]
    ),
    .executable(
      name: "skit",
      targets: ["skit"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax.git", from: "601.0.1"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0")
  ],
  targets: [
    .target(
      name: "SyntaxKit",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax")
      ]
    ),
    .executableTarget(
      name: "skit",
      dependencies: ["SyntaxKit"]
    ),
    .testTarget(
      name: "SyntaxKitTests",
      dependencies: ["SyntaxKit"]
    ),
  ]
)
