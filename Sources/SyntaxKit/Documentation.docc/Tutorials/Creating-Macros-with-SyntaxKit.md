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

<!-- skip-test -->
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
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.1")
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

<!-- skip-test -->
```swift
import SwiftCompilerPlugin
import SwiftSyntax
public import SwiftSyntaxMacros
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
        
        // Validate arguments with proper error handling
        guard arguments.count == 2 else {
            context.addError(
                .invalidArguments("stringify macro requires exactly two arguments, got \(arguments.count)"),
                at: node
            )
            return "(/* error: wrong number of arguments */, \"error\")"
        }
        
        let firstArg = arguments.first!.expression
        let secondArg = arguments.last!.expression
        
        // Build the result using SyntaxKit's declarative syntax
        do {
            return try Tuple {
                // First element: the sum of the two expressions
                Infix("+") {
                    VariableExp(firstArg.trimmed.description)
                    VariableExp(secondArg.trimmed.description)
                }
                
                // Second element: the source code as a string literal
                Literal.string("\(firstArg.trimmed.description) + \(secondArg.trimmed.description)")
            }.expr
        } catch {
            context.addError(
                .compilationError("Failed to generate tuple syntax: \(error.localizedDescription)"),
                at: node
            )
            return "(/* compilation error */, \"error\")"
        }
    }
}
```

## Step 4: Create the Macro Plugin

Create the file `Sources/MyMacroMacros/MacroPlugin.swift`:

<!-- skip-test -->
```swift
import SwiftCompilerPlugin
public import SwiftSyntaxMacros

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

<!-- skip-test -->
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

<!-- skip-test -->
```swift
import XCTest
public import SwiftSyntaxMacros
public import SwiftSyntaxMacrosTestSupport
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

## Advanced Example: Member Macro

Member macros can automatically generate code within the declaration they're attached to. Here's an example that generates memberwise initializers:

<!-- skip-test -->
```swift
import SwiftCompilerPlugin
import SwiftSyntax
public import SwiftSyntaxMacros
import SyntaxKit

public struct MemberwiseInitMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Only work with structs
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.addError(
                .unsupportedDeclaration("@MemberwiseInit can only be applied to structs"),
                at: declaration
            )
            return []
        }
        
        // Extract stored properties
        let storedProperties = structDecl.memberBlock.members.compactMap { member in
            member.decl.as(VariableDeclSyntax.self)
        }.filter { variable in
            // Only stored properties (not computed)
            variable.bindings.allSatisfy { binding in
                binding.accessorBlock == nil
            }
        }
        
        guard !storedProperties.isEmpty else {
            context.addError(
                .missingRequiredProperty("No stored properties found for memberwise initializer"),
                at: declaration
            )
            return []
        }
        
        // Build parameter list for initializer
        var parameters: [FunctionParameter] = []
        var assignments: [CodeBlock] = []
        
        for property in storedProperties {
            for binding in property.bindings {
                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
                      let type = binding.typeAnnotation?.type else {
                    continue
                }
                
                // Create parameter
                let param = FunctionParameter(
                    name: identifier.trimmed.text,
                    type: type.trimmed.description
                )
                parameters.append(param)
                
                // Create assignment statement
                let assignment = Assignment {
                    MemberAccess(base: "self", member: identifier.trimmed.text)
                    VariableExp(identifier.trimmed.text)
                }
                assignments.append(assignment)
            }
        }
        
        // Create the initializer using SyntaxKit
        let initializer = Initializer {
            parameters.forEach { param in
                Parameter(param.name, type: param.type)
            }
        } body: {
            assignments.forEach { $0 }
        }
        
        return [initializer.syntax]
    }
}

struct FunctionParameter {
    let name: String
    let type: String
}
```

You can use this macro like this:

<!-- skip-test -->
```swift
@MemberwiseInit
struct Person {
    let name: String
    let age: Int
    var email: String?
}

// Expands to include:
// init(name: String, age: Int, email: String?) {
//     self.name = name
//     self.age = age
//     self.email = email
// }
```

## Advanced Example: Accessor Macro

Accessor macros can transform stored properties into computed properties by generating custom getters and setters. Here's an example that adds validation:

<!-- skip-test -->
```swift
import SwiftCompilerPlugin
import SwiftSyntax
public import SwiftSyntaxMacros
import SyntaxKit

public struct ValidatedMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
              let type = binding.typeAnnotation?.type else {
            context.addError(
                .unsupportedDeclaration("@Validated can only be applied to stored properties"),
                at: declaration
            )
            return []
        }
        
        // Extract validation parameters from the macro
        let minValue = extractArgument(from: node, named: "min") ?? "0"
        let maxValue = extractArgument(from: node, named: "max") ?? "100"
        
        let propertyName = identifier.trimmed.text
        let storageName = "_\(propertyName)"
        
        // Create getter using SyntaxKit
        let getter = Getter {
            Return {
                VariableExp(storageName)
            }
        }
        
        // Create setter with validation using SyntaxKit
        let setter = Setter {
            // Validate the new value
            Guard {
                Infix(">=") {
                    VariableExp("newValue")
                    Literal.int(minValue)
                }
                &&
                Infix("<=") {
                    VariableExp("newValue")  
                    Literal.int(maxValue)
                }
            } else: {
                FunctionCall("fatalError") {
                    Literal.string("Value must be between \(minValue) and \(maxValue)")
                }
            }
            
            // Assign if validation passes
            Assignment {
                VariableExp(storageName)
                VariableExp("newValue")
            }
        }
        
        return [getter.syntax, setter.syntax]
    }
    
    private static func extractArgument(from node: AttributeSyntax, named: String) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }
        
        for argument in arguments {
            if argument.label?.text == named,
               let value = argument.expression.as(IntegerLiteralExprSyntax.self) {
                return value.literal.text
            }
        }
        return nil
    }
}
```

