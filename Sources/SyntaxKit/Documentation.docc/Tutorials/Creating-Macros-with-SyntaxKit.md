# Creating Macros with SyntaxKit

Learn how to create Swift macros using SyntaxKit's declarative syntax.

## Overview

This tutorial walks you through creating a simple freestanding expression macro using SyntaxKit. We'll build a `#stringify` macro that takes two expressions and returns a tuple containing their sum and the source code that produced it.

## Prerequisites

- Swift 6.1 or later
- Xcode 15.0 or later
- Basic understanding of Swift macros

## Step 1: Create the Package Structure

First, create a new Swift package for your macro:

```bash
mkdir MyMacro
cd MyMacro
swift package init --type library
```

## Step 2: Configure Package.swift

Update your `Package.swift` to include the necessary dependencies and targets:

```swift
// swift-tools-version: 6.1
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "MyMacro",
    platforms: [
        .macOS(.v13),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "MyMacro",
            targets: ["MyMacro"]
        ),
        .executable(
            name: "MyMacroClient",
            targets: ["MyMacroClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/your-username/SyntaxKit.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "601.0.1")
    ],
    targets: [
        // Macro implementation
        .macro(
            name: "MyMacroMacros",
            dependencies: [
                .product(name: "SyntaxKit", package: "SyntaxKit"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        
        // Library that exposes the macro
        .target(name: "MyMacro", dependencies: ["MyMacroMacros"]),
        
        // Client executable
        .executableTarget(name: "MyMacroClient", dependencies: ["MyMacro"]),
        
        // Tests
        .testTarget(
            name: "MyMacroTests",
            dependencies: [
                "MyMacroMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
```

## Step 3: Create the Macro Implementation

Create the file `Sources/MyMacroMacros/StringifyMacro.swift`:

```swift
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros
import SyntaxKit

/// A freestanding expression macro that takes two expressions and returns
/// a tuple containing their sum and the source code that produced it.
///
/// For example:
/// ```swift
/// let (result, code) = #stringify(a + b)
/// ```
/// expands to:
/// ```swift
/// let (result, code) = (a + b, "a + b")
/// ```
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        // Extract the arguments from the macro
        let arguments = node.arguments
        
        // Ensure we have exactly two arguments
        guard arguments.count == 2,
              let firstArg = arguments.first?.expression,
              let secondArg = arguments.last?.expression else {
            fatalError("compiler bug: the macro does not have exactly two arguments")
        }
        
        // Build the result using SyntaxKit's declarative syntax
        return Tuple {
            // First element: the sum of the two expressions
            try Infix("+") {
                VariableExp(firstArg.description)
                VariableExp(secondArg.description)
            }
            
            // Second element: the source code as a string literal
            Literal.string("\(firstArg.description) + \(secondArg.description)")
        }.expr
    }
}
```

## Step 4: Create the Macro Plugin

Create the file `Sources/MyMacroMacros/MacroPlugin.swift`:

```swift
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MyMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
    ]
}
```

## Step 5: Create the Public API

Create the file `Sources/MyMacro/MyMacro.swift`:

```swift
/// A freestanding expression macro that takes two expressions and returns
/// a tuple containing their sum and the source code that produced it.
///
/// ## Example
/// ```swift
/// let a = 17
/// let b = 25
/// let (result, code) = #stringify(a, b)
/// // result = 42, code = "a + b"
/// ```
@freestanding(expression)
public macro stringify(_ first: Any, _ second: Any) -> (Any, String) = #externalMacro(
    module: "MyMacroMacros",
    type: "StringifyMacro"
)
```

## Step 6: Create a Client Example

Create the file `Sources/MyMacroClient/main.swift`:

```swift
import MyMacro

let a = 17
let b = 25

let (result, code) = #stringify(a, b)

print("The value \(result) was produced by the code \"\(code)\"")
// Output: The value 42 was produced by the code "a + b"
```

## Step 7: Test Your Macro

Create the file `Tests/MyMacroTests/StringifyMacroTests.swift`:

```swift
import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import MyMacroMacros

final class StringifyMacroTests: XCTestCase {
    func testStringifyMacro() {
        assertMacroExpansion(
            """
            let (result, code) = #stringify(a, b)
            """,
            expandedSource: """
            let (result, code) = (a + b, "a + b")
            """,
            macros: testMacros
        )
    }
    
    func testStringifyMacroWithLiterals() {
        assertMacroExpansion(
            """
            let (result, code) = #stringify(5, 3)
            """,
            expandedSource: """
            let (result, code) = (5 + 3, "5 + 3")
            """,
            macros: testMacros
        )
    }
}

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
]
```

## Step 8: Build and Run

Build your macro package:

```bash
swift build
```

Run the client example:

```bash
swift run MyMacroClient
```

## How It Works

1. **Macro Declaration**: The `@freestanding(expression)` attribute tells Swift that this is a freestanding expression macro.

2. **Macro Implementation**: The `StringifyMacro` struct implements the `ExpressionMacro` protocol, which requires an `expansion` method.

3. **SyntaxKit Integration**: Instead of manually building SwiftSyntax nodes, we use SyntaxKit's declarative syntax:
   - `Tuple { ... }` creates a tuple expression
   - `Infix("+") { ... }` creates an infix operator expression
   - `VariableExp(...)` creates a variable expression
   - `Literal.string(...)` creates a string literal

4. **Code Generation**: The macro expands `#stringify(a, b)` into `(a + b, "a + b")`.

## Advanced Example: Extension Macro

You can also create extension macros using SyntaxKit. Here's a simple example:

```swift
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros
import SyntaxKit

public struct AddDescriptionMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        // Get the type name
        let typeName = declaration.as(StructDeclSyntax.self)?.name ?? 
                      declaration.as(ClassDeclSyntax.self)?.name ?? 
                      declaration.as(EnumDeclSyntax.self)?.name
        
        guard let typeName else {
            throw MacroError("Macro can only be applied to structs, classes, or enums")
        }
        
        // Create an extension that adds a description property
        let extensionDecl = Extension(typeName.trimmed.text) {
            ComputedProperty("description") {
                Return {
                    Literal.string("\(typeName.trimmed.text) instance")
                }
            }
        }.inherits("CustomStringConvertible")
        
        return [extensionDecl.syntax.as(ExtensionDeclSyntax.self)!]
    }
}

enum MacroError: Error {
    case error(String)
}
```


## See Also

- ``Struct``
- ``Enum``
- ``Variable``
- ``Function``
- ``Extension``
- ``ComputedProperty`` 