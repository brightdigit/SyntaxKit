//
//  Toolchain.swift
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
  import Subprocess

  /// Platform-specific shared-library filename for a Swift library product.
  internal func dylibFilename(forLibrary name: String) -> String {
    #if os(Linux)
      return "lib\(name).so"
    #else
      return "lib\(name).dylib"
    #endif
  }

  /// Verbatim `swift --version` output, or nil on spawn failure. Capped at 4 KiB.
  internal func captureSwiftVersion() async -> String? {
    let result = try? await run(
      .name("swift"),
      arguments: ["--version"],
      output: .string(limit: 4_096),
      error: .discarded
    )
    return result?.standardOutput
  }

  /// `<size>/<mtime>` fingerprint of the bundled libSyntaxKit dylib, or nil
  /// if unreadable. Catches in-place rebuilds without a version bump.
  internal func libStamp(libPath: String) -> String? {
    let dylib = "\(libPath)/\(dylibFilename(forLibrary: "SyntaxKit"))"
    guard let attrs = try? FileManager.default.attributesOfItem(atPath: dylib) else { return nil }
    let size = (attrs[.size] as? NSNumber)?.intValue ?? 0
    let mtime = (attrs[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
    return "\(size)/\(Int(mtime))"
  }

  /// Root for all skit caches. Honours `XDG_CACHE_HOME`, else macOS
  /// `~/Library/Caches/...` or Linux `~/.cache/syntaxkit`.
  internal func syntaxKitCacheRoot() throws -> URL {
    if let xdg = ProcessInfo.processInfo.environment["XDG_CACHE_HOME"], !xdg.isEmpty {
      return URL(fileURLWithPath: xdg).appendingPathComponent("syntaxkit")
    }
    let home = NSHomeDirectory()
    #if os(macOS)
      return URL(fileURLWithPath: home)
        .appendingPathComponent("Library/Caches/com.brightdigit.SyntaxKit")
    #else
      return URL(fileURLWithPath: home).appendingPathComponent(".cache/syntaxkit")
    #endif
  }

#endif