You would also need to add a stored property for the backing storage in a member macro or manually:

<!-- skip-test -->
```swift
struct Temperature {
    @Validated(min: -273, max: 1000)
    var celsius: Int
    
    // The macro transforms the above into:
    // private var _celsius: Int
    // var celsius: Int {
    //     get { _celsius }
    //     set {
    //         guard newValue >= -273 && newValue <= 1000 else {
    //             fatalError("Value must be between -273 and 1000")
    //         }
    //         _celsius = newValue
    //     }
    // }
}
```

This example shows how SyntaxKit simplifies complex accessor generation compared to manually building SwiftSyntax nodes.

## Advanced Example: Peer Macro

Peer macros can generate companion types alongside the declaration they're attached to. Here's an example that creates a builder pattern companion:

<!-- skip-test -->
```swift
import SwiftCompilerPlugin
import SwiftSyntax
public import SwiftSyntaxMacros
import SyntaxKit

public struct BuilderMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.addError(
                .unsupportedDeclaration("@Builder can only be applied to structs"),
                at: declaration
            )
            return []
        }
        
        let structName = structDecl.name.trimmed.text
        let builderName = "\(structName)Builder"
        
        // Extract properties for the builder
        let properties = structDecl.memberBlock.members.compactMap { member in
            member.decl.as(VariableDeclSyntax.self)
        }.flatMap { variable in
            variable.bindings.compactMap { binding in
                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
                      let type = binding.typeAnnotation?.type else {
                    return nil
                }
                return PropertyInfo(
                    name: identifier.trimmed.text,
                    type: type.trimmed.description,
                    isOptional: type.trimmed.description.hasSuffix("?")
                )
            }
        }
        
        // Create builder properties (all optional)
        var builderProperties: [CodeBlock] = []
        var builderMethods: [CodeBlock] = []
        
        for property in properties {
            // Builder property (always optional for flexibility)
            let builderPropertyType = property.isOptional ? property.type : "\(property.type)?"
            let builderProperty = Variable(
                property.name,
                type: builderPropertyType,
                value: Literal.nil
            ).asPrivate()
            builderProperties.append(builderProperty)
            
            // Builder method
            let builderMethod = Function("with\(property.name.capitalized)") {
                Parameter("_", name: property.name, type: property.type)
            }
            .returns(builderName)
            .body {
                Assignment {
                    MemberAccess(base: "self", member: property.name)
                    VariableExp(property.name)
                }
                Return {
                    VariableExp("self")
                }
            }
            builderMethods.append(builderMethod)
        }
        
        // Create build method
        let buildMethod = Function("build") {
            // No parameters
        }
        .returns(structName)
        .body {
            // Validate required properties
            for property in properties.filter({ !$0.isOptional }) {
                Guard {
                    Infix("!=") {
                        MemberAccess(base: "self", member: property.name)
                        Literal.nil
                    }
                } else: {
                    FunctionCall("fatalError") {
                        Literal.string("Required property '\(property.name)' not set")
                    }
                }
            }
            
            // Return constructed instance
            Return {
                StructInit(structName) {
                    for property in properties {
                        InitializerClause(
                            name: property.name,
                            value: MemberAccess(base: "self", member: property.name)
                        )
                    }
                }
            }
        }
        
        // Create the builder class using SyntaxKit
        let builderClass = Class(builderName) {
            builderProperties.forEach { $0 }
            
            // Default initializer
            Initializer {
                // Empty body - properties default to nil
            }.asPublic()
            
            builderMethods.forEach { $0 }
            buildMethod
        }.asPublic()
        
        // Also create a static builder method on the original struct
        let staticBuilderMethod = Function("builder") {
            // No parameters
        }
        .asStatic()
        .returns(builderName) 
        .body {
            Return {
                StructInit(builderName)
            }
        }
        .asPublic()
        
        // Create extension to add the static builder method
        let builderExtension = Extension(structName) {
            staticBuilderMethod
        }
        
        return [builderClass.syntax, builderExtension.syntax]
    }
}

struct PropertyInfo {
    let name: String
    let type: String
    let isOptional: Bool
}
```

This peer macro generates a builder pattern companion class:

