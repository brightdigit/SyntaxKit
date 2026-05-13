//
//  StructTests.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import Testing

@testable import SyntaxKit

internal struct StructTests {
  @Test internal func testGenericStruct() {
    let stackStruct = Struct("Stack") {
      Variable(.var, name: "items", type: "[Element]", equals: Literal.array([])).withExplicitType()

      Function("push") {
        Parameter(unlabeled: "item", type: "Element")
      } _: {
        VariableExp("items").call("append") {
          ParameterExp(name: "", value: VariableExp("item"))
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
