//
//  Subprocess.Configuration+Swift.swift
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

#if canImport(Subprocess)

  import Foundation
  import Subprocess
  import SyntaxKit
  import System

  extension Subprocess.Configuration {
    /// Bounded output capacity for the spawned process (16 MiB stdout / 1 MiB
    /// stderr). Output above this is exotic; we'd surface a clear SubprocessError
    /// rather than silently truncate.
    private static let stdoutLimitBytes = 16 * 1_024 * 1_024
    private static let stderrLimitBytes = 1 * 1_024 * 1_024

    /// Subdirectory of the lib dir holding the SwiftSyntax CShims headers.
    private static let cShimsIncludeSuffix = "_SwiftSyntaxCShims-include"

    /// Filename prefix for the per-render temporary executable.
    private static let renderExecutablePrefix = "skit-render-"

    /// swiftc flags used to build the compile invocation.
    private static let flagSuppressWarnings = "-suppress-warnings"
    private static let flagInclude = "-I"
    private static let flagLibrarySearchPath = "-L"
    private static let flagLinkSyntaxKit = "-lSyntaxKit"
    private static let flagPassToClang = "-Xcc"
    private static let flagPassToLinker = "-Xlinker"
    private static let flagRPath = "-rpath"
    private static let flagOutput = "-o"

    /// A configuration that compiles `wrappedPath` into an executable at
    /// `outputPath`, linked against `libSyntaxKit` in `libPath`.
    ///
    /// Builds the full flag set: link against libSyntaxKit, include the CShims
    /// headers, and bake an rpath so the produced binary loads the dylib at
    /// runtime. `swiftc` is used rather than the `swift` interpreter because the
    /// interpreter's JIT does not load the dynamic libSyntaxKit's symbols. The
    /// executable is resolved by name on `PATH`.
    internal static func compileSwift(
      libPath: String,
      wrappedPath: String,
      outputPath: String
    ) -> Self {
      let cShimsInclude = "\(libPath)/\(cShimsIncludeSuffix)"
      let arguments: [String] = [
        flagSuppressWarnings,
        flagInclude, libPath,
        flagLibrarySearchPath, libPath,
        flagLinkSyntaxKit,
        flagPassToClang, flagInclude, flagPassToClang, cShimsInclude,
        flagPassToLinker, flagRPath, flagPassToLinker, libPath,
        flagOutput, outputPath,
        wrappedPath,
      ]
      return Self(executable: .name(Skit.swiftcExecutableName), arguments: Arguments(arguments))
    }

    /// Renders the `invocation` by compiling the wrapped DSL program with
    /// `swiftc` and then running the produced executable, whose stdout is the
    /// generated Swift source. This is the Subprocess backend skit hands to
    /// `Runner` as its `run` closure — the one seam between the (platform-
    /// agnostic) engine in SyntaxKit and the Subprocess implementation.
    ///
    /// A compile failure short-circuits and is reported with the compiler's
    /// exit code + stderr (the render layer maps any non-zero exit to a render
    /// failure). A successful compile is followed by running the binary and
    /// reporting its result. A completed spawn always reports `.completed`; the
    /// timeout race that can produce `.timedOut` lives in `Runner`.
    internal static func runSwift(
      for invocation: SyntaxKit.SwiftInvocation
    ) async throws -> SwiftRunOutcome {
      let outputURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("\(renderExecutablePrefix)\(UUID().uuidString)")
      defer { try? FileManager.default.removeItem(at: outputURL) }

      // 1. Compile the wrapped program to a temporary executable.
      let compile = try await Subprocess.run(
        .compileSwift(
          libPath: invocation.libPath,
          wrappedPath: invocation.wrappedPath,
          outputPath: outputURL.path
        ),
        output: .discarded,
        error: .string(limit: stderrLimitBytes)
      )
      guard compile.terminationStatus.exitCode == 0 else {
        return .completed(
          ProcessResult(
            exitCode: compile.terminationStatus.exitCode,
            stdout: Data(),
            stderr: compile.standardError ?? ""
          )
        )
      }

      // 2. Run the compiled program; its stdout is the rendered Swift source.
      let render = try await Subprocess.run(
        .path(FilePath(outputURL.path)),
        output: .string(limit: stdoutLimitBytes),
        error: .string(limit: stderrLimitBytes)
      )
      return .completed(
        ProcessResult(
          exitCode: render.terminationStatus.exitCode,
          stdout: Data((render.standardOutput ?? "").utf8),
          stderr: render.standardError ?? ""
        )
      )
    }
  }

#endif
