//
//  Skit+Run.swift
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

extension Skit {
  /// Render one or more SyntaxKit DSL files into Swift source.
  ///
  /// `Run` is the default subcommand. It accepts either a single `.swift`
  /// file or a directory of `.swift` files; in directory mode the rendered
  /// output is written into a mirrored tree under `-o`. The actual work is
  /// delegated to a `Runner` value (`Runner.swift`).
  internal struct Run: AsyncParsableCommand {
    /// The subcommand name as invoked on the command line.
    internal static let commandName = "run"

    /// User-facing option/flag names (the `--long` CLI surface).
    internal static let outputOptionName = "output"
    internal static let libOptionName = "lib"
    internal static let noCacheFlagName = "no-cache"
    internal static let timeoutOptionName = "timeout"
    internal static let noToolchainCheckFlagName = "no-toolchain-check"

    /// Environment variable holding an override for the libSyntaxKit directory.
    internal static let libDirEnvironmentKey = "SKIT_LIB_DIR"

    /// Prefix for skit's own diagnostics written to stderr.
    internal static let messagePrefix = "skit: "

    /// Argument passed to `swift` to capture the toolchain version banner.
    internal static let versionFlag = "--version"

    /// Path to the script that rebuilds the self-contained release bundle.
    internal static let buildReleaseScriptPath = "Scripts/build-skit-release.sh"

    internal static let configuration = CommandConfiguration(
      commandName: commandName,
      abstract: "Render SyntaxKit DSL input(s) into Swift source."
    )

    @Argument(help: "Path to a .swift input file or a directory of inputs.")
    internal var input: String

    @Option(
      name: [.short, .customLong(Run.outputOptionName)],
      help: "Output file (single-file mode) or directory (folder mode)."
    )
    internal var output: String?

    @Option(
      name: .customLong(Run.libOptionName),
      help: "Directory containing libSyntaxKit.dylib + module files."
    )
    internal var libPath: String?

    @Flag(
      name: .customLong(Run.noCacheFlagName),
      help: "Skip the rendered-output cache (always run swift)."
    )
    internal var noCache: Bool = false

    @Option(
      name: .customLong(Run.timeoutOptionName),
      help: "Per-input timeout for the spawned `swift` in seconds (0 disables)."
    )
    internal var timeoutSeconds: Int = 60

    @Flag(
      name: .customLong(Run.noToolchainCheckFlagName),
      help: "Skip the bundle/local Swift-toolchain comparison."
    )
    internal var noToolchainCheck: Bool = false

    internal func validate() throws {
      guard timeoutSeconds >= 0 else {
        throw ValidationError(
          "--\(Self.timeoutOptionName) expects a non-negative integer (seconds), "
            + "got: \(timeoutSeconds)"
        )
      }
    }

    internal func execute() async throws(CommandError) {
      // The spawn backend is nil only where there's no Subprocess backend
      // (Windows, embedded) — there `run` can't spawn `swift`/`swiftc`.
      guard let backend = Self.swiftBackend else {
        throw CommandError.unsupportedPlatform
      }

      // Capture the two backend-dependent inputs to the otherwise
      // platform-agnostic session setup: the local `swift --version` (feeds
      // the toolchain check + the cache key, spawned exactly once per run)
      // and the SKIT_LIB_DIR override.
      let swiftVersion = await backend.captureSwiftVersion()
      let envLibPath = ProcessInfo.processInfo.environment[Self.libDirEnvironmentKey]
        .flatMap { $0.isEmpty ? nil : $0 }

      // Resolve lib dir → toolchain-gate → cache → assemble Runner. That
      // orchestration lives in SyntaxKit (the `Runner` session initializer);
      // skit injects the captured `swiftVersion` and the backend's spawn
      // method, and maps the typed setup failure onto the CLI's exit policy.
      let runner: Runner
      do {
        runner = try Runner(
          libCandidates: [self.libPath, envLibPath],
          swiftVersion: swiftVersion,
          enforceToolchainCheck: !noToolchainCheck,
          useCache: !noCache,
          timeoutSeconds: timeoutSeconds
        ) { try await backend.runSwift(for: $0) }
      } catch {
        throw CommandError(error)
      }

      // Hand the input off to the runner: `render` owns presentation and the
      // single-file/directory dispatch, translating render failures into
      // `CommandError` for the outer catch to map.
      try await render(using: runner, input: input, output: output)
    }

    /// Renders the input(s), with a single seam between the pipeline and the
    /// process: every step `throw`s a typed `CommandError`, and the outer catch
    /// maps that to its stderr diagnostic + terminal `ExitCode`/`ValidationError`.
    /// Any non-`CommandError` propagates to ArgumentParser unchanged.
    internal func run() async throws {
      do {
        try await self.execute()
      } catch {
        if let diagnostic = error.diagnostic {
          FileHandle.standardError.write(Data(diagnostic.utf8))
        }
        throw error.terminalError
      }
    }
  }
}
