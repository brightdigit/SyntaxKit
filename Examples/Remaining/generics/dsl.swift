import SyntaxKit

// Example of generating a BlackjackCard struct with a nested Suit enum
let genericGroup = Group{
    Protocol("Stackable") {
        AssociatedType("Element")
        FunctionRequirement("push", parameters: {
            Parameter(name: "item", type: "Element")
        }).mutating()
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
}
// Generate and print the code
print(genericGroup.generateCode()) 