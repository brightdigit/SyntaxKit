//
//  OutputCache.swift
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

#if canImport(Subprocess)

  import Foundation

  /// Bumped when the output cache layout changes in a way that requires invalidation.
  private let outputCacheSchemaVersion = "v1"

  /// 64-bit content hash over (cache schema, input source bytes, helpers key,
  /// swift version, libSyntaxKit stamp, sorted SKIT_*/SYNTAXKIT_* env vars).
  /// Any change in these inputs produces a fresh key and forces a recompile.
  /// See `ContentHasher` for the choice of FNV-1a over a cryptographic hash.
  internal func outputCacheKey(
    inputSource: String,
    helpers: CompiledHelpers?,
    libPath: String
  ) async -> String {
    var hasher = ContentHasher()
    hasher.update(data: Data(outputCacheSchemaVersion.utf8))
    hasher.update(data: Data(inputSource.utf8))

    if let helpers {
      // Helpers cache dir name *is* the helpers cache key (per Helpers.swift).
      hasher.update(data: Data(helpers.outputDir.lastPathComponent.utf8))
    } else {
      hasher.update(data: Data("no-helpers".utf8))
    }

    if let version = await captureSwiftVersion() {
      hasher.update(data: Data(version.utf8))
    }
    if let stamp = libStamp(libPath: libPath) {
      hasher.update(data: Data(stamp.utf8))
    }

    let env = ProcessInfo.processInfo.environment
      .filter { $0.key.hasPrefix("SKIT_") || $0.key.hasPrefix("SYNTAXKIT_") }
      .sorted { $0.key < $1.key }
    for (key, value) in env {
      hasher.update(data: Data("\(key)=\(value)\0".utf8))
    }

    return hasher.finalize()
  }

  /// Returns the cached rendered output for `key`, or nil on miss.
  internal func lookupCachedOutput(key: String) -> Data? {
    guard let dir = try? outputCacheDir(for: key) else { return nil }
    return try? Data(contentsOf: dir.appendingPathComponent("output.swift"))
  }

  /// Atomically stores `data` under `key`. Concurrent writers race via a
  /// `tmp.<pid>.<uuid>/` staging dir + rename; the loser drops their copy.
  internal func storeCachedOutput(key: String, data: Data) throws {
    let cacheRoot = try outputCacheDir(for: key)
    let final = cacheRoot.appendingPathComponent("output.swift")
    let fm = FileManager.default

    try fm.createDirectory(
      at: cacheRoot.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )

    let staging = cacheRoot.deletingLastPathComponent()
      .appendingPathComponent(
        "tmp.\(ProcessInfo.processInfo.processIdentifier).\(UUID().uuidString)"
      )
    try fm.createDirectory(at: staging, withIntermediateDirectories: true)
    try data.write(to: staging.appendingPathComponent("output.swift"))

    do {
      try fm.moveItem(at: staging, to: cacheRoot)
    } catch {
      try? fm.removeItem(at: staging)
      if !fm.fileExists(atPath: final.path) {
        throw error
      }
    }
  }

  private func outputCacheDir(for key: String) throws -> URL {
    try syntaxKitCacheRoot()
      .appendingPathComponent("outputs")
      .appendingPathComponent(key)
  }

#endif
