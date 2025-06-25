//
//  CaptureReferenceType.swift
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

/// Represents the type of reference capture in closures.
public enum CaptureReferenceType: CaseIterable, Sendable, Equatable {
  case weak
  case unowned

  /// Returns the corresponding SwiftSyntax Keyword for this capture reference type.
  public var keyword: Keyword {
    switch self {
    case .weak:
      return .weak
    case .unowned:
      return .unowned
    }
  }
}

extension Keyword {
  /// Creates a Keyword from a CaptureReferenceType.
  /// - Parameter captureReferenceType: The capture reference type to convert.
  public init(_ captureReferenceType: CaptureReferenceType) {
    self = captureReferenceType.keyword
  }
}
