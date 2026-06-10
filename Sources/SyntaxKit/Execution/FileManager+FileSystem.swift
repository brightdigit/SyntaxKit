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

/// What exists at a filesystem path — the result of a single existence check,
/// replacing the `fileExists(atPath:isDirectory:)` + `ObjCBool` idiom with a
/// value callers can `switch` over.
internal enum PathKind: Equatable {
  /// Nothing exists at the path.
  case missing
  /// A regular file (or any non-directory) exists at the path.
  case file
  /// A directory exists at the path.
  case directory
}

/// Size + modification date of a file: the change-detection inputs behind a
/// content fingerprint/stamp.
internal struct FileFingerprint: Equatable {
  /// File size in bytes (0 when the attribute is absent).
  internal let size: Int
  /// Last-modification date (Unix epoch when the attribute is absent).
  internal let modificationDate: Date
}

/// A recursive regular-file enumeration failure, decoupled from any domain so
/// the caller maps it onto its own error type.
internal enum FileEnumerationError: Error {
  /// The directory couldn't be enumerated at all.
  case notEnumerable(URL)
  /// A file's resource values couldn't be read mid-walk.
  case resourceValuesUnavailable(URL, any Error)
}

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
