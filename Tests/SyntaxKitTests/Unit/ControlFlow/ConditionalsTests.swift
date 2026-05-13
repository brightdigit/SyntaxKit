//
//  ConditionalsTests.swift
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

@Suite internal struct ConditionalsTests {
  @Test("If / else-if / else chain generates correct syntax")
  internal func testIfElseChain() throws {
    // Arrange: build the DSL example using the updated APIs
    let conditional = Group {
      Variable(.let, name: "score", type: "Int", equals: "85")

      If {
        Infix(">=", lhs: VariableExp("score"), rhs: Literal.integer(90))
      } then: {
        Call("print") {
          ParameterExp(name: "", value: VariableExp("\"Excellent!\""))
        }
      } else: {
        If {
          Infix(">=", lhs: VariableExp("score"), rhs: Literal.integer(80))
        } then: {
          Call("print") {
            ParameterExp(name: "", value: VariableExp("\"Good job!\""))
          }
        }

        Then {
          Call("print") {
            ParameterExp(name: "", value: VariableExp("\"Needs improvement\""))
          }
        }
      }
    }

    // Act
    let generated = conditional.generateCode().normalize()

    // Assert key structure is present
    #expect(generated.contains("let score".normalize()))
    #expect(generated.contains("if score >= 90".normalize()))
    #expect(generated.contains("else if score >= 80".normalize()))
    #expect(generated.contains("else {".normalize()))
  }

  @Test("If with multiple conditions generates correct syntax")
  internal func testIfWithMultipleConditions() throws {
    let ifStatement = If {
      Infix(">=", lhs: VariableExp("score"), rhs: Literal.integer(90))
    } then: {
      Call("print") {
        ParameterExp(unlabeled: VariableExp("Excellent!"))
      }
    } else: {
      If {
        Infix(">=", lhs: VariableExp("score"), rhs: Literal.integer(80))
      } then: {
        Call("print") {
          ParameterExp(unlabeled: VariableExp("Good!"))
        }
      }
    }
    let generated = ifStatement.generateCode()
    #expect(generated.contains("if score >= 90"))
    #expect(generated.contains("else if score >= 80"))
  }
}
