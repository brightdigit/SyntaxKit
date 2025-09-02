import Foundation
import Testing

@testable import SyntaxKit

/// Tests specifically focused on assertion migration from XCTest to Swift Testing
/// Ensures all assertion patterns from the original tests work correctly with #expect()
internal struct AssertionMigrationTests {
  // MARK: - XCTAssertEqual Migration Tests

  @Test internal func testEqualityAssertionMigration() throws {
    // Test the most common migration: XCTAssertEqual -> #expect(a == b)
    let function = Function("test", returns: "String") {
      Return {
        Literal.string("hello")
      }
    }

    let generated = function.syntax.description
      .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
      .trimmingCharacters(in: .whitespacesAndNewlines)

    let expected = "func test() -> String { return \"hello\" }"
      .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
      .trimmingCharacters(in: .whitespacesAndNewlines)

    // This replaces: XCTAssertEqual(generated, expected)
    #expect(generated == expected)
  }

  // MARK: - XCTAssertFalse Migration Tests

  @Test internal func testFalseAssertionMigration() {
    let syntax = Group {
      Variable(.let, name: "test", type: "String", equals: "\"value\"")
    }

    let generated = syntax.generateCode().trimmingCharacters(in: .whitespacesAndNewlines)

    // This replaces: XCTAssertFalse(generated.isEmpty)
    #expect(!generated.isEmpty)
  }

  // MARK: - Complex Assertion Migration Tests

  @Test internal func testNormalizedStringComparisonMigration() throws {
    let blackjackCard = Struct("Card") {
      Enum("Suit") {
        EnumCase("hearts").equals("♡")
        EnumCase("spades").equals("♠")
      }.inherits("Character")
    }

    let expected = """
      struct Card {
        enum Suit: Character {
          case hearts = "♡"
          case spades = "♠"
        }
      }
      """

    // Test the complete normalization pipeline that was used in XCTest
    let normalizedGenerated = blackjackCard.syntax.description.normalize()

    let normalizedExpected = expected.normalize()

    // This replaces: XCTAssertEqual(normalizedGenerated, normalizedExpected)
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testMultipleAssertionsInSingleTest() {
    let generated = "struct Test { var value: Int }"

    // Test multiple assertions in one test method
    #expect(!generated.isEmpty)
    #expect(generated.contains("struct Test"))
    #expect(generated.contains("var value: Int"))
  }
}
