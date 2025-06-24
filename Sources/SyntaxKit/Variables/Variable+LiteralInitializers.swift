//
//  Variable+LiteralInitializers.swift
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

// MARK: - Variable Literal Initializers

extension Variable {
  /// Creates a `let` or `var` declaration with a literal value.
  /// - Parameters:
  ///   - kind: The kind of variable, either ``VariableKind/let`` or ``VariableKind/var``.
  ///   - name: The name of the variable.
  ///   - equals: A literal value that conforms to ``LiteralValue``.
  public init<T: CodeBlockable & LiteralValue>(
    _ kind: VariableKind, name: String, equals value: T
  ) {
    self.init(
      kind: kind,
      name: name,
      type: value.typeName,
      defaultValue: value.codeBlock,
      explicitType: false
    )
  }

  /// Creates a `let` or `var` declaration with a string literal value.
  /// - Parameters:
  ///   - kind: The kind of variable, either ``VariableKind/let`` or ``VariableKind/var``.
  ///   - name: The name of the variable.
  ///   - equals: A string literal value.
  public init(
    _ kind: VariableKind, name: String, equals value: String
  ) {
    self.init(
      kind: kind,
      name: name,
      type: "String",
      defaultValue: Literal.string(value),
      explicitType: false
    )
  }

  /// Creates a `let` or `var` declaration with an integer literal value.
  /// - Parameters:
  ///   - kind: The kind of variable, either ``VariableKind/let`` or ``VariableKind/var``.
  ///   - name: The name of the variable.
  ///   - equals: An integer literal value.
  public init(
    _ kind: VariableKind, name: String, equals value: Int
  ) {
    self.init(
      kind: kind,
      name: name,
      type: "Int",
      defaultValue: Literal.integer(value),
      explicitType: false
    )
  }

  /// Creates a `let` or `var` declaration with a boolean literal value.
  /// - Parameters:
  ///   - kind: The kind of variable, either ``VariableKind/let`` or ``VariableKind/var``.
  ///   - name: The name of the variable.
  ///   - equals: A boolean literal value.
  public init(
    _ kind: VariableKind, name: String, equals value: Bool
  ) {
    self.init(
      kind: kind,
      name: name,
      type: "Bool",
      defaultValue: Literal.boolean(value),
      explicitType: false
    )
  }

  /// Creates a `let` or `var` declaration with a double literal value.
  /// - Parameters:
  ///   - kind: The kind of variable, either ``VariableKind/let`` or ``VariableKind/var``.
  ///   - name: The name of the variable.
  ///   - equals: A double literal value.
  public init(
    _ kind: VariableKind, name: String, equals value: Double
  ) {
    self.init(
      kind: kind,
      name: name,
      type: "Double",
      defaultValue: Literal.float(value),
      explicitType: false
    )
  }

  /// Creates a `let` or `var` declaration with a Literal value.
  /// - Parameters:
  ///   - kind: The kind of variable, either ``VariableKind/let`` or ``VariableKind/var``.
  ///   - name: The name of the variable.
  ///   - equals: A Literal value.
  public init(
    _ kind: VariableKind, name: String, equals value: Literal
  ) {
    self.init(
      kind: kind,
      name: name,
      type: value.typeName,
      defaultValue: value,
      explicitType: false
    )
  }

  /// Creates a `let` or `var` declaration with a value built from a CodeBlock builder closure.
  /// - Parameters:
  ///   - kind: The kind of variable, either ``VariableKind/let`` or ``VariableKind/var``.
  ///   - name: The name of the variable.
  ///   - value: A builder closure that returns a CodeBlock for the initial value.
  ///   - explicitType: Whether the variable has an explicit type.
  public init(
    _ kind: VariableKind,
    name: String,
    @CodeBlockBuilderResult value: () throws -> [CodeBlock],
    explicitType: Bool? = nil
  ) rethrows {
    self.init(
      kind: kind,
      name: name,
      type: "",
      defaultValue: try value().first ?? EmptyCodeBlock(),
      explicitType: explicitType ?? false
    )
  }
}
