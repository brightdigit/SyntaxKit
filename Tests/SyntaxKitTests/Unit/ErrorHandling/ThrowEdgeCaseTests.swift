import Foundation
import Testing

@testable import SyntaxKit

@Suite internal struct ThrowEdgeCaseTests {
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
