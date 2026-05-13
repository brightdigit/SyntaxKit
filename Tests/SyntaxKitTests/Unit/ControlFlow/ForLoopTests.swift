//
//  ForLoopTests.swift
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

@Suite
internal final class ForLoopTests {
  @Test
  internal func testSimpleForInLoop() throws {
    let forLoop = For(
      VariableExp("item"),
      in: VariableExp("items"),
      then: {
        Call("print") {
          ParameterExp(name: "", value: VariableExp("item"))
        }
      }
    )
    let generated = forLoop.syntax.description
    #expect(generated.contains("for item in items"))
    #expect(generated.contains("print(item)"))
  }

  @Test
  internal func testForInWithWhereClause() throws {
    let forLoop = For(
      VariableExp("number"),
      in: VariableExp("numbers"),
      where: {
        Infix("%", lhs: VariableExp("number"), rhs: Literal.integer(2))
      },
      then: {
        Call("print") {
          ParameterExp(name: "", value: VariableExp("number"))
        }
      }
    )
    let generated = forLoop.syntax.description
    #expect(generated.contains("for number in numbers where number % 2"))
    #expect(generated.contains("print(number)"))
  }
}
