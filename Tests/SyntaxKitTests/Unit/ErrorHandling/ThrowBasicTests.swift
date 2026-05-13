//
//  ThrowBasicTests.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

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
