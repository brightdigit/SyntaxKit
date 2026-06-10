//
//  ToolchainCheckResult.swift
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

/// Outcome of comparing the bundle's recorded build toolchain against the
/// local `swift --version`. The swiftmodule format isn't reliably
/// forward-compatible across Swift releases, so a mismatch is worth surfacing.
public enum ToolchainCheckResult {
  /// Bundle stamp matches the local `swift --version` exactly.
  case match
  /// The toolchain check couldn't be performed: either `<libPath>/swift-version.txt`
  /// is missing (older bundle that predates the stamp) or the local
  /// `swift --version` couldn't be captured. The caller proceeds; presentation
  /// of the skipped-check note belongs to the call site, not this value type.
  case stampMissing
  /// The bundle stamp and the local `swift --version` differ.
  case mismatch(bundle: String, local: String)

  /// Filename for the bundle's recorded build-toolchain version.
  private static let toolchainStampFilename = "swift-version.txt"
}

extension ToolchainCheckResult {
  /// Compares `<libPath>/swift-version.txt` to the caller-captured
  /// `swiftVersion` string. The swiftmodule format isn't reliably
  /// forward-compatible across even patch-level Swift releases (originating
  /// bug: 6.3.0 → 6.3.2 rejected the swiftmodule), so the comparison is
  /// exact-string after normalising trailing whitespace.
  public init(libPath: String, swiftVersion: String?) {
    let stampURL = URL(fileURLWithPath: libPath)
      .appendingPathComponent(Self.toolchainStampFilename)
    guard let stampData = try? Data(contentsOf: stampURL),
      let stampRaw = String(data: stampData, encoding: .utf8)
    else {
      self = .stampMissing
      return
    }
    guard let localRaw = swiftVersion else {
      self = .stampMissing
      return
    }
    let bundle = stampRaw.trimmingCharacters(in: .whitespacesAndNewlines)
    let local = localRaw.trimmingCharacters(in: .whitespacesAndNewlines)
    self = bundle == local ? .match : .mismatch(bundle: bundle, local: local)
  }
}
