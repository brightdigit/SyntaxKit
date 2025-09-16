//
//  SyntaxType.swift
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

/// Semantic classification of syntax elements in the Swift AST.
///
/// SyntaxType provides a high-level categorization of syntax nodes that helps
/// consumers understand the role and purpose of each element without needing
/// to parse the detailed SwiftSyntax type names. This classification is
/// particularly useful for syntax highlighting, code analysis, and other
/// tools that need to treat different kinds of syntax elements differently.
///
/// The classification is based on the SwiftSyntax type hierarchy and groups
/// related syntax elements into meaningful categories.
package enum SyntaxType: String, Codable, Equatable, Sendable {
  /// Declaration syntax elements.
  /// Includes: struct, class, enum, func, var, let, import, protocol, extension, etc.
  case decl

  /// Expression syntax elements.
  /// Includes: literals, function calls, property access, operators, closures, etc.
  case expr

  /// Pattern syntax elements.
  /// Includes: identifier patterns, tuple patterns, wildcard patterns, etc.
  /// Used in variable bindings, function parameters, and pattern matching.
  case pattern

  /// Type syntax elements.
  /// Includes: type annotations, type references, generic parameters, etc.
  case type

  /// Collection syntax elements.
  /// Includes: lists, arrays, and other grouped syntax elements.
  /// Special category for nodes that contain multiple child elements.
  case collection

  /// Other syntax elements.
  /// Includes: punctuation, keywords, comments, and structural elements
  /// that don't fit into the above semantic categories.
  case other
}
