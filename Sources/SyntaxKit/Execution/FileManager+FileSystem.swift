//
//  FileManager+FileSystem.swift
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

extension FileManager {
  /// Classifies what exists at `path` in a single stat — `.missing`, `.file`,
  /// or `.directory`.
  internal func pathKind(atPath path: String) -> PathKind {
    var isDirectory: ObjCBool = false
    guard fileExists(atPath: path, isDirectory: &isDirectory) else {
      return .missing
    }
    return isDirectory.boolValue ? .directory : .file
  }

  /// Size + modification date of the file at `path`, or `nil` if its attributes
  /// can't be read. Absent individual attributes default to `0` / the Unix
  /// epoch so a readable item always yields a fingerprint.
  internal func fingerprint(atPath path: String) -> FileFingerprint? {
    guard let attributes = try? attributesOfItem(atPath: path) else {
      return nil
    }
    let size = (attributes[.size] as? NSNumber)?.intValue ?? 0
    let modificationDate =
      (attributes[.modificationDate] as? Date)
      ?? Date(timeIntervalSince1970: 0)
    return FileFingerprint(size: size, modificationDate: modificationDate)
  }

  /// Every regular (non-directory) file under `directory`, recursively, with
  /// hidden files skipped and the result sorted by path. Sorted because callers
  /// generally want deterministic ordering, and doing it here keeps that
  /// guarantee in one place. Unfiltered by extension — the caller decides what
  /// counts as relevant.
  internal func regularFiles(under directory: URL) throws(FileEnumerationError) -> [URL] {
    guard
      let enumerator = enumerator(
        at: directory,
        includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
        options: [.skipsHiddenFiles]
      )
    else {
      throw .notEnumerable(directory)
    }

    var result: [URL] = []
    for case let url as URL in enumerator {
      // `.skipsHiddenFiles` keys off the dot-prefix convention on Unix but the
      // `FILE_ATTRIBUTE_HIDDEN` attribute on Windows, so a dot-prefixed entry
      // slips through there. Filter dot-prefixed components explicitly to keep
      // the same hidden-file semantics on every platform.
      if hasHiddenComponent(url, under: directory) { continue }
      let values: URLResourceValues
      do {
        values = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
      } catch {
        throw .resourceValuesUnavailable(url, error)
      }
      if values.isDirectory == true { continue }
      guard values.isRegularFile == true else { continue }
      result.append(url)
    }
    return result.sorted { $0.path < $1.path }
  }

  /// True when `url` lies under a dot-prefixed path component relative to
  /// `directory`. Mirrors `.skipsHiddenFiles` on platforms (Windows) where that
  /// option keys off the hidden *attribute* rather than the dot-prefix
  /// convention — and matches Unix's behavior of not descending into hidden
  /// directories by also excluding files nested under them.
  private func hasHiddenComponent(_ url: URL, under directory: URL) -> Bool {
    let base = directory.standardizedFileURL.pathComponents
    let full = url.standardizedFileURL.pathComponents
    guard full.count > base.count else {
      return false
    }
    return full[base.count...].contains { $0.hasPrefix(".") }
  }

  /// Writes `data` to `destination`, first creating any missing intermediate
  /// directories.
  internal func writeData(_ data: Data, to destination: URL) throws {
    try createDirectory(
      at: destination.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try data.write(to: destination)
  }
}
