import Foundation
import Testing

@testable import SyntaxKit

@Suite internal struct CatchComplexTests {
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
      "do { try someFunction(param: \"test\") } "
      + "catch .requestFailed(let statusCode, let message) { "
      + "logAPIError(statusCode: statusCode, message: message) }"

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
      "do { try someFunction(param: \"test\") } "
      + "catch .connectionFailed { retryConnection(maxAttempts: 3) }"

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
      do { try someFunction(param: "test") } catch .invalidEmail {
        logValidationError(field: "email")
        let errorMessage = "Invalid email format"
        showError(message: errorMessage)
      }
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
      do { try someFunction(param: "test") } catch .connectionFailed {
        let retryCount = 0
        attemptConnection(attempt: retryCount)
        incrementRetryCount(current: retryCount)
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }
}
