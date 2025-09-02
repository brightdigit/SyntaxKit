//
//  PropertyRequirement.swift
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

/// A property requirement inside a protocol declaration.
public struct PropertyRequirement: CodeBlock {
  /// The accessor options for the property.
  public enum Access: Sendable {
    case get
    case getSet
  }

  private let name: String
  private let type: String
  private let access: Access

  /// Creates a property requirement.
  /// - Parameters:
  ///   - name: The property name.
  ///   - type: The property type.
  ///   - access: Whether the property is get-only or get/set.
  public init(_ name: String, type: String, access: Access = .get) {
    self.name = name
    self.type = type
    self.access = access
  }

  public var syntax: SyntaxProtocol {
    let varKeyword = TokenSyntax.keyword(.var, trailingTrivia: .space)
    let identifier = TokenSyntax.identifier(name, trailingTrivia: .space)

    let typeAnnotation = TypeAnnotationSyntax(
      colon: .colonToken(leadingTrivia: .space, trailingTrivia: .space),
      type: IdentifierTypeSyntax(name: .identifier(type))
    )

    // Build accessor list
    let accessorList: AccessorDeclListSyntax = {
      switch access {
      case .get:
        return AccessorDeclListSyntax([
          AccessorDeclSyntax(
            accessorSpecifier: .keyword(.get, trailingTrivia: .space)
          )
        ])
      case .getSet:
        return AccessorDeclListSyntax([
          AccessorDeclSyntax(
            accessorSpecifier: .keyword(.get, trailingTrivia: .space)
          ),
          AccessorDeclSyntax(
            accessorSpecifier: .keyword(.set, trailingTrivia: .space)
          ),
        ])
      }
    }()

    let accessorBlock = AccessorBlockSyntax(
      leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .space),
      accessors: .accessors(accessorList),
      rightBrace: .rightBraceToken(leadingTrivia: .space, trailingTrivia: .newline)
    )

    return VariableDeclSyntax(
      bindingSpecifier: varKeyword,
      bindings: PatternBindingListSyntax([
        PatternBindingSyntax(
          pattern: IdentifierPatternSyntax(identifier: identifier),
          typeAnnotation: typeAnnotation,
          accessorBlock: accessorBlock
        )
      ])
    )
  }
}
