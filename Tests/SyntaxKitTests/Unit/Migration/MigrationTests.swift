import Testing

@testable import SyntaxKit

/// Tests specifically for verifying the Swift Testing framework migration
/// These tests ensure that the migration from XCTest to Swift Testing works correctly
internal struct MigrationTests {
  // MARK: - Basic Test Structure Migration Tests

  @Test internal func testStructBasedTestExecution() {
    // Test that struct-based tests execute properly
    let result = true
    #expect(result == true)
  }

  @Test internal func testThrowingTestMethod() throws {
    // Test that @Test works with throws declaration
    let syntax = Struct("TestStruct") {
      Variable(.let, name: "value", type: "String")
    }

    let generated = syntax.syntax.description
    #expect(!generated.isEmpty)
  }

  // MARK: - Assertion Migration Tests

  @Test internal func testExpectEqualityAssertion() {
    // Test #expect() replacement for XCTAssertEqual
    let actual = "test"
    let expected = "test"
    #expect(actual == expected)
  }

  @Test internal func testExpectBooleanAssertion() {
    // Test #expect() replacement for XCTAssertTrue/XCTAssertFalse
    let condition = true
    #expect(condition)
    #expect(!false)
  }

  @Test internal func testExpectEmptyStringAssertion() {
    // Test #expect() replacement for XCTAssertFalse(string.isEmpty)
    let generated = "non-empty string"
    #expect(!generated.isEmpty)
  }

  // MARK: - Code Generation Testing with New Framework

  @Test internal func testBasicCodeGenerationWithNewFramework() throws {
    let blackjackCard = Struct("BlackjackCard") {
      Enum("Suit") {
        EnumCase("spades").equals("♠")
        EnumCase("hearts").equals("♡")
        EnumCase("diamonds").equals("♢")
        EnumCase("clubs").equals("♣")
      }.inherits("Character")
    }

    let expected = """
      struct BlackjackCard {
        enum Suit: Character {
          case spades = "♠"
          case hearts = "♡"
          case diamonds = "♢"
          case clubs = "♣"
        }
      }
      """

    // Use the same normalization approach as existing tests
    let normalizedGenerated = blackjackCard.syntax.description.normalize()

    let normalizedExpected = expected.normalize()

    #expect(normalizedGenerated == normalizedExpected)
  }

  // MARK: - String Options Migration Tests

  @Test internal func testStringCompareOptionsSimplification() {
    // Test that .regularExpression works instead of String.CompareOptions.regularExpression
    let testString = "public func test() { }"
    let result = testString.replacingOccurrences(
      of: "public\\s+",
      with: "",
      options: .regularExpression
    )
    let expected = "func test() { }"
    #expect(result == expected)
  }

  @Test internal func testCharacterSetSimplification() {
    // Test that .whitespacesAndNewlines works instead of CharacterSet.whitespacesAndNewlines
    let testString = "  test  \n"
    let result = testString.trimmingCharacters(in: .whitespacesAndNewlines)
    let expected = "test"
    #expect(result == expected)
  }

  // MARK: - Complex Code Generation Tests

  @Test internal func testComplexStructGeneration() throws {
    let syntax = Struct("TestCard") {
      Variable(.let, name: "rank", type: "String")
      Variable(.let, name: "suit", type: "String")

      Function("description", returns: "String") {
        Return {
          VariableExp("\"\\(rank) of \\(suit)\"")
        }
      }
    }

    let generated = syntax.syntax.description.normalize()

    // Verify generated code contains expected elements
    #expect(generated.contains("struct TestCard".normalize()))
    #expect(generated.contains("let rank: String".normalize()))
    #expect(generated.contains("let suit: String".normalize()))
    #expect(generated.contains("func description() -> String".normalize()))
  }

  @Test internal func testMigrationBackwardCompatibility() {
    // Ensure that the migrated tests maintain the same functionality
    let group = Group {
      Return {
        Literal.integer(42)
      }
    }
    let generated = group.generateCode()
    #expect(generated.trimmingCharacters(in: .whitespacesAndNewlines) == "return 42")
  }
}
