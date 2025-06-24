import Testing

@testable import SyntaxKit

internal struct EdgeCaseTests {
  // MARK: - Error Handling Tests

  @Test("Infix with wrong number of operands throws error")
  internal func testInfixWrongOperandCount() throws {
    // Test that Infix throws an error when given wrong number of operands
    do {
      _ = try Infix("+") {
        // Only one operand - should throw error
        VariableExp("x")
      }
      // If we reach here, no error was thrown, which is unexpected
      #expect(false, "Expected error to be thrown for wrong operand count")
    } catch let error as Infix.InfixError {
      // Verify it's the correct error type
      switch error {
      case let .wrongOperandCount(expected, got):
        #expect(expected == 2)
        #expect(got == 1)
      case .nonExprCodeBlockOperand:
        #expect(false, "Expected wrongOperandCount error, got nonExprCodeBlockOperand")
      }
    } catch {
      #expect(false, "Expected InfixError, got \(type(of: error))")
    }
  }

  // MARK: - Default Condition Tests

  @Test("If with no conditions uses true as default")
  internal func testIfWithNoConditionsUsesTrueAsDefault() throws {
    let ifStatement = If {
      Return {
        Literal.string("executed")
      }
    }

    let generated = ifStatement.generateCode()
    #expect(generated.contains("if true"))
    #expect(generated.contains("return \"executed\""))
  }

  @Test("Guard with no conditions uses true as default")
  internal func testGuardWithNoConditionsUsesTrueAsDefault() throws {
    let guardStatement = Guard {
      Return {
        Literal.string("executed")
      }
    }

    let generated = guardStatement.generateCode()
    #expect(generated.contains("guard true"))
    #expect(generated.contains("return \"executed\""))
  }

  // MARK: - Return Statement Tests

  @Test("Return with expression generates correct syntax")
  internal func testReturnWithExpression() {
    let returnStatement = Return {
      Literal.string("hello")
    }

    let generated = returnStatement.generateCode()
    #expect(generated.contains("return \"hello\""))
  }

  @Test("Return with variable expression generates correct syntax")
  internal func testReturnWithVariableExpression() {
    let returnStatement = Return {
      VariableExp("value")
    }

    let generated = returnStatement.generateCode()
    #expect(generated.contains("return value"))
  }

  @Test("Return with no expressions generates bare return")
  internal func testReturnWithNoExpressions() {
    let returnStatement = Return {
      // Empty - should generate bare return
    }

    let generated = returnStatement.generateCode()
    #expect(generated.contains("return"))
    #expect(!generated.contains("return "))
    #expect(!generated.contains("return \"\""))
    #expect(!generated.contains("return nil"))
  }

  // MARK: - TupleAssignment Tests

  @Test("TupleAssignment asyncSet falls back to regular syntax when conditions not met")
  internal func testTupleAssignmentAsyncSetFallback() {
    // Test case 1: Value is not a Tuple
    let tupleAssignment1 = TupleAssignment(
      ["a", "b"],
      equals: Literal.string("not a tuple")
    ).asyncSet()

    let generated1 = tupleAssignment1.generateCode()
    #expect(generated1.contains("let (a, b) = \"not a tuple\""))
    #expect(!generated1.contains("async let"))

    // Test case 2: Element count mismatch
    let tupleAssignment2 = TupleAssignment(
      ["a", "b", "c"],  // 3 elements
      equals: Tuple {
        Literal.integer(1)
        Literal.integer(2)
        // Missing third element
      }
    ).asyncSet()

    let generated2 = tupleAssignment2.generateCode()
    #expect(generated2.contains("let (a, b, c) = (1, 2)"))
    #expect(!generated2.contains("async let"))
  }
}
