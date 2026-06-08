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

  /// On-disk cache of rendered skit output, content-keyed so a re-run on
  /// unchanged input skips the `swift` spawn entirely.
  internal struct OutputCache {
    /// Bumped when the cache layout changes in a way that requires invalidation.
    private static let schemaVersion = "v1"

    /// `<syntaxKitCacheRoot>/outputs/`. Populated once at init; per-key
    /// directories are derived from it on demand.
    private let root: URL

    internal init() throws {
      self.root = try syntaxKitCacheRoot().appendingPathComponent("outputs")
    }

    /// 64-bit content hash over (schema version, input source bytes, swift
    /// version, libSyntaxKit stamp, sorted SKIT_*/SYNTAXKIT_* env vars). Any
    /// change in these inputs produces a fresh key and forces a recompile.
    /// See `ContentHasher` for the choice of FNV-1a over a cryptographic hash.
    internal func key(forInput source: String, libPath: String) async -> String {
      var hasher = ContentHasher()
      // Schema version: bump to invalidate every existing cache entry at once.
      hasher.update(data: Data(Self.schemaVersion.utf8))
      // Input source bytes: the primary driver of the key.
      hasher.update(data: Data(source.utf8))

      // Toolchain version. Different `swift` builds emit different bytes for
      // the same DSL input.
      if let version = await captureSwiftVersion() {
        hasher.update(data: Data(version.utf8))
      }
      // libSyntaxKit stamp. A rebuilt dylib can change the rendered output
      // even without a Swift-version bump.
      if let stamp = FileManager.default.libStamp(libPath: libPath) {
        hasher.update(data: Data(stamp.utf8))
      }

      // SKIT_*/SYNTAXKIT_* env vars. Sorted so the cache key is stable, and
      // NUL-terminated so `"AB=" + "C"` doesn't collide with `"A=" + "BC"`.
      let env = ProcessInfo.processInfo.environment
        .filter { $0.key.hasPrefix("SKIT_") || $0.key.hasPrefix("SYNTAXKIT_") }
        .sorted { $0.key < $1.key }
      for (key, value) in env {
        hasher.update(data: Data("\(key)=\(value)\0".utf8))
      }

      return hasher.finalize()
    }

    /// Returns the cached rendered output for `key`, or nil on miss.
    internal func lookup(key: String) -> Data? {
      try? Data(contentsOf: directory(for: key).appendingPathComponent("output.swift"))
    }

    /// Atomically stores `data` under `key`. Concurrent writers race via a
    /// `tmp.<pid>.<uuid>/` staging dir + rename; the loser drops their copy.
    internal func store(key: String, data: Data) throws {
      let cacheRoot = directory(for: key)
      let final = cacheRoot.appendingPathComponent("output.swift")
      let fileManager = FileManager.default

      // Ensure the parent of the cache key dir exists. The key dir itself is
      // installed by the atomic rename below.
      try fileManager.createDirectory(
        at: cacheRoot.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )

      // Stage the payload in a per-pid + uuid sibling dir so it can be renamed
      // into place as a single atomic step.
      let staging = cacheRoot.deletingLastPathComponent()
        .appendingPathComponent(
          "tmp.\(ProcessInfo.processInfo.processIdentifier).\(UUID().uuidString)"
        )
      try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)
      try data.write(to: staging.appendingPathComponent("output.swift"))

      // Atomic rename into the cache path. If a peer already populated this
      // key, swallow the rename error and drop our staging copy. Re-throw only
      // if the destination is still missing afterwards.
      do {
        try fileManager.moveItem(at: staging, to: cacheRoot)
      } catch {
        try? fileManager.removeItem(at: staging)
        if !fileManager.fileExists(atPath: final.path) {
          throw error
        }
      }
    }

    private func directory(for key: String) -> URL {
      root.appendingPathComponent(key)
    }
  }

#endif
