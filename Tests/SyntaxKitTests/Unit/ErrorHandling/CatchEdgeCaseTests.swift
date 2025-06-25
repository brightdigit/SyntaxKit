import Testing

@testable import SyntaxKit

@Suite internal struct CatchEdgeCaseTests {
  // MARK: - Edge Cases

  @Test("Catch with empty body generates correct syntax")
  internal func testCatchWithEmptyBody() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("ignored")) {
        // Empty body
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch .ignored { }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with single statement generates correct syntax")
  internal func testCatchWithSingleStatement() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("connectionFailed")) {
        Call("retry") {
          ParameterExp(name: "maxAttempts", value: Literal.integer(1))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch .connectionFailed { retry(maxAttempts: 1) }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with function call and variable assignment generates correct syntax")
  internal func testCatchWithFunctionCallAndVariableAssignment() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("invalidInput")) {
        Variable(.let, name: "errorMessage", equals: Literal.string("Invalid input"))
        Call("logError") {
          ParameterExp(name: "message", value: VariableExp("errorMessage"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch .invalidInput {
        let errorMessage = "Invalid input"
        logError(message: errorMessage)
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with conditional logic generates correct syntax")
  internal func testCatchWithConditionalLogic() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("connectionFailed")) {
        Variable(.let, name: "retryCount", equals: Literal.integer(0))
        Call("checkRetryCount") {
          ParameterExp(name: "count", value: VariableExp("retryCount"))
        }
        Call("showError") {
          ParameterExp(name: "message", value: Literal.string("Max retries exceeded"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch .connectionFailed {
        let retryCount = 0
        checkRetryCount(count: retryCount)
        showError(message: "Max retries exceeded")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }
}
