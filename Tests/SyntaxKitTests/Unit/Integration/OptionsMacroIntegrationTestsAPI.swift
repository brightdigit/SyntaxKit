import Foundation
import Testing

@testable import SyntaxKit

internal struct OptionsMacroIntegrationTestsAPI {
  // MARK: - API Validation Tests

  @Test internal func testNewSyntaxKitAPICompleteness() {
    // Verify that all the new API components work together correctly

    // Test LiteralValue protocol
    let array: [String] = ["a", "b", "c"]
    #expect(array.typeName == "[String]")
    #expect(array.literalString == "[\"a\", \"b\", \"c\"]")

    let dict: [Int: String] = [1: "a", 2: "b"]
    #expect(dict.typeName == "[Int: String]")
    #expect(dict.literalString.contains("1: \"a\""))
    #expect(dict.literalString.contains("2: \"b\""))

    // Test Variable with static support
    let staticVar = Variable(.let, name: "test", equals: array).withExplicitType().static()
    let staticGenerated = staticVar.generateCode().normalize()
    #expect(staticGenerated.contains("static let test: [String] = [\"a\", \"b\", \"c\"]"))

    // Test Extension with inheritance
    let ext = Extension("Test") {
      // Empty content
    }.inherits("Protocol1", "Protocol2")

    let extGenerated = ext.generateCode().normalize()
    #expect(extGenerated.contains("extension Test: Protocol1, Protocol2"))

    // Test TypeAlias
    let alias = TypeAlias("MyType", equals: "String")
    let aliasGenerated = alias.generateCode().normalize()
    #expect(aliasGenerated.contains("typealias MyType = String"))
  }
}
