//
//  Main.swift
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

import Foundation
import SwiftParser
import SwiftSyntax

@main
internal enum SkitRun {
  internal static func main() async throws {
    let args: CLIArgs
    do {
      args = try CLIArgs.parse(CommandLine.arguments)
    } catch {
      FileHandle.standardError.write(Data("\(error)\n".utf8))
      exit(2)
    }

    let libPath: String
    do {
      libPath = try resolveLibPath(override: args.libPath)
    } catch {
      FileHandle.standardError.write(Data("\(error)\n".utf8))
      exit(2)
    }

    switch args.mode {
    case .singleFile(let input, let output):
      let helpers = try resolveHelpers(
        nearInputPath: input,
        libPath: libPath,
        options: args.helpers
      )
      try runSingleFile(
        inputPath: input,
        outputPath: output,
        libPath: libPath,
        helpers: helpers,
        useCache: args.useCache,
        timeoutSeconds: args.timeoutSeconds
      )
    case .directory(let inputDir, let outputDir):
      let helpers = try resolveHelpers(
        nearInputPath: inputDir,
        libPath: libPath,
        options: args.helpers
      )
      let exitCode = await runDirectory(
        inputDir: inputDir,
        outputDir: outputDir,
        libPath: libPath,
        helpers: helpers,
        useCache: args.useCache,
        timeoutSeconds: args.timeoutSeconds
      )
      exit(exitCode)
    }
  }
}

// MARK: - Helpers resolution

private func resolveHelpers(
  nearInputPath path: String,
  libPath: String,
  options: HelpersOptions
) throws -> CompiledHelpers? {
  let helpersDir: URL?
  switch options {
  case .disabled:
    return nil
  case .auto:
    helpersDir = discoverHelpersDir(near: URL(fileURLWithPath: path).standardizedFileURL)
  case .explicit(let dir):
    let url = URL(fileURLWithPath: dir).standardizedFileURL
    var isDir: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir),
      isDir.boolValue
    else {
      throw CLIError(message: "--helpers path is not a directory: \(dir)")
    }
    helpersDir = url
  }
  guard let helpersDir else { return nil }

  guard let compiled = try buildHelpers(helpersDir: helpersDir, libPath: libPath) else {
    return nil
  }
  let suffix = compiled.cacheHit ? "cached" : "compiled"
  FileHandle.standardError.write(
    Data(
      "skitrun: helpers \(suffix) at \(helpersDir.path)\n".utf8
    ))
  return compiled
}

// MARK: - Resource location

/// Resolves the directory containing `libSyntaxKit.dylib` + module files,
/// in priority order: explicit flag → env var → adjacent-to-binary
/// (`<bin-dir>/lib/`) → Homebrew layout (`<bin-dir>/../lib/skitrun/`).
internal func resolveLibPath(override: String?) throws -> String {
  if let override {
    guard isLibDir(override) else {
      throw CLIError(message: "--lib path does not look like a SyntaxKit lib dir: \(override)")
    }
    return override
  }

  if let env = ProcessInfo.processInfo.environment["SKITRUN_LIB_DIR"], !env.isEmpty {
    guard isLibDir(env) else {
      throw CLIError(message: "SKITRUN_LIB_DIR is set but path is not a lib dir: \(env)")
    }
    return env
  }

  if let execURL = Bundle.main.executableURL?.resolvingSymlinksInPath() {
    let execDir = execURL.deletingLastPathComponent()

    let adjacent = execDir.appendingPathComponent("lib").path
    if isLibDir(adjacent) { return adjacent }

    let brewLayout = execDir.deletingLastPathComponent()
      .appendingPathComponent("lib/skitrun").path
    if isLibDir(brewLayout) { return brewLayout }
  }

  throw CLIError(
    message: """
      Could not locate SyntaxKit lib directory. Looked for:
        1. --lib <dir>           (not provided)
        2. $SKITRUN_LIB_DIR       (not set)
        3. <binary-dir>/lib/      (not found)
        4. <binary-dir>/../lib/skitrun/  (not found)
      Run Docs/research/poc-step4-release.sh to produce a self-contained
      release bundle under .build/skitrun-release/.
      """)
}

