//
//  SourceRange.swift
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

/// Represents the source location range of a syntax element in the original Swift code.
///
/// SourceRange provides line and column coordinates for both the start and end
/// positions of a syntax element. This information is crucial for tools that need
/// to map parsed elements back to their original source locations, such as:
/// - IDEs showing syntax highlighting and error locations
/// - Code analysis tools reporting issues
/// - Refactoring tools modifying specific code regions
///
/// Coordinates use 1-based indexing to match common editor conventions.
internal struct SourceRange: Codable, Equatable {
  /// The line number where this syntax element begins (1-based).
  internal let startRow: Int

  /// The column number where this syntax element begins (1-based).
  internal let startColumn: Int

  /// The line number where this syntax element ends (1-based).
  internal let endRow: Int

  /// The column number where this syntax element ends (1-based).
  internal let endColumn: Int

  /// Creates a new SourceRange with the specified coordinates.
  ///
  /// - Parameters:
  ///   - startRow: Starting line number (1-based)
  ///   - startColumn: Starting column number (1-based)
  ///   - endRow: Ending line number (1-based)
  ///   - endColumn: Ending column number (1-based)
  internal init(startRow: Int, startColumn: Int, endRow: Int, endColumn: Int) {
    self.startRow = startRow
    self.startColumn = startColumn
    self.endRow = endRow
    self.endColumn = endColumn
  }
}
