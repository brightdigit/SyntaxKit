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
    
    Struct("Stack") {
        Variable(.var, name: "items", type: "[Element]", equals: "[]")

        Function("push") {
            Parameter(name: "item", type: "Element")
        } _: {
            VariableExp("items").call("append") {
                ParameterExp(name: "item", value: "item")
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
    }.generic("Element")

    Enum("Noop") {
        Function("nothing", returns: "any Stackable") {
            Parameter(name: "stack", type: "any Stackable")
        } _: {
            Returns{
                VariableExp("stack")
            }
        }
    }
}
// Generate and print the code
print(genericGroup.generateCode()) 