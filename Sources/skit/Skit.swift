//
//  Skit.swift
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
import SyntaxParser

@main
internal struct Skit: AsyncParsableCommand {
  internal static let configuration = CommandConfiguration(
    commandName: "skit",
    abstract: "Render SyntaxKit DSL into Swift source, or parse Swift into JSON.",
    subcommands: [Run.self, Parse.self],
    defaultSubcommand: Run.self
  )
}

// MARK: - skit run

extension Skit {
  internal struct Run: AsyncParsableCommand {
    internal static let configuration = CommandConfiguration(
      commandName: "run",
      abstract: "Render SyntaxKit DSL input(s) into Swift source.",
      discussion: """
        Wraps each input in a `Group { … }` closure and spawns `swift` to
        evaluate it. The rendered output is written to stdout (single-file
        mode) or mirrored into an output directory (folder mode).

        Forms:
          skit run Input.swift                — render to stdout
          skit run Input.swift -o Out.swift   — render to a file
          skit run InputDir/ -o OutDir/       — walk **/*.swift (skipping
                                                 files prefixed with '_')
                                                 and mirror rendered output
                                                 into OutDir/
        """
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
      help: ArgumentHelp(
        "Directory containing libSyntaxKit.dylib + module files.",
        discussion: """
          When omitted, skit searches: $SKIT_LIB_DIR, then <binary-dir>/lib/,
          then <binary-dir>/../lib/skit/. Build a self-contained bundle with
          Scripts/build-skit-release.sh.
          """
      )
    )
    internal var libPath: String?

    @Option(
      name: .customLong("helpers"),
      help: ArgumentHelp(
        "Override Helpers/ directory location.",
        discussion: """
          By default skit walks up from the input looking for one. Helper
          sources are pre-compiled into libSyntaxKitHelpers.dylib and made
          importable via `import SyntaxKitHelpers`.
          """
      )
    )
    internal var helpersDir: String?

    @Flag(
      name: .customLong("no-helpers"),
      help: "Skip helpers discovery entirely."
    )
    internal var noHelpers: Bool = false

    @Flag(
      name: .customLong("no-cache"),
      help: ArgumentHelp(
        "Skip the rendered-output cache (always run swift).",
        discussion: """
          The cache lives at <syntaxkit cache>/outputs/<hash>/ and is keyed
          on input bytes, helpers, swift version, libSyntaxKit stamp, and
          SKIT_*/SYNTAXKIT_* env.
          """
      )
    )
    internal var noCache: Bool = false

    @Option(
      name: .customLong("timeout"),
      help: ArgumentHelp(
        "Per-input timeout for the spawned `swift` (seconds).",
        discussion: """
          Default 60. On expiry: SIGTERM, then SIGKILL after a 5s grace; the
          file exits with code 124. Pass 0 to disable the watchdog.
          """
      )
    )
    internal var timeoutSeconds: Int = 60

    @Flag(
      name: .customLong("no-toolchain-check"),
      help: ArgumentHelp(
        "Skip the bundle/local Swift-toolchain comparison.",
        discussion: """
          skit compares <lib>/swift-version.txt to `swift --version` at
          startup and refuses to spawn `swift` on mismatch — swiftmodules
          aren't reliably compatible across compiler versions. See issue
          #157 for the auto-rebuild plan.
          """
      )
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
      let libPath: String
      do {
        libPath = try resolveLibPath(override: self.libPath)
      } catch {
        FileHandle.standardError.write(Data("\(error)\n".utf8))
        throw ExitCode(2)
      }

      if !noToolchainCheck {
        switch toolchainCheck(libPath: libPath) {
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
        let helpers = try resolveHelpers(
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
        let helpers = try resolveHelpers(
          nearInputPath: input,
          libPath: libPath,
          options: helpersOptions
        )
        try runSingleFile(
          inputPath: input,
          outputPath: output,
          libPath: libPath,
          helpers: helpers,
          useCache: !noCache,
          timeoutSeconds: timeoutSeconds
        )
      }
    }
  }
}

// MARK: - skit parse

extension Skit {
  internal struct Parse: ParsableCommand {
    internal static let configuration = CommandConfiguration(
      commandName: "parse",
      abstract: "Parse Swift source on stdin into a JSON syntax tree on stdout."
    )

    internal func run() throws {
      let code = String(data: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) ?? ""
      let treeNodes = SyntaxParser.parse(code: code)
      let encoder = JSONEncoder()
      let data = try encoder.encode(treeNodes)
      let json = String(decoding: data, as: UTF8.self)
      print(json)
    }
  }
}
