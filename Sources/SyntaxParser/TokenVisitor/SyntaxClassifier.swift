//
//  SyntaxClassifier.swift
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
@_spi(RawSyntax) import SwiftSyntax

/// Utility for classifying Swift syntax nodes and cleaning type names.
///
/// SyntaxClassifier provides semantic classification of syntax elements and
/// handles the normalization of SwiftSyntax type names for readability.
/// This helps categorize nodes by their role in the language (declarations,
/// expressions, patterns, etc.) rather than their specific SwiftSyntax type.
internal enum SyntaxClassifier {
  // MARK: - String Constants

  /// Suffix used by SwiftSyntax type names (e.g., "VariableDeclSyntax" → "VariableDecl").
  private static let syntax = "Syntax"

  // MARK: - Classification Methods

  /// Classifies a syntax node by its semantic role in the Swift language.
  ///
  /// This method examines the SwiftSyntax node type hierarchy to determine
  /// the semantic category of the node, which helps consumers understand
  /// its purpose without needing detailed SwiftSyntax knowledge.
  ///
  /// - Parameter node: The SwiftSyntax node to classify
  /// - Returns: The semantic classification of the node
  internal static func classifyNode(_ node: Syntax) -> SyntaxType {
    switch node {
    case _ where node.is(DeclSyntax.self):
      return .decl  // Declarations (struct, func, var, etc.)
    case _ where node.is(ExprSyntax.self):
      return .expr  // Expressions (literals, function calls, etc.)
    case _ where node.is(PatternSyntax.self):
      return .pattern  // Patterns (identifier patterns, tuple patterns, etc.)
    case _ where node.is(TypeSyntax.self):
      return .type  // Type annotations and references
    default:
      return .other  // Other syntax elements (punctuation, keywords, etc.)
    }
  }

  /// Cleans up SwiftSyntax type names by removing the "Syntax" suffix.
  ///
  /// SwiftSyntax type names typically end with "Syntax" (e.g., "VariableDeclSyntax").
  /// This method removes that suffix to create more readable names for output
  /// (e.g., "VariableDecl"), making the tree structure more human-friendly.
  ///
  /// - Parameter node: The SwiftSyntax node whose type name should be cleaned
  /// - Returns: Cleaned class name without "Syntax" suffix
  internal static func cleanClassName(from node: Syntax) -> String {
    let fullName = "\(node.syntaxNodeType)"
    if fullName.hasSuffix(syntax) {
      return String(fullName.dropLast(syntax.count))
    } else {
      return fullName
    }
  }
}
