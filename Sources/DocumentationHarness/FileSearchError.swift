//
//  FileSearchError.swift
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

/// Errors that can occur during file searching operations
package enum FileSearchError: Error, LocalizedError {
  /// Cannot access the specified path
  case cannotAccessPath(String, underlying: any Error)
  /// Cannot read the contents of a directory
  case cannotReadDirectory(String, underlying: any Error)
  /// An unknown error occurred
  case unknownError(any Error)

  /// Human-readable description of the file search error
  package var errorDescription: String? {
    switch self {
    case .cannotAccessPath(let path, let underlying):
      return "Cannot access path '\(path)': \(underlying.localizedDescription)"
    case .cannotReadDirectory(let path, let underlying):
      return "Cannot read directory '\(path)': \(underlying.localizedDescription)"
    case .unknownError(let error):
      return "Unknown Error: \(error)"
    }
  }
}
