# Creating Macros with SyntaxKit

Learn how to create Swift macros that generate code using SyntaxKit's declarative API.

## Overview

This tutorial shows you how to create Swift macros that use SyntaxKit to generate code declaratively. We'll walk through creating two different types of macros:

1. An **Extension Macro** that adds protocol conformance and generates extensions
2. A **Freestanding Expression Macro** that transforms expressions

## Prerequisites

- Swift 6.1+ (for macros)
- Xcode 26.0+ or Swift 6.1+

## Project Setup

First, create a new Swift package for your macro:

```swift
// swift-tools-version: 6.1

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
    .package(url: "https://github.com/brightdigit/SyntaxKit", from: "0.0.2"),
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
```

## Tutorial 1: Extension Macro with SyntaxKit

Let's create an extension macro similar to the `@Options` macro that adds protocol conformance and generates extensions.

### Step 1: Define the Macro

Create your macro declaration in the main target:

```swift
// Sources/MyMacro/MyMacro.swift
import Foundation

/// A macro that adds protocol conformance and generates extensions for enums.
@attached(
    extension,
    conformances: MyProtocol,
    names: named(myProperty)
)
@attached(peer, names: suffixed(Wrapper))
public macro MyMacro() = #externalMacro(module: "MyMacroMacros", type: "MyMacro")
```

### Step 2: Implement the Macro

Create the macro implementation using SyntaxKit:

```swift
// Sources/MyMacroMacros/MyMacro.swift
import SwiftSyntax
import SwiftSyntaxMacros
import SyntaxKit

public struct MyMacro: ExtensionMacro, PeerMacro {
    
    // Extension macro implementation
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw MacroError.onlyWorksWithEnums
        }
        
        let typeName = enumDecl.name
        
        // Extract enum cases
        let caseElements = enumDecl.memberBlock.members.flatMap { member in
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
                return [EnumCaseElementSyntax]()
            }
            return Array(caseDecl.elements)
        }
        
        // Generate case names array
        let caseNames = caseElements.map { $0.name.trimmed.text }
        
        // Create the extension using SyntaxKit
        let extensionDecl = Extension(typeName.trimmed.text) {
            // Add a type alias
            TypeAlias("MyType", equals: "String")
            
            // Add a static property with the case names
            Variable(.let, name: "myProperty", equals: caseNames).static()
            
            // Add a computed property
            ComputedProperty("description") {
                Return {
                    VariableExp("myProperty.joined(separator: \", \")")
                }
            }
        }.inherits("MyProtocol")
        
        return [extensionDecl.syntax.as(ExtensionDeclSyntax.self)!]
    }
    
    // Peer macro implementation
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw MacroError.onlyWorksWithEnums
        }
        
        let typeName = enumDecl.name
        let wrapperName = "\(typeName.trimmed)Wrapper"
        
        // Create a wrapper struct using SyntaxKit
        let wrapperStruct = Struct(wrapperName) {
            Variable(.let, name: "value", type: typeName.trimmed.text)
            
            Init {
                Parameter(name: "value", type: typeName.trimmed.text)
            }
            
            ComputedProperty("description") {
                Return {
                    VariableExp("value.description")
                }
            }
        }
        
        return [wrapperStruct.syntax.as(DeclSyntax.self)!]
    }
}

enum MacroError: Error {
    case onlyWorksWithEnums
}
```

### Step 3: Register the Macro

Create the macro plugin:

```swift
// Sources/MyMacroMacros/MacrosPlugin.swift
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        MyMacro.self
    ]
}
```

### Step 4: Use the Macro

```swift
// Example usage
@MyMacro
enum Color: String {
    case red = "red"
    case green = "green"
    case blue = "blue"
}

// This generates:
// - An extension conforming to MyProtocol
// - A static property `myProperty` with case names
// - A computed property `description`
// - A peer struct `ColorWrapper`
```

## Tutorial 2: Freestanding Expression Macro

Let's create a freestanding expression macro that uses SyntaxKit to generate code.

### Step 1: Define the Macro

```swift
// Sources/MyMacro/MyMacro.swift
/// A macro that creates a tuple with a value and its string representation.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "MyMacroMacros", type: "StringifyMacro")
```

### Step 2: Implement the Macro

```swift
// Sources/MyMacroMacros/StringifyMacro.swift
import SwiftSyntax
import SwiftSyntaxMacros
import SyntaxKit

public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        
        guard let argument = node.arguments.first?.expression else {
            fatalError("Macro requires exactly one argument")
        }
        
        // Create a tuple using SyntaxKit
        let tuple = Tuple {
            VariableExp(argument.description)
            Literal.string(argument.description)
        }
        
        return tuple.expr
    }
}
```

### Step 3: Use the Macro

```swift
// Example usage
let result = #stringify(42 + 8)
// result is (50, "42 + 8")
```

