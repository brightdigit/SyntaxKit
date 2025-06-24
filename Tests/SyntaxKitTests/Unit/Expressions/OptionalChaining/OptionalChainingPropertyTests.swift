//
//  OptionalChainingPropertyTests.swift
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

/// Test suite for OptionalChainingExp property access functionality.
///
/// This test suite covers the optional chaining expression functionality
/// with property access (e.g., `user.profile?`, `self.property?`) in SyntaxKit.
internal final class OptionalChainingPropertyTests {
  /// Tests optional chaining with property access.
  @Test("Optional chaining with property access generates correct syntax")
  internal func testOptionalChainingWithPropertyAccess() {
    let optionalChain = OptionalChainingExp(
      base: PropertyAccessExp(base: VariableExp("user"), propertyName: "profile")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("user.profile?"))
  }

  /// Tests optional chaining with nested property access.
  @Test("Optional chaining with nested property access generates correct syntax")
  internal func testOptionalChainingWithNestedPropertyAccess() {
    let optionalChain = OptionalChainingExp(
      base: PropertyAccessExp(
        base: PropertyAccessExp(base: VariableExp("user"), propertyName: "profile"),
        propertyName: "settings"
      )
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("user.profile.settings?"))
  }

  /// Tests optional chaining with array access.
  @Test("Optional chaining with array access generates correct syntax")
  internal func testOptionalChainingWithArrayAccess() {
    let optionalChain = OptionalChainingExp(
      base: PropertyAccessExp(base: VariableExp("users"), propertyName: "0")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("users.0?"))
  }

  /// Tests optional chaining with dictionary access.
  @Test("Optional chaining with dictionary access generates correct syntax")
  internal func testOptionalChainingWithDictionaryAccess() {
    let optionalChain = OptionalChainingExp(
      base: PropertyAccessExp(base: VariableExp("config"), propertyName: "apiKey")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("config.apiKey?"))
  }

  /// Tests optional chaining with computed property.
  @Test("Optional chaining with computed property generates correct syntax")
  internal func testOptionalChainingWithComputedProperty() {
    let optionalChain = OptionalChainingExp(
      base: PropertyAccessExp(base: VariableExp("self"), propertyName: "computedValue")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("self.computedValue?"))
  }

  /// Tests optional chaining with static property.
  @Test("Optional chaining with static property generates correct syntax")
  internal func testOptionalChainingWithStaticProperty() {
    let optionalChain = OptionalChainingExp(
      base: PropertyAccessExp(base: VariableExp("UserManager"), propertyName: "shared")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("UserManager.shared?"))
  }

  /// Tests optional chaining with subscript access.
  @Test("Optional chaining with subscript access generates correct syntax")
  internal func testOptionalChainingWithSubscriptAccess() {
    let optionalChain = OptionalChainingExp(
      base: PropertyAccessExp(base: VariableExp("array"), propertyName: "0")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("array.0?"))
  }
}
