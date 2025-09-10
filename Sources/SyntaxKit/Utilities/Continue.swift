//
//  Continue.swift
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

public import SwiftSyntax

/// A `continue` statement.
public struct Continue: CodeBlock {
  private let label: String?

  public var syntax: any SyntaxProtocol {
    let continueStmt = ContinueStmtSyntax(
      continueKeyword: .keyword(.continue, trailingTrivia: .newline)
    )

    if let label = label {
      return StmtSyntax(
        continueStmt.with(
          \.label,
          .identifier(label)
        )
      )
    } else {
      return StmtSyntax(continueStmt)
    }
  }

  /// Creates a `continue` statement.
  /// - Parameter label: An optional label to continue to a specific loop.
  public init(_ label: String? = nil) {
    self.label = label
  }
}