private func isLibDir(_ path: String) -> Bool {
  let fm = FileManager.default
  var isDir: ObjCBool = false
  guard fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else { return false }
  return fm.fileExists(atPath: "\(path)/\(dylibFilename(forLibrary: "SyntaxKit"))")
}

// MARK: - Single-file mode

private func runSingleFile(
  inputPath: String,
  outputPath: String?,
  libPath: String,
  helpers: CompiledHelpers?,
  useCache: Bool,
  timeoutSeconds: Int
) throws {
  let result = try processFile(
    inputPath: inputPath,
    libPath: libPath,
    helpers: helpers,
    useCache: useCache,
    timeoutSeconds: timeoutSeconds
  )
  if !result.stderr.isEmpty {
    FileHandle.standardError.write(Data(result.stderr.utf8))
  }
  guard result.exitCode == 0 else {
    exit(result.exitCode)
  }
  if let outputPath {
    try result.stdout.write(to: URL(fileURLWithPath: outputPath))
  } else {
    FileHandle.standardOutput.write(result.stdout)
  }
}

// MARK: - Folder mode

private func runDirectory(
  inputDir: String,
  outputDir: String,
  libPath: String,
  helpers: CompiledHelpers?,
  useCache: Bool,
  timeoutSeconds: Int
) async -> Int32 {
  let inputURL = URL(fileURLWithPath: inputDir).standardizedFileURL
  let outputURL = URL(fileURLWithPath: outputDir).standardizedFileURL

  let inputs: [URL]
  do {
    inputs = try collectInputs(at: inputURL, excluding: helpersExcludePath(inputDir: inputURL))
  } catch {
    FileHandle.standardError.write(Data("skitrun: failed to walk \(inputDir): \(error)\n".utf8))
    return 1
  }

  if inputs.isEmpty {
    FileHandle.standardError.write(Data("skitrun: no .swift inputs under \(inputDir)\n".utf8))
    return 0
  }

  let maxConcurrent = max(1, ProcessInfo.processInfo.activeProcessorCount)

  var outcomes: [FileOutcome] = []
  var iterator = inputs.makeIterator()

  await withTaskGroup(of: FileOutcome.self) { group in
    for _ in 0..<maxConcurrent {
      guard let next = iterator.next() else { break }
      group.addTask {
        runOne(
          next, libPath: libPath, helpers: helpers,
          useCache: useCache, timeoutSeconds: timeoutSeconds
        )
      }
    }
    for await outcome in group {
      outcomes.append(outcome)
      if let next = iterator.next() {
        group.addTask {
        runOne(
          next, libPath: libPath, helpers: helpers,
          useCache: useCache, timeoutSeconds: timeoutSeconds
        )
      }
      }
    }
  }

  // Write outputs and surface diagnostics. Successes are always written, even
  // when other files in the batch failed (Tuist-analog batch semantics).
  var failed = 0
  for outcome in outcomes {
    let relative = outcome.input.path.dropFirst(inputURL.path.count + 1)
    let destination = outputURL.appendingPathComponent(String(relative))

    switch outcome.result {
    case .failure(let error):
      failed += 1
      FileHandle.standardError.write(Data("\(outcome.input.path): \(error)\n".utf8))
    case .success(let processResult):
      if !processResult.stderr.isEmpty {
        FileHandle.standardError.write(Data("---- \(outcome.input.path) ----\n".utf8))
        FileHandle.standardError.write(Data(processResult.stderr.utf8))
      }
      if processResult.exitCode != 0 {
        failed += 1
        continue
      }
      do {
        try FileManager.default.createDirectory(
          at: destination.deletingLastPathComponent(),
          withIntermediateDirectories: true
        )
        try processResult.stdout.write(to: destination)
      } catch {
        failed += 1
        FileHandle.standardError.write(Data("\(outcome.input.path): \(error)\n".utf8))
      }
    }
  }

  FileHandle.standardError.write(
    Data(
      "skitrun: \(outcomes.count - failed)/\(outcomes.count) succeeded\n".utf8
    ))

  return failed == 0 ? 0 : 1
}

