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
internal struct StructureProperty: Codable, Equatable {
  /// The name of this structural property.
  /// Corresponds to SwiftSyntax property names like "name", "parameters", "body", etc.
  internal let name: String

  /// The value of this property, if it contains terminal data.
  /// Present for tokens, literals, and other concrete values.
  /// Nil for missing optional properties.
  internal let value: StructureValue?

  /// Reference to another syntax node type, if this property contains a nested structure.
  /// Used when this property points to another syntax node rather than containing terminal data.
  /// Example: "body" property might reference "CodeBlockSyntax"
  internal let ref: String?

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
}
