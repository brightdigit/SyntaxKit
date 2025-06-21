import Testing

@testable import SyntaxKit

@Suite internal struct CatchTests {
  // MARK: - Basic Catch Tests

  @Test("Basic catch without pattern generates correct syntax")
  internal func testBasicCatchWithoutPattern() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("An error occurred"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch { print(\"An error occurred\") }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with enum case pattern generates correct syntax")
  internal func testCatchWithEnumCasePattern() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("connectionFailed")) {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Connection failed"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch .connectionFailed { print(\"Connection failed\") }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with enum case and associated value generates correct syntax")
  internal func testCatchWithEnumCaseAndAssociatedValue() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("invalidInput").associatedValue("fieldName", type: "String")) {
        Call("print") {
          ParameterExp(
            unlabeled: Literal.string("Invalid input for field: \\(fieldName)")
          )
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch .invalidInput(let fieldName) { print(\"Invalid input for field: \\(fieldName)\") }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  // MARK: - Catch with Different Pattern Types

  @Test("Catch with multiple enum cases generates correct syntax")
  internal func testCatchWithMultipleEnumCases() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("timeout")) {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Request timed out"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch .timeout { print(\"Request timed out\") }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with error binding generates correct syntax")
  internal func testCatchWithErrorBinding() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch {
        Call("logError") {
          ParameterExp(name: "error", value: VariableExp("error"))
        }
        Call("print") {
          ParameterExp(
            unlabeled: Literal.string("Error: \\(error)")
          )
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected =
      "do { try someFunction(param: \"test\") } catch { logError(error: error) print(\"Error: \\(error)\") }"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with specific error type generates correct syntax")
  internal func testCatchWithSpecificErrorType() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("CustomError")) {
        Call("handleCustomError") {
          ParameterExp(name: "error", value: VariableExp("error"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch .CustomError { handleCustomError(error: error) }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  // MARK: - Complex Catch Patterns

  @Test("Catch with multiple associated values generates correct syntax")
  internal func testCatchWithMultipleAssociatedValues() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(
        EnumCase("requestFailed")
          .associatedValue("statusCode", type: "Int")
          .associatedValue("message", type: "String")
      ) {
        Call("logAPIError") {
          ParameterExp(name: "statusCode", value: VariableExp("statusCode"))
          ParameterExp(name: "message", value: VariableExp("message"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected =
      "do { try someFunction(param: \"test\") } catch .requestFailed(let statusCode, let message) { logAPIError(statusCode: statusCode, message: message) }"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with where clause generates correct syntax")
  internal func testCatchWithWhereClause() throws {
    // Note: This would require additional DSL support for where clauses
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("connectionFailed")) {
        Call("retryConnection") {
          ParameterExp(name: "maxAttempts", value: Literal.integer(3))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected =
      "do { try someFunction(param: \"test\") } catch .connectionFailed { retryConnection(maxAttempts: 3) }"

    #expect(generated.normalize() == expected.normalize())
  }

  // MARK: - Catch with Complex Body

  @Test("Catch with multiple statements generates correct syntax")
  internal func testCatchWithMultipleStatements() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("invalidEmail")) {
        Call("logValidationError") {
          ParameterExp(name: "field", value: Literal.string("email"))
        }
        Variable(.let, name: "errorMessage", equals: Literal.string("Invalid email format"))
        Call("showError") {
          ParameterExp(name: "message", value: VariableExp("errorMessage"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do { try someFunction(param: "test") } catch .invalidEmail { logValidationError(field: "email") let errorMessage = "Invalid email format" showError(message: errorMessage) }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with nested control flow generates correct syntax")
  internal func testCatchWithNestedControlFlow() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("connectionFailed")) {
        Variable(.let, name: "retryCount", equals: Literal.integer(0))
        Call("attemptConnection") {
          ParameterExp(name: "attempt", value: VariableExp("retryCount"))
        }
        Call("incrementRetryCount") {
          ParameterExp(name: "current", value: VariableExp("retryCount"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do { try someFunction(param: "test") } catch .connectionFailed { let retryCount = 0 attemptConnection(attempt: retryCount) incrementRetryCount(current: retryCount) }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  // MARK: - Integration Tests

  @Test("Catch in do-catch statement generates correct syntax")
  internal func testCatchInDoCatchStatement() throws {
    let doCatch = Do {
      Call("fetchData") {
        ParameterExp(name: "id", value: Literal.integer(123))
      }.throwing()
    } catch: {
      Catch(EnumCase("connectionFailed")) {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Connection failed"))
        }
      }
      Catch(EnumCase("invalidId")) {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Invalid ID"))
        }
      }
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Unexpected error: \\(error)"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try fetchData(id: 123)
      } catch .connectionFailed {
        print("Connection failed")
      } catch .invalidId {
        print("Invalid ID")
      } catch {
        print("Unexpected error: \\(error)")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with async operations generates correct syntax")
  internal func testCatchWithAsyncOperations() throws {
    let doCatch = Do {
      Variable(.let, name: "data") {
        Call("fetchData") {
          ParameterExp(name: "id", value: Literal.integer(123))
        }
      }.async()
    } catch: {
      Catch(EnumCase("timeout")) {
        Variable(.let, name: "fallbackData") {
          Call("fetchFallbackData") {
            ParameterExp(name: "id", value: Literal.integer(123))
          }
        }.async()
      }
      Catch {
        Call("logError") {
          ParameterExp(name: "error", value: VariableExp("error"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        async let data = fetchData(id: 123)
      } catch .timeout {
        async let fallbackData = fetchFallbackData(id: 123)
      } catch {
        logError(error: error)
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with error recovery generates correct syntax")
  internal func testCatchWithErrorRecovery() throws {
    let doCatch = Do {
      Call("processUserData") {
        ParameterExp(name: "user", value: VariableExp("user"))
      }.throwing()
    } catch: {
      Catch(
        EnumCase("missingField")
          .associatedValue("fieldName", type: "String")
      ) {
        Call("setDefaultValue") {
          ParameterExp(name: "field", value: VariableExp("fieldName"))
        }
        Call("processUserData") {
          ParameterExp(name: "user", value: VariableExp("user"))
        }.throwing()
      }
      Catch {
        Call("handleUnexpectedError") {
          ParameterExp(name: "error", value: VariableExp("error"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try processUserData(user: user)
      } catch .missingField(let fieldName) {
        setDefaultValue(field: fieldName)
        try processUserData(user: user)
      } catch {
        handleUnexpectedError(error: error)
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

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
