//
//  Variable+Modifiers.swift
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

extension Variable {
  /// Builds the modifiers for the variable declaration.
  internal func buildModifiers() -> DeclModifierListSyntax {
    var modifiers: [DeclModifierSyntax] = []

    if isStatic {
      modifiers.append(buildStaticModifier())
    }

    if isAsync {
      modifiers.append(buildAsyncModifier())
    }

    if let access = accessModifier {
      modifiers.append(buildAccessModifier(access))
    }

    return DeclModifierListSyntax(modifiers)
  }

  /// Builds a static modifier.
  private func buildStaticModifier() -> DeclModifierSyntax {
    DeclModifierSyntax(name: .keyword(.static, trailingTrivia: .space))
  }

  /// Builds an async modifier.
  private func buildAsyncModifier() -> DeclModifierSyntax {
    DeclModifierSyntax(name: .keyword(.async, trailingTrivia: .space))
  }

  /// Builds an access modifier.
  private func buildAccessModifier(_ access: AccessModifier) -> DeclModifierSyntax {
    DeclModifierSyntax(name: .keyword(access.keyword, trailingTrivia: .space))
  }
}
