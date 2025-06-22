import Testing

@testable import SyntaxKit

@Suite internal struct ThrowFunctionTests {
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
}
