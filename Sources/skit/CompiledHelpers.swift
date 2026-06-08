//
//  CompiledHelpers.swift
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

  /// A compiled `Helpers/` directory ready to splice into the input spawn.
  internal struct CompiledHelpers: Sendable {
    /// Directory containing `libSyntaxKitHelpers.dylib` + `.swiftmodule` files.
    let outputDir: URL
    /// Whether the build was reused from cache (false = freshly compiled).
    let cacheHit: Bool
  }

  extension CompiledHelpers {
    /// Resolves a `Helpers/` directory and compiles it (or reuses the cached
    /// build). Fails (returns nil) when helpers are disabled, when no `Helpers/`
    /// was found in auto mode, or when the directory exists but contains no
    /// `.swift` sources. On success, writes a one-line "skit: helpers
    /// cached/compiled at <path>" note to stderr so users can see whether the
    /// cache hit.
    internal init?(
      nearInputPath path: String,
      libPath: String,
      options: HelpersOptions
    ) async throws {
      // Pick the helpers dir according to the mode: walk up the tree, accept an
      // explicit override (after validating it's a directory), or bail out.
      let helpersDir: URL?
      switch options {
      case .disabled:
        return nil
      case .auto:
        helpersDir = discoverHelpersDir(near: URL(fileURLWithPath: path).standardizedFileURL)
      case .explicit(let dir):
        let url = URL(fileURLWithPath: dir).standardizedFileURL
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir),
          isDir.boolValue
        else {
          throw CLIError(message: "--helpers path is not a directory: \(dir)")
        }
        helpersDir = url
      }
      guard let helpersDir else { return nil }

      // Compile (or reuse the cached build). An empty Helpers/ dir is treated
      // as "no helpers" rather than an error.
      guard let compiled = try await buildHelpers(helpersDir: helpersDir, libPath: libPath) else {
        return nil
      }
      let suffix = compiled.cacheHit ? "cached" : "compiled"
      FileHandle.standardError.write(
        Data(
          "skit: helpers \(suffix) at \(helpersDir.path)\n".utf8
        ))
      self = compiled
    }
  }

#endif
