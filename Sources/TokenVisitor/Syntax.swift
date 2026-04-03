//
//  Syntax.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

import SwiftSyntax

/// Extension on Syntax to provide convenient access to syntax type classification.
extension Syntax {
  /// Returns the semantic classification of this syntax node.
  ///
  /// If the node's type conforms to `SyntaxClassifiable`, returns its static
  /// `syntaxType`. Otherwise, returns `.other`.
  internal var syntaxType: SyntaxType {
    if let classifiable = self.syntaxNodeType as? any SyntaxClassifiable.Type {
      return classifiable.syntaxType
    }
    return .other
  }

  /// Cleans up SwiftSyntax type names by removing the "Syntax" suffix.
  ///
  /// SwiftSyntax type names typically end with "Syntax" (e.g., "VariableDeclSyntax").
  /// This method removes that suffix to create more readable names for output
  /// (e.g., "VariableDecl"), making the tree structure more human-friendly.
  ///
  /// - Returns: Cleaned class name without "Syntax" suffix
  internal var cleanClassName: String {
    let fullName = "\(syntaxNodeType)"
    let syntaxSuffix = "Syntax"
    if fullName.hasSuffix(syntaxSuffix) {
      return String(fullName.dropLast(syntaxSuffix.count))
    } else {
      return fullName
    }
  }
}