<!-- skip-test -->
```swift
@Builder
struct User {
    let name: String
    let age: Int
    let email: String?
}

// Generates:
// public class UserBuilder {
//     private var name: String? = nil
//     private var age: Int? = nil
//     private var email: String? = nil
//     
//     public init() {}
//     
//     public func withName(_ name: String) -> UserBuilder {
//         self.name = name
//         return self
//     }
//     
//     public func withAge(_ age: Int) -> UserBuilder {
//         self.age = age
//         return self
//     }
//     
//     public func withEmail(_ email: String?) -> UserBuilder {
//         self.email = email
//         return self
//     }
//     
//     public func build() -> User {
//         guard name != nil else { fatalError("Required property 'name' not set") }
//         guard age != nil else { fatalError("Required property 'age' not set") }
//         return User(name: self.name!, age: self.age!, email: self.email)
//     }
// }
// 
// extension User {
//     public static func builder() -> UserBuilder {
//         return UserBuilder()
//     }
// }

// Usage:
// let user = User.builder()
//     .withName("Alice")
//     .withAge(30)
//     .withEmail("alice@example.com")
//     .build()
```

## Advanced Example: Extension Macro

You can also create extension macros using SyntaxKit. Here's a simple example:

<!-- skip-test -->
```swift
import SwiftCompilerPlugin
import SwiftSyntax
public import SwiftSyntaxMacros
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
            context.addError(
                .unsupportedDeclaration("Macro can only be applied to structs, classes, or enums"),
                at: declaration
            )
            return []
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

```

## Error Handling Best Practices

Proper error handling is crucial for macro development. Here's a comprehensive MacroError pattern that all examples should use:

<!-- skip-test -->
```swift
import SwiftSyntax
public import SwiftSyntaxMacros
import SwiftDiagnostics

/// Comprehensive error handling for macros
enum MacroError: Error, DiagnosticMessage {
    case invalidArguments(String)
    case unsupportedDeclaration(String)
    case missingRequiredProperty(String)
    case compilationError(String)
    
    var message: String {
        switch self {
        case .invalidArguments(let details):
            return "Invalid macro arguments: \(details)"
        case .unsupportedDeclaration(let details):
            return "Macro cannot be applied to this declaration: \(details)"
        case .missingRequiredProperty(let details):
            return "Required property missing: \(details)"
        case .compilationError(let details):
            return "Compilation error: \(details)"
        }
    }
    
    var severity: DiagnosticSeverity { .error }
    
    var diagnosticID: MessageID {
        MessageID(domain: "SyntaxKitMacros", id: "\(self)")
    }
    
    /// Creates a diagnostic with source location
    func diagnostic(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: Syntax(node), message: self)
    }
}

extension MacroExpansionContext {
    /// Add a diagnostic message to the compilation
    func addError(_ error: MacroError, at node: some SyntaxProtocol) {
        diagnose(error.diagnostic(at: node))
    }
    
    func addWarning(_ message: String, at node: some SyntaxProtocol) {
        let warning = BasicDiagnosticMessage(
            message: message,
            diagnosticID: MessageID(domain: "SyntaxKitMacros", id: "warning"),
            severity: .warning
        )
        diagnose(Diagnostic(node: Syntax(node), message: warning))
    }
}
```

### Enhanced StringifyMacro with Proper Error Handling

Here's the improved StringifyMacro with comprehensive error handling:

<!-- skip-test -->
```swift
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        
        // Validate macro arguments with detailed error reporting
        let arguments = node.arguments
        
        guard !arguments.isEmpty else {
            context.addError(
                .invalidArguments("stringify macro requires at least one argument"),
                at: node
            )
            // Return placeholder to allow compilation to continue
            return "(/* stringify macro error */, \"error\")"
        }
        
        guard arguments.count <= 2 else {
            context.addError(
                .invalidArguments("stringify macro accepts at most 2 arguments, got \(arguments.count)"),
                at: node
            )
            return "(/* too many arguments */, \"error\")"
        }
        
        // Extract arguments safely
        let firstArg = arguments.first!.expression
        let secondArg = arguments.count > 1 ? arguments[arguments.index(after: arguments.startIndex)].expression : nil
        
        do {
            if let secondArg = secondArg {
                // Two argument version: return sum and code
                return try Tuple {
                    Infix("+") {
                        VariableExp(firstArg.trimmed.description)
                        VariableExp(secondArg.trimmed.description)
                    }
                    Literal.string("\(firstArg.trimmed.description) + \(secondArg.trimmed.description)")
                }.expr
            } else {
                // Single argument version: return value and its code
                return try Tuple {
                    VariableExp(firstArg.trimmed.description)
                    Literal.string(firstArg.trimmed.description)
                }.expr
            }
        } catch {
            context.addError(
                .compilationError("Failed to generate syntax: \(error.localizedDescription)"),
                at: node
            )
            return "(/* compilation error */, \"error\")"
        }
    }
}
```



## See Also

- ``Struct``
- ``Enum``
- ``Variable``
- ``Function``
- ``Extension``
- ``ComputedProperty`` 
