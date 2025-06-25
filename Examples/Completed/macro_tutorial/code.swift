import Foundation

// MARK: - Macro Tutorial Examples
// This file demonstrates the concepts from the "Creating Macros with SyntaxKit" tutorial

// MARK: - Example 1: Extension Macro Usage
// This shows how the @MyMacro would be used (as defined in the tutorial)

protocol MyProtocol {
    var description: String { get }
}

// Example of what the macro would generate:
@MyMacro
enum Color: String {
    case red = "red"
    case green = "green"
    case blue = "blue"
}

// The macro would generate:
// extension Color: MyProtocol {
//     typealias MyType = String
//     static let myProperty = ["red", "green", "blue"]
//     var description: String {
//         return myProperty.joined(separator: ", ")
//     }
// }
//
// struct ColorWrapper {
//     let value: Color
//     init(value: Color) {
//         self.value = value
//     }
//     var description: String {
//         return value.description
//     }
// }

// MARK: - Example 2: Freestanding Expression Macro Usage
// This shows how the #stringify macro would be used

// let result = #stringify(42 + 8)
// result would be (50, "42 + 8")

// MARK: - Example 3: Complex Macro Generation
// This shows what a complex macro might generate

struct User {
    var status: UserStatus
    var name: String
}

enum UserStatus: String {
    case active = "active"
    case inactive = "inactive"
    case pending = "pending"
}

// A complex macro might generate an extension like this:
extension User {
    enum Status: String {
        case active = "active"
        case inactive = "inactive"
        case pending = "pending"
    }
    
    var isValid: Bool {
        if status == .active {
            return true
        } else {
            return false
        }
    }
    
    func updateStatus(newStatus: Status) {
        status = newStatus
        print("Status updated to \(newStatus)")
    }
    
    static func createDefault() -> User {
        return User(status: .pending, name: "Default")
    }
}

// MARK: - Example 4: SyntaxKit Code Generation
// This shows how SyntaxKit would be used to generate the above code

import SyntaxKit

// Example of generating the User extension using SyntaxKit
let userExtension = Extension("User") {
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
            Init("User") {
                Parameter(name: "status", value: ".pending")
                Parameter(name: "name", value: "\"Default\"")
            }
        }
    }.static()
    
}.inherits("Identifiable", "Codable")

// MARK: - Example 5: Error Handling in Macros
// This shows how macros should handle errors

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

// MARK: - Example 6: Testing Macros
// This shows how macros should be tested

/*
// Example test for the MyMacro
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
*/

// MARK: - Example 7: Integration with SwiftSyntax
// This shows how SyntaxKit can be mixed with raw SwiftSyntax

/*
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
*/

// MARK: - Usage Examples

// Example usage of the generated code
let color = Color.red
print(color.description) // Would print: "red, green, blue"

let user = User(status: .pending, name: "John")
print(user.isValid) // Would print: false

user.updateStatus(newStatus: .active)
print(user.isValid) // Would print: true

let defaultUser = User.createDefault()
print(defaultUser.name) // Would print: "Default"
print(defaultUser.status) // Would print: .pending 