## Advanced Example: Complex Code Generation

Here's a more complex example that generates a complete struct with multiple properties and methods:

```swift
public struct ComplexMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroError.onlyWorksWithStructs
        }
        
        let typeName = structDecl.name
        
        // Generate a complex extension using SyntaxKit
        let extensionDecl = Extension(typeName.trimmed.text) {
            // Add a nested enum
            Enum("Status") {
                EnumCase("active").equals("active")
                EnumCase("inactive").equals("inactive")
                EnumCase("pending").equals("pending")
            }.inherits("String")
            
            // Add a computed property with complex logic
            ComputedProperty("isValid") {
                If(VariableExp("status == .active"), then: {
                    Return { Literal.boolean(true) }
                }, else: {
                    Return { Literal.boolean(false) }
                })
            }
            
            // Add a method with parameters
            Function("updateStatus", parameters: [Parameter("newStatus", type: "Status")]) {
                Assignment("status", VariableExp("newStatus"))
                Call("print") {
                    ParameterExp(unlabeled: "\"Status updated to \\(newStatus)\"")
                }
            }
            
            // Add a static method
            Function("createDefault", parameters: []) {
                Return {
                    Init(typeName.trimmed.text) {
                        Parameter(name: "status", value: ".pending")
                    }
                }
            }.static()
            
        }.inherits("Identifiable", "Codable")
        
        return [extensionDecl.syntax.as(ExtensionDeclSyntax.self)!]
    }
}
```

## Best Practices

### 1. Error Handling

Always provide meaningful error messages:

```swift
enum MacroError: Error, CustomStringConvertible {
    case onlyWorksWithEnums
    case invalidCaseName(String)
    case missingRawValue
    
    var description: String {
        switch self {
        case .onlyWorksWithEnums:
            return "This macro can only be applied to enums"
        case .invalidCaseName(let name):
            return "Invalid case name: \(name)"
        case .missingRawValue:
            return "Enum cases must have raw values"
        }
    }
}
```

### 2. Type Safety

Use SyntaxKit's type-safe builders to avoid runtime errors:

```swift
// Good: Type-safe approach
let variable = Variable(.let, name: "count", type: "Int", equals: "0")

// Good: Using result builders
let structDecl = Struct("MyStruct") {
    Variable(.let, name: "id", type: "UUID")
    Variable(.var, name: "name", type: "String")
}
```

### 3. Testing

Create comprehensive tests for your macros:

```swift
// Tests/MyMacroTests/MyMacroTests.swift
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class MyMacroTests: XCTestCase {
    func testExtensionMacro() throws {
        assertMacroExpansion(
            """
            @MyMacro
            enum Color: String {
                case red = "red"
                case blue = "blue"
            }
            """,
            expandedSource: """
            enum Color: String {
                case red = "red"
                case blue = "blue"
            }
            
            extension Color: MyProtocol {
                typealias MyType = String
                static let myProperty = ["red", "blue"]
                var description: String {
                    return myProperty.joined(separator: ", ")
                }
            }
            
            struct ColorWrapper {
                let value: Color
                init(value: Color) {
                    self.value = value
                }
                var description: String {
                    return value.description
                }
            }
            """,
            macros: ["MyMacro": MyMacro.self]
        )
    }
}
```

## Integration with Existing Code

SyntaxKit makes it easy to integrate with existing SwiftSyntax code:

```swift
// You can mix SyntaxKit with raw SwiftSyntax
let syntaxKitStruct = Struct("Generated") {
    Variable(.let, name: "value", type: "String")
}

// Convert to SwiftSyntax and modify
var structDecl = syntaxKitStruct.syntax.as(StructDeclSyntax.self)!
structDecl = structDecl.with(\.modifiers, DeclModifierListSyntax {
    DeclModifierSyntax(name: .keyword(.public))
})

// Convert back to SyntaxKit if needed
let modifiedStruct = Struct(structDecl)
```

## Conclusion

SyntaxKit provides a powerful, declarative way to generate Swift code in macros. By using result builders and type-safe APIs, you can create complex code generation logic that's both readable and maintainable.

The key benefits of using SyntaxKit in macros include:

- **Declarative syntax** that's easy to read and write
- **Type safety** that catches errors at compile time
- **Composability** that allows building complex structures from simple parts
- **Integration** with existing SwiftSyntax code when needed

For more examples and advanced usage, explore the [Options macro implementation](https://github.com/brightdigit/SyntaxKit/tree/main/Macros/Options) and the [SKSampleMacro](https://github.com/brightdigit/SyntaxKit/tree/main/Macros/SKSampleMacro) in the SyntaxKit repository.

## See Also

- ``Struct``
- ``Enum``
- ``Variable``
- ``Function``
- ``Extension``
- ``ComputedProperty`` 