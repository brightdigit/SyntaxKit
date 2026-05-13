//
//  ThrowFunctionTests.swift
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
