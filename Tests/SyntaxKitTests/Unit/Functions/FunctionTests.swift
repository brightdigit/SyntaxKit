import Testing

@testable import SyntaxKit

internal struct FunctionTests {
  @Test internal func testBasicFunction() throws {
    let function = Function("calculateSum", returns: "Int") {
      Parameter(name: "a", type: "Int")
      Parameter(name: "b", type: "Int")
    } _: {
      Return {
        VariableExp("a + b")
      }
    }

    let expected = """
      func calculateSum(a: Int, b: Int) -> Int {
        return a + b
      }
      """

    // Normalize whitespace, remove comments and modifiers, and normalize colon spacing
    let normalizedGenerated = function.syntax.description.normalize()

    let normalizedExpected = expected.normalize()

    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testStaticFunction() throws {
    let function = Function(
      "createInstance",
      returns: "MyType",
      {
        Parameter(name: "value", type: "String")
      },
      {
        Return {
          Init("MyType") {
            ParameterExp(name: "value", value: Literal.ref("value"))
          }
        }
      }
    ).static()

    let expected = """
      static func createInstance(value: String) -> MyType {
        return MyType(value: value)
      }
      """

    // Normalize whitespace, remove comments and modifiers, and normalize colon spacing
    let normalizedGenerated = function.syntax.description.normalize()

    let normalizedExpected = expected.normalize()

    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testMutatingFunction() throws {
    let function = Function(
      "updateValue",
      {
        Parameter(name: "newValue", type: "String")
      },
      {
        Assignment("value", Literal.ref("newValue"))
      }
    ).mutating()

    let expected = """
      mutating func updateValue(newValue: String) {
        value = newValue
      }
      """

    // Normalize whitespace, remove comments and modifiers, and normalize colon spacing
    let normalizedGenerated = function.syntax.description.normalize()

    let normalizedExpected = expected.normalize()

    #expect(normalizedGenerated == normalizedExpected)
  }
}
