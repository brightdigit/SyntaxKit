// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

// MARK: - Library Linkage

// The SyntaxKit library product is normally built with automatic (static)
// linkage. The self-contained skit release bundle (Scripts/build-skit-release.sh)
// needs a dynamic libSyntaxKit.dylib instead, so it sets SYNTAXKIT_DYNAMIC_LIB=1
// rather than patching this manifest in place.
// swiftlint:disable:next explicit_top_level_acl explicit_acl
let syntaxKitLibraryType: Product.Library.LibraryType? =
  ProcessInfo.processInfo.environment["SYNTAXKIT_DYNAMIC_LIB"] == "1" ? .dynamic : nil

// MARK: - Swift Settings Configuration

// swiftlint:disable:next explicit_top_level_acl explicit_acl
let swiftSettings: [SwiftSetting] = [
  // Swift 6.2 Upcoming Features (not yet enabled by default)
  // SE-0335: Introduce existential `any`
  .enableUpcomingFeature("ExistentialAny"),
  // SE-0409: Access-level modifiers on import declarations
  .enableUpcomingFeature("InternalImportsByDefault"),
  // SE-0444: Member import visibility (Swift 6.1+)
  .enableUpcomingFeature("MemberImportVisibility"),
  // SE-0413: Typed throws
  .enableUpcomingFeature("FullTypedThrows"),

  // Experimental Features (stable enough for use)
  // SE-0426: BitwiseCopyable protocol
  .enableExperimentalFeature("BitwiseCopyable"),
  // SE-0432: Borrowing and consuming pattern matching for noncopyable types
  .enableExperimentalFeature("BorrowingSwitch"),
  // Extension macros
  .enableExperimentalFeature("ExtensionMacros"),
  // Freestanding expression macros
  .enableExperimentalFeature("FreestandingExpressionMacros"),
  // Init accessors
  .enableExperimentalFeature("InitAccessors"),
  // Isolated any types
  .enableExperimentalFeature("IsolatedAny"),
  // Move-only classes
  .enableExperimentalFeature("MoveOnlyClasses"),
  // Move-only enum deinits
  .enableExperimentalFeature("MoveOnlyEnumDeinits"),
  // SE-0429: Partial consumption of noncopyable values
  .enableExperimentalFeature("MoveOnlyPartialConsumption"),
  // Move-only resilient types
  .enableExperimentalFeature("MoveOnlyResilientTypes"),
  // Move-only tuples
  .enableExperimentalFeature("MoveOnlyTuples"),
  // SE-0427: Noncopyable generics
  .enableExperimentalFeature("NoncopyableGenerics"),
  // One-way closure parameters
  // .enableExperimentalFeature("OneWayClosureParameters"),
  // Raw layout types
  .enableExperimentalFeature("RawLayout"),
  // Reference bindings
  .enableExperimentalFeature("ReferenceBindings"),
  // SE-0430: sending parameter and result values
  .enableExperimentalFeature("SendingArgsAndResults"),
  // Symbol linkage markers
  .enableExperimentalFeature("SymbolLinkageMarkers"),
  // Transferring args and results
  .enableExperimentalFeature("TransferringArgsAndResults"),
  // SE-0393: Value and Type Parameter Packs
  .enableExperimentalFeature("VariadicGenerics"),
  // Warn unsafe reflection
  .enableExperimentalFeature("WarnUnsafeReflection"),

  // Enhanced compiler checking
  // .unsafeFlags([
  //   // Enable concurrency warnings
  //   "-warn-concurrency",
  //   // Enable actor data race checks
  //   "-enable-actor-data-race-checks",
  //   // Complete strict concurrency checking
  //   "-strict-concurrency=complete",
  //   // Enable testing support
  //   "-enable-testing",
  //   // Warn about functions with >100 lines
  //   "-Xfrontend", "-warn-long-function-bodies=100",
  //   // Warn about slow type checking expressions
  //   "-Xfrontend", "-warn-long-expression-type-checking=100"
  // ])
]

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
      type: syntaxKitLibraryType,
      targets: ["SyntaxKit"]
    ),
    .executable(
      name: "skit",
      targets: ["skit"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.1"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    .package(url: "https://github.com/swiftlang/swift-subprocess.git", from: "0.4.0"),
    .package(url: "https://github.com/apple/swift-system.git", from: "1.0.0")
  ],
  targets: [
    .target(
      name: "SyntaxKit",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax")
      ],
      swiftSettings: swiftSettings
    ),
    .target(
      name: "TokenVisitor",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax")
      ],
      swiftSettings: swiftSettings
    ),
    .target(
      name: "SyntaxParser",
      dependencies: [
        "TokenVisitor",
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax")
      ],
      exclude: ["README.md"],
      swiftSettings: swiftSettings
    ),
    .target(
      name: "DocumentationHarness",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax")
      ],
      swiftSettings: swiftSettings
    ),
    .executableTarget(
      name: "skit",
      dependencies: [
        "SyntaxKit",
        "SyntaxParser",
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(
          name: "Subprocess",
          package: "swift-subprocess",
          condition: .when(platforms: [.macOS, .linux, .windows])
        ),
        .product(
          name: "SystemPackage",
          package: "swift-system",
          condition: .when(platforms: [.linux, .windows])
        )
      ],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "SyntaxKitTests",
      dependencies: [
        "SyntaxKit",
        .product(
          name: "Subprocess",
          package: "swift-subprocess",
          condition: .when(platforms: [.macOS, .linux, .windows])
        )
      ],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "SyntaxDocTests",
      dependencies: ["SyntaxKit", "DocumentationHarness"],
      swiftSettings: swiftSettings
    ),
  ]
)
