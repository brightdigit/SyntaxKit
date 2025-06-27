import Foundation
import SyntaxKit
import Testing

@Suite internal struct GenericsExampleTests {
  @Test("Generics DSL generates expected Swift code (integration)")
  internal func testGenericsExampleIntegration() throws {
    // DSL equivalent of Examples/Remaining/generics/dsl.swift
    let program = Group {
      Protocol("Stackable") {
        AssociatedType("Element").inherits("Hashable", "Identifiable")
        FunctionRequirement("push") {
          Parameter(unlabeled: "item", type: "Element")
        }.mutating()
        FunctionRequirement("pop", returns: "Element?").mutating()
        FunctionRequirement("peek", returns: "Element?")
        PropertyRequirement("isEmpty", type: "Bool", access: .get)
        PropertyRequirement("count", type: "Int", access: .get)
      }
      
      Struct("Stack") {
        Variable(.var, name: "items", type: "[Element]", equals: Literal.array([])).withExplicitType()

        Function("push") {
          Parameter(unlabeled: "item", type: "Element")
        } _: {
          VariableExp("items").call("append") {
            ParameterExp(unlabeled: VariableExp("item"))
          }
        }.mutating()

        Function("pop", returns: "Element?") {
          VariableExp("items").call("popLast")
        }.mutating()

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
          Parameter(unlabeled: "stack", type: "any Stackable")
        } _: {
          Return{
            VariableExp("stack")
          }
        }.static()
      }
    }

    // Expected Swift code from Examples/Remaining/generics/code.swift
    let expectedCode = """
      protocol Stackable {
        associatedtype Element : Hashable & Identifiable

        mutating func push(_ item: Element)
        mutating func pop() -> Element?
        func peek() -> Element?
        var isEmpty: Bool { get }
        var count: Int { get }
      }

      struct Stack<Element> {
        var items: [Element] = []

        mutating func push(_ item: Element) {
          items.append(item)
        }

        mutating func pop() -> Element? {
          items.popLast()
        }

        func peek() -> Element? {
          items.last
        }

        var isEmpty: Bool {
          items.isEmpty
        }

        var count: Int {
          items.count
        }
      }

      enum Noop {
        static func nothing(_ stack: any Stackable) -> any Stackable { 
          return stack
        }
      }
      """

    // Generate code from DSL
    let generated = program.generateCode().normalize()
    let expected = expectedCode.normalize()
    #expect(generated == expected)
  }
} 