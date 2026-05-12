import SyntaxKit

// MARK: - Macro Tutorial DSL Examples
//
// This file demonstrates the SyntaxKit DSL patterns one would use to generate
// the kind of code a Swift macro produces. Each example is a top-level block;
// skitrun concatenates them into a single rendered file. (The original
// version of this file used per-example `let` bindings and a final `print`,
// which skitrun's wrapper doesn't accept — top-level expressions only.)

Group {
    // MARK: Example 1 — Extension Macro Generation
    Extension("Color") {
        TypeAlias("MyType", equals: "String")
        Variable(.let, name: "myProperty", equals: ["red", "green", "blue"]).static()
        ComputedProperty("description", type: "String") {
            Return { VariableExp("myProperty.joined(separator: \", \")") }
        }
    }.inherits("MyProtocol")

    // MARK: Example 2 — Peer Macro Generation
    //
    // The original example declared `init(value: Color) { self.value = value }`
    // via `Init { Parameter(...) }`, which isn't part of the current public DSL
    // (Init is an expression-only call here). Emit the initializer body as raw
    // Swift instead.
    Struct("ColorWrapper") {
        Variable(.let, name: "value", type: "Color")
        VariableExp("""
            init(value: Color) {
                self.value = value
            }
            """)
        ComputedProperty("description", type: "String") {
            Return { VariableExp("value.description") }
        }
    }

    // MARK: Example 3 — Freestanding Expression Macro Generation
    Tuple {
        VariableExp("42 + 8")
        Literal.string("42 + 8")
    }

    // MARK: Example 4 — Complex Extension Generation
    Extension("User") {
        Enum("Status") {
            EnumCase("active").equals("active")
            EnumCase("inactive").equals("inactive")
            EnumCase("pending").equals("pending")
        }.inherits("String")

        ComputedProperty("isValid", type: "Bool") {
            If(VariableExp("status == .active"), then: {
                Return { Literal.boolean(true) }
            }, else: {
                Return { Literal.boolean(false) }
            })
        }

        Function("updateStatus") {
            Parameter(name: "newStatus", type: "Status")
        } _: {
            Assignment("status", VariableExp("newStatus"))
            Call("print") {
                ParameterExp(unlabeled: Literal.string("Status updated to \\(newStatus)"))
            }
        }

        Function("createDefault") {
        } _: {
            Return {
                Init("User") {
                    ParameterExp(name: "status", value: VariableExp(".pending"))
                    ParameterExp(name: "name", value: Literal.string("Default"))
                }
            }
        }.static()
    }.inherits("Identifiable", "Codable")

    // MARK: Example 5 — Error Handling Structure
    Enum("MacroError") {
        EnumCase("onlyWorksWithEnums")
        EnumCase("invalidCaseName").associatedValue("name", type: "String")
        EnumCase("missingRawValue")
    }.inherits("Error", "CustomStringConvertible")

    // MARK: Example 8 — Protocol Generation
    Protocol("MyProtocol") {
        PropertyRequirement("description", type: "String", access: .get)
    }

    // MARK: Example 9 — Complex Control Flow Generation
    Function("processData") {
        Parameter(name: "data", type: "[String]")
    } _: {
        Variable(.var, name: "result", equals: "[]")
        For(VariableExp("item"), in: VariableExp("data"), then: {
            If(VariableExp("item.hasPrefix(\"test\")"), then: {
                Call("result.append") {
                    ParameterExp(unlabeled: VariableExp("item.uppercased()"))
                }
            }, else: {
                Call("result.append") {
                    ParameterExp(unlabeled: VariableExp("item.lowercased()"))
                }
            })
        })
        Return { VariableExp("result") }
    }

    // MARK: Example 10 — Nested Structure Generation
    Struct("ComplexStruct") {
        Enum("NestedEnum") {
            EnumCase("case1")
            EnumCase("case2").equals("value2")
        }.inherits("String")

        Struct("NestedStruct") {
            Variable(.let, name: "id", type: "UUID")
            Variable(.var, name: "name", type: "String")

            VariableExp("""
                init(name: String) {
                    self.id = UUID()
                    self.name = name
                }
                """)

            ComputedProperty("displayName", type: "String") {
                Return {
                    VariableExp("name.isEmpty ? \"Unknown\" : name")
                }
            }
        }

        Variable(.let, name: "enumValue", type: "NestedEnum")
        Variable(.var, name: "structValue", type: "NestedStruct")

        Function("updateName") {
            Parameter(name: "newName", type: "String")
        } _: {
            Assignment("structValue.name", VariableExp("newName"))
            Call("print") {
                ParameterExp(unlabeled: Literal.string("Name updated to: \\(newName)"))
            }
        }
    }

    // MARK: Example 11 — Switch Statement Generation
    Function("handleStatus") {
        Parameter(name: "status", type: "UserStatus")
    } _: {
        Switch("status") {
            SwitchCase(".active") {
                Call("print") {
                    ParameterExp(unlabeled: Literal.string("User is active"))
                }
                Return { Literal.boolean(true) }
            }
            SwitchCase(".inactive") {
                Call("print") {
                    ParameterExp(unlabeled: Literal.string("User is inactive"))
                }
                Return { Literal.boolean(false) }
            }
            SwitchCase(".pending") {
                Call("print") {
                    ParameterExp(unlabeled: Literal.string("User status is pending"))
                }
                Return { Literal.boolean(false) }
            }
            Default {
                Call("print") {
                    ParameterExp(unlabeled: Literal.string("Unknown status"))
                }
                Return { Literal.boolean(false) }
            }
        }
    }

    // MARK: Example 12 — Guard Statement Generation
    Function("validateUser") {
        Parameter(name: "user", type: "User?")
    } _: {
        Guard {
            Let("user", "user")
        } else: {
            Call("print") {
                ParameterExp(unlabeled: Literal.string("User is nil"))
            }
            Return { Literal.boolean(false) }
        }

        Guard {
            Let("name", "user.name")
            Let("nameLength", "name.count")
        } else: {
            Call("print") {
                ParameterExp(unlabeled: Literal.string("Invalid user name"))
            }
            Return { Literal.boolean(false) }
        }

        If(VariableExp("nameLength > 0"), then: {
            Call("print") {
                ParameterExp(unlabeled: Literal.string("User \\(name) is valid"))
            }
            Return { Literal.boolean(true) }
        }, else: {
            Call("print") {
                ParameterExp(unlabeled: Literal.string("User name is empty"))
            }
            Return { Literal.boolean(false) }
        })
    }
}
