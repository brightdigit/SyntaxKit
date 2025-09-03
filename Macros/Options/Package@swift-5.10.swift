// swift-tools-version: 5.10

// swiftlint:disable explicit_top_level_acl
// swiftlint:disable prefixed_toplevel_constant
// swiftlint:disable explicit_acl

import CompilerPluginSupport
import PackageDescription

let swiftSettings = [
  SwiftSetting.enableUpcomingFeature("BareSlashRegexLiterals"),
  SwiftSetting.enableUpcomingFeature("ConciseMagicFile"),
  SwiftSetting.enableUpcomingFeature("ExistentialAny"),
  SwiftSetting.enableUpcomingFeature("ForwardTrailingClosures"),
  SwiftSetting.enableUpcomingFeature("ImplicitOpenExistentials"),
  SwiftSetting.enableUpcomingFeature("StrictConcurrency"),
  SwiftSetting.enableUpcomingFeature("DisableOutwardActorInference"),
  SwiftSetting.enableExperimentalFeature("StrictConcurrency")
]

let package = Package(
  name: "Options",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
    .macCatalyst(.v13),
    .visionOS(.v1)
  ],
  products: [
    .library(
      name: "Options",
      targets: ["Options"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax", from: "510.0.0")
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0")
  ],
  targets: [
    .target(
      name: "Options",
      dependencies: ["OptionsMacros"],
      swiftSettings: swiftSettings
    ),
    .macro(
      name: "OptionsMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
      ],
      swiftSettings: swiftSettings
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