private struct FileOutcome: Sendable {
  let input: URL
  let result: Result<ProcessResult, any Error>
}

private func runOne(
  _ input: URL,
  libPath: String,
  helpers: CompiledHelpers?,
  useCache: Bool,
  timeoutSeconds: Int
) -> FileOutcome {
  do {
    let result = try processFile(
      inputPath: input.path,
      libPath: libPath,
      helpers: helpers,
      useCache: useCache,
      timeoutSeconds: timeoutSeconds
    )
    return FileOutcome(input: input, result: .success(result))
  } catch {
    return FileOutcome(input: input, result: .failure(error))
  }
}

/// Returns the path of a `Helpers/` directory living directly under `inputDir`,
/// so the folder-mode enumerator can skip its descendants. Helpers that live
/// outside the input tree don't need to be excluded (they aren't enumerated).
private func helpersExcludePath(inputDir: URL) -> String? {
  let candidate = inputDir.appendingPathComponent("Helpers").standardizedFileURL
  var isDir: ObjCBool = false
  guard FileManager.default.fileExists(atPath: candidate.path, isDirectory: &isDir),
    isDir.boolValue
  else {
    return nil
  }
  return candidate.path
}

private func collectInputs(at inputDir: URL, excluding excludedDir: String?) throws -> [URL] {
  guard
    let enumerator = FileManager.default.enumerator(
      at: inputDir,
      includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
      options: [.skipsHiddenFiles]
    )
  else {
    throw CLIError(message: "could not enumerate \(inputDir.path)")
  }

  var result: [URL] = []
  for case let url as URL in enumerator {
    let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
    if values.isDirectory == true {
      if let excludedDir, url.standardizedFileURL.path == excludedDir {
        enumerator.skipDescendants()
      }
      continue
    }
    guard values.isRegularFile == true else { continue }
    guard url.pathExtension == "swift" else { continue }
    guard !url.lastPathComponent.hasPrefix("_") else { continue }
    result.append(url.standardizedFileURL)
  }
  return result.sorted { $0.path < $1.path }
}

// MARK: - Per-file work

private struct ProcessResult {
  let exitCode: Int32
  let stdout: Data
  let stderr: String
}

private func processFile(
  inputPath: String,
  libPath: String,
  helpers: CompiledHelpers?,
  useCache: Bool,
  timeoutSeconds: Int
) throws -> ProcessResult {
  let inputURL = URL(fileURLWithPath: inputPath).standardizedFileURL
  let absoluteInputPath = inputURL.path
  let source = try String(contentsOf: inputURL, encoding: .utf8)

  let cacheKey: String? =
    useCache
    ? outputCacheKey(inputSource: source, helpers: helpers, libPath: libPath)
    : nil
  if let cacheKey, let cached = lookupCachedOutput(key: cacheKey) {
    return ProcessResult(exitCode: 0, stdout: cached, stderr: "")
  }

  let wrapped = wrap(source: source, originalPath: absoluteInputPath)

  let tmpDir = FileManager.default.temporaryDirectory
    .appendingPathComponent("skitrun-\(UUID().uuidString)")
  try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tmpDir) }

  let wrappedURL = tmpDir.appendingPathComponent("Input.wrapped.swift")
  try wrapped.write(to: wrappedURL, atomically: true, encoding: .utf8)

  let raw = try runSwift(
    wrappedPath: wrappedURL.path,
    libPath: libPath,
    helpers: helpers,
    timeoutSeconds: timeoutSeconds
  )
  // #sourceLocation maps body diagnostics back to the input file. Errors in
  // the preamble (lines outside the body) still reference the wrapper —
  // rewrite literal occurrences of its path so users see something coherent.
  let stderr = raw.stderr.replacingOccurrences(
    of: wrappedURL.path,
    with: absoluteInputPath
  )

  if let cacheKey, raw.exitCode == 0 {
    try? storeCachedOutput(key: cacheKey, data: raw.stdout)
  }

  return ProcessResult(exitCode: raw.exitCode, stdout: raw.stdout, stderr: stderr)
}

