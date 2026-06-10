//
//  Runner+Session.swift
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

extension Runner {
  /// Brings up a render-ready `Runner`: resolves the libSyntaxKit directory
  /// from `libCandidates` (falling back to bundle-relative layouts), optionally
  /// gates on the bundle/local toolchain comparison, and wires up the output
  /// cache.
  ///
  /// Platform-agnostic by construction — the two inputs that need a Subprocess
  /// backend are injected by the caller: the already-captured `swiftVersion`
  /// (`swift --version` output, or nil if capture failed) and the `run` closure
  /// that actually spawns `swift` for one `SwiftInvocation`.
  ///
  /// - Throws: `RunnerSetupError` for a lookup or toolchain failure, so the caller
  ///   owns the presentation and exit mapping.
  public init(
    libCandidates: [String?],
    swiftVersion: String?,
    enforceToolchainCheck: Bool,
    useCache: Bool,
    timeoutSeconds: Int,
    fileManager: @autoclosure @escaping @Sendable () -> FileManager = .default,
    run: @Sendable @escaping (SwiftInvocation) async throws -> SwiftRunOutcome
  ) throws(RunnerSetupError) {
    // 1. Resolve the libSyntaxKit bundle dir. Failure is fatal — there's no
    // dylib + swiftmodules to link against without it.
    let libPath: String
    do {
      libPath = try Bundle.main.resolveLibPath(
        candidates: libCandidates,
        fileManager: fileManager()
      )
    } catch {
      throw RunnerSetupError.libResolutionFailed(error)
    }

    // 2. Compare the bundle's recorded `swift --version` against the local one.
    // swiftmodules aren't reliably forward-compatible across compiler versions,
    // so a mismatch is surfaced rather than letting the spawned `swift` emit a
    // cryptic module-version diagnostic. A *mismatch* fails setup; anything else
    // is remembered (no IO here — the SDK stays silent) so a later render
    // failure can hint that an unverified toolchain may be the cause.
    let verification: ToolchainVerification
    if enforceToolchainCheck {
      switch ToolchainCheckResult(libPath: libPath, swiftVersion: swiftVersion) {
      case .match:
        verification = .verified
      case .stampMissing:
        verification = .unverified
      case .mismatch(let bundle, let local):
        throw RunnerSetupError.toolchainMismatch(bundle: bundle, local: local)
      }
    } else {
      verification = .notChecked
    }

    // 3. Build the output cache (nil when disabled). The captured `swiftVersion`
    // is bound in so per-input key derivation doesn't re-spawn `swift`.
    let cache: OutputCache? =
      useCache
      ? OutputCache(swiftVersion: swiftVersion, fileManager: fileManager())
      : nil

    // 4. Delegate to the designated initializer, binding the spawn closure.
    self.init(
      libPath: libPath,
      cache: cache,
      timeoutSeconds: timeoutSeconds,
      toolchainVerification: verification,
      fileManager: fileManager(),
      run: run
    )
  }
}
