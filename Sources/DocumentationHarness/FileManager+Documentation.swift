//
//  FileManager+Documentation.swift
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

// MARK: - Documentation Error Types

// MARK: - FileManager Extensions

extension FileManager: FileSearcher {
  /// Directories to skip during recursive search
  private static let skipDirectories = [
    ".build",
    "node_modules",
    ".git",
    ".svn",
    "DerivedData",
    "build",
    ".swiftpm",
  ]

  private func searchItem(_ itemURL: URL, _ pathExtensions: [String]) throws(FileSearchError)
    -> [URL]
  {
    var documentationFiles = [URL]()

    let itemResourceValues: URLResourceValues
    do {
      itemResourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey])
    } catch {
      throw FileSearchError.cannotAccessPath(itemURL.path, underlying: error)
    }

    if itemResourceValues.isDirectory == true {
      // Skip certain directories
      let directoryName = itemURL.lastPathComponent
      if Self.skipDirectories.contains(directoryName) {
        return documentationFiles
      }

      // Recursively call this method for subdirectories
      let subdirectoryFiles = try findDocumentationFiles(
        in: itemURL,
        pathExtensions: pathExtensions
      )
      documentationFiles.append(contentsOf: subdirectoryFiles)
    } else if pathExtensions.contains(where: { itemURL.path.hasSuffix("." + $0) }) {
      // Direct file with matching extension
      documentationFiles.append(itemURL)
    }
    return documentationFiles
  }

  internal func searchDirectory(at path: URL, forExtensions pathExtensions: [String])
    throws(FileSearchError) -> [URL]
  {
    let contents: [URL]
    do {
      contents = try contentsOfDirectory(at: path, includingPropertiesForKeys: [.isDirectoryKey])
    } catch {
      throw FileSearchError.cannotReadDirectory(path.path, underlying: error)
    }

    // Directory - recursively find files with specified extensions
    let documentationFiles: [URL]
    do {
      documentationFiles = try contents.flatMap({ itemURL in
        try searchItem(itemURL, pathExtensions)
      })
    } catch let fileSearchError as FileSearchError {
      throw fileSearchError
    } catch {
      assertionFailure("Should only be a FileSearchError: \(error.localizedDescription)")
      throw .unknownError(error)
    }

    return documentationFiles
  }
}
