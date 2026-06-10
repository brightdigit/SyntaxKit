//
//  OutputCacheTests.swift
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
import Testing

@testable import SyntaxKit

@Suite internal struct OutputCacheTests {
  /// A value-type `EnvironmentProvider` whose environment is fixed, so
  /// cache-key derivation can be tested without depending on the real process
  /// environment. A value type rather than a `ProcessInfo` subclass because
  /// `swift-corelibs-foundation` (Linux/Windows) declares `ProcessInfo` as
  /// `final` with `environment` on an extension — subclass-and-override
  /// doesn't compile there.
  private struct FakeEnvironment: EnvironmentProvider {
    let environment: [String: String]
    let processIdentifier: Int32 = 1
  }

  /// A stub `ContentHashing` that ignores its input and returns a fixed digest,
  /// used to prove `OutputCache` derives keys through the injected factory.
  private struct StubHasher: ContentHashing {
    private static let fixedDigest = "stub-digest"
    mutating func update(data: Data) {}
    func finalize() -> String { Self.fixedDigest }
  }

  private static let libPath = "/nonexistent/lib"

  private func cache(
    swiftVersion: String? = "swift 6.1",
    environment: [String: String] = [:]
  ) -> OutputCache {
    OutputCache(
      swiftVersion: swiftVersion,
      environmentProvider: FakeEnvironment(environment: environment)
    )
  }

  private func key(_ cache: OutputCache, source: String = "Struct(\"Foo\") {}") -> String {
    cache.key(forInput: source, libPath: Self.libPath)
  }

  @Test("key() derives the digest through the injected hasher factory")
  internal func usesInjectedHasher() {
    let cache = OutputCache(
      swiftVersion: "swift 6.1",
      environmentProvider: FakeEnvironment(environment: [:]),
      makeHasher: { StubHasher() }
    )
    #expect(cache.key(forInput: "anything", libPath: Self.libPath) == "stub-digest")
  }

  @Test("The same inputs always derive the same key")
  internal func stableKey() {
    let cache = cache()
    #expect(key(cache) == key(cache))
  }

  @Test("Different source bytes derive different keys")
  internal func sourceSensitivity() {
    let cache = cache()
    #expect(key(cache, source: "Struct(\"A\") {}") != key(cache, source: "Struct(\"B\") {}"))
  }

  @Test("A different swift version derives a different key")
  internal func swiftVersionSensitivity() {
    #expect(key(cache(swiftVersion: "swift 6.1")) != key(cache(swiftVersion: "swift 6.2")))
  }

  @Test("SKIT_/SYNTAXKIT_ env vars are mixed into the key")
  internal func relevantEnvVarsChangeKey() {
    let base = key(cache(environment: [:]))
    #expect(key(cache(environment: ["SKIT_FOO": "1"])) != base)
    #expect(key(cache(environment: ["SYNTAXKIT_BAR": "1"])) != base)
  }

  @Test("Unrelated env vars are ignored by the key")
  internal func irrelevantEnvVarsIgnored() {
    let base = key(cache(environment: [:]))
    #expect(key(cache(environment: ["PATH": "/usr/bin", "HOME": "/root"])) == base)
  }

  @Test("store then lookup round-trips the rendered payload")
  internal func storeLookupRoundTrip() throws {
    let cacheRoot = FileManager.default.temporaryDirectory
      .appendingPathComponent("outputcache-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: cacheRoot) }

    // XDG_CACHE_HOME redirects the cache root; it isn't a SKIT_/SYNTAXKIT_ var,
    // so it doesn't affect the key itself.
    let cache = cache(environment: ["XDG_CACHE_HOME": cacheRoot.path])
    let key = key(cache)
    let payload = Data("rendered output".utf8)

    #expect(cache.lookup(key: key) == nil)
    try cache.store(key: key, data: payload)
    #expect(cache.lookup(key: key) == payload)
  }
}
