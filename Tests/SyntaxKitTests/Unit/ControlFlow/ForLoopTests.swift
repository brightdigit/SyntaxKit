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
