import SyntaxKit

// MARK: - Macro Tutorial DSL Examples
// This file shows how SyntaxKit DSL would be used to generate the macro examples

// MARK: - Example 1: Extension Macro Generation
// This shows how to generate the extension that @MyMacro would create

let colorExtension = Extension("Color") {
    // Add a type alias
    TypeAlias("MyType", equals: "String")
    
    // Add a static property with case names
    Variable(.let, name: "myProperty", equals: ["red", "green", "blue"]).static()
    
    // Add a computed property
    ComputedProperty("description") {
        Return {
            VariableExp("myProperty.joined(separator: \", \")")
        }
    }
}.inherits("MyProtocol")

// MARK: - Example 2: Peer Macro Generation
// This shows how to generate the wrapper struct that @MyMacro would create

let colorWrapper = Struct("ColorWrapper") {
    Variable(.let, name: "value", type: "Color")
    
    Init {
        Parameter(name: "value", type: "Color")
    }
    
    ComputedProperty("description") {
        Return {
            VariableExp("value.description")
        }
    }
}

// MARK: - Example 3: Freestanding Expression Macro Generation
// This shows how to generate the tuple that #stringify would create

let stringifyResult = Tuple {
    VariableExp("42 + 8")
    Literal.string("42 + 8")
}

// MARK: - Example 4: Complex Extension Generation
// This shows how to generate a complex extension with multiple members

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

// MARK: - Example 5: Error Handling Structure
// This shows how to generate error handling code

let macroError = Enum("MacroError") {
    EnumCase("onlyWorksWithEnums")
    EnumCase("invalidCaseName").associatedValue("name", type: "String")
    EnumCase("missingRawValue")
}.inherits("Error", "CustomStringConvertible")

// MARK: - Example 6: Test Code Generation
// This shows how to generate test code for macros

let testFunction = Function("testExtensionMacro", parameters: []) {
    Call("assertMacroExpansion") {
        ParameterExp(name: "input", value: "\"\"\"\n@MyMacro\nenum Color: String {\n    case red = \"red\"\n    case blue = \"blue\"\n}\n\"\"\"")
        ParameterExp(name: "expected", value: "\"\"\"\nenum Color: String {\n    case red = \"red\"\n    case blue = \"blue\"\n}\n\nextension Color: MyProtocol {\n    typealias MyType = String\n    static let myProperty = [\"red\", \"blue\"]\n    var description: String {\n        return myProperty.joined(separator: \", \")\n    }\n}\n\nstruct ColorWrapper {\n    let value: Color\n    init(value: Color) {\n        self.value = value\n    }\n    var description: String {\n        return value.description\n    }\n}\n\"\"\"")
        ParameterExp(name: "macros", value: "[\"MyMacro\": MyMacro.self]")
    }
}.throws()

// MARK: - Example 7: Integration Example
// This shows how to mix SyntaxKit with raw SwiftSyntax

let baseStruct = Struct("Generated") {
    Variable(.let, name: "value", type: "String")
}

// Convert to SwiftSyntax and modify (this would be done in the macro)
// var structDecl = baseStruct.syntax.as(StructDeclSyntax.self)!
// structDecl = structDecl.with(\.modifiers, DeclModifierListSyntax {
//     DeclModifierSyntax(name: .keyword(.public))
// })

// MARK: - Example 8: Protocol Generation
// This shows how to generate protocols that macros might need

let myProtocol = Protocol("MyProtocol") {
    PropertyRequirement("description", type: "String", access: .get)
}

// MARK: - Example 9: Complex Control Flow Generation
// This shows how to generate complex control flow in macros

let complexFunction = Function("processData", parameters: [Parameter("data", type: "[String]")]) {
    Variable(.var, name: "result", equals: "[]")
    
    For(VariableExp("item"), in: VariableExp("data"), then: {
        If(VariableExp("item.hasPrefix(\"test\")"), then: {
            Call("result.append") {
                ParameterExp(unlabeled: "item.uppercased()")
            }
        }, else: {
            Call("result.append") {
                ParameterExp(unlabeled: "item.lowercased()")
            }
        })
    })
    
    Return {
        VariableExp("result")
    }
}

// MARK: - Example 10: Nested Structure Generation
// This shows how to generate nested structures

let complexStruct = Struct("ComplexStruct") {
    // Nested enum
    Enum("NestedEnum") {
        EnumCase("case1")
        EnumCase("case2").equals("value2")
    }.inherits("String")
    
    // Nested struct
    Struct("NestedStruct") {
        Variable(.let, name: "id", type: "UUID")
        Variable(.var, name: "name", type: "String")
        
        Init {
            Parameter(name: "name", type: "String")
        }
        
        ComputedProperty("displayName") {
            Return {
                VariableExp("name.isEmpty ? \"Unknown\" : name")
            }
        }
    }
    
    // Properties
    Variable(.let, name: "enumValue", type: "NestedEnum")
    Variable(.var, name: "structValue", type: "NestedStruct")
    
    // Methods
    Function("updateName", parameters: [Parameter("newName", type: "String")]) {
        Assignment("structValue.name", VariableExp("newName"))
        Call("print") {
            ParameterExp(unlabeled: "\"Name updated to: \\(newName)\"")
        }
    }
}

// MARK: - Example 11: Switch Statement Generation
// This shows how to generate switch statements in macros

let switchFunction = Function("handleStatus", parameters: [Parameter("status", type: "UserStatus")]) {
    Switch("status") {
        SwitchCase(".active") {
            Call("print") {
                ParameterExp(unlabeled: "\"User is active\"")
            }
            Return { Literal.boolean(true) }
        }
        SwitchCase(".inactive") {
            Call("print") {
                ParameterExp(unlabeled: "\"User is inactive\"")
            }
            Return { Literal.boolean(false) }
        }
        SwitchCase(".pending") {
            Call("print") {
                ParameterExp(unlabeled: "\"User status is pending\"")
            }
            Return { Literal.boolean(false) }
        }
        Default {
            Call("print") {
                ParameterExp(unlabeled: "\"Unknown status\"")
            }
            Return { Literal.boolean(false) }
        }
    }
}

// MARK: - Example 12: Guard Statement Generation
// This shows how to generate guard statements in macros

let guardFunction = Function("validateUser", parameters: [Parameter("user", type: "User?")]) {
    Guard {
        Let("user", "user")
    } else: {
        Call("print") {
            ParameterExp(unlabeled: "\"User is nil\"")
        }
        Return { Literal.boolean(false) }
    }
    
    Guard {
        Let("name", "user.name")
        Let("nameLength", "name.count")
    } else: {
        Call("print") {
            ParameterExp(unlabeled: "\"Invalid user name\"")
        }
        Return { Literal.boolean(false) }
    }
    
    If(VariableExp("nameLength > 0"), then: {
        Call("print") {
            ParameterExp(unlabeled: "\"User \\(name) is valid\"")
        }
        Return { Literal.boolean(true) }
    }, else: {
        Call("print") {
            ParameterExp(unlabeled: "\"User name is empty\"")
        }
        Return { Literal.boolean(false) }
    })
}

// MARK: - Generate All Examples

let allExamples = Group {
    colorExtension
    colorWrapper
    stringifyResult
    userExtension
    macroError
    testFunction
    myProtocol
    complexFunction
    complexStruct
    switchFunction
    guardFunction
}

// Print the generated code
print(allExamples.generateCode()) 