//
//  VariableCoverageTests.swift
//  SyntaxKitTests
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import SwiftSyntax
import Testing

@testable import SyntaxKit

/// Test suite for improving code coverage of Variable-related functionality.
///
/// This test suite focuses on testing edge cases and uncovered code paths
/// in the Variable extension files to ensure comprehensive test coverage.
internal final class VariableCoverageTests {
  // MARK: - Variable+Modifiers.swift Coverage Tests

  /// Tests the "public" case in buildAccessModifier.
  @Test("Build access modifier public")
  internal func testBuildAccessModifierPublic() {
    // Test the "public" case in buildAccessModifier
    let variable = Variable(.let, name: "test", equals: "value")
      .access(.public)

    let syntax = variable.syntax
    let description = syntax.description

    // Verify that the public access modifier is properly included
    #expect(description.contains("public let test  = \"value\""))
  }

  /// Tests the "internal" case in buildAccessModifier.
  @Test("Build access modifier internal")
  internal func testBuildAccessModifierInternal() {
    // Test the "internal" case in buildAccessModifier
    let variable = Variable(.let, name: "test", equals: "value")
      .access(.internal)

    let syntax = variable.syntax
    let description = syntax.description

    // Verify that the internal access modifier is properly included
    #expect(description.contains("internal let test  = \"value\""))
  }

  /// Tests the "fileprivate" case in buildAccessModifier.
  @Test("Build access modifier fileprivate")
  internal func testBuildAccessModifierFileprivate() {
    // Test the "fileprivate" case in buildAccessModifier
    let variable = Variable(.let, name: "test", equals: "value")
      .access(.fileprivate)

    let syntax = variable.syntax
    let description = syntax.description

    // Verify that the fileprivate access modifier is properly included
    #expect(description.contains("fileprivate let test  = \"value\""))
  }

  // MARK: - Variable.swift Coverage Tests

  /// Tests the fallback type case in Variable initializer.
  @Test("Variable initializer with fallback type")
  internal func testVariableInitializerWithFallbackType() {
    // Test the fallback type case in Variable initializer
    // This tests when type is nil and defaultValue is not an Init
    let variable = Variable(kind: .let, name: "test", defaultValue: VariableExp("value"))

    let syntax = variable.syntax
    let description = syntax.description

    // Should use empty string as fallback type
    #expect(description.contains("let test  = value"))
  }

  /// Tests the fallback case in buildExpressionFromValue.
  @Test("Build expression from value fallback")
  internal func testBuildExpressionFromValueFallback() {
    // Test the fallback case in buildExpressionFromValue
    // This tests when value is neither ExprCodeBlock nor ExprSyntax

    // Create a custom CodeBlock that doesn't conform to ExprCodeBlock
    struct CustomCodeBlock: SyntaxKit.CodeBlock {
      var syntax: SyntaxProtocol {
        // Return something that's not ExprSyntax
        DeclSyntax(
          VariableDeclSyntax(
            attributes: AttributeListSyntax([]),
            modifiers: DeclModifierListSyntax([]),
            bindingSpecifier: .keyword(.let, trailingTrivia: .space),
            bindings: PatternBindingListSyntax([])
          )
        )
      }
    }

    let customBlock = CustomCodeBlock()
    let variable = Variable(kind: .let, name: "test", defaultValue: customBlock)

    let syntax = variable.syntax
    let description = syntax.description

    // Should fallback to empty identifier
    #expect(description.contains("let test  = "))
  }

  // MARK: - Variable+Attributes.swift Coverage Tests

  /// Tests buildAttributeArguments with empty arguments array.
  @Test("Build attribute arguments with empty array")
  internal func testBuildAttributeArgumentsWithEmptyArray() {
    // Test buildAttributeArguments with empty arguments array
    let variable = Variable(.let, name: "test", equals: "value")
      .attribute("TestAttribute", arguments: [])

    let syntax = variable.syntax
    let description = syntax.description

    // Should include attribute without parentheses
    #expect(description.contains("@TestAttribute"))
    #expect(!description.contains("@TestAttribute()"))
  }

  /// Tests buildAttributeArguments with multiple arguments.
  @Test("Build attribute arguments with multiple arguments")
  internal func testBuildAttributeArgumentsWithMultipleArguments() {
    // Test buildAttributeArguments with multiple arguments
    let variable = Variable(.let, name: "test", equals: "value")
      .attribute("TestAttribute", arguments: ["arg1", "arg2", "arg3"])

    let syntax = variable.syntax
    let description = syntax.description

    // Should include attribute with comma-separated arguments
    #expect(description.contains("@TestAttribute(arg1, arg2, arg3)"))
  }

  /// Tests buildAttributeList with multiple attributes.
  @Test("Build attribute list with multiple attributes")
  internal func testBuildAttributeListWithMultipleAttributes() {
    // Test buildAttributeList with multiple attributes
    let variable = Variable(.let, name: "test", equals: "value")
      .attribute("Attribute1")
      .attribute("Attribute2", arguments: ["arg1"])
      .attribute("Attribute3", arguments: ["arg1", "arg2"])

    let syntax = variable.syntax
    let description = syntax.description

    // Should include all attributes
    #expect(description.contains("@Attribute1"))
    #expect(description.contains("@Attribute2(arg1)"))
    #expect(description.contains("@Attribute3(arg1, arg2)"))
  }
}
