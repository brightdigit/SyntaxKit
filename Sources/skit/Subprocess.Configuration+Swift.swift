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

  extension Subprocess.Configuration {
    /// Bounded output capacity for the spawned `swift` (16 MiB stdout / 1 MiB
    /// stderr). Output above this is exotic; we'd surface a clear SubprocessError
    /// rather than silently truncate.
    private static let stdoutLimitBytes = 16 * 1_024 * 1_024
    private static let stderrLimitBytes = 1 * 1_024 * 1_024

    /// Subdirectory of the lib dir holding the SwiftSyntax CShims headers.
    private static let cShimsIncludeSuffix = "_SwiftSyntaxCShims-include"

    /// swiftc flags used to build the `swift` invocation.
    private static let flagSuppressWarnings = "-suppress-warnings"
    private static let flagInclude = "-I"
    private static let flagLibrarySearchPath = "-L"
    private static let flagLinkSyntaxKit = "-lSyntaxKit"
    private static let flagPassToClang = "-Xcc"
    private static let flagPassToLinker = "-Xlinker"
    private static let flagRPath = "-rpath"

    /// A configuration that runs the `swift` interpreter on `wrappedPath`,
    /// linked against `libSyntaxKit` in `libPath`.
    ///
    /// Builds the full flag set: link against libSyntaxKit, include the CShims
    /// headers, and set rpath so the dylib loads at runtime. The executable is
    /// resolved by name on `PATH`.
    internal static func swift(libPath: String, wrappedPath: String) -> Self {
      let cShimsInclude = "\(libPath)/\(cShimsIncludeSuffix)"
      let arguments: [String] = [
        flagSuppressWarnings,
        flagInclude, libPath,
        flagLibrarySearchPath, libPath,
        flagLinkSyntaxKit,
        flagPassToClang, flagInclude, flagPassToClang, cShimsInclude,
        flagPassToLinker, flagRPath, flagPassToLinker, libPath,
        wrappedPath,
      ]
      return Self(executable: .name(Skit.swiftExecutableName), arguments: Arguments(arguments))
    }

    /// Spawns `swift` for the render `invocation` and normalizes the result
    /// into a `SwiftRunOutcome`. This is the Subprocess backend skit hands to
    /// `Runner` as its `run` closure — the one seam between the (platform-
    /// agnostic) engine in SyntaxKit and the Subprocess implementation. A
    /// completed spawn always reports `.completed`; the timeout race that can
    /// produce `.timedOut` lives in `Runner`.
    internal static func runSwift(
      for invocation: SyntaxKit.SwiftInvocation
    ) async throws -> SwiftRunOutcome {
      let record = try await Subprocess.run(
        .swift(libPath: invocation.libPath, wrappedPath: invocation.wrappedPath),
        output: .string(limit: stdoutLimitBytes),
        error: .string(limit: stderrLimitBytes)
      )
      return .completed(
        ProcessResult(
          exitCode: record.terminationStatus.exitCode,
          stdout: Data((record.standardOutput ?? "").utf8),
          stderr: record.standardError ?? ""
        )
      )
    }
  }

#endif
