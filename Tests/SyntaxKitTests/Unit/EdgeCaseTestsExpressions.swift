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
    let infix = Infix("*") {
      Parenthesized {
        Infix("+") {
          VariableExp("a")
          VariableExp("b")
        }
      }
      Parenthesized {
        Infix("-") {
          VariableExp("c")
          VariableExp("d")
        }
      }
    }

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
      Infix("+") {
        VariableExp("a")
        VariableExp("b")
      }
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
