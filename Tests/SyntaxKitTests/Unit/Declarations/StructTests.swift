import Foundation
import Testing

@testable import SyntaxKit

internal struct StructTests {
  @Test internal func testGenericStruct() {
    let stackStruct = Struct("Stack") {
      Variable(.var, name: "items", type: "[Element]", equals: Literal.array([])).withExplicitType()

      Function("push") {
        Parameter(name: "item", type: "Element", isUnnamed: true)
      } _: {
        VariableExp("items").call("append") {
          ParameterExp(name: "", value: "item")
        }
      }.mutating()

      Function("pop", returns: "Element?") {
        Return { VariableExp("items").call("popLast") }
      }.mutating()

      Function("peek", returns: "Element?") {
        Return { VariableExp("items").property("last") }
      }

      ComputedProperty("isEmpty", type: "Bool") {
        Return { VariableExp("items").property("isEmpty") }
      }

      ComputedProperty("count", type: "Int") {
        Return { VariableExp("items").property("count") }
      }
    }.generic("Element")

    let expectedCode = """
      struct Stack<Element> {
        var items: [Element] = []

        mutating func push(_ item: Element) {
          items.append(item)
        }

        mutating func pop() -> Element? {
          return items.popLast()
        }

        func peek() -> Element? {
          return items.last
        }

        var isEmpty: Bool {
          return items.isEmpty
        }

        var count: Int {
          return items.count
        }
      }
      """

    let normalizedGenerated = stackStruct.generateCode().normalizeStructural()
    let normalizedExpected = expectedCode.normalizeStructural()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testGenericStructWithInheritance() {
    let containerStruct = Struct("Container") {
      Variable(.var, name: "value", type: "T").withExplicitType()
    }.generic("T").inherits("Equatable")

    let expectedCode = """
      struct Container<T>: Equatable {
        var value: T
      }
      """

    let normalizedGenerated = containerStruct.generateCode().normalizeStructural()
    let normalizedExpected = expectedCode.normalizeStructural()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testNonGenericStruct() {
    let simpleStruct = Struct("Point") {
      Variable(.var, name: "x", type: "Double").withExplicitType()
      Variable(.var, name: "y", type: "Double").withExplicitType()
    }

    let expectedCode = """
      struct Point {
        var x: Double
        var y: Double
      }
      """

    let normalizedGenerated = simpleStruct.generateCode().normalizeStructural()
    let normalizedExpected = expectedCode.normalizeStructural()
    #expect(normalizedGenerated == normalizedExpected)
  }
}
