import Testing

@testable import SyntaxKit

@Suite internal struct ThrowTests {
  // MARK: - Basic Throw Tests

  @Test("Basic throw with enum case generates correct syntax")
  internal func testBasicThrowWithEnumCase() throws {
    let throwStatement = Throw(EnumCase("connectionFailed"))

    let generated = throwStatement.generateCode()
    let expected = "throw .connectionFailed"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Throw with enum case and type generates correct syntax")
  internal func testThrowWithEnumCaseAndType() throws {
    let throwStatement = Throw(EnumCase("connectionFailed"))

    let generated = throwStatement.generateCode()
    let expected = "throw .connectionFailed"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Throw with enum case with associated value generates correct syntax")
  internal func testThrowWithEnumCaseWithAssociatedValue() throws {
    let throwStatement = Throw(
      EnumCase("invalidInput")
        .associatedValue("fieldName", type: "String")
    )

    let generated = throwStatement.generateCode()
    let expected = "throw .invalidInput(fieldName)"

    #expect(generated.normalize() == expected.normalize())
  }

  // MARK: - Throw with Different Expression Types

  @Test("Throw with string literal generates correct syntax")
  internal func testThrowWithStringLiteral() throws {
    let throwStatement = Throw(Literal.string("Custom error message"))

    let generated = throwStatement.generateCode()
    let expected = "throw \"Custom error message\""

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Throw with integer literal generates correct syntax")
  internal func testThrowWithIntegerLiteral() throws {
    let throwStatement = Throw(Literal.integer(404))

    let generated = throwStatement.generateCode()
    let expected = "throw 404"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Throw with boolean literal generates correct syntax")
  internal func testThrowWithBooleanLiteral() throws {
    let throwStatement = Throw(Literal.boolean(true))

    let generated = throwStatement.generateCode()
    let expected = "throw true"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Throw with variable expression generates correct syntax")
  internal func testThrowWithVariableExpression() throws {
    let throwStatement = Throw(VariableExp("customError"))

    let generated = throwStatement.generateCode()
    let expected = "throw customError"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Throw with property access generates correct syntax")
  internal func testThrowWithPropertyAccess() throws {
    let throwStatement = Throw(VariableExp("user").property("validationError"))

    let generated = throwStatement.generateCode()
    let expected = "throw user.validationError"

    #expect(generated.normalize() == expected.normalize())
  }

  // MARK: - Throw with Function Calls

  @Test("Throw with function call generates correct syntax")
  internal func testThrowWithFunctionCall() throws {
    let throwStatement = Throw(
      Call("createError") {
        ParameterExp(name: "code", value: Literal.integer(500))
        ParameterExp(name: "message", value: Literal.string("Internal server error"))
      }
    )

    let generated = throwStatement.generateCode()
    let expected = "throw createError(code: 500, message: \"Internal server error\")"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Throw with async function call generates correct syntax")
  internal func testThrowWithAsyncFunctionCall() throws {
    let throwStatement = Throw(
      Call("fetchError") {
        ParameterExp(name: "id", value: Literal.integer(123))
      }.async()
    )

    let generated = throwStatement.generateCode()
    let expected = "throw await fetchError(id: 123)"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Throw with throwing function call generates correct syntax")
  internal func testThrowWithThrowingFunctionCall() throws {
    let throwStatement = Throw(
      Call("parseError") {
        ParameterExp(name: "data", value: VariableExp("jsonData"))
      }.throwing()
    )

    let generated = throwStatement.generateCode()
    let expected = "throw try parseError(data: jsonData)"

    #expect(generated.normalize() == expected.normalize())
  }

  // MARK: - Complex Throw Expressions

  @Test("Throw with conditional expression generates correct syntax")
  internal func testThrowWithConditionalExpression() throws {
    let throwStatement = Throw(
      If(VariableExp("isNetworkError")) {
        EnumCase("connectionFailed")
      } else: {
        EnumCase("invalidInput")
      }
    )

    let generated = throwStatement.generateCode()
    let expected = "throw if isNetworkError { .connectionFailed } else { .invalidInput }"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Throw with tuple expression generates correct syntax")
  internal func testThrowWithTupleExpression() throws {
    let throwStatement = Throw(
      Tuple {
        Literal.string("Error occurred")
        Literal.integer(500)
      }
    )

    let generated = throwStatement.generateCode()
    let expected = "throw (\"Error occurred\", 500)"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Throw with array literal generates correct syntax")
  internal func testThrowWithArrayLiteral() throws {
    let throwStatement = Throw(
      Literal.array([
        Literal.string("Error 1"),
        Literal.string("Error 2"),
      ])
    )

    let generated = throwStatement.generateCode()
    let expected = "throw [\"Error 1\", \"Error 2\"]"

    #expect(generated.normalize() == expected.normalize())
  }

  // MARK: - Integration Tests

  @Test("Throw in guard statement generates correct syntax")
  internal func testThrowInGuardStatement() throws {
    let guardStatement = Guard {
      VariableExp("user").property("isValid").not()
    } else: {
      Throw(EnumCase("invalidUser"))
    }

    let generated = guardStatement.generateCode()
    let expected = "guard !user.isValid else { throw .invalidUser }"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Throw in function generates correct syntax")
  internal func testThrowInFunction() throws {
    let function = Function("validateUser") {
      Parameter(name: "user", type: "User")
    } _: {
      Guard {
        VariableExp("user").property("name").property("isEmpty").not()
      } else: {
        Throw(EnumCase("emptyName"))
      }
      Guard {
        VariableExp("user").property("email").property("isEmpty").not()
      } else: {
        Throw(EnumCase("emptyEmail"))
      }
    }.throws("ValidationError")

    let generated = function.generateCode()
    let expected = """
      func validateUser(user: User) throws(ValidationError) {
        guard !user.name.isEmpty else { throw .emptyName }
        guard !user.email.isEmpty else { throw .emptyEmail }
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Throw in async function generates correct syntax")
  internal func testThrowInAsyncFunction() throws {
    let function = Function("fetchUser") {
      Parameter(name: "id", type: "Int")
    } _: {
      Guard {
        VariableExp("id") > Literal.integer(0)
      } else: {
        Throw(EnumCase("invalidId"))
      }
      Variable(.let, name: "user") {
        Call("fetchUserFromAPI") {
          ParameterExp(name: "userId", value: VariableExp("id"))
        }
      }.async()
      Guard {
        VariableExp("user") != Literal.nil
      } else: {
        Throw(EnumCase("userNotFound"))
      }
    }.asyncThrows("NetworkError")

    let generated = function.generateCode()
    let expected = """
      func fetchUser(id: Int) async throws(NetworkError) {
        guard id > 0 else { throw .invalidId }
        async let user = fetchUserFromAPI(userId: id)
        guard user != nil else { throw .userNotFound }
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Throw with custom error type generates correct syntax")
  internal func testThrowWithCustomErrorType() throws {
    let throwStatement = Throw(
      Call("CustomError") {
        ParameterExp(name: "code", value: Literal.integer(404))
        ParameterExp(name: "message", value: Literal.string("Not found"))
        ParameterExp(name: "details", value: VariableExp("errorDetails"))
      }
    )

    let generated = throwStatement.generateCode()
    let expected = "throw CustomError(code: 404, message: \"Not found\", details: errorDetails)"

    #expect(generated.normalize() == expected.normalize())
  }

  // MARK: - Edge Cases

  @Test("Throw with nil literal generates correct syntax")
  internal func testThrowWithNilLiteral() throws {
    let throwStatement = Throw(Literal.nil)

    let generated = throwStatement.generateCode()
    let expected = "throw nil"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Throw with float literal generates correct syntax")
  internal func testThrowWithFloatLiteral() throws {
    let throwStatement = Throw(Literal.float(3.14))

    let generated = throwStatement.generateCode()
    let expected = "throw 3.14"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Throw with reference literal generates correct syntax")
  internal func testThrowWithReferenceLiteral() throws {
    let throwStatement = Throw(Literal.ref("globalError"))

    let generated = throwStatement.generateCode()
    let expected = "throw globalError"

    #expect(generated.normalize() == expected.normalize())
  }
}
