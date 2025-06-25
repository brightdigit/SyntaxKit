//
//  Closure+Capture.swift
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

/// Represents capture specifier and name information for closure captures.
private struct CaptureInfo {
  let specifier: ClosureCaptureSpecifierSyntax?
  let name: TokenSyntax

  init(from param: ParameterExp) {
    if let refExp = param.value as? ReferenceExp {
      self.init(fromReference: refExp)
    } else {
      self.init(fromParameter: param)
    }
  }

  private init(fromReference refExp: ReferenceExp) {
    let keyword = refExp.captureReferenceType.keyword

    self.specifier = ClosureCaptureSpecifierSyntax(
      specifier: .keyword(keyword, trailingTrivia: .space)
    )

    if let varExp = refExp.captureExpression as? VariableExp {
      self.name = .identifier(varExp.name)
    } else {
      self.name = .identifier("self")  // fallback
      #warning(
        "TODO: Review fallback for non-VariableExp capture expression"
      )
    }
  }

  private init(fromParameter param: ParameterExp) {
    self.specifier = nil

    if let varExp = param.value as? VariableExp {
      self.name = .identifier(varExp.name)
    } else {
      self.name = .identifier("self")  // fallback
      #warning(
        "TODO: Review fallback for non-VariableExp parameter value"
      )
    }
  }
}

extension Closure {
  /// Builds the capture clause for the closure.
  internal func buildCaptureClause() -> ClosureCaptureClauseSyntax? {
    guard !capture.isEmpty else {
      return nil
    }

    return ClosureCaptureClauseSyntax(
      leftSquare: .leftSquareToken(),
      items: ClosureCaptureListSyntax(
        capture.map(buildCaptureItem)
      ),
      rightSquare: .rightSquareToken()
    )
  }

  /// Builds a capture item from a parameter expression.
  private func buildCaptureItem(from param: ParameterExp) -> ClosureCaptureSyntax {
    let captureInfo = CaptureInfo(from: param)

    return ClosureCaptureSyntax(
      specifier: captureInfo.specifier,
      name: captureInfo.name,
      initializer: nil,
      trailingComma: nil
    )
  }
}
