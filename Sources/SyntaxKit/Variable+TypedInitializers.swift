//
//  Variable+TypedInitializers.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

// MARK: - Variable Typed Initializers

extension Variable {
  /// Creates a `let` or `var` declaration with an Init value, inferring the type from the Init.
  /// - Parameters:
  ///   - kind: The kind of variable, either ``VariableKind/let`` or ``VariableKind/var``.
  ///   - name: The name of the variable.
  ///   - equals: An Init expression.
  ///   - explicitType: Whether the variable has an explicit type.
  public init(
    _ kind: VariableKind,
    name: String,
    equals defaultValue: Init,
    explicitType: Bool? = nil
  ) {
    self.init(
      kind: kind,
      name: name,
      type: nil,  // Will be inferred from Init
      defaultValue: defaultValue,
      explicitType: explicitType ?? false
    )
  }

  /// Creates a `let` or `var` declaration with an explicit type.
  /// - Parameters:
  ///   - kind: The kind of variable, either ``VariableKind/let`` or ``VariableKind/var``.
  ///   - name: The name of the variable.
  ///   - type: The type of the variable.
  ///   - equals: The initial value expression of the variable, if any.
  ///   - explicitType: Whether the variable has an explicit type.
  public init(
    _ kind: VariableKind,
    name: String,
    type: String,
    equals defaultValue: CodeBlock? = nil,
    explicitType: Bool? = nil
  ) {
    let finalExplicitType = explicitType ?? (defaultValue == nil)
    self.init(
      kind: kind,
      name: name,
      type: type,
      defaultValue: defaultValue,
      explicitType: finalExplicitType
    )
  }

  /// Creates a `let` or `var` declaration with an explicit type and string literal value.
  /// - Parameters:
  ///   - kind: The kind of variable, either ``VariableKind/let`` or ``VariableKind/var``.
  ///   - name: The name of the variable.
  ///   - type: The type of the variable.
  ///   - equals: A string literal value.
  ///   - explicitType: Whether the variable has an explicit type.
  public init(
    _ kind: VariableKind,
    name: String,
    type: String,
    equals value: String,
    explicitType: Bool? = nil
  ) {
    self.init(
      kind: kind,
      name: name,
      type: type,
      defaultValue: Literal.string(value),
      explicitType: explicitType ?? true
    )
  }

  /// Creates a `let` or `var` declaration with an explicit type and integer literal value.
  /// - Parameters:
  ///   - kind: The kind of variable, either ``VariableKind/let`` or ``VariableKind/var``.
  ///   - name: The name of the variable.
  ///   - type: The type of the variable.
  ///   - equals: An integer literal value.
  ///   - explicitType: Whether the variable has an explicit type.
  public init(
    _ kind: VariableKind,
    name: String,
    type: String,
    equals value: Int,
    explicitType: Bool? = nil
  ) {
    self.init(
      kind: kind,
      name: name,
      type: type,
      defaultValue: Literal.integer(value),
      explicitType: explicitType ?? true
    )
  }

  /// Creates a `let` or `var` declaration with an explicit type and boolean literal value.
  /// - Parameters:
  ///   - kind: The kind of variable, either ``VariableKind/let`` or ``VariableKind/var``.
  ///   - name: The name of the variable.
  ///   - type: The type of the variable.
  ///   - equals: A boolean literal value.
  ///   - explicitType: Whether the variable has an explicit type.
  public init(
    _ kind: VariableKind,
    name: String,
    type: String,
    equals value: Bool,
    explicitType: Bool? = nil
  ) {
    self.init(
      kind: kind,
      name: name,
      type: type,
      defaultValue: Literal.boolean(value),
      explicitType: explicitType ?? true
    )
  }

  /// Creates a `let` or `var` declaration with an explicit type and double literal value.
  /// - Parameters:
  ///   - kind: The kind of variable, either ``VariableKind/let`` or ``VariableKind/var``.
  ///   - name: The name of the variable.
  ///   - type: The type of the variable.
  ///   - equals: A double literal value.
  ///   - explicitType: Whether the variable has an explicit type.
  public init(
    _ kind: VariableKind,
    name: String,
    type: String,
    equals value: Double,
    explicitType: Bool? = nil
  ) {
    self.init(
      kind: kind,
      name: name,
      type: type,
      defaultValue: Literal.float(value),
      explicitType: explicitType ?? true
    )
  }
}
