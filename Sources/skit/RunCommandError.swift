//
//  RunCommandError.swift
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

import ArgumentParser
import Foundation
import SyntaxKit

/// Typed failures the `run` pipeline can produce. The render steps just
/// `throw` the case that describes *what* failed; `run()` catches these in
/// one place and converts each to its stderr diagnostic + process exit, so
/// the steps stay free of presentation/exit logic.
internal enum RunCommandError: Error {
  /// A usage error (bad input path, or a directory given without `-o`).
  /// Surfaced as an ArgumentParser `ValidationError` (exit 64), which prints
  /// the message and the command's usage.
  case usage(String)
  /// The libSyntaxKit directory couldn't be resolved. Exit 2.
  case libResolutionFailed(any Error)
  /// The bundle's recorded `swift --version` differs from the local one.
  /// Exit 2.
  case toolchainMismatch(bundle: String, local: String)
  /// The spawned `swift` exited non-zero (compile failure, `124` on timeout,
  /// `128 + signal`). Carries that code + the toolchain stderr; the code is
  /// passed through as the process exit. Also carries the session's
  /// `toolchainVerification` so an unverified toolchain can be hinted as a
  /// possible cause alongside the diagnostics.
  case renderFailed(exitCode: Int32, stderr: String, toolchain: ToolchainVerification)
  /// A directory batch couldn't be walked. Exit 1.
  case directoryWalkFailed(input: String, underlying: any Error)
  /// A render/batch failure whose diagnostics were already surfaced (per-input
  /// output, a printed summary, or none). Exit 1 with nothing further to say.
  case failed
  /// A wrapped Foundation/Subprocess failure with no dedicated mapping; the
  /// underlying error is rethrown so ArgumentParser prints it (exit 1).
  case unexpected(any Error)
  /// `run` was invoked on a platform without a Subprocess backend. Exit 1.
  case unsupportedPlatform

  /// stderr text to emit before exiting, or nil. `.usage` is printed by
  /// `ValidationError`; `.failed`/`.unexpected` print nothing here (their
  /// diagnostics were already surfaced, or ArgumentParser prints them).
  internal var diagnostic: String? {
    switch self {
    case .usage, .failed, .unexpected:
      return nil
    case .libResolutionFailed(let error):
      return "\(error)\n"
    case .toolchainMismatch(let bundle, let local):
      return Self.toolchainMismatchMessage(bundle: bundle, local: local)
    case .renderFailed(_, let stderr, let toolchain):
      let parts = [stderr.isEmpty ? nil : stderr, Self.toolchainHint(toolchain)]
        .compactMap { $0 }
      return parts.isEmpty ? nil : parts.joined()
    case .directoryWalkFailed(let input, let underlying):
      return "\(Skit.Run.messagePrefix)failed to walk \(input): \(underlying)\n"
    case .unsupportedPlatform:
      return "\(Skit.Run.messagePrefix)run is not supported on this platform "
        + "(no Subprocess backend).\n"
    }
  }

  /// The terminal error ArgumentParser acts on: a `ValidationError` (usage),
  /// an `ExitCode`, or the wrapped underlying error.
  internal var terminalError: any Error {
    switch self {
    case .usage(let message):
      return ValidationError(message)
    case .libResolutionFailed, .toolchainMismatch:
      return ExitCode(2)
    case .renderFailed(let exitCode, _, _):
      return ExitCode(exitCode)
    case .directoryWalkFailed, .failed, .unsupportedPlatform:
      return ExitCode(1)
    case .unexpected(let underlying):
      return underlying
    }
  }

  /// Maps a SyntaxKit session-setup failure onto the CLI's exit policy.
  internal init(_ error: RunnerSetupError) {
    switch error {
    case .libResolutionFailed(let underlying):
      self = .libResolutionFailed(underlying)
    case .toolchainMismatch(let bundle, let local):
      self = .toolchainMismatch(bundle: bundle, local: local)
    }
  }

  /// Maps the `RunError` from `Runner.renderFile` onto the CLI's exit policy.
  /// `renderFile`'s error is exhaustive over `RunError`, so every case has a
  /// direct translation.
  internal init(renderFileError error: RunError) {
    switch error {
    case .invalidInput(let message):
      self = .usage(message)
    case .renderFailed(let exitCode, let stderr, let toolchain):
      self = .renderFailed(exitCode: exitCode, stderr: stderr, toolchain: toolchain)
    case .unexpected(let underlying):
      self = .unexpected(underlying)
    }
  }

  /// Maps the `CollectInputsError` from `FileManager.collectInputs` onto the
  /// CLI's exit policy. Both cases are bulk directory-walk failures, carrying
  /// `input` for the "failed to walk" framing the CLI prints.
  internal init(collectInputsError error: CollectInputsError, input: String) {
    switch error {
    case .cliError(let underlying):
      self = .directoryWalkFailed(input: input, underlying: underlying)
    case .resourceValuesFailure(let underlying):
      self = .directoryWalkFailed(input: input, underlying: underlying)
    }
  }

  /// A one-line note appended to a render failure when the bundle/local Swift
  /// toolchain wasn't confirmed compatible — so a module-version error reads
  /// as a possible toolchain mismatch rather than a mysterious build failure.
  /// `nil` when the toolchain was verified (nothing to add). `internal` so the
  /// directory-batch path can surface the same note once.
  internal static func toolchainHint(_ verification: ToolchainVerification) -> String? {
    switch verification {
    case .verified:
      return nil
    case .notChecked:
      return "\(Skit.Run.messagePrefix)note: the bundle/local Swift-toolchain check was skipped "
        + "(--\(Skit.Run.noToolchainCheckFlagName)); if this is a module-version error, a "
        + "toolchain mismatch may be the cause.\n"
    case .unverified:
      return
        "\(Skit.Run.messagePrefix)note: couldn't verify the bundle's Swift toolchain against "
        + "your local `swift` (no toolchain stamp, or version capture failed); if this is a "
        + "module-version error, a toolchain mismatch may be the cause.\n"
    }
  }

  /// Human-readable error explaining why the bundle's recorded
  /// `swift --version` differs from the local one, and how to recover.
  private static func toolchainMismatchMessage(bundle: String, local: String) -> String {
    """
    \(Skit.Run.messagePrefix)toolchain mismatch
      bundle: \(bundle)
      local:  \(local)
    The bundle's libSyntaxKit was built against a different `swift` than the
    one on your PATH. Swift swiftmodules aren't reliably compatible across
    versions, so spawning `swift` would fail with a cryptic module-version
    diagnostic.

    Rebuild the bundle with:
      \(Skit.Run.buildReleaseScriptPath)
    Or pass --\(Skit.Run.noToolchainCheckFlagName) to try anyway.

    """
  }
}
