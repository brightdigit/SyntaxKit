//
//  Bundle+ResolveLibPath.swift
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

extension Bundle {
  /// Bundle-relative lib dir name for the adjacent layout (`<exec-dir>/lib`).
  private static let libDirectoryName = "lib"
  /// Bundle-relative lib dir path for the Homebrew layout
  /// (`<exec-dir>/../lib/skit`).
  private static let homebrewLibSkitSubpath = "lib/skit"

  /// Resolves a directory containing `libSyntaxKit.dylib` + swiftmodules.
  ///
  /// Tries each non-nil entry in `candidates` in order; if any non-nil
  /// candidate is not a SyntaxKit lib dir, throws `CLIError`. If every
  /// candidate is absent, falls back to bundle-relative paths derived
  /// from `executableURL`:
  ///   - `<exec-dir>/lib`             (adjacent layout)
  ///   - `<exec-dir>/../lib/skit`     (Homebrew layout)
  ///
  /// `executableURL` overrides the bundle's own executable location used to
  /// derive the adjacent/Homebrew fallbacks; it defaults to `self.executableURL`
  /// and exists so tests can point the fallbacks at a fixture tree.
  public func resolveLibPath(
    candidates: [String?],
    fileManager: FileManager = .default,
    executableURL: URL? = nil
  ) throws -> String {
    for candidate in candidates {
      guard let candidate else { continue }
      guard fileManager.isLibDir(candidate) else {
        throw CLIError(message: "path does not look like a SyntaxKit lib dir: \(candidate)")
      }
      return candidate
    }

    if let execURL = (executableURL ?? self.executableURL)?.resolvingSymlinksInPath() {
      let execDir = execURL.deletingLastPathComponent()

      let adjacent = execDir.appendingPathComponent(Self.libDirectoryName).path
      if fileManager.isLibDir(adjacent) {
        return adjacent
      }

      let brewLayout = execDir.deletingLastPathComponent()
        .appendingPathComponent(Self.homebrewLibSkitSubpath).path
      if fileManager.isLibDir(brewLayout) {
        return brewLayout
      }
    }

    throw CLIError(
      message: """
        Could not locate SyntaxKit lib directory. Looked for:
          1. explicit candidates       (none provided or all empty)
          2. <binary-dir>/lib/         (not found)
          3. <binary-dir>/../lib/skit/ (not found)
        Run Scripts/build-skit.sh to produce a self-contained
        release bundle under .build/skit-release/.
        """
    )
  }
}
