import Foundation
import Testing

@testable import SyntaxKit

@Suite internal struct ThrowBasicTests {
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
}
