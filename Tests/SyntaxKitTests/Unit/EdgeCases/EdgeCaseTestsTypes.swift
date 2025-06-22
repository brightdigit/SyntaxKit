import Testing

@testable import SyntaxKit

internal struct EdgeCaseTestsTypes {
  // MARK: - Complex Type Tests

  @Test("TypeAlias with complex nested types")
  internal func testTypeAliasWithComplexNestedTypes() throws {
    let typeAlias = TypeAlias("ComplexType", equals: "Array<Dictionary<String, Optional<Int>>>")

    let generated = typeAlias.generateCode()
    #expect(
      generated.normalize().contains(
        "typealias ComplexType = Array<Dictionary<String, Optional<Int>>>".normalize()
      )
    )
  }

  @Test("TypeAlias with multiple generic parameters")
  internal func testTypeAliasWithMultipleGenericParameters() throws {
    let typeAlias = TypeAlias("Result", equals: "Result<Success, Failure>")

    let generated = typeAlias.generateCode().normalize()
    #expect(generated.contains("typealias Result = Result<Success, Failure>".normalize()))
  }

  // MARK: - Function Parameter Tests

  @Test("Function with unnamed parameter generates correct syntax")
  internal func testFunctionWithUnnamedParameter() throws {
    let function = Function("process") {
      Parameter(name: "data", type: "Data", isUnnamed: true)
    } _: {
      Variable(.let, name: "result", type: "String", equals: "processed")
    }

    let generated = function.generateCode()
    #expect(generated.contains("func process(_ data: Data)"))
  }

  @Test("Function with parameter default value generates correct syntax")
  internal func testFunctionWithParameterDefaultValue() throws {
    let function = Function("greet") {
      Parameter(name: "name", type: "String", defaultValue: "\"World\"")
    } _: {
      Variable(.let, name: "message", type: "String", equals: "greeting")
    }

    let generated = function.generateCode()
    #expect(generated.contains("func greet(name : String = \"World\")"))
  }

  // MARK: - Enum Case Tests

  @Test("EnumCase with string raw value generates correct syntax")
  internal func testEnumCaseWithStringRawValue() throws {
    let enumDecl = Enum("Status") {
      EnumCase("active").equals(Literal.string("active"))
      EnumCase("inactive").equals(Literal.string("inactive"))
    }

    let generated = enumDecl.generateCode().normalize()
    #expect(generated.contains("case active = \"active\""))
    #expect(generated.contains("case inactive = \"inactive\""))
  }

  @Test("EnumCase with double raw value generates correct syntax")
  internal func testEnumCaseWithDoubleRawValue() throws {
    let enumDecl = Enum("Precision") {
      EnumCase("low").equals(Literal.float(0.1))
      EnumCase("high").equals(Literal.float(0.001))
    }

    let generated = enumDecl.generateCode().normalize()
    #expect(generated.contains("case low = 0.1"))
    #expect(generated.contains("case high = 0.001"))
  }

  // MARK: - Computed Property Tests

  @Test("ComputedProperty with complex return expression")
  internal func testComputedPropertyWithComplexReturn() throws {
    let computedProperty = ComputedProperty("description", type: "String") {
      Return {
        VariableExp("name").call("appending") {
          ParameterExp(name: "", value: "\" - \" + String(count)")
        }
      }
    }

    let generated = computedProperty.generateCode().normalize()
    #expect(generated.contains("var description: String"))
    #expect(generated.contains("return name.appending(\" - \" + String(count))"))
  }

  // MARK: - Comment Integration Tests

  @Test("ComputedProperty with comments generates correct syntax")
  internal func testComputedPropertyWithComments() throws {
    let computedProperty = ComputedProperty("formattedName", type: "String") {
      Return {
        VariableExp("name").property("uppercased")
      }
    }.comment {
      Line(.doc, "Returns the name in uppercase format")
    }

    let generated = computedProperty.generateCode()
    #expect(generated.contains("/// Returns the name in uppercase format"))
    #expect(generated.contains("var formattedName  : String"))
  }

  // MARK: - Literal Tests

  @Test("Literal with nil generates correct syntax")
  internal func testLiteralWithNil() throws {
    let literal = Literal.nil
    let generated = literal.generateCode()
    #expect(generated.contains("nil"))
  }

  @Test("Literal with boolean generates correct syntax")
  internal func testLiteralWithBoolean() throws {
    let literal = Literal.boolean(true)
    let generated = literal.generateCode()
    #expect(generated.contains("true"))
  }

  @Test("Literal with float generates correct syntax")
  internal func testLiteralWithFloat() throws {
    let literal = Literal.float(3.14159)
    let generated = literal.generateCode()
    #expect(generated.contains("3.14159"))
  }
}
