//
//  Closure.swift
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

// MARK: - ClosureParameter

public struct ClosureParameter {
  public var name: String
  public var type: String?
  internal var attributes: [AttributeInfo]

  public init(_ name: String, type: String? = nil) {
    self.name = name
    self.type = type
    self.attributes = []
  }

  internal init(_ name: String, type: String? = nil, attributes: [AttributeInfo]) {
    self.name = name
    self.type = type
    self.attributes = attributes
  }

  public func attribute(_ attribute: String, arguments: [String] = []) -> Self {
    var copy = self
    copy.attributes.append(AttributeInfo(name: attribute, arguments: arguments))
    return copy
  }
}

// MARK: - ClosureParameterBuilderResult

@resultBuilder
public enum ClosureParameterBuilderResult {
  public static func buildBlock(_ components: ClosureParameter...) -> [ClosureParameter] {
    components
  }
  public static func buildOptional(_ component: [ClosureParameter]?) -> [ClosureParameter] {
    component ?? []
  }
  public static func buildEither(first component: [ClosureParameter]) -> [ClosureParameter] {
    component
  }
  public static func buildEither(second component: [ClosureParameter]) -> [ClosureParameter] {
    component
  }
  public static func buildArray(_ components: [[ClosureParameter]]) -> [ClosureParameter] {
    components.flatMap { $0 }
  }
}

// MARK: - Closure

public struct Closure: CodeBlock {
  public let capture: [ParameterExp]
  public let parameters: [ClosureParameter]
  public let returnType: String?
  public let body: [CodeBlock]
  internal var attributes: [AttributeInfo] = []

  public init(
    @ParameterExpBuilderResult capture: () -> [ParameterExp] = { [] },
    @ClosureParameterBuilderResult parameters: () -> [ClosureParameter] = { [] },
    returns returnType: String? = nil,
    @CodeBlockBuilderResult body: () -> [CodeBlock]
  ) {
    self.capture = capture()
    self.parameters = parameters()
    self.returnType = returnType
    self.body = body()
  }

  public func attribute(_ attribute: String, arguments: [String] = []) -> Self {
    var copy = self
    copy.attributes.append(AttributeInfo(name: attribute, arguments: arguments))
    return copy
  }

  public var syntax: SyntaxProtocol {
    // Capture list
    let captureClause: ClosureCaptureClauseSyntax? =
      capture.isEmpty
      ? nil
      : ClosureCaptureClauseSyntax(
        leftSquare: .leftSquareToken(),
        items: ClosureCaptureListSyntax(
          capture.map { param in
            // Handle weak references properly
            let specifier: ClosureCaptureSpecifierSyntax?
            let name: TokenSyntax

            if let weakRef = param.value as? WeakReferenceExp {
              specifier = ClosureCaptureSpecifierSyntax(
                specifier: .keyword(.weak, trailingTrivia: .space)
              )
              // Extract the identifier from the weak reference base
              if let varExp = weakRef.captureExpression as? VariableExp {
                name = .identifier(varExp.name)
              } else {
                name = .identifier("self")  // fallback
              }
            } else {
              specifier = nil
              if let varExp = param.value as? VariableExp {
                name = .identifier(varExp.name)
              } else {
                name = .identifier("self")  // fallback
              }
            }

            return ClosureCaptureSyntax(
              specifier: specifier,
              name: name,
              initializer: nil,
              trailingComma: nil
            )
          }
        ),
        rightSquare: .rightSquareToken()
      )

    // Parameters
    let paramList: [ClosureParameterSyntax] = parameters.map { param in
      ClosureParameterSyntax(
        leadingTrivia: nil,
        attributes: AttributeListSyntax([]),
        modifiers: DeclModifierListSyntax([]),
        firstName: .identifier(param.name),
        secondName: nil,
        colon: param.type != nil ? .colonToken(trailingTrivia: .space) : nil,
        type: param.type.map { IdentifierTypeSyntax(name: .identifier($0)) },
        ellipsis: nil,
        trailingComma: nil,
        trailingTrivia: nil
      )
    }

    let signature: ClosureSignatureSyntax? =
      (parameters.isEmpty && returnType == nil && capture.isEmpty && attributes.isEmpty)
      ? nil
      : ClosureSignatureSyntax(
        attributes: attributes.isEmpty
          ? AttributeListSyntax([])
          : AttributeListSyntax(
            attributes.enumerated().map { idx, attr in
              AttributeListSyntax.Element(
                AttributeSyntax(
                  atSign: .atSignToken(),
                  attributeName: IdentifierTypeSyntax(
                    name: .identifier(attr.name),
                    trailingTrivia: (capture.isEmpty || idx != attributes.count - 1)
                      ? Trivia() : .space),
                  leftParen: nil,
                  arguments: nil,
                  rightParen: nil
                )
              )
            }
          ),
        capture: captureClause,
        parameterClause: parameters.isEmpty
          ? nil
          : .parameterClause(
            ClosureParameterClauseSyntax(
              leftParen: .leftParenToken(),
              parameters: ClosureParameterListSyntax(
                parameters.map { param in
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
              ),
              rightParen: .rightParenToken()
            )),
        effectSpecifiers: nil,
        returnClause: returnType == nil
          ? nil
          : ReturnClauseSyntax(
            arrow: .arrowToken(trailingTrivia: .space),
            type: returnType!.typeSyntax
          ),
        inKeyword: .keyword(.in, leadingTrivia: .space, trailingTrivia: .space)
      )

    // Body
    let bodyBlock = CodeBlockItemListSyntax(
      body.compactMap {
        if let decl = $0.syntax.as(DeclSyntax.self) {
          return CodeBlockItemSyntax(item: .decl(decl)).with(\.trailingTrivia, .newline)
        } else if let paramExp = $0 as? ParameterExp {
          // Handle ParameterExp by extracting its value
          if let exprBlock = paramExp.value as? ExprCodeBlock {
            return CodeBlockItemSyntax(item: .expr(exprBlock.exprSyntax)).with(
              \.trailingTrivia, .newline)
          } else if let expr = paramExp.value.syntax.as(ExprSyntax.self) {
            return CodeBlockItemSyntax(item: .expr(expr)).with(\.trailingTrivia, .newline)
          } else if let paramExpr = paramExp.syntax.as(ExprSyntax.self) {
            return CodeBlockItemSyntax(item: .expr(paramExpr)).with(\.trailingTrivia, .newline)
          }
          return nil
        } else if let exprBlock = $0 as? ExprCodeBlock {
          return CodeBlockItemSyntax(item: .expr(exprBlock.exprSyntax)).with(
            \.trailingTrivia, .newline)
        } else if let expr = $0.syntax.as(ExprSyntax.self) {
          return CodeBlockItemSyntax(item: .expr(expr)).with(\.trailingTrivia, .newline)
        } else if let stmt = $0.syntax.as(StmtSyntax.self) {
          return CodeBlockItemSyntax(item: .stmt(stmt)).with(\.trailingTrivia, .newline)
        }
        return nil
      }
    )

    return ExprSyntax(
      ClosureExprSyntax(
        leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
        signature: signature,
        statements: bodyBlock,
        rightBrace: .rightBraceToken(leadingTrivia: .newline)
      )
    )
  }
}
