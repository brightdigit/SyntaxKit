//
//  Closure+Signature.swift
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

extension Closure {
  /// Builds the signature for the closure.
  internal func buildSignature(captureClause: ClosureCaptureClauseSyntax?)
    -> ClosureSignatureSyntax?
  {
    guard needsSignature else {
      return nil
    }

    return ClosureSignatureSyntax(
      attributes: buildAttributeList(),
      capture: captureClause,
      parameterClause: buildParameterClause().map { .parameterClause($0) },
      effectSpecifiers: nil,
      returnClause: buildReturnClause(),
      inKeyword: .keyword(.in, leadingTrivia: .space, trailingTrivia: .space)
    )
  }

  /// Builds the attribute list for the closure signature.
  private func buildAttributeList() -> AttributeListSyntax {
    guard !attributes.isEmpty else {
      return AttributeListSyntax([])
    }

    return AttributeListSyntax(
      attributes.enumerated().map { idx, attr in
        AttributeListSyntax.Element(
          AttributeSyntax(
            atSign: .atSignToken(),
            attributeName: IdentifierTypeSyntax(
              name: .identifier(attr.name),
              trailingTrivia: (capture.isEmpty || idx != attributes.count - 1)
                ? Trivia() : .space
            ),
            leftParen: nil,
            arguments: nil,
            rightParen: nil
          )
        )
      }
    )
  }

  /// Builds the parameter clause for the closure signature.
  private func buildParameterClause() -> ClosureParameterClauseSyntax? {
    guard !parameters.isEmpty else {
      return nil
    }

    return ClosureParameterClauseSyntax(
      leftParen: .leftParenToken(),
      parameters: ClosureParameterListSyntax(
        parameters.map(buildParameterSyntax)
      ),
      rightParen: .rightParenToken()
    )
  }

  /// Builds parameter syntax from a closure parameter.
  private func buildParameterSyntax(from param: ClosureParameter) -> ClosureParameterSyntax {
    ClosureParameterSyntax(
      attributes: AttributeListSyntax([]),
      firstName: .identifier(param.name),
      secondName: nil,
      colon: param.name.isEmpty ? nil : .colonToken(trailingTrivia: .space),
      type: param.type?.typeSyntax as? TypeSyntax,
      ellipsis: nil,
      trailingComma: nil
    )
  }

  /// Builds the return clause for the closure signature.
  private func buildReturnClause() -> ReturnClauseSyntax? {
    returnType.map {
      ReturnClauseSyntax(
        arrow: .arrowToken(trailingTrivia: .space),
        type: $0.typeSyntax
      )
    }
  }
}
