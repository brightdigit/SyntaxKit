//
//  TupleAssignmentBasicTests.swift
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

@Suite internal struct TupleAssignmentBasicTests {
  // MARK: - Basic Tuple Assignment Tests

  @Test("Basic tuple assignment generates correct syntax")
  internal func testBasicTupleAssignment() throws {
    let tupleAssignment = TupleAssignment(
      ["x", "y"],
      equals: Tuple {
        Literal.integer(1)
        Literal.integer(2)
      }
    )

    let generated = tupleAssignment.generateCode()
    let expected = "let (x, y) = (1, 2)"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Single element tuple assignment generates correct syntax")
  internal func testSingleElementTupleAssignment() throws {
    let tupleAssignment = TupleAssignment(
      ["value"],
      equals: Tuple {
        Literal.string("test")
      }
    )

    let generated = tupleAssignment.generateCode()
    let expected = "let (value) = (\"test\")"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Three element tuple assignment generates correct syntax")
  internal func testThreeElementTupleAssignment() throws {
    let tupleAssignment = TupleAssignment(
      ["x", "y", "z"],
      equals: Tuple {
        Literal.integer(1)
        Literal.integer(2)
        Literal.integer(3)
      }
    )

    let generated = tupleAssignment.generateCode()
    let expected = "let (x, y, z) = (1, 2, 3)"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Tuple assignment with mixed literal types generates correct syntax")
  internal func testTupleAssignmentWithMixedTypes() throws {
    let tupleAssignment = TupleAssignment(
      ["name", "age", "isActive"],
      equals: Tuple {
        Literal.string("John")
        Literal.integer(30)
        Literal.boolean(true)
      }
    )

    let generated = tupleAssignment.generateCode()
    let expected = "let (name, age, isActive) = (\"John\", 30, true)"

    #expect(generated.normalize() == expected.normalize())
  }
}
