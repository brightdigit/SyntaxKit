import Foundation
import Testing

@testable import SyntaxKit

@Suite internal struct ThrowComplexTests {
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
        Infix(.greaterThan, lhs: VariableExp("id"), rhs: Literal.integer(0))
      } else: {
        Throw(EnumCase("invalidId"))
      }
      Variable(.let, name: "user") {
        Call("fetchUserFromAPI") {
          ParameterExp(name: "userId", value: VariableExp("id"))
        }
      }.async()
      Guard {
        Infix(.notEqual, lhs: VariableExp("user"), rhs: Literal.nil)
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
}
