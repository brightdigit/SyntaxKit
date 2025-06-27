import Foundation
import SyntaxKit
import Testing

@Suite internal struct GenericsTests {
  @Test("Generics DSL generates expected Swift code")
  internal func testGenericsExample() throws {
    // Build DSL equivalent of Examples/Remaining/generics/dsl.swift
    let program = try Group {
      Protocol("Stackable") {
        AssociatedType("Element").inherits("Hashable", "Identifiable")
        FunctionRequirement("push") {
          Parameter(name: "item", type: "Element")
        }.mutating()
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

        ComputedProperty("isEmpty", type: "Bool") {
          VariableExp("items").property("isEmpty")
        }

        ComputedProperty("count", type: "Int") {
          VariableExp("items").property("count")
        }
      }.generic("Element")

      Enum("Noop") {
        Function("nothing", returns: "any Stackable") {
          Parameter(name: "stack", type: "any Stackable")
        } _: {
          Return{
            VariableExp("stack")
          }
        }
      }
    }

    // For now, just test that it compiles
    let generated = program.generateCode()
    print("Generated code:")
    print(generated)
    
    // TODO: Add proper comparison once AssociatedType is implemented
    #expect(!generated.isEmpty)
  }
} 