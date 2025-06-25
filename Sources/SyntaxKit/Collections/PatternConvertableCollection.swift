//
//  PatternConvertableCollection.swift
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

import SwiftSyntax

/// A tuple pattern that can be used as a CodeBlock for for-in loops.
internal struct PatternConvertableCollection: PatternCodeBlock {
  private let elements: [PatternConvertible?]

  internal init(elements: [PatternConvertible?]) {
    self.elements = elements
  }

  internal var patternSyntax: PatternSyntax {
    let patternElements = TuplePatternElementListSyntax(
      elements.enumerated().map { index, element in
        let patternElement: TuplePatternElementSyntax
        if let element = element {
          patternElement = TuplePatternElementSyntax(
            label: nil,
            colon: nil,
            pattern: element.patternSyntax,
            trailingComma: index < elements.count - 1 ? .commaToken(trailingTrivia: .space) : nil
          )
        } else {
          // Wildcard pattern
          patternElement = TuplePatternElementSyntax(
            label: nil,
            colon: nil,
            pattern: PatternSyntax(WildcardPatternSyntax(wildcard: .wildcardToken())),
            trailingComma: index < elements.count - 1 ? .commaToken(trailingTrivia: .space) : nil
          )
        }
        return patternElement
      }
    )

    return PatternSyntax(
      TuplePatternSyntax(
        leftParen: .leftParenToken(),
        elements: patternElements,
        rightParen: .rightParenToken()
      )
    )
  }

  internal var syntax: SyntaxProtocol {
    // For CodeBlock conformance, we return the pattern syntax as an expression
    // This is a bit of a hack, but it allows us to use TuplePatternCodeBlock in For loops
    patternSyntax
  }
}
