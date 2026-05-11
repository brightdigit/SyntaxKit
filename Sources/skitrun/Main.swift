//
//  Main.swift
//  SyntaxKit — skitrun (POC for issue #154)
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
import SwiftParser
import SwiftSyntax

@main
internal enum SkitRun {
  internal static func main() throws {
    let args = try CLIArgs.parse(CommandLine.arguments)

    let inputURL = URL(fileURLWithPath: args.inputPath)
    let absoluteInputPath = inputURL.standardizedFileURL.path
    let source = try String(contentsOf: inputURL, encoding: .utf8)
    let wrapped = wrap(source: source, originalPath: absoluteInputPath)

    let tmpDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("skitrun-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmpDir) }

    let wrappedURL = tmpDir.appendingPathComponent("Input.wrapped.swift")
    try wrapped.write(to: wrappedURL, atomically: true, encoding: .utf8)

    let result = try runSwift(
      wrappedPath: wrappedURL.path,
      libPath: args.libPath
    )

    if !result.stderr.isEmpty {
      // #sourceLocation already maps body diagnostics to the input file.
      // For diagnostics in the preamble (lines outside the body) the path
      // still references the wrapper — rewrite verbatim path occurrences so
      // users see something coherent.
      let rewritten = result.stderr.replacingOccurrences(
        of: wrappedURL.path,
        with: absoluteInputPath
      )
      FileHandle.standardError.write(Data(rewritten.utf8))
    }

    guard result.exitCode == 0 else {
      exit(result.exitCode)
    }

    if let outputPath = args.outputPath {
      try result.stdout.write(to: URL(fileURLWithPath: outputPath))
    } else {
      FileHandle.standardOutput.write(result.stdout)
    }
  }
}

// MARK: - Arg parsing

private struct CLIArgs {
  let inputPath: String
  let outputPath: String?
  let libPath: String

  static func parse(_ argv: [String]) throws -> CLIArgs {
    var inputPath: String?
    var outputPath: String?
    var libPath = "/tmp/syntaxkit-poc/lib"

    var i = 1
    while i < argv.count {
      let arg = argv[i]
      switch arg {
      case "-o", "--output":
        guard i + 1 < argv.count else { throw usage("-o requires a value") }
        outputPath = argv[i + 1]
        i += 2
      case "--lib":
        guard i + 1 < argv.count else { throw usage("--lib requires a value") }
        libPath = argv[i + 1]
        i += 2
      case "-h", "--help":
        FileHandle.standardError.write(Data(helpText.utf8))
        exit(0)
      case _ where arg.hasPrefix("-"):
        throw usage("unknown flag: \(arg)")
      default:
        guard inputPath == nil else { throw usage("only one input file is supported") }
        inputPath = arg
        i += 1
      }
    }

    guard let inputPath else { throw usage("missing input file") }
    return CLIArgs(inputPath: inputPath, outputPath: outputPath, libPath: libPath)
  }
}

private let helpText = """
  skitrun <input.swift> [-o <output.swift>] [--lib <lib-dir>]

  POC for issue #154 — runs a SyntaxKit DSL input file by wrapping it in a
  Group { … } closure and spawning `swift`.

  Options:
    -o, --output <file>   Write rendered Swift to <file> (default: stdout).
    --lib <dir>           Directory containing libSyntaxKit.dylib + module files.
                          (default: /tmp/syntaxkit-poc/lib, produced by
                           Docs/research/poc-step1.sh)
  """

private func usage(_ message: String) -> CLIError {
  CLIError(message: "\(message)\n\n\(helpText)\n")
}

private struct CLIError: Error, CustomStringConvertible {
  let message: String
  var description: String { message }
}

// MARK: - Wrapping

/// Splits the input into hoisted `import` declarations and a verbatim body,
/// returning a complete Swift program that runs SyntaxKit on the body.
///
/// The body is fenced in `#sourceLocation` directives so compiler diagnostics
/// in the body reference the original input file and line numbers.
internal func wrap(source: String, originalPath: String) -> String {
  let tree = Parser.parse(source: source)
  let locConverter = SourceLocationConverter(fileName: originalPath, tree: tree)

  // Find the first non-import top-level statement; everything before it that
  // is an import gets hoisted, anything before that which is *not* an import
  // stays in the body (e.g. a top-level `// comment` is left alone).
  var hoisted: [String] = []
  var firstBodyByte: AbsolutePosition?

  for item in tree.statements {
    if let importDecl = item.item.as(ImportDeclSyntax.self),
       firstBodyByte == nil {
      hoisted.append(importDecl.description.trimmingCharacters(in: .whitespacesAndNewlines))
      continue
    }
    firstBodyByte = item.position
    break
  }

  let body: String
  let firstBodyLine: Int
  if let firstBodyByte {
    let start = source.utf8.index(source.utf8.startIndex, offsetBy: firstBodyByte.utf8Offset)
    body = String(source[start...])
    firstBodyLine = locConverter.location(for: firstBodyByte).line
  } else {
    body = ""
    firstBodyLine = 1
  }

  let hoistedBlock = hoisted.isEmpty ? "" : hoisted.joined(separator: "\n") + "\n"

  // #sourceLocation must use a forward-slash path; escape backslashes/quotes
  // defensively even though macOS paths shouldn't contain them.
  let escapedPath = originalPath
    .replacingOccurrences(of: "\\", with: "\\\\")
    .replacingOccurrences(of: "\"", with: "\\\"")

  return """
    import SyntaxKit
    \(hoistedBlock)
    let __skitrun_root = Group {
    #sourceLocation(file: "\(escapedPath)", line: \(firstBodyLine))
    \(body)
    #sourceLocation()
    }

    print(__skitrun_root.generateCode())
    """
}

// MARK: - Spawning swift

private struct RunResult {
  let exitCode: Int32
  let stdout: Data
  let stderr: String
}

private func runSwift(wrappedPath: String, libPath: String) throws -> RunResult {
  let cShimsInclude = "\(libPath)/_SwiftSyntaxCShims-include"

  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = [
    "swift",
    "-suppress-warnings",
    "-I", libPath,
    "-L", libPath,
    "-lSyntaxKit",
    "-Xcc", "-I", "-Xcc", cShimsInclude,
    "-Xlinker", "-rpath", "-Xlinker", libPath,
    wrappedPath
  ]

  let stdoutPipe = Pipe()
  let stderrPipe = Pipe()
  process.standardOutput = stdoutPipe
  process.standardError = stderrPipe

  try process.run()
  process.waitUntilExit()

  let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
  let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

  return RunResult(
    exitCode: process.terminationStatus,
    stdout: stdoutData,
    stderr: String(decoding: stderrData, as: UTF8.self)
  )
}