// MARK: - Arg parsing

internal enum HelpersOptions {
  case auto
  case disabled
  case explicit(String)
}

private struct CLIArgs {
  enum Mode {
    case singleFile(input: String, output: String?)
    case directory(input: String, output: String)
  }

  let mode: Mode
  let libPath: String?
  let helpers: HelpersOptions
  let useCache: Bool
  let timeoutSeconds: Int

  static let defaultTimeoutSeconds = 60

  static func parse(_ argv: [String]) throws -> CLIArgs {
    var inputPath: String?
    var outputPath: String?
    var libPath: String?
    var helpers: HelpersOptions = .auto
    var useCache = true
    var timeoutSeconds = defaultTimeoutSeconds

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
      case "--helpers":
        guard i + 1 < argv.count else { throw usage("--helpers requires a value") }
        helpers = .explicit(argv[i + 1])
        i += 2
      case "--no-helpers":
        helpers = .disabled
        i += 1
      case "--no-cache":
        useCache = false
        i += 1
      case "--timeout":
        guard i + 1 < argv.count else { throw usage("--timeout requires a value") }
        guard let parsed = Int(argv[i + 1]), parsed >= 0 else {
          throw usage("--timeout expects a non-negative integer (seconds), got: \(argv[i + 1])")
        }
        timeoutSeconds = parsed
        i += 2
      case "-h", "--help":
        FileHandle.standardError.write(Data(helpText.utf8))
        exit(0)
      case _ where arg.hasPrefix("-"):
        throw usage("unknown flag: \(arg)")
      default:
        guard inputPath == nil else { throw usage("only one input path is supported") }
        inputPath = arg
        i += 1
      }
    }

    guard let inputPath else { throw usage("missing input path") }

    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: inputPath, isDirectory: &isDirectory) else {
      throw usage("input does not exist: \(inputPath)")
    }

    let mode: Mode
    if isDirectory.boolValue {
      guard let outputPath else {
        throw usage("directory inputs require -o <output-dir>")
      }
      mode = .directory(input: inputPath, output: outputPath)
    } else {
      mode = .singleFile(input: inputPath, output: outputPath)
    }

    return CLIArgs(
      mode: mode,
      libPath: libPath,
      helpers: helpers,
      useCache: useCache,
      timeoutSeconds: timeoutSeconds
    )
  }
}

private let helpText = """
  skitrun <input> [-o <output>] [--lib <lib-dir>]

  POC for issue #154 — runs SyntaxKit DSL input(s) by wrapping each in a
  Group { … } closure and spawning `swift`.

  Forms:
    skitrun Input.swift                 — render to stdout
    skitrun Input.swift -o Out.swift    — render to a file
    skitrun InputDir/ -o OutDir/        — walk **/*.swift (skipping files
                                          prefixed with '_') and mirror
                                          rendered output into OutDir/

  Options:
    -o, --output <path>   Output file (single-file mode) or directory (folder mode).
    --lib <dir>           Directory containing libSyntaxKit.dylib + module files.
                          When omitted, skitrun searches: $SKITRUN_LIB_DIR,
                          then <binary-dir>/lib/, then <binary-dir>/../lib/skitrun/.
                          Build a self-contained bundle with
                          Docs/research/poc-step4-release.sh.
    --helpers <dir>       Override Helpers/ directory location. By default,
                          skitrun walks up from the input looking for one.
                          Compiled into libSyntaxKitHelpers.dylib and made
                          importable via `import SyntaxKitHelpers`.
    --no-helpers          Skip helpers discovery entirely.
    --no-cache            Skip the rendered-output cache (always run swift).
                          The cache lives at <syntaxkit cache>/outputs/<hash>/
                          and is keyed on input bytes, helpers, swift version,
                          libSyntaxKit stamp, and SKITRUN_*/SYNTAXKIT_* env.
    --timeout <seconds>   Per-input timeout for the spawned `swift` process
                          (default 60). On expiry: SIGTERM, then SIGKILL after
                          a 5s grace; the file exits with code 124. Pass 0 to
                          disable the watchdog.
  """

