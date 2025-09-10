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
