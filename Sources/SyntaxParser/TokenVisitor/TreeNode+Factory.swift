//
//  TreeNode+Factory.swift
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

extension TreeNode {
  /// Creates a TreeNode from a SwiftSyntax node with proper initialization.
  ///
  /// This initializer extracts essential information from the SwiftSyntax node and
  /// creates a corresponding TreeNode with cleaned class name, semantic type
  /// classification, and source location information.
  ///
  /// - Parameters:
  ///   - id: Unique identifier for the new node
  ///   - node: The SwiftSyntax node to convert
  ///   - locationConverter: Converter for source positions to line/column coordinates
  ///   - syntaxType: The semantic classification of the node
  ///   - className: The cleaned class name (without "Syntax" suffix)
  internal convenience init(
    id: Int,
    from node: Syntax,
    locationConverter: SourceLocationConverter,
    syntaxType: SyntaxType,
    className: String
  ) {
    // Extract source location information
    let sourceRange = node.sourceRange(converter: locationConverter)
    let start = sourceRange.start
    let end = sourceRange.end

    // Initialize with extracted information
    self.init(
      id: id,
      text: className,
      range: SourceRange(
        startRow: start.line,
        startColumn: start.column,
        endRow: end.line,
        endColumn: end.column
      ),
      type: syntaxType
    )
  }
}
