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
    var isDir: ObjCBool = false
    guard fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
      return false
    }
    return fileExists(atPath: "\(path)/\(Self.syntaxKitProductName.dylibFilename)")
  }

  /// `<size>/<mtime>` fingerprint of `libSyntaxKit.{dylib,so}` under
  /// `libPath`, or nil if unreadable. Catches in-place rebuilds without a
  /// version bump.
  internal func libStamp(libPath: String) -> String? {
    let dylib = "\(libPath)/\(Self.syntaxKitProductName.dylibFilename)"
    guard let attrs = try? attributesOfItem(atPath: dylib) else { return nil }
    let size = (attrs[.size] as? NSNumber)?.intValue ?? 0
    let mtime = (attrs[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
    return "\(size)/\(Int(mtime))"
  }

  /// Returns every `.swift` file under `inputDir` (recursive), sorted, with
  /// hidden files and files prefixed by `_` removed. Sorted output keeps
  /// batch behaviour deterministic across runs.
  ///
  /// Throws `CollectInputsError.cliError` when the directory can't be
  /// enumerated, or `.resourceValuesFailure` when a file's resource values
  /// can't be read — both are bulk failures with nothing per-file to report.
  internal func collectInputs(at inputDir: URL) throws(CollectInputsError) -> [URL] {
    guard
      let enumerator = enumerator(
        at: inputDir,
        includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
        options: [.skipsHiddenFiles]
      )
    else {
      throw .cliError(CLIError(message: "could not enumerate \(inputDir.path)"))
    }

    var result: [URL] = []
    for case let url as URL in enumerator {
      let values: URLResourceValues
      do {
        values = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
      } catch {
        throw .resourceValuesFailure(error)
      }
      // Directories aren't outputs.
      if values.isDirectory == true { continue }
      // Filter for `.swift` regular files, skipping the `_`-prefixed
      // convention for "not an input" sources.
      guard values.isRegularFile == true else { continue }
      guard url.pathExtension == Self.swiftFileExtension else { continue }
      guard !url.lastPathComponent.hasPrefix(Self.nonInputFilePrefix) else { continue }
      result.append(url.standardizedFileURL)
    }
    return result.sorted { $0.path < $1.path }
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
    let relative = result.input.path.dropFirst(inputBase.path.count + 1)
    let destination = outputBase.appendingPathComponent(String(relative))

    // stderr is the toolchain's diagnostics whenever the render produced any —
    // i.e. on every successful spawn, regardless of how the write then fares.
    let stderr = (try? result.result.get())?.stderr ?? ""

    // Fold the render result into the write result: a render failure passes
    // through, a non-zero exit becomes `.renderFailed`, and a clean render is
    // committed to disk (capturing any write error as `.unexpected`).
    let outcome = result.result.flatMap { processResult -> Result<Void, RunError> in
      guard processResult.exitCode == 0 else {
        return .failure(
          .renderFailed(
            exitCode: processResult.exitCode,
            stderr: processResult.stderr,
            toolchain: toolchain
          )
        )
      }
      return Result {
        try createDirectory(
          at: destination.deletingLastPathComponent(),
          withIntermediateDirectories: true
        )
        try processResult.stdout.write(to: destination)
      }
      .mapError(RunError.unexpected)
    }

    // Collapse the success/failure result into the outcome's optional error
    // (nil == success).
    let failure: (any Error)?
    switch outcome {
    case .success:
      failure = nil
    case .failure(let error):
      failure = error
    }

    return DirectoryRender.FileOutcome(
      input: result.input,
      stderr: stderr,
      result: failure
    )
  }
}
