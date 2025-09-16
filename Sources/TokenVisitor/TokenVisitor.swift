//
//  TokenVisitor.swift
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

/// AST visitor that transforms SwiftSyntax nodes into a simplified tree structure for JSON serialization.
///
/// TokenVisitor traverses the SwiftSyntax Abstract Syntax Tree and extracts essential information
/// into a flat array of TreeNode objects. Each node contains:
/// - Semantic type classification (declaration, expression, pattern, type, etc.)
/// - Source location information (line/column ranges)
/// - Structural properties and relationships
/// - Token information for leaf nodes
///
/// The visitor implements the SyntaxRewriter protocol to perform a depth-first traversal,
/// building a parent-child relationship between nodes using ID references rather than
/// object references (suitable for JSON serialization).
internal final class TokenVisitor<NodeType: TreeNodeProtocol>: SyntaxRewriter {
  // MARK: - State Management

  /// The flattened tree structure built during AST traversal.
  /// Each TreeNode represents a syntax element with its metadata and relationships.
  package var tree = [NodeType]()

  /// Currently active node during traversal (used to build parent-child relationships).
  /// This is implicitly unwrapped because it's guaranteed to be set during normal traversal.
  private var current: NodeType?

  /// Sequential ID counter for assigning unique identifiers to each tree node.
  private var index = 0

  // MARK: - Configuration

  /// Converts SwiftSyntax source positions to line/column coordinates.
  package let locationConverter: SourceLocationConverter

  // MARK: - Initialization

  /// Creates a new TokenVisitor with the specified configuration.
  ///
  /// - Parameters:
  ///   - locationConverter: Converts syntax positions to line/column coordinates
  ///   - showMissingTokens: Whether to include missing/implicit tokens in output
  package init(locationConverter: SourceLocationConverter, showMissingTokens: Bool) {
    self.locationConverter = locationConverter
    // Use .all view mode if showing missing tokens, otherwise only source-accurate tokens
    super.init(viewMode: showMissingTokens ? .all : .sourceAccurate)
  }

  // MARK: - SyntaxRewriter Overrides

  /// Called before visiting a syntax node's children.
  ///
  /// This method extracts essential information from each SwiftSyntax node and creates
  /// a corresponding TreeNode with:
  /// - Cleaned class name (removes "Syntax" suffix)
  /// - Semantic type classification (declaration, expression, pattern, type, other)
  /// - Source location range (line/column coordinates)
  /// - Structural properties based on the node's layout
  ///
  /// - Parameter node: The SwiftSyntax node being visited
  override internal func visitPre(_ node: Syntax) {
    // Classify and extract node information using utility types
    let className = node.cleanClassName
    let syntaxType = node.syntaxType

    // Create tree node using convenience initializer
    let treeNode = NodeType(
      id: index,
      from: node,
      locationConverter: locationConverter,
      syntaxType: syntaxType,
      className: className
    )

    // Add to tree and prepare for next node
    tree.append(treeNode)
    index += 1

    // Extract structural information using utility
    let allChildren = node.children(viewMode: .all)
    StructureExtractor.extractStructure(from: node, into: treeNode, allChildren: allChildren)

    // Establish parent-child relationship
    if let current {
      treeNode.parent = current.id
    }
    current = treeNode
  }

  /// Called when visiting a token (leaf node in the syntax tree).
  ///
  /// This method processes terminal tokens like keywords, identifiers, operators, and literals.
  /// It extracts the token's text content and associated trivia (whitespace, comments, etc.).
  ///
  /// - Parameter token: The token being visited
  /// - Returns: The unmodified token (this is a read-only transformation)
  override internal func visit(_ token: TokenSyntax) -> TokenSyntax {
    assert(current != nil)

    // Store the actual token text content
    current?.text = token.text

    // Create token metadata with kind information
    current?.token = Token(
      kind: "\(token.tokenKind)",
      leadingTrivia: .empty,
      trailingTrivia: .empty
    )

    // Process leading trivia (whitespace, comments before the token)
    for piece in token.leadingTrivia {
      let trivia = processTriviaPiece(piece)
      current?.token?.leadingTrivia += trivia
    }

    // Process trailing trivia (whitespace, comments after the token)
    for piece in token.trailingTrivia {
      let trivia = processTriviaPiece(piece)
      current?.token?.trailingTrivia += trivia
    }

    return token
  }

  /// Called after visiting a syntax node and all its children.
  ///
  /// This method restores the current node pointer to the parent, maintaining
  /// the traversal state as we move back up the tree.
  ///
  /// - Parameter node: The syntax node whose children have been visited
  override internal func visitPost(_ node: Syntax) {
    assert(current != nil)

    // Move back to parent node, or nil if we're at the root
    if let parent = current?.parent {
      current = tree[parent]
    } else {
      current = nil
    }
  }

  // MARK: - Helper Methods

  /// Converts a SwiftSyntax trivia piece into its string representation.
  ///
  /// Trivia includes all the "invisible" elements around tokens: whitespace,
  /// comments, and other formatting. This method converts each type of trivia
  /// into plain text suitable for console output, preserving the original
  /// formatting and content.
  ///
  /// - Parameter piece: The trivia piece to convert
  /// - Returns: String representation of the trivia
  internal func processTriviaPiece(_ piece: TriviaPiece) -> String {
    piece.processedString
  }
}
