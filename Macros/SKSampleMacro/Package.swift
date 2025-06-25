// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SKSampleMacro",
    platforms: [
      .macOS(.v13),
      .iOS(.v13),
      .watchOS(.v6),
      .tvOS(.v13),
      .visionOS(.v1)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SKSampleMacro",
            targets: ["SKSampleMacro"]
        ),
        .executable(
            name: "SKSampleMacroClient",
            targets: ["SKSampleMacroClient"]
        ),
    ],
    dependencies: [
      .package(path: "../.."),
      .package(url: "https://github.com/apple/swift-syntax.git", from: "601.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "SKSampleMacroMacros",
            dependencies: [
                .product(name: "SyntaxKit", package: "SyntaxKit"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "SKSampleMacro", dependencies: ["SKSampleMacroMacros"]),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(name: "SKSampleMacroClient", dependencies: ["SKSampleMacro"]),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "SKSampleMacroTests",
            dependencies: [
                "SKSampleMacroMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
