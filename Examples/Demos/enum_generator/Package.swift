// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "EnumGeneratorExample",
    platforms: [
        .macOS(.v13),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13)
    ],
    products: [
        .executable(name: "enum-generator-demo", targets: ["EnumGeneratorDemo"]),
        .executable(name: "integration-demo", targets: ["IntegrationDemo"])
    ],
    dependencies: [
        .package(path: "../../../") // SyntaxKit
    ],
    targets: [
        .executableTarget(
            name: "EnumGeneratorDemo",
            dependencies: ["SyntaxKit"],
            path: ".",
            sources: ["after/enum_generator.swift"]
        ),
        .executableTarget(
            name: "IntegrationDemo", 
            dependencies: [],
            path: ".",
            sources: ["integration_demo.swift"]
        )
    ]
)