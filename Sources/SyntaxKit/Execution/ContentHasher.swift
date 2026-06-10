//
//  ContentHasher.swift
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

public import Foundation

/// Non-cryptographic 64-bit FNV-1a hasher used to derive content-addressed
/// cache keys. The cache keys aren't security-critical — there's no
/// adversary trying to forge a collision — so we don't need a cryptographic
/// hash. 64 bits of output gives ~10⁻⁹ collision probability at 10⁶ cache
/// entries, which is well past anything we'll see in practice.
///
/// FNV-1a is deterministic across processes and platforms (unlike the Swift
/// stdlib `Hasher`, whose seed is randomized per-process) — that
/// determinism is what makes it usable as an on-disk cache key. It is the
/// default `ContentHashing` conformer used by `OutputCache`.
public struct ContentHasher: ContentHashing {
  private static let offsetBasis: UInt64 = 0xcbf2_9ce4_8422_2325
  private static let prime: UInt64 = 0x0000_0100_0000_01b3

  /// Width of the zero-padded lowercase-hex digest (64 bits → 16 hex chars).
  private static let hexWidth = 16

  private var state: UInt64 = ContentHasher.offsetBasis

  /// Creates a hasher seeded with the FNV-1a offset basis.
  public init() {}

  public mutating func update(data: Data) {
    for byte in data {
      state ^= UInt64(byte)
      state &*= ContentHasher.prime
    }
  }

  /// Returns the full 64-bit hash as a 16-char lowercase-hex string suitable
  /// for use as a directory name. Built with `String(_:radix:)` rather than
  /// `String(format: "%016x", …)` because the `%x` specifier consumes a 32-bit
  /// `unsigned int`, which would silently truncate the digest to its low 32
  /// bits and halve the entropy described above.
  public func finalize() -> String {
    let hex = String(state, radix: 16)
    return String(repeating: "0", count: max(0, Self.hexWidth - hex.count)) + hex
  }
}
