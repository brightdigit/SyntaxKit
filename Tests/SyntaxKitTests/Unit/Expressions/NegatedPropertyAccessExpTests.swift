//
//  NegatedPropertyAccessExpTests.swift
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

/// Test suite for NegatedPropertyAccessExp expression functionality.
///
/// This test suite covers the negated property access expression
/// functionality (e.g., `!user.isEnabled`) in SyntaxKit.
internal final class NegatedPropertyAccessExpTests {
  /// Tests basic negated property access expression.
  @Test("Basic negated property access expression generates correct syntax")
  internal func testBasicNegatedPropertyAccess() {
    let negatedAccess = NegatedPropertyAccessExp(
      baseName: "user",
      propertyName: "isEnabled"
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!user.isEnabled"))
  }

  /// Tests negated property access with complex base expression.
  @Test("Negated property access with complex base expression generates correct syntax")
  internal func testNegatedPropertyAccessWithComplexBaseExpression() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: Call("getUserManager"),
        propertyName: "currentUser"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!getUserManager().currentUser"))
  }

  /// Tests negated property access with deeply nested property access.
  @Test("Negated property access with deeply nested property access generates correct syntax")
  internal func testNegatedPropertyAccessWithDeeplyNestedPropertyAccess() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: PropertyAccessExp(
          base: PropertyAccessExp(
            base: Call("getUserManager"),
            propertyName: "currentUser"
          ),
          propertyName: "profile"
        ),
        propertyName: "settings"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!getUserManager().currentUser.profile.settings"))
  }

  /// Tests negated property access with method call.
  @Test("Negated property access with method call generates correct syntax")
  internal func testNegatedPropertyAccessWithMethodCall() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: Call("getData"),
        propertyName: "isValid"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!getData().isValid"))
  }

  /// Tests negated property access with nested property access base.
  @Test("Negated property access with nested property access base generates correct syntax")
  internal func testNegatedPropertyAccessWithNestedPropertyAccessBase() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: VariableExp("viewController"),
        propertyName: "delegate"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!viewController.delegate"))
  }

  /// Tests negated property access with function call base.
  @Test("Negated property access with function call base generates correct syntax")
  internal func testNegatedPropertyAccessWithFunctionCallBase() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: Call("getCurrentUser"),
        propertyName: "isActive"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!getCurrentUser().isActive"))
  }

  /// Tests negated property access with complex function call base.
  @Test("Negated property access with complex function call base generates correct syntax")
  internal func testNegatedPropertyAccessWithComplexFunctionCallBase() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: Call("getUserManager"),
        propertyName: "isAuthenticated"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!getUserManager().isAuthenticated"))
  }

  /// Tests negated property access with literal base.
  @Test("Negated property access with literal base generates correct syntax")
  internal func testNegatedPropertyAccessWithLiteralBase() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: VariableExp("constant"),
        propertyName: "isValid"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!constant.isValid"))
  }

  /// Tests negated property access with array literal base.
  @Test("Negated property access with array literal base generates correct syntax")
  internal func testNegatedPropertyAccessWithArrayLiteralBase() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: VariableExp("array"),
        propertyName: "isEmpty"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!array.isEmpty"))
  }

  /// Tests negated property access with dictionary literal base.
  @Test("Negated property access with dictionary literal base generates correct syntax")
  internal func testNegatedPropertyAccessWithDictionaryLiteralBase() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: VariableExp("dict"),
        propertyName: "isEmpty"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!dict.isEmpty"))
  }

  /// Tests negated property access with tuple literal base.
  @Test("Negated property access with tuple literal base generates correct syntax")
  internal func testNegatedPropertyAccessWithTupleLiteralBase() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: VariableExp("tuple"),
        propertyName: "isEmpty"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!tuple.isEmpty"))
  }

  /// Tests negated property access with conditional operator base.
  @Test("Negated property access with conditional operator base generates correct syntax")
  internal func testNegatedPropertyAccessWithConditionalOperatorBase() {
    let conditional = ConditionalOp(
      if: VariableExp("isEnabled"),
      then: VariableExp("enabledValue"),
      else: VariableExp("disabledValue")
    )

    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: conditional,
        propertyName: "isValid"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!isEnabled ? enabledValue : disabledValue.isValid"))
  }

  /// Tests negated property access with enum case base.
  @Test("Negated property access with enum case base generates correct syntax")
  internal func testNegatedPropertyAccessWithEnumCaseBase() {
    let enumCase = EnumCase("active")
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: enumCase,
        propertyName: "isEnabled"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!.isEnabled"))
  }

  /// Tests negated property access with closure base.
  @Test("Negated property access with closure base generates correct syntax")
  internal func testNegatedPropertyAccessWithClosureBase() {
    let closure = Closure(body: { VariableExp("result") })
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: closure,
        propertyName: "isValid"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description.normalize()

    #expect(description.contains("! { result }.isValid".normalize()))
  }

  /// Tests negated property access with init call base.
  @Test("Negated property access with init call base generates correct syntax")
  internal func testNegatedPropertyAccessWithInitCallBase() {
    let initCall = Init("String")
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: initCall,
        propertyName: "isEmpty"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!String().isEmpty"))
  }

  /// Tests negated property access with reference expression base.
  @Test("Negated property access with reference expression base generates correct syntax")
  internal func testNegatedPropertyAccessWithReferenceExpressionBase() {
    let reference = ReferenceExp(
      base: VariableExp("self"),
      referenceType: "weak"
    )

    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: reference,
        propertyName: "isValid"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!self.isValid"))
  }

  /// Tests negated property access with property access expression base.
  @Test("Negated property access with property access expression base generates correct syntax")
  internal func testNegatedPropertyAccessWithPropertyAccessExpressionBase() {
    let propertyAccess = PropertyAccessExp(
      base: VariableExp("user"),
      propertyName: "profile"
    )
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: propertyAccess,
        propertyName: "isValid"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!user.profile.isValid"))
  }

  /// Tests negated property access with complex nested expression base.
  @Test("Negated property access with complex nested expression base generates correct syntax")
  internal func testNegatedPropertyAccessWithComplexNestedExpressionBase() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: PropertyAccessExp(
          base: Call("getUserManager"),
          propertyName: "currentUser"
        ),
        propertyName: "isAuthenticated"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!getUserManager().currentUser.isAuthenticated"))
  }

  /// Tests negated property access with empty property name.
  @Test("Negated property access with empty property name generates correct syntax")
  internal func testNegatedPropertyAccessWithEmptyPropertyName() {
    let negatedAccess = NegatedPropertyAccessExp(
      baseName: "user",
      propertyName: ""
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!user."))
  }

  /// Tests negated property access with special character property name.
  @Test("Negated property access with special character property name generates correct syntax")
  internal func testNegatedPropertyAccessWithSpecialCharacterPropertyName() {
    let negatedAccess = NegatedPropertyAccessExp(
      baseName: "user",
      propertyName: "is_Enabled"
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!user.is_Enabled"))
  }

  /// Tests negated property access with numeric property name.
  @Test("Negated property access with numeric property name generates correct syntax")
  internal func testNegatedPropertyAccessWithNumericPropertyName() {
    let negatedAccess = NegatedPropertyAccessExp(
      baseName: "user",
      propertyName: "value1"
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!user.value1"))
  }

  /// Tests negated property access with camelCase property name.
  @Test("Negated property access with camelCase property name generates correct syntax")
  internal func testNegatedPropertyAccessWithCamelCasePropertyName() {
    let negatedAccess = NegatedPropertyAccessExp(
      baseName: "user",
      propertyName: "isUserEnabled"
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!user.isUserEnabled"))
  }

  /// Tests negated property access with snake_case property name.
  @Test("Negated property access with snake_case property name generates correct syntax")
  internal func testNegatedPropertyAccessWithSnakeCasePropertyName() {
    let negatedAccess = NegatedPropertyAccessExp(
      baseName: "user",
      propertyName: "is_user_enabled"
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!user.is_user_enabled"))
  }

  /// Tests negated property access with kebab-case property name.
  @Test("Negated property access with kebab-case property name generates correct syntax")
  internal func testNegatedPropertyAccessWithKebabCasePropertyName() {
    let negatedAccess = NegatedPropertyAccessExp(
      baseName: "user",
      propertyName: "is-user-enabled"
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!user.is-user-enabled"))
  }

  /// Tests negated property access with property name containing spaces.
  @Test("Negated property access with property name containing spaces generates correct syntax")
  internal func testNegatedPropertyAccessWithPropertyNameContainingSpaces() {
    let negatedAccess = NegatedPropertyAccessExp(
      baseName: "user",
      propertyName: "is user enabled"
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!user.is user enabled"))
  }

  /// Tests negated property access with property name containing special characters.
  @Test(
    "Negated property access with property name containing special characters generates correct syntax"
  )
  internal func testNegatedPropertyAccessWithPropertyNameContainingSpecialCharacters() {
    let negatedAccess = NegatedPropertyAccessExp(
      baseName: "user",
      propertyName: "is@user#enabled"
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!user.is@user#enabled"))
  }

  /// Tests negated property access with nested property access.
  @Test("Negated property access with nested property access generates correct syntax")
  internal func testNegatedPropertyAccessWithNestedPropertyAccess() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: PropertyAccessExp(
          base: PropertyAccessExp(
            base: Call("getUserManager"),
            propertyName: "currentUser"
          ),
          propertyName: "profile"
        ),
        propertyName: "settings"
      )
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!getUserManager().currentUser.profile.settings"))
  }
}
