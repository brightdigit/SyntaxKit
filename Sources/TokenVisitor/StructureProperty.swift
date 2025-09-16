//
//  StructureProperty.swift
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
import SwiftSyntax

/// Represents a named property within a syntax node's structure.
///
/// StructureProperty describes the internal components of a syntax node, such as
/// the "name" property of a function declaration or the "parameters" of a function call.
/// Each property has a name and may contain either a value (for terminals) or a
/// reference to another syntax node type.
///
/// Examples:
/// - Function declaration "name" property → StructureValue with identifier text
/// - Function declaration "body" property → Reference to "CodeBlockSyntax"
/// - Missing optional property → nil value with just the property name
package struct StructureProperty: Codable, Equatable {
  // MARK: - String Constants

  /// Property name for collection element type information.
  private static let element: String = "Element"

  /// Property name for collection count information.
  private static let count: String = "Count"

  /// Placeholder text for missing or nil syntax elements.
  private static let nilValue: String = "nil"

  /// The name of this structural property.
  /// Corresponds to SwiftSyntax property names like "name", "parameters", "body", etc.
  private let name: String

  /// The value of this property, if it contains terminal data.
  /// Present for tokens, literals, and other concrete values.
  /// Nil for missing optional properties.
  private let value: StructureValue?

  /// Reference to another syntax node type, if this property contains a nested structure.
  /// Used when this property points to another syntax node rather than containing terminal data.
  /// Example: "body" property might reference "CodeBlockSyntax"
  private let ref: String?

  /// Creates a new StructureProperty with the specified components.
  ///
  /// - Parameters:
  ///   - name: The property name
  ///   - value: Terminal value data, if any
  ///   - ref: Reference to another syntax type, if any
  internal init(name: String, value: StructureValue? = nil, ref: String? = nil) {
    self.name = name
    self.value = value
    self.ref = ref
  }

  // MARK: - Convenience Initializers

  /// Creates a StructureProperty for a missing property with a nil value indicator.
  ///
  /// - Parameters:
  ///   - name: The property name
  ///   - nilValue: The value to display for the nil value (will be converted to string)
  internal init(nilValueWithName name: String) {
    self.init(name: name, value: StructureValue(text: Self.nilValue), ref: nil)
  }

  /// Creates a StructureProperty for a token value.
  ///
  /// - Parameters:
  ///   - name: The property name
  ///   - text: The token text
  ///   - kind: The token kind
  private init(token name: String, text: String, kind: Any) {
    self.init(name: name, value: StructureValue(text: text, kind: "\(kind)"), ref: nil)
  }

  /// Creates a StructureProperty for a syntax node reference.
  ///
  /// - Parameters:
  ///   - name: The property name
  ///   - type: The syntax node type (will be converted to string)
  internal init(reference name: String, type: Any) {
    let typeString = "\(type)"
    self.init(name: name, value: StructureValue(text: typeString), ref: typeString)
  }

  /// Creates a StructureProperty for a primitive value.
  ///
  /// - Parameters:
  ///   - name: The property name
  ///   - value: The primitive value (will be converted to string)
  internal init(primitive name: String, value: Any) {
    self.init(name: name, value: StructureValue(text: "\(value)"), ref: nil)
  }

  internal init(token name: String, tokenSyntax: TokenSyntax) {
    self.init(
      token: name,
      text: tokenSyntax.text,
      kind: tokenSyntax.tokenKind
    )
  }

  internal init(collectionWithCount count: Int) {
    self.init(primitive: Self.count, value: count)
  }

  internal init(elementWithType type: Any.Type) {
    self.init(primitive: Self.element, value: type)
  }
}
