//
//  SyntaxParser.swift
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
import SwiftOperators
import SwiftParser
import SwiftSyntax

// MARK: - Module Overview

/*
 # SyntaxParser Module Architecture

 The SyntaxParser module provides a bridge between Apple's SwiftSyntax framework and
 JSON-based tools that need to analyze Swift source code. It transforms the complex
 SwiftSyntax AST into a simplified, flat structure suitable for serialization and
 external consumption.

 ## Key Components

 ### Core Parser (`SyntaxParser`)
 - Main entry point for parsing Swift code
 - Handles operator precedence folding options
 - Orchestrates the parsing pipeline
 - Returns JSON-serialized results

 ### AST Visitor (`TokenVisitor`)
 - Implements SwiftSyntax's SyntaxRewriter protocol
 - Performs depth-first traversal of the syntax tree
 - Extracts essential information from each node
 - Builds flattened tree structure with ID-based relationships
 - Processes tokens and trivia (whitespace, comments)

 ### Data Structures
 - `TreeNode`: Core representation of syntax elements with metadata
 - `StructureProperty`: Named properties within syntax nodes
 - `StructureValue`: Terminal values and type references
 - `Token`: Token-specific metadata (kind, trivia)
 - `SourceRange`: Line/column location coordinates
 - `SyntaxType`: Semantic classification of syntax elements
 - `SyntaxResponse`: Container for final JSON output (deprecated)

 ## Processing Pipeline

 1. **Parse**: SwiftSyntax parses Swift source code into AST
 2. **Transform**: Optional operator precedence folding
 3. **Visit**: TokenVisitor traverses AST and extracts data
 4. **Classify**: Nodes are semantically classified (decl/expr/pattern/type/other)
 5. **Flatten**: Tree structure is flattened using ID references
 6. **Serialize**: Result is encoded to JSON format

 ## Output Format

 The JSON output contains a flat array of TreeNode objects, each with:
 - Unique ID and parent reference (creates tree structure)
 - Semantic type classification for easy filtering
 - Source location for mapping back to original code
 - Structural properties describing internal organization
 - Token metadata for leaf nodes (kind, trivia)

 ## Design Principles

 ### Console-First
 - Optimized for command-line tools and external analysis
 - Plain text output without HTML escaping (as of recent refactor)
 - Clean JSON suitable for piping between tools

 ### Flattened Structure
 - Uses ID-based references instead of object nesting
 - Avoids circular references in JSON serialization
 - Enables efficient access patterns for external tools

 ### Semantic Classification
 - Groups syntax elements by role (declarations, expressions, etc.)
 - Simplifies filtering and analysis for consumers
 - Abstracts away SwiftSyntax implementation details

 ### Preservation of Details
 - Maintains source location information
 - Preserves trivia (whitespace, comments) exactly
 - Includes both present and missing tokens for completeness

 ## Usage Example

 ```swift
 let code = """
     struct User {
         let name: String
     }
     """

 let treeNodes = SyntaxParser.parse(code: code)
 // treeNodes contains the array of TreeNode objects directly
 ```

 This module is primarily consumed by the `skit` command-line tool for
 converting Swift source code to JSON for external analysis and tooling.
 */

/// Main entry point for parsing Swift source code into TreeNode representation.
///
/// SyntaxParser converts Swift source code into an array of TreeNode objects that represents
/// the Abstract Syntax Tree (AST). This provides direct access to the parsed syntax structure
/// for programmatic analysis and manipulation.
///
/// The parser leverages Apple's SwiftSyntax framework to perform the actual parsing,
/// then transforms the complex SwiftSyntax AST into a simplified, flat structure
/// suitable for direct consumption by Swift code.
package enum SyntaxParser {
  // MARK: - Configuration Constants

  /// Option key to enable operator precedence folding during parsing.
  /// When enabled, expressions are reorganized according to Swift's operator precedence rules.
  @available(*, deprecated, message: "Operator precedence folding is not supported in the new parse(code:) method")
  private static let fold = "fold"

  /// Option key to include missing/implicit tokens in the output.
  /// Useful for debugging or when you need to see all syntax elements including placeholders.
  @available(*, deprecated, message: "Missing token display is not supported in the new parse(code:) method")
  private static let showMissing = "showmissing"

  /// Default filename used for source location tracking when no specific file is provided.
  private static let defaultFileName = ""

  // MARK: - Public Interface

  /// Parses Swift source code and returns an array of TreeNode objects.
  ///
  /// This method performs the complete parsing pipeline:
  /// 1. Parses Swift source code using SwiftSyntax
  /// 2. Traverses the AST to extract structure and token information
  /// 3. Returns the tree nodes directly without JSON serialization
  ///
  /// - Parameter code: Swift source code to parse
  /// - Returns: Array of TreeNode objects representing the syntax tree
  package static func parse(code: String) -> [TreeNode] {
    // Parse the Swift source code into a SwiftSyntax AST
    let sourceFile = Parser.parse(source: code)

    // Use raw syntax tree without precedence folding for simplicity
    let syntax = Syntax(sourceFile)

    // Create visitor to traverse AST and extract structured information
    let visitor = TokenVisitor(
      locationConverter: SourceLocationConverter(
        fileName: defaultFileName, tree: sourceFile),
      showMissingTokens: false
    )

    // Traverse the syntax tree and build our simplified representation
    _ = visitor.rewrite(syntax)

    // Return the tree nodes directly
    return visitor.tree
  }

  /// Parses Swift source code and returns a JSON representation of its syntax tree.
  ///
  /// This method performs the complete parsing pipeline:
  /// 1. Parses Swift source code using SwiftSyntax
  /// 2. Optionally applies operator precedence folding
  /// 3. Traverses the AST to extract structure and token information
  /// 4. Converts the tree to JSON format suitable for external consumption
  ///
  /// - Parameters:
  ///   - code: Swift source code to parse
  ///   - options: Optional parsing configuration. Supported options:
  ///     - "fold": Apply operator precedence folding
  ///     - "showmissing": Include missing/implicit tokens in output
  /// - Returns: SyntaxResponse containing the JSON representation
  /// - Throws: JSONEncoder errors if serialization fails
  @available(*, deprecated, message: "Use parse(code:) instead for direct TreeNode access")
  package static func parse(code: String, options: [String] = []) throws -> SyntaxResponse {
    // Parse the Swift source code into a SwiftSyntax AST
    let sourceFile = Parser.parse(source: code)

    // Optionally apply operator precedence folding for proper expression structure
    let syntax: Syntax
    if options.contains(fold) {
      // Use standard Swift operator table to reorganize expressions by precedence
      syntax = OperatorTable.standardOperators.foldAll(sourceFile, errorHandler: { _ in })
    } else {
      // Use raw syntax tree without precedence folding
      syntax = Syntax(sourceFile)
    }

    // Create visitor to traverse AST and extract structured information
    let visitor = TokenVisitor(
      locationConverter: SourceLocationConverter(
        fileName: defaultFileName, tree: sourceFile),
      showMissingTokens: options.contains(showMissing)
    )

    // Traverse the syntax tree and build our simplified representation
    _ = visitor.rewrite(syntax)

    // Convert the extracted tree structure to JSON
    let tree = visitor.tree
    let encoder = JSONEncoder()
    let data = try encoder.encode(tree)
    let json = String(decoding: data, as: UTF8.self)

    return SyntaxResponse(syntaxJSON: json)
  }
}