private func usage(_ message: String) -> CLIError {
  CLIError(message: "\(message)\n\n\(helpText)\n")
}

internal struct CLIError: Error, CustomStringConvertible {
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
      firstBodyByte == nil
    {
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
  let escapedPath =
    originalPath
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

/// Exit code returned when the spawned `swift` is killed by skitrun's timeout
/// watchdog. Matches POSIX `timeout(1)`.
private let timeoutExitCode: Int32 = 124

/// Grace period between SIGTERM and SIGKILL when the child won't exit on its own.
private let killGraceSeconds: Int = 5

private func runSwift(
  wrappedPath: String,
  libPath: String,
  helpers: CompiledHelpers?,
  timeoutSeconds: Int
) throws -> ProcessResult {
  let cShimsInclude = "\(libPath)/_SwiftSyntaxCShims-include"

  var arguments: [String] = [
    "swift",
    "-suppress-warnings",
    "-I", libPath,
    "-L", libPath,
    "-lSyntaxKit",
    "-Xcc", "-I", "-Xcc", cShimsInclude,
    "-Xlinker", "-rpath", "-Xlinker", libPath,
  ]

  if let helpers {
    let helpersPath = helpers.outputDir.path
    arguments.append(contentsOf: [
      "-I", helpersPath,
      "-L", helpersPath,
      "-l\(helpersModuleName)",
      "-Xlinker", "-rpath", "-Xlinker", helpersPath,
    ])
  }

  arguments.append(wrappedPath)

  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = arguments

  let stdoutPipe = Pipe()
  let stderrPipe = Pipe()
  process.standardOutput = stdoutPipe
  process.standardError = stderrPipe

  // Linux Foundation's `Process.waitUntilExit()` blocks indefinitely on
  // already-exited children in some configurations; terminationHandler +
  // semaphore is the workaround.
  let exitSemaphore = DispatchSemaphore(value: 0)
  process.terminationHandler = { _ in exitSemaphore.signal() }

  try process.run()

  // Drain both pipes concurrently — reading sequentially deadlocks on Linux
  // when either pipe (~64 KB buffer) fills before the child exits. Box the
  // buffers in classes so Swift 6 strict-concurrency is satisfied without
  // `@unchecked Sendable` on local vars.
  let outBox = PipeDataBox()
  let errBox = PipeDataBox()
  let group = DispatchGroup()
  group.enter()
  DispatchQueue.global().async {
    outBox.value = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    group.leave()
  }
  group.enter()
  DispatchQueue.global().async {
    errBox.value = stderrPipe.fileHandleForReading.readDataToEndOfFile()
    group.leave()
  }

  // Timeout watchdog: wait for the child with a deadline. On expiry, send
  // SIGTERM, give a fixed grace, then SIGKILL. timeoutSeconds == 0 disables.
  let timedOut: Bool
  if timeoutSeconds > 0 {
    let deadline: DispatchTime = .now() + .seconds(timeoutSeconds)
    if exitSemaphore.wait(timeout: deadline) == .timedOut {
      process.terminate()  // SIGTERM
      if exitSemaphore.wait(timeout: .now() + .seconds(killGraceSeconds)) == .timedOut {
        kill(process.processIdentifier, SIGKILL)
        exitSemaphore.wait()
      }
      timedOut = true
    } else {
      timedOut = false
    }
  } else {
    exitSemaphore.wait()
    timedOut = false
  }
  // Child is dead now — pipes get EOF, drain completes shortly.
  group.wait()

  if timedOut {
    let prefix = Data("skitrun: timed out after \(timeoutSeconds)s\n".utf8)
    let stderr = String(decoding: prefix + errBox.value, as: UTF8.self)
    return ProcessResult(exitCode: timeoutExitCode, stdout: outBox.value, stderr: stderr)
  }

  return ProcessResult(
    exitCode: process.terminationStatus,
    stdout: outBox.value,
    stderr: String(decoding: errBox.value, as: UTF8.self)
  )
}

private final class PipeDataBox: @unchecked Sendable {
  var value = Data()
}
