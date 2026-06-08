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

extension Skit {
  /// Render one or more SyntaxKit DSL files into Swift source.
  ///
  /// `Run` is the default subcommand. It accepts either a single `.swift`
  /// file or a directory of `.swift` files; in directory mode the rendered
  /// output is written into a mirrored tree under `-o`. The actual work is
  /// delegated to free functions in `Runner.swift`.
  internal struct Run: AsyncParsableCommand {
    internal static let configuration = CommandConfiguration(
      commandName: "run",
      abstract: "Render SyntaxKit DSL input(s) into Swift source."
    )

    @Argument(help: "Path to a .swift input file or a directory of inputs.")
    internal var input: String

    @Option(
      name: [.short, .customLong("output")],
      help: "Output file (single-file mode) or directory (folder mode)."
    )
    internal var output: String?

    @Option(
      name: .customLong("lib"),
      help: "Directory containing libSyntaxKit.dylib + module files."
    )
    internal var libPath: String?

    @Flag(
      name: .customLong("no-cache"),
      help: "Skip the rendered-output cache (always run swift)."
    )
    internal var noCache: Bool = false

    @Option(
      name: .customLong("timeout"),
      help: "Per-input timeout for the spawned `swift` in seconds (0 disables)."
    )
    internal var timeoutSeconds: Int = 60

    @Flag(
      name: .customLong("no-toolchain-check"),
      help: "Skip the bundle/local Swift-toolchain comparison."
    )
    internal var noToolchainCheck: Bool = false

    internal func validate() throws {
      guard timeoutSeconds >= 0 else {
        throw ValidationError(
          "--timeout expects a non-negative integer (seconds), got: \(timeoutSeconds)"
        )
      }
    }

    internal func run() async throws {
      #if canImport(Subprocess)
        // 1. Resolve the libSyntaxKit bundle dir. Failure here is fatal — we
        // can't spawn `swift` without knowing where the dylib + swiftmodules
        // live. The error message lists the four lookup paths in priority order.
        let libPath: String
        do {
          let envLibPath = ProcessInfo.processInfo.environment["SKIT_LIB_DIR"].flatMap {
            $0.isEmpty ? nil : $0
          }
          libPath = try Bundle.main.resolveLibPath(candidates: self.libPath, envLibPath)
        } catch {
          FileHandle.standardError.write(Data("\(error)\n".utf8))
          throw ExitCode(2)
        }

        // 2. Capture local `swift --version` once. Feeds both the toolchain
        // check (compares against the bundle stamp) and the output cache key
        // (one shard per toolchain). Doing this here means we spawn
        // `swift --version` exactly once per `skit run` invocation rather
        // than once per input.
        let swiftVersion = await captureSwiftVersion()

        // 3. Compare the bundle's recorded `swift --version` against the local
        // one. swiftmodules aren't reliably forward-compatible across compiler
        // versions, so a mismatch produces a clear error rather than letting
        // the spawned `swift` emit a cryptic module-version diagnostic.
        if !noToolchainCheck {
          switch ToolchainCheckResult(libPath: libPath, swiftVersion: swiftVersion) {
          case .match, .stampMissing:
            break
          case .mismatch(let bundle, let local):
            FileHandle.standardError.write(
              Data(toolchainMismatchMessage(bundle: bundle, local: local).utf8))
            throw ExitCode(2)
          }
        }

        // 4. Build the output cache (nil under `--no-cache`). The captured
        // `swiftVersion` is bound into the instance so per-input key derivation
        // doesn't re-spawn `swift`.
        let cache: OutputCache? = noCache ? nil : OutputCache(swiftVersion: swiftVersion)

        // 5. Stat the input to pick single-file vs. directory mode. Directory
        // mode requires an explicit `-o` output dir; single-file mode falls
        // back to stdout.
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: input, isDirectory: &isDirectory) else {
          throw ValidationError("input does not exist: \(input)")
        }

        if isDirectory.boolValue {
          guard let output else {
            throw ValidationError("directory inputs require -o <output-dir>")
          }
          // 6a. Hand off to the directory orchestrator and surface its exit
          // code via ExitCode (so a partial-failure batch returns 1).
          let exitCode = await runDirectory(
            inputDir: input,
            outputDir: output,
            libPath: libPath,
            cache: cache,
            timeoutSeconds: timeoutSeconds
          )
          throw ExitCode(exitCode)
        } else {
          // 6b. Hand off to the single-file orchestrator. It calls `exit()`
          // directly on non-zero subprocess exit, so a thrown ExitCode here
          // would be unreachable in that path.
          try await runSingleFile(
            inputPath: input,
            outputPath: output,
            libPath: libPath,
            cache: cache,
            timeoutSeconds: timeoutSeconds
          )
        }
      #else
        // Subprocess is the only backend skit knows how to use to spawn
        // `swift`/`swiftc`. Without it (Windows, embedded), `run` cannot work.
        FileHandle.standardError.write(
          Data("skit: run is not supported on this platform (no Subprocess backend).\n".utf8)
        )
        throw ExitCode(1)
      #endif
    }
  }
}

#if canImport(Subprocess)

  import Subprocess

  extension Skit.Run {
    /// Verbatim `swift --version` output, or nil on spawn failure. Capped at 4 KiB.
    fileprivate func captureSwiftVersion() async -> String? {
      let result = try? await Subprocess.run(
        .name("swift"),
        arguments: ["--version"],
        output: .string(limit: 4_096),
        error: .discarded
      )
      return result?.standardOutput
    }
  }

#endif
