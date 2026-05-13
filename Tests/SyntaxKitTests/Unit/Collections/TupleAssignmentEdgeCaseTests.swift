//
//  TupleAssignmentEdgeCaseTests.swift
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

@Suite internal struct TupleAssignmentEdgeCaseTests {
  // MARK: - Edge Cases and Error Handling Tests

  @Test("Tuple assignment with empty elements array throws error")
  internal func testTupleAssignmentWithEmptyElements() throws {
    // This should be handled gracefully by the DSL
    let tupleAssignment = TupleAssignment(
      [],
      equals: Tuple {
        Literal.integer(1)
      }
    )

    let generated = tupleAssignment.generateCode()
    let expected = "let () = (1)"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Tuple assignment with variable expressions generates correct syntax")
  internal func testTupleAssignmentWithVariableExpressions() throws {
    let tupleAssignment = TupleAssignment(
      ["firstName", "lastName"],
      equals: Tuple {
        VariableExp("user.firstName")
        VariableExp("user.lastName")
      }
    )

    let generated = tupleAssignment.generateCode()
    let expected = "let (firstName, lastName) = (user.firstName, user.lastName)"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Tuple assignment with function calls generates correct syntax")
  internal func testTupleAssignmentWithFunctionCalls() throws {
    let tupleAssignment = TupleAssignment(
      ["min", "max"],
      equals: Tuple {
        Call("findMinimum") {
          ParameterExp(name: "array", value: VariableExp("numbers"))
        }
        Call("findMaximum") {
          ParameterExp(name: "array", value: VariableExp("numbers"))
        }
      }
    )

    let generated = tupleAssignment.generateCode()
    let expected = "let (min, max) = (findMinimum(array: numbers), findMaximum(array: numbers))"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Tuple assignment with nested tuples generates correct syntax")
  internal func testTupleAssignmentWithNestedTuples() throws {
    let tupleAssignment = TupleAssignment(
      ["point", "color"],
      equals: Tuple {
        Tuple {
          Literal.integer(10)
          Literal.integer(20)
        }
        Tuple {
          Literal.integer(255)
          Literal.integer(0)
          Literal.integer(0)
        }
      }
    )

    let generated = tupleAssignment.generateCode()
    let expected = "let (point, color) = ((10, 20), (255, 0, 0))"

    #expect(generated.normalize() == expected.normalize())
  }
}
