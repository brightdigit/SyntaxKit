//
//  EdgeCaseTestsExpressions.swift
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
import SwiftSyntax
import Testing

@testable import SyntaxKit

internal struct EdgeCaseTestsExpressions {
  // MARK: - Switch and Case Tests

  @Test("Switch with multiple patterns generates correct syntax")
  internal func testSwitchWithMultiplePatterns() throws {
    let switchStmt = Switch("value") {
      SwitchCase("1") {
        Return { VariableExp("one") }
      }
      SwitchCase("2") {
        Return { VariableExp("two") }
      }
    }

    let generated = switchStmt.generateCode()
    #expect(generated.contains("switch value"))
    #expect(generated.contains("case 1:"))
    #expect(generated.contains("case 2:"))
  }

  @Test("SwitchCase with multiple patterns generates correct syntax")
  internal func testSwitchCaseWithMultiplePatterns() throws {
    let switchCase = SwitchCase("1", "2", "3") {
      Return { VariableExp("number") }
    }

    let generated = switchCase.generateCode()
    #expect(generated.contains("case 1, 2, 3:"))
  }

  // MARK: - Complex Expression Tests

  @Test("Infix with complex expressions generates correct syntax")
  internal func testInfixWithComplexExpressions() throws {
    let infix = Infix(
      "*",
      lhs: Parenthesized {
        Infix("+", lhs: VariableExp("a"), rhs: VariableExp("b"))
      },
      rhs: Parenthesized {
        Infix("-", lhs: VariableExp("c"), rhs: VariableExp("d"))
      }
    )

    let generated = infix.generateCode()
    #expect(generated.contains("(a + b) * (c - d)"))
  }

  @Test("Return with VariableExp generates correct syntax")
  internal func testReturnWithVariableExp() throws {
    let returnStmt = Return {
      VariableExp("result")
    }

    let generated = returnStmt.generateCode()
    #expect(generated.contains("return result"))
  }

  @Test("Return with complex expression generates correct syntax")
  internal func testReturnWithComplexExpression() throws {
    let returnStmt = Return {
      Infix("+", lhs: VariableExp("a"), rhs: VariableExp("b"))
    }

    let generated = returnStmt.generateCode()
    #expect(generated.contains("return a + b"))
  }

  // MARK: - CodeBlock Expression Tests

  @Test("CodeBlock expr with TokenSyntax wraps in DeclReferenceExpr")
  internal func testCodeBlockExprWithTokenSyntax() throws {
    let variableExp = VariableExp("x")
    let expr = variableExp.expr

    let generated = expr.description
    #expect(generated.contains("x"))
  }

  // MARK: - Code Generation Edge Cases

  @Test("CodeBlock generateCode with CodeBlockItemListSyntax")
  internal func testCodeBlockGenerateCodeWithItemList() throws {
    let group = Group {
      Variable(.let, name: "x", type: "Int", equals: 1).withExplicitType()
      Variable(.let, name: "y", type: "Int", equals: 2).withExplicitType()
    }

    let generated = group.generateCode()
    #expect(generated.contains("let x  : Int = 1"))
    #expect(generated.contains("let y  : Int = 2"))
  }

  @Test("CodeBlock generateCode with single declaration")
  internal func testCodeBlockGenerateCodeWithSingleDeclaration() throws {
    let variable = Variable(.let, name: "x", type: "Int", equals: 1).withExplicitType()

    let generated = variable.generateCode()
    #expect(generated.contains("let x  : Int = 1"))
  }

  @Test("CodeBlock generateCode with single statement")
  internal func testCodeBlockGenerateCodeWithSingleStatement() throws {
    let assignment = Assignment("x", Literal.integer(42))

    let generated = assignment.generateCode()
    #expect(generated.contains("x = 42"))
  }

  @Test("CodeBlock generateCode with single expression")
  internal func testCodeBlockGenerateCodeWithSingleExpression() throws {
    let variableExp = VariableExp("x")

    let generated = variableExp.generateCode()
    #expect(generated.contains("x"))
  }
}
