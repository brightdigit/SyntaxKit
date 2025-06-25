import Testing

@testable import SyntaxKit

/// Tests for code style and API simplification changes introduced during Swift Testing migration
/// Validates the simplified Swift APIs and formatting changes
internal struct CodeStyleMigrationTests {
  // MARK: - CharacterSet Simplification Tests

  @Test internal func testCharacterSetSimplification() {
    // Test that .whitespacesAndNewlines works instead of CharacterSet.whitespacesAndNewlines
    let testString = "\n  test content  \n\t"

    // Old style: CharacterSet.whitespacesAndNewlines
    // New style: .whitespacesAndNewlines
    let trimmed = testString.trimmingCharacters(in: .whitespacesAndNewlines)

    #expect(trimmed == "test content")
  }

  // MARK: - Indentation and Formatting Tests

  @Test internal func testConsistentIndentationInMigratedCode() throws {
    // Test that the indentation changes in the migrated code work correctly
    let syntax = Struct("IndentationTest") {
      Variable(.let, name: "property1", type: "String")
      Variable(.let, name: "property2", type: "Int")

      Function("method") {
        Parameter(name: "param", type: "String")
      } _: {
        Variable(.let, name: "local", equals: .string("value"))
        Return {
          VariableExp("local")
        }
      }
    }

    let generated = syntax.generateCode().normalize()

    // Verify proper indentation is maintained
    #expect(
      generated
        == "struct IndentationTest { let property1: String let property2: Int "
        + "func method(param: String) { let local = \"value\" return local } }"
    )
  }

  // MARK: - Multiline String Formatting Tests

  @Test internal func testMultilineStringFormatting() {
    let expected = """
      struct TestStruct {
        let value: String
        var count: Int
      }
      """

    let syntax = Struct("TestStruct") {
      Variable(.let, name: "value", type: "String")
      Variable(.var, name: "count", type: "Int")
    }

    let normalized = syntax.generateCode().normalize()

    let expectedNormalized = expected.normalize()

    #expect(normalized == expectedNormalized)
  }

  @Test internal func testMigrationPreservesCodeGeneration() {
    // Ensure that the style changes don't break core functionality
    let group = Group {
      Return {
        Literal.string("migrated")
      }
    }

    let generated = group.generateCode().trimmingCharacters(in: .whitespacesAndNewlines)
    #expect(generated == "return \"migrated\"")
  }
}
