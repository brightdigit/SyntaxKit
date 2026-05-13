//
//  FunctionTests.swift
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

internal struct FunctionTests {
  @Test internal func testBasicFunction() throws {
    let function = Function("calculateSum", returns: "Int") {
      Parameter(name: "a", type: "Int")
      Parameter(name: "b", type: "Int")
    } _: {
      Return {
        VariableExp("a + b")
      }
    }

    let expected = """
      func calculateSum(a: Int, b: Int) -> Int {
        return a + b
      }
      """

    // Normalize whitespace, remove comments and modifiers, and normalize colon spacing
    let normalizedGenerated = function.syntax.description.normalize()

    let normalizedExpected = expected.normalize()

    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testStaticFunction() throws {
    let function = Function(
      "createInstance",
      returns: "MyType",
      {
        Parameter(name: "value", type: "String")
      },
      {
        Return {
          Init("MyType") {
            ParameterExp(name: "value", value: Literal.ref("value"))
          }
        }
      }
    ).static()

    let expected = """
      static func createInstance(value: String) -> MyType {
        return MyType(value: value)
      }
      """

    // Normalize whitespace, remove comments and modifiers, and normalize colon spacing
    let normalizedGenerated = function.syntax.description.normalize()

    let normalizedExpected = expected.normalize()

    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testMutatingFunction() throws {
    let function = Function(
      "updateValue",
      {
        Parameter(name: "newValue", type: "String")
      },
      {
        Assignment("value", Literal.ref("newValue"))
      }
    ).mutating()

    let expected = """
      mutating func updateValue(newValue: String) {
        value = newValue
      }
      """

    // Normalize whitespace, remove comments and modifiers, and normalize colon spacing
    let normalizedGenerated = function.syntax.description.normalize()

    let normalizedExpected = expected.normalize()

    #expect(normalizedGenerated == normalizedExpected)
  }
}
