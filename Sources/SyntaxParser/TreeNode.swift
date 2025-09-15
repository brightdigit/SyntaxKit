//
//  TreeNode.swift
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

/// Represents a single node in the simplified syntax tree structure.
///
/// TreeNode is the core data structure that represents each element of the Swift AST
/// in a flat, JSON-serializable format. Each node contains essential information about
/// a syntax element including its location, type, content, and relationships.
///
/// The tree structure is flattened using ID-based parent-child relationships rather
/// than object references, making it suitable for JSON serialization and consumption
/// by external tools.
internal final class TreeNode: Codable {
  // MARK: - Identity and Relationships

  /// Unique identifier for this node within the tree.
  /// Used to establish parent-child relationships and references.
  internal let id: Int

  /// ID of the parent node, if any.
  /// Root nodes have no parent (nil). This creates a flat tree structure
  /// suitable for JSON serialization.
  internal var parent: Int?

  // MARK: - Content and Metadata

  /// The text content or type name of this syntax element.
  /// For tokens: the actual source text (e.g., "let", "myVariable", "42")
  /// For syntax nodes: the cleaned type name (e.g., "VariableDecl", "FunctionCall")
  internal var text: String

  /// Source location range where this syntax element appears in the original code.
  /// Provides line and column coordinates for both start and end positions.
  internal var range = SourceRange(
    startRow: 0,
    startColumn: 0,
    endRow: 0,
    endColumn: 0
  )

  /// Structural properties that describe the internal organization of this syntax element.
  /// Each property represents a named component (e.g., "name", "parameters", "body")
  /// and may reference other nodes or contain token values.
  internal var structure = [StructureProperty]()

  /// Semantic classification of this syntax element.
  /// Helps consumers understand the role of this node (declaration, expression, etc.).
  internal var type: SyntaxType

  /// Token-specific metadata, present only for leaf nodes in the syntax tree.
  /// Contains detailed information about token kind, leading/trailing trivia.
  internal var token: Token?

  // MARK: - Initialization

  /// Creates a new TreeNode with the specified properties.
  ///
  /// - Parameters:
  ///   - id: Unique identifier for this node
  ///   - text: Text content or type name
  ///   - range: Source location range
  ///   - type: Semantic classification
  internal init(id: Int, text: String, range: SourceRange, type: SyntaxType) {
    self.id = id
    self.text = text
    self.range = range
    self.type = type
  }
}

extension TreeNode: Equatable {
  internal static func == (lhs: TreeNode, rhs: TreeNode) -> Bool {
    lhs.id == rhs.id && lhs.parent == rhs.parent && lhs.text == rhs.text && lhs.range == rhs.range
      && lhs.structure == rhs.structure && lhs.type == rhs.type && lhs.token == rhs.token
  }
}
