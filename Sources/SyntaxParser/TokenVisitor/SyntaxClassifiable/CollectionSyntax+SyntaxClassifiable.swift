//
//  CollectionSyntax+SyntaxClassifiable.swift
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
@_spi(RawSyntax) import SwiftSyntax

// MARK: - Collection Syntax Extensions

/// Extension for CodeBlockItemListSyntax to conform to SyntaxClassifiable.
extension CodeBlockItemListSyntax: SyntaxClassifiable {
  /// Code block item lists are classified as `.collection` type.
  internal static var syntaxType: SyntaxType {
    .collection
  }
}

/// Extension for AttributeListSyntax to conform to SyntaxClassifiable.
extension AttributeListSyntax: SyntaxClassifiable {
  /// Attribute lists are classified as `.collection` type.
  internal static var syntaxType: SyntaxType {
    .collection
  }
}

/// Extension for DeclModifierListSyntax to conform to SyntaxClassifiable.
extension DeclModifierListSyntax: SyntaxClassifiable {
  /// Declaration modifier lists are classified as `.collection` type.
  internal static var syntaxType: SyntaxType {
    .collection
  }
}

/// Extension for FunctionParameterListSyntax to conform to SyntaxClassifiable.
extension FunctionParameterListSyntax: SyntaxClassifiable {
  /// Function parameter lists are classified as `.collection` type.
  internal static var syntaxType: SyntaxType {
    .collection
  }
}

/// Extension for LabeledExprListSyntax to conform to SyntaxClassifiable.
extension LabeledExprListSyntax: SyntaxClassifiable {
  /// Labeled expression lists are classified as `.collection` type.
  internal static var syntaxType: SyntaxType {
    .collection
  }
}

/// Extension for PatternBindingListSyntax to conform to SyntaxClassifiable.
extension PatternBindingListSyntax: SyntaxClassifiable {
  /// Pattern binding lists are classified as `.collection` type.
  internal static var syntaxType: SyntaxType {
    .collection
  }
}

/// Extension for SwitchCaseListSyntax to conform to SyntaxClassifiable.
extension SwitchCaseListSyntax: SyntaxClassifiable {
  /// Switch case lists are classified as `.collection` type.
  internal static var syntaxType: SyntaxType {
    .collection
  }
}

/// Extension for SwitchCaseItemListSyntax to conform to SyntaxClassifiable.
extension SwitchCaseItemListSyntax: SyntaxClassifiable {
  /// Switch case item lists are classified as `.collection` type.
  internal static var syntaxType: SyntaxType {
    .collection
  }
}

/// Extension for ConditionElementListSyntax to conform to SyntaxClassifiable.
extension ConditionElementListSyntax: SyntaxClassifiable {
  /// Condition element lists are classified as `.collection` type.
  internal static var syntaxType: SyntaxType {
    .collection
  }
}

/// Extension for CatchClauseListSyntax to conform to SyntaxClassifiable.
extension CatchClauseListSyntax: SyntaxClassifiable {
  /// Catch clause lists are classified as `.collection` type.
  internal static var syntaxType: SyntaxType {
    .collection
  }
}

// Note: Additional collection syntax types can be added here as needed.
// Only the most commonly used types are included to avoid compilation errors
// with types that may not exist in all SwiftSyntax versions.
