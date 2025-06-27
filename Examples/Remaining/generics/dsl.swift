import SyntaxKit

// Example of generating a BlackjackCard struct with a nested Suit enum
let genericGroup = Group{
    Protocol("Stackable") {
        AssociatedType("Element").inherits("Hashable", "Identifiable")
        FunctionRequirement("push", parameters: {
            Parameter(name: "item", type: "Element")
        }).mutating()
        FunctionRequirement("pop", returns: "Element?").mutating()
        FunctionRequirement("peek", returns: "Element?")
        PropertyRequirement("isEmpty", type: "Bool", access: .get)
        PropertyRequirement("count", type: "Int", access: .get)
    }
    
    Struct("Stack", generic: "Element") {
        Variable(.var, name: "items", type: "[Element]", equals: "[]")

        Function("push") parameters:{
            Parameter(name: "item", type: "Element")
        } {
            VariableExp("output").call("append") {
                Parameter(name: "item", value: "item")
            }
        }

        Function("pop", returns: "Element?") {
            VariableExp("items").call("popLast")
        }

        Function("peek", returns: "Element?") {
            VariableExp("items").property("last")
        }

        ComputedProperty("isEmpty") {
            VariableExp("items").property("isEmpty")
        }

        ComputedProperty("count") {
            VariableExp("items").property("count")
        }
    }

    Enum("Noop") {
        Function("nothing", parameters: {
            Parameter(name: "stack", type: "any Stackable")
        }, returns: "any Stackable") {
            Returns{
                VariableExp("stack")
            }
        }
    }
}
// Generate and print the code
print(genericGroup.generateCode()) 