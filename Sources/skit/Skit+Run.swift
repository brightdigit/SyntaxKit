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
        let libPath: String
        do {
          libPath = try resolveLibPath(override: self.libPath)
        } catch {
          FileHandle.standardError.write(Data("\(error)\n".utf8))
          throw ExitCode(2)
        }

        if !noToolchainCheck {
          switch await toolchainCheck(libPath: libPath) {
          case .match, .stampMissing:
            break
          case .mismatch(let bundle, let local):
            FileHandle.standardError.write(
              Data(toolchainMismatchMessage(bundle: bundle, local: local).utf8))
            throw ExitCode(2)
          }
        }

        let helpersOptions: HelpersOptions
        if noHelpers {
          helpersOptions = .disabled
        } else if let dir = helpersDir {
          helpersOptions = .explicit(dir)
        } else {
          helpersOptions = .auto
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: input, isDirectory: &isDirectory) else {
          throw ValidationError("input does not exist: \(input)")
        }

        if isDirectory.boolValue {
          guard let output else {
            throw ValidationError("directory inputs require -o <output-dir>")
          }
          let helpers = try await resolveHelpers(
            nearInputPath: input,
            libPath: libPath,
            options: helpersOptions
          )
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
          let helpers = try await resolveHelpers(
            nearInputPath: input,
            libPath: libPath,
            options: helpersOptions
          )
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
        FileHandle.standardError.write(
          Data("skit: run is not supported on this platform (no Subprocess backend).\n".utf8)
        )
        throw ExitCode(1)
      #endif
    }
  }
}
