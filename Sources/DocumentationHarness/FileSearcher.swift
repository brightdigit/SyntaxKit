//
//  FileSearcher.swift
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

package import Foundation

/// Protocol for searching files in directories
package protocol FileSearcher {
  /// Searches a directory for files with specific extensions
  /// - Parameters:
  ///   - path: The directory URL to search
  ///   - pathExtensions: Array of file extensions to search for (without dots)
  /// - Returns: Array of URLs for matching files
  /// - Throws: FileSearchError if search fails
  func searchDirectory(at path: URL, forExtensions pathExtensions: [String]) throws(FileSearchError)
    -> [URL]
}

extension FileSearcher {
  internal func findDocumentationFiles(in path: URL, pathExtensions: [String])
    throws(FileSearchError)
    -> [URL]
  {
    let resourceValues: URLResourceValues
    do {
      resourceValues = try path.resourceValues(forKeys: [.isDirectoryKey])
    } catch {
      throw FileSearchError.cannotAccessPath(path.path, underlying: error)
    }

    if resourceValues.isDirectory == true {
      return try searchDirectory(at: path, forExtensions: pathExtensions)
    } else {
      // Single file - check if it has a matching extension
      if pathExtensions.contains(where: { path.path.hasSuffix("." + $0) }) {
        return [path]
      } else {
        return []
      }
    }
  }
}
