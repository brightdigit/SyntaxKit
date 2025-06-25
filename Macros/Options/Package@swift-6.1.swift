// swift-tools-version: 6.1

// swiftlint:disable explicit_top_level_acl
// swiftlint:disable prefixed_toplevel_constant
// swiftlint:disable explicit_acl

import CompilerPluginSupport
import PackageDescription


let package = Package(
  name: "Options",
  platforms: [
    .macOS(.v13),
    .iOS(.v13),
    .watchOS(.v6),
    .tvOS(.v13),
    .visionOS(.v1)
  ],
  products: [
    .library(
      name: "Options",
      targets: ["Options"]
    )
  ],
  dependencies: [
    .package(path: "../.."),
    .package(url: "https://github.com/apple/swift-syntax.git", from: "601.0.1")
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0")
  ],
  targets: [
    .target(
      name: "Options",
      dependencies: ["OptionsMacros"]
    ),
    .macro(
      name: "OptionsMacros",
      dependencies: [
        .product(name: "SyntaxKit", package: "SyntaxKit"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
      ]
    ),
    .testTarget(
      name: "OptionsTests",
      dependencies: ["Options"]
    )
  ]
)

// swiftlint:enable explicit_top_level_acl
// swiftlint:enable prefixed_toplevel_constant
// swiftlint:enable explicit_acl
