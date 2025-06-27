//  AssociatedType.swift
//  SyntaxKit
//
//  Created by Leo Dion.
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

/// Represents an associatedtype requirement in a protocol.
public struct AssociatedType: CodeBlock, Sendable {
    private let name: String
    private var inherited: [String] = []

    public init(_ name: String) {
        self.name = name
    }

    /// Adds inherited protocols/constraints to the associatedtype.
    public func inherits(_ protocols: String...) -> Self {
        var copy = self
        copy.inherited.append(contentsOf: protocols)
        return copy
    }

    public var syntax: SyntaxProtocol {
        let associatedTypeKeyword = TokenSyntax.keyword(.associatedtype, trailingTrivia: .space)
        let identifier = TokenSyntax.identifier(name)
        var inheritanceClause: TypeInheritanceClauseSyntax? = nil
        if !inherited.isEmpty {
            let joined = inherited.joined(separator: " & ")
            let inheritedTypes = InheritedTypeListSyntax([
                InheritedTypeSyntax(type: TypeSyntax(IdentifierTypeSyntax(name: .identifier(joined))))
            ])
            inheritanceClause = TypeInheritanceClauseSyntax(
                colon: .colonToken(leadingTrivia: .space, trailingTrivia: .space),
                inheritedTypes: inheritedTypes
            )
        }
        return AssociatedTypeDeclSyntax(
            attributes: AttributeListSyntax([]),
            modifiers: DeclModifierListSyntax([]),
            associatedtypeKeyword: associatedTypeKeyword,
            name: identifier,
            inheritanceClause: inheritanceClause,
            initializer: nil,
            genericWhereClause: nil
        )
    }
} 