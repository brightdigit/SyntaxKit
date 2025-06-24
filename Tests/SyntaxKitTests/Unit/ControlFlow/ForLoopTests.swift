import Testing

@testable import SyntaxKit

@Suite
internal final class ForLoopTests {
  @Test
  internal func testSimpleForInLoop() throws {
    let forLoop = try For(
      VariableExp("item"),
      in: VariableExp("items"),
      then: {
        Call("print") {
          ParameterExp(name: "", value: "item")
        }
      }
    )
    let generated = forLoop.syntax.description
    let expected = "for item in items {\n    print(item)\n}"
    #expect(generated.contains("for item in items"))
    #expect(generated.contains("print(item)"))
  }

  @Test
  internal func testForInWithWhereClause() throws {
    let forLoop = try For(
      VariableExp("number"),
      in: VariableExp("numbers"),
      where: {
        try Infix("%") {
          VariableExp("number")
          Literal.integer(2)
        }
      },
      then: {
        Call("print") {
          ParameterExp(name: "", value: "number")
        }
      }
    )
    let generated = forLoop.syntax.description
    #expect(generated.contains("for number in numbers where number % 2"))
    #expect(generated.contains("print(number)"))
  }
}
