//
//  FileManager+Execution.swift
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
  /// Library product name whose platform-specific dylib marks a lib dir.
  private static let syntaxKitProductName = "SyntaxKit"
  /// File extension identifying SyntaxKit DSL input files.
  private static let swiftFileExtension = "swift"
  /// Filename prefix marking a source as "not an input" (skipped in batches).
  private static let nonInputFilePrefix = "_"

  /// True if `path` is a directory containing `libSyntaxKit.{dylib,so}`.
  internal func isLibDir(_ path: String) -> Bool {
    guard pathKind(atPath: path) == .directory else { return false }
    return pathKind(atPath: "\(path)/\(Self.syntaxKitProductName.dylibFilename)") != .missing
  }

  /// `<size>/<mtime>` fingerprint of `libSyntaxKit.{dylib,so}` under
  /// `libPath`, or nil if unreadable. Catches in-place rebuilds without a
  /// version bump.
  internal func libStamp(libPath: String) -> String? {
    let dylib = "\(libPath)/\(Self.syntaxKitProductName.dylibFilename)"
    return fingerprint(atPath: dylib).map {
      "\($0.size)/\(Int($0.modificationDate.timeIntervalSince1970))"
    }
  }

  /// Returns every `.swift` file under `inputDir` (recursive), sorted, with
  /// hidden files and files prefixed by `_` removed. The recursive walk and
  /// sort come from `regularFiles(under:)`; this method adds only the SyntaxKit
  /// input convention (`.swift` extension, skip the `_`-prefixed "not an input"
  /// sources).
  ///
  /// Throws `CollectInputsError.cliError` when the directory can't be
  /// enumerated, or `.resourceValuesFailure` when a file's resource values
  /// can't be read — both are bulk failures with nothing per-file to report.
  internal func collectInputs(at inputDir: URL) throws(CollectInputsError) -> [URL] {
    let files: [URL]
    do {
      files = try regularFiles(under: inputDir)
    } catch {
      // `error` is typed `FileEnumerationError`; map each case onto the
      // collect-specific error the caller already presents.
      switch error {
      case .notEnumerable(let directory):
        throw .cliError(CLIError(message: "could not enumerate \(directory.path)"))
      case .resourceValuesUnavailable(_, let underlying):
        throw .resourceValuesFailure(underlying)
      }
    }

    return
      files
      .filter { $0.pathExtension == Self.swiftFileExtension }
      .filter { !$0.lastPathComponent.hasPrefix(Self.nonInputFilePrefix) }
      .map(\.standardizedFileURL)
  }

  /// Builds the `FileOutcome` for one render result, writing a successful
  /// render's stdout to its mirrored destination under `outputBase`. The write
  /// side effect lives here; failures (a non-zero render exit, or a write
  /// error) are folded into the returned outcome rather than thrown, so a
  /// failing peer doesn't prevent successful files in the batch from being
  /// written (Tuist-analog batch semantics). No diagnostics are printed here;
  /// the caller does that.
  internal func writeOutput(
    for result: RenderTaskResult,
    inputBase: URL,
    outputBase: URL,
    toolchain: Runner.ToolchainVerification
  ) -> DirectoryRender.FileOutcome {
    // Mirror the input's location under the output base (generic path math).
    let destination = result.input.rerooted(from: inputBase, onto: outputBase)

    // stderr is the toolchain's diagnostics whenever the render produced any —
    // i.e. on every successful spawn, regardless of how the write then fares.
    let stderr = (try? result.result.get())?.stderr ?? ""

    let failure: RunError?
    do {
      try result.writeOutput(to: destination, toolchain: toolchain) { [self] in
        try self.writeData($0.output, to: $0.destination)
      }
      failure = nil
    } catch {
      failure = error
    }

    return DirectoryRender.FileOutcome(
      input: result.input,
      stderr: stderr,
      result: failure
    )
  }
}
