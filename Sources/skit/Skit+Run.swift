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

    @Option(
      name: .customLong("helpers"),
      help: "Override Helpers/ directory location."
    )
    internal var helpersDir: String?

    @Flag(
      name: .customLong("no-helpers"),
      help: "Skip helpers discovery entirely."
    )
    internal var noHelpers: Bool = false

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

        // 2. Compare the bundle's recorded `swift --version` against the local
        // one. swiftmodules aren't reliably forward-compatible across compiler
        // versions, so a mismatch produces a clear error rather than letting
        // the spawned `swift` emit a cryptic module-version diagnostic.
        if !noToolchainCheck {
          switch await ToolchainCheckResult(libPath: libPath) {
          case .match, .stampMissing:
            break
          case .mismatch(let bundle, let local):
            FileHandle.standardError.write(
              Data(toolchainMismatchMessage(bundle: bundle, local: local).utf8))
            throw ExitCode(2)
          }
        }

        // 3. Decide which helpers-resolution mode this invocation is in.
        // The actual discovery / compilation happens later in `CompiledHelpers.init`.
        let helpersOptions: HelpersOptions
        if noHelpers {
          helpersOptions = .disabled
        } else if let dir = helpersDir {
          helpersOptions = .explicit(dir)
        } else {
          helpersOptions = .auto
        }

        // 4. Stat the input to pick single-file vs. directory mode. Directory
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
          // 5a. Resolve helpers relative to the input root. This is the only
          // place we compile `Helpers/`; the result is reused across every
          // input file in the directory.
          let helpers = try await CompiledHelpers(
            nearInputPath: input,
            libPath: libPath,
            options: helpersOptions
          )
          // 6a. Hand off to the directory orchestrator and surface its exit
          // code via ExitCode (so a partial-failure batch returns 1).
          let exitCode = await runDirectory(
            inputDir: input,
            outputDir: output,
            libPath: libPath,
            helpers: helpers,
            useCache: !noCache,
            timeoutSeconds: timeoutSeconds
          )
          throw ExitCode(exitCode)
        } else {
          // 5b. Resolve helpers relative to this single file's parent.
          let helpers = try await CompiledHelpers(
            nearInputPath: input,
            libPath: libPath,
            options: helpersOptions
          )
          // 6b. Hand off to the single-file orchestrator. It calls `exit()`
          // directly on non-zero subprocess exit, so a thrown ExitCode here
          // would be unreachable in that path.
          try await runSingleFile(
            inputPath: input,
            outputPath: output,
            libPath: libPath,
            helpers: helpers,
            useCache: !noCache,
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
