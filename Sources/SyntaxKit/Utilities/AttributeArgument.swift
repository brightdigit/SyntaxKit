//
//  AttributeArgument.swift
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

/// Builds an expression syntax node from an attribute argument string.
/// - Parameter argument: If surrounded by double-quotes, produces a string literal expression;
///   otherwise produces an identifier reference expression.
/// - Returns: An `ExprSyntax` representing the argument.
internal func buildAttributeArgumentExpr(from argument: String) -> ExprSyntax {
  if argument.hasPrefix("\"") && argument.hasSuffix("\"") && argument.count >= 2 {
    let content = String(argument.dropFirst().dropLast())
    return ExprSyntax(
      StringLiteralExprSyntax(
        openingQuote: .stringQuoteToken(),
        segments: StringLiteralSegmentListSyntax([
          .stringSegment(StringSegmentSyntax(content: .stringSegment(content)))
        ]),
        closingQuote: .stringQuoteToken()
      )
    )
  } else {
    return ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(argument)))
  }
}
