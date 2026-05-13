//
//  NormalizeOptions.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

/// Options for string normalization
public struct NormalizeOptions: OptionSet, Sendable {
  /// Preserve newlines between sibling elements (useful for SwiftUI)
  public static let preserveSiblingNewlines = NormalizeOptions(rawValue: 1 << 0)

  /// Preserve newlines after braces
  public static let preserveBraceNewlines = NormalizeOptions(rawValue: 1 << 1)

  /// Preserve indentation structure
  public static let preserveIndentation = NormalizeOptions(rawValue: 1 << 2)

  /// Default options for general code comparison
  public static let `default`: NormalizeOptions = []

  /// Options for SwiftUI code that needs to preserve some formatting
  public static let swiftUI: NormalizeOptions = [.preserveSiblingNewlines, .preserveBraceNewlines]

  /// Options for structural comparison (ignores all formatting)
  public static let structural: NormalizeOptions = []

  /// The raw value backing this option set.
  public let rawValue: Int

  /// Creates a new instance.
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
}
