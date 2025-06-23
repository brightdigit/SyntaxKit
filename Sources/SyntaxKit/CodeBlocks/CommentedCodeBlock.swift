//
//  CommentedCodeBlock.swift
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
import SwiftSyntax

// MARK: - Wrapper `CodeBlock` that injects leading trivia

internal struct CommentedCodeBlock: CodeBlock {
  internal let base: CodeBlock
  internal let lines: [Line]

  internal var syntax: SyntaxProtocol {
    // Shortcut if there are no comment lines
    guard !lines.isEmpty else {
      return base.syntax
    }

    let commentTrivia = Trivia(pieces: lines.flatMap { [$0.triviaPiece, TriviaPiece.newlines(1)] })

    // Re-write the first token of the underlying syntax node to prepend the trivia.
    final class FirstTokenRewriter: SyntaxRewriter {
      let newToken: TokenSyntax
      private var replaced = false
      init(newToken: TokenSyntax) { self.newToken = newToken }
      override func visit(_ token: TokenSyntax) -> TokenSyntax {
        if !replaced {
          replaced = true
          return newToken
        }
        return token
      }
    }

    guard let firstToken = base.syntax.firstToken(viewMode: .sourceAccurate) else {
      // Fallback – no tokens? return original syntax
      return base.syntax
    }

    let newFirstToken = firstToken.with(\.leadingTrivia, commentTrivia + firstToken.leadingTrivia)

    let rewriter = FirstTokenRewriter(newToken: newFirstToken)
    let rewritten = rewriter.rewrite(Syntax(base.syntax))
    return rewritten
  }
}
