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
