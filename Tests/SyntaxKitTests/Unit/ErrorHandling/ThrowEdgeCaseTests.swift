//
//  ThrowEdgeCaseTests.swift
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
