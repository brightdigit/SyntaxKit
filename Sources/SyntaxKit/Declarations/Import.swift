//
//  Import.swift
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

/// A Swift `import` declaration.
public struct Import: CodeBlock {
  private let moduleName: String
  private var accessModifier: String?
  private var attributes: [AttributeInfo] = []

  /// Creates an `import` declaration.
  /// - Parameter moduleName: The name of the module to import.
  public init(_ moduleName: String) {
    self.moduleName = moduleName
  }

  /// Sets the access modifier for the import declaration.
  /// - Parameter access: The access modifier (e.g., "public", "private").
  /// - Returns: A copy of the import with the access modifier set.
  public func access(_ access: String) -> Self {
    var copy = self
    copy.accessModifier = access
    return copy
  }

  /// Adds an attribute to the import declaration.
  /// - Parameters:
  ///   - attribute: The attribute name (without the @ symbol).
  ///   - arguments: The arguments for the attribute, if any.
  /// - Returns: A copy of the import with the attribute added.
  public func attribute(_ attribute: String, arguments: [String] = []) -> Self {
    var copy = self
    copy.attributes.append(AttributeInfo(name: attribute, arguments: arguments))
    return copy
  }

  public var syntax: SyntaxProtocol {
    // Build access modifier
    var modifiers: DeclModifierListSyntax = []
    if let access = accessModifier {
      let keyword: Keyword
      switch access {
      case "public":
        keyword = .public
      case "private":
        keyword = .private
      case "internal":
        keyword = .internal
      case "fileprivate":
        keyword = .fileprivate
      default:
        keyword = .public  // fallback
      }
      modifiers = DeclModifierListSyntax([
        DeclModifierSyntax(name: .keyword(keyword, trailingTrivia: .space))
      ])
    }

    // Build import path
    let importPath = ImportPathComponentListSyntax([
      ImportPathComponentSyntax(name: .identifier(moduleName))
    ])

    return ImportDeclSyntax(
      attributes: buildAttributeList(from: attributes),
      modifiers: modifiers,
      importKeyword: .keyword(.import, trailingTrivia: .space),
      importKindSpecifier: nil,
      path: importPath
    )
  }

  private func buildAttributeList(from attributes: [AttributeInfo]) -> AttributeListSyntax {
    if attributes.isEmpty {
      return AttributeListSyntax([])
    }
    let attributeElements = attributes.map { attributeInfo in
      let arguments = attributeInfo.arguments

      var leftParen: TokenSyntax?
      var rightParen: TokenSyntax?
      var argumentsSyntax: AttributeSyntax.Arguments?

      if !arguments.isEmpty {
        leftParen = .leftParenToken()
        rightParen = .rightParenToken()

        let argumentList = arguments.map { argument in
          DeclReferenceExprSyntax(baseName: .identifier(argument))
        }

        argumentsSyntax = .argumentList(
          LabeledExprListSyntax(
            argumentList.enumerated().map { index, expr in
              var element = LabeledExprSyntax(expression: ExprSyntax(expr))
              if index < argumentList.count - 1 {
                element = element.with(\.trailingComma, .commaToken(trailingTrivia: .space))
              }
              return element
            }
          )
        )
      }

      return AttributeListSyntax.Element(
        AttributeSyntax(
          atSign: .atSignToken(),
          attributeName: IdentifierTypeSyntax(name: .identifier(attributeInfo.name)),
          leftParen: leftParen,
          arguments: argumentsSyntax,
          rightParen: rightParen
        )
      )
    }
    return AttributeListSyntax(attributeElements)
  }
}
