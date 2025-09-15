//
//  SyntaxResponse.swift
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

/// Container for the final JSON representation of parsed Swift syntax.
///
/// SyntaxResponse is the top-level result type returned by the SyntaxParser.
/// It wraps the JSON string representation of the parsed syntax tree,
/// providing a simple interface for the `skit` command-line tool and
/// other consumers to access the structured syntax data.
///
/// The JSON contains a flat array of TreeNode objects representing the
/// complete Swift syntax tree in a format suitable for external analysis
/// tools, IDEs, and other applications that need to understand Swift code structure.
package struct SyntaxResponse: Codable {
  /// JSON string representation of the parsed syntax tree.
  /// Contains a serialized array of TreeNode objects with their relationships,
  /// source locations, and structural information.
  package let syntaxJSON: String

  /// Creates a new SyntaxResponse with the provided JSON data.
  ///
  /// - Parameter syntaxJSON: The JSON string representation of the syntax tree
  package init(syntaxJSON: String) {
    self.syntaxJSON = syntaxJSON
  }
}
