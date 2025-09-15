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
internal final class TokenVisitor: SyntaxRewriter {
  // MARK: - State Management

  /// The flattened tree structure built during AST traversal.
  /// Each TreeNode represents a syntax element with its metadata and relationships.
  internal var tree = [TreeNode]()

  /// Currently active node during traversal (used to build parent-child relationships).
  /// This is implicitly unwrapped because it's guaranteed to be set during normal traversal.
  private var current: TreeNode!

  /// Sequential ID counter for assigning unique identifiers to each tree node.
  private var index = 0

  // MARK: - Configuration

  /// Converts SwiftSyntax source positions to line/column coordinates.
  internal let locationConverter: SourceLocationConverter

  /// Whether to include missing/implicit tokens in the output tree.
  /// When true, placeholder tokens and missing syntax elements are included.
  internal let showMissingTokens: Bool

  // MARK: - String Constants

  /// Suffix used by SwiftSyntax type names (e.g., "VariableDeclSyntax" → "VariableDecl").
  private static let syntax = "Syntax"

  /// Placeholder text for missing or nil syntax elements.
  private static let nilValue = "nil"

  /// Property name for collection element type information.
  private static let element = "Element"

  /// Property name for collection count information.
  private static let count = "Count"

  /// Empty string constant used throughout the module.
  internal static let emptyString = ""

  // MARK: - Initialization

  /// Creates a new TokenVisitor with the specified configuration.
  ///
  /// - Parameters:
  ///   - locationConverter: Converts syntax positions to line/column coordinates
  ///   - showMissingTokens: Whether to include missing/implicit tokens in output
  internal init(locationConverter: SourceLocationConverter, showMissingTokens: Bool) {
    self.locationConverter = locationConverter
    self.showMissingTokens = showMissingTokens
    // Use .all view mode if showing missing tokens, otherwise only source-accurate tokens
    super.init(viewMode: showMissingTokens ? .all : .sourceAccurate)
  }

  // MARK: - SyntaxRewriter Overrides

  // swiftlint:disable:next cyclomatic_complexity function_body_length
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
    let syntaxNodeType = node.syntaxNodeType

    // Clean up class name by removing "Syntax" suffix for readability
    let className: String
    if "\(syntaxNodeType)".hasSuffix(Self.syntax) {
      className = String("\(syntaxNodeType)".dropLast(6))
    } else {
      className = "\(syntaxNodeType)"
    }

    // Extract source location information
    let sourceRange = node.sourceRange(converter: locationConverter)
    let start = sourceRange.start
    let end = sourceRange.end

    // Classify the syntax node by its semantic role
    let syntaxType: SyntaxType
    switch node {
    case _ where node.is(DeclSyntax.self):
      syntaxType = .decl      // Declarations (struct, func, var, etc.)
    case _ where node.is(ExprSyntax.self):
      syntaxType = .expr      // Expressions (literals, function calls, etc.)
    case _ where node.is(PatternSyntax.self):
      syntaxType = .pattern   // Patterns (identifier patterns, tuple patterns, etc.)
    case _ where node.is(TypeSyntax.self):
      syntaxType = .type      // Type annotations and references
    default:
      syntaxType = .other     // Other syntax elements (punctuation, keywords, etc.)
    }

    // Create our simplified tree node representation
    let treeNode = TreeNode(
      id: index,
      text: className,
      range: SourceRange(
        startRow: start.line,
        startColumn: start.column,
        endRow: end.line,
        endColumn: end.column
      ),
      type: syntaxType
    )

    // Add to tree and prepare for next node
    tree.append(treeNode)
    index += 1

    // Extract structural information based on the node's layout
    let allChildren = node.children(viewMode: .all)

    switch node.syntaxNodeType.structure {
    case .layout(let keyPaths):
      // Handle nodes with fixed structure (most syntax nodes)
      if let syntaxNode = node.as(node.syntaxNodeType) {
        for keyPath in keyPaths {
          guard let name = childName(keyPath) else {
            continue
          }

          // Check if this property has an actual child node
          guard allChildren.contains(where: { child in child.keyPathInParent == keyPath }) else {
            // Property exists but has no value - mark as nil
            treeNode.structure.append(
              StructureProperty(
                name: name, value: StructureValue(text: Self.nilValue))
            )
            continue
          }

          // Extract the actual property value
          let keyPath = keyPath as AnyKeyPath
          switch syntaxNode[keyPath: keyPath] {
          case let value as TokenSyntax:
            // Handle token nodes (keywords, identifiers, operators, etc.)
            treeNode.structure.append(
              StructureProperty(
                name: name,
                value: StructureValue(
                  text: value.text,
                  kind: "\(value.tokenKind)"
                )
              )
            )
          case let value?:
            if let value = value as? any SyntaxProtocol {
              // Handle nested syntax nodes - store type reference
              let type = "\(value.syntaxNodeType)"
              treeNode.structure.append(
                StructureProperty(
                  name: name,
                  value: StructureValue(text: "\(type)"),
                  ref: "\(type)"
                )
              )
            } else {
              // Handle primitive values
              treeNode.structure.append(
                StructureProperty(name: name, value: StructureValue(text: "\(value)"))
              )
            }
          case .none:
            // Property exists but is nil
            treeNode.structure.append(StructureProperty(name: name))
          }
        }
      }
    case .collection(let syntax):
      // Handle collection nodes (lists, arrays, etc.)
      treeNode.type = .collection
      treeNode.structure.append(
        StructureProperty(
          name: Self.element,
          value: StructureValue(text: "\(syntax)")
        )
      )
      treeNode.structure.append(
        StructureProperty(
          name: Self.count,
          value: StructureValue(text: "\(node.children(viewMode: .all).count)")
        )
      )
    case .choices:
      // Handle choice nodes (union types) - no special processing needed
      break
    }

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
    // Store the actual token text content
    current.text = token.text

    // Create token metadata with kind information
    current.token = Token(
      kind: "\(token.tokenKind)", leadingTrivia: Self.emptyString,
      trailingTrivia: Self.emptyString)

    // Process leading trivia (whitespace, comments before the token)
    for piece in token.leadingTrivia {
      let trivia = processTriviaPiece(piece)
      current.token?.leadingTrivia += trivia
    }

    // Perform any additional token processing
    processToken(token)

    // Process trailing trivia (whitespace, comments after the token)
    for piece in token.trailingTrivia {
      let trivia = processTriviaPiece(piece)
      current.token?.trailingTrivia += trivia
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
    // Move back to parent node, or nil if we're at the root
    if let parent = current.parent {
      current = tree[parent]
    } else {
      current = nil
    }
  }
}
