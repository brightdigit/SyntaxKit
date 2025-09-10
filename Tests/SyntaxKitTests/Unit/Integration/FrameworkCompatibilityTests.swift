import Foundation
import Testing

@testable import SyntaxKit

/// Tests to ensure compatibility and feature parity between XCTest and Swift Testing
/// Validates that the migration maintains all testing capabilities
internal struct FrameworkCompatibilityTests {
  // MARK: - Test Organization Migration Tests

  @Test internal func testStructBasedOrganization() {
    // Test that struct-based test organization works
    // This replaces: final class TestClass: XCTestCase
    let testExecuted = true
    #expect(testExecuted)
  }

  @Test internal func testMethodAnnotationMigration() throws {
    // Test that @Test annotation works with throws
    // This replaces: func testMethod() throws
    let syntax = Enum("TestEnum") {
      EnumCase("first")
      EnumCase("second")
    }

    let generated = syntax.syntax.description
    #expect(!generated.isEmpty)
    #expect(generated.contains("enum TestEnum"))
  }

  // MARK: - Error Handling Compatibility Tests

  @Test internal func testThrowingTestCompatibility() {
    // Ensure throws declaration works properly with @Test
    let function = Function("throwingFunction", returns: "String") {
      Parameter(name: "input", type: "String")
    } _: {
      Return {
        VariableExp("input.uppercased()")
      }
    }

    let generated = function.syntax.description
    #expect(generated.contains("func throwingFunction"))
  }

  // MARK: - Complex DSL Compatibility Tests

  @Test internal func testFullBlackjackCompatibility() throws {
    // Test complex DSL patterns work with new framework
    let syntax = Struct("BlackjackCard") {
      Enum("Suit") {
        EnumCase("spades").equals("♠")
        EnumCase("hearts").equals("♡")
        EnumCase("diamonds").equals("♢")
        EnumCase("clubs").equals("♣")
      }.inherits("Character")

      Enum("Rank") {
        EnumCase("ace").equals(1)
        EnumCase("two").equals(2)
        EnumCase("jack").equals(11)
        EnumCase("queen").equals(12)
        EnumCase("king").equals(13)
      }.inherits("Int")

      Variable(.let, name: "rank", type: "Rank")
      Variable(.let, name: "suit", type: "Suit")
    }

    let generated = syntax.syntax.description
    let normalized = generated.normalize()

    // Validate all components are present
    #expect(normalized.contains("struct BlackjackCard"))
    #expect(normalized.contains("enum Suit: Character"))
    #expect(normalized.contains("enum Rank: Int"))
    #expect(normalized.contains("let rank: Rank"))
    #expect(normalized.contains("let suit: Suit"))
  }

  // MARK: - Function Generation Compatibility Tests

  @Test internal func testFunctionGenerationCompatibility() throws {
    let function = Function("calculateValue", returns: "Int") {
      Parameter(name: "multiplier", type: "Int")
      Parameter(name: "base", type: "Int", defaultValue: "10")
    } _: {
      Return {
        VariableExp("multiplier * base")
      }
    }

    let generated = function.syntax.description
    let normalized =
      generated
      .normalize()

    #expect(normalized.contains("func calculateValue(multiplier: Int, base: Int = 10) -> Int"))
    #expect(normalized.contains("return multiplier * base"))
  }

  // MARK: - Comment Injection Compatibility Tests

  @Test internal func testCommentInjectionCompatibility() {
    let syntax = Struct("DocumentedStruct") {
      Variable(.let, name: "value", type: "String")
        .comment {
          Line(.doc, "The main value of the struct")
        }
    }.comment {
      Line("MARK: - Data Models")
      Line(.doc, "A documented struct for testing")
    }

    let generated = syntax.generateCode()

    #expect(!generated.isEmpty)
    #expect(generated.contains("struct DocumentedStruct"))
    #expect(generated.normalize().contains("let value: String".normalize()))
  }

  // MARK: - Migration Regression Tests

  @Test internal func testNoRegressionInCodeGeneration() {
    // Ensure migration doesn't introduce regressions
    let simpleStruct = Struct("Point") {
      Variable(.var, name: "x", type: "Double", equals: 0.0).withExplicitType()
      Variable(.var, name: "y", type: "Double", equals: 0.0).withExplicitType()
    }

    let generated = simpleStruct.generateCode().normalize()

    #expect(generated.contains("struct Point"))
    #expect(generated.contains("var x: Double = 0.0".normalize()))
    #expect(generated.contains("var y: Double = 0.0".normalize()))
  }

  @Test internal func testLiteralGeneration() {
    let group = Group {
      Return {
        Literal.integer(100)
      }
    }

    let generated = group.generateCode().trimmingCharacters(in: .whitespacesAndNewlines)
    #expect(generated == "return 100")
  }
}
