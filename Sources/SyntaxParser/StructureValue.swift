//
//  StructureValue.swift
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

/// Contains the concrete value data for a structure property.
///
/// StructureValue holds the actual content of a syntax element property,
/// such as the text of an identifier token or the string representation
/// of a syntax node type. It optionally includes kind information to
/// distinguish between different types of values.
///
/// Examples:
/// - Token value: text="let", kind="keyword(SwiftSyntax.Keyword.let)"
/// - Type reference: text="VariableDeclSyntax", kind=nil
/// - Literal value: text="42", kind="integerLiteral(42)"
package struct StructureValue: Codable, Equatable {
  /// The string representation of this value.
  /// Contains the actual text content or type name.
  package let text: String

  /// Optional kind information that provides additional context about the value type.
  /// Present for tokens to indicate their specific token kind (e.g., "keyword", "identifier").
  /// Nil for simple text values and type references.
  package let kind: String?

  /// Creates a new StructureValue with the specified content.
  ///
  /// - Parameters:
  ///   - text: The string representation of the value
  ///   - kind: Optional kind information for additional context
  package init(text: String, kind: String? = nil) {
    self.text = text
    self.kind = kind
  }
}
