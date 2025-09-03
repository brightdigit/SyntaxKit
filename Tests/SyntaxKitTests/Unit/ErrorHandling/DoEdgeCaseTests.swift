import Foundation
import Testing

@testable import SyntaxKit

@Suite internal struct DoEdgeCaseTests {
  // MARK: - Edge Cases

  @Test("Do statement with empty body generates correct syntax")
  internal func testDoStatementWithEmptyBody() throws {
    let doStatement = Do {
      // Empty body
    } catch: {
      Catch {
        // Empty catch
      }
    }

    let generated = doStatement.generateCode()
    let expected = """
      do {
      } catch {
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Do statement with single expression generates correct syntax")
  internal func testDoStatementWithSingleExpression() throws {
    let doStatement = Do {
      VariableExp("someVariable")
    } catch: {
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Error"))
        }
      }
    }

    let generated = doStatement.generateCode()
    let expected = """
      do {
        someVariable
      } catch {
        print("Error")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Do statement with function call and variable assignment generates correct syntax")
  internal func testDoStatementWithFunctionCallAndVariableAssignment() throws {
    let doStatement = Do {
      Variable(.let, name: "result", equals: Literal.integer(42))
      Call("processResult") {
        ParameterExp(name: "value", value: VariableExp("result"))
      }
    } catch: {
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Error processing result"))
        }
      }
    }

    let generated = doStatement.generateCode()
    let expected = """
      do {
        let result = 42
        processResult(value: result)
      } catch {
        print("Error processing result")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Do statement with nested do statement generates correct syntax")
  internal func testDoStatementWithNestedDoStatement() throws {
    let doStatement = Do {
      Call("outerFunction") {
        ParameterExp(name: "param", value: Literal.string("outer"))
      }
      Do {
        Call("innerFunction") {
          ParameterExp(name: "param", value: Literal.string("inner"))
        }
      } catch: {
        Catch {
          Call("print") {
            ParameterExp(unlabeled: Literal.string("Inner error"))
          }
        }
      }
    } catch: {
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Outer error"))
        }
      }
    }

    let generated = doStatement.generateCode()
    let expected = """
      do {
        outerFunction(param: "outer")
        do {
          innerFunction(param: "inner")
        } catch {
          print("Inner error")
        }
      } catch {
        print("Outer error")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Do statement with tuple assignment generates correct syntax")
  internal func testDoStatementWithTupleAssignment() throws {
    let doStatement = Do {
      TupleAssignment(
        ["x", "y"],
        equals: Tuple {
          Literal.integer(10)
          Literal.integer(20)
        }
      )
      Call("processCoordinates") {
        ParameterExp(name: "x", value: VariableExp("x"))
        ParameterExp(name: "y", value: VariableExp("y"))
      }
    } catch: {
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Error processing coordinates"))
        }
      }
    }

    let generated = doStatement.generateCode()
    let expected = """
      do {
        let (x, y) = (10, 20)
        processCoordinates(x: x, y: y)
      } catch {
        print("Error processing coordinates")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }
}
