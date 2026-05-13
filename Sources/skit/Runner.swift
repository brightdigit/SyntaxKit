//
//  Runner.swift
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
  import SwiftParser
  import SwiftSyntax

  // MARK: - Helpers resolution

  internal enum HelpersOptions {
    case auto
    case disabled
    case explicit(String)
  }

  internal func resolveHelpers(
    nearInputPath path: String,
    libPath: String,
    options: HelpersOptions
  ) async throws -> CompiledHelpers? {
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

    guard let compiled = try await buildHelpers(helpersDir: helpersDir, libPath: libPath) else {
      return nil
    }
    let suffix = compiled.cacheHit ? "cached" : "compiled"
    FileHandle.standardError.write(
      Data(
        "skit: helpers \(suffix) at \(helpersDir.path)\n".utf8
      ))
    return compiled
  }

  // MARK: - Resource location

  /// Resolves the directory containing `libSyntaxKit.dylib` + module files,
  /// in priority order: explicit flag → env var → adjacent-to-binary
  /// (`<bin-dir>/lib/`) → Homebrew layout (`<bin-dir>/../lib/skit/`).
  internal func resolveLibPath(override: String?) throws -> String {
    if let override {
      guard isLibDir(override) else {
        throw CLIError(message: "--lib path does not look like a SyntaxKit lib dir: \(override)")
      }
      return override
    }

    if let env = ProcessInfo.processInfo.environment["SKIT_LIB_DIR"], !env.isEmpty {
      guard isLibDir(env) else {
        throw CLIError(message: "SKIT_LIB_DIR is set but path is not a lib dir: \(env)")
      }
      return env
    }

    if let execURL = Bundle.main.executableURL?.resolvingSymlinksInPath() {
      let execDir = execURL.deletingLastPathComponent()

      let adjacent = execDir.appendingPathComponent("lib").path
      if isLibDir(adjacent) { return adjacent }

      let brewLayout = execDir.deletingLastPathComponent()
        .appendingPathComponent("lib/skit").path
      if isLibDir(brewLayout) { return brewLayout }
    }

    throw CLIError(
      message: """
        Could not locate SyntaxKit lib directory. Looked for:
          1. --lib <dir>           (not provided)
          2. $SKIT_LIB_DIR         (not set)
          3. <binary-dir>/lib/     (not found)
          4. <binary-dir>/../lib/skit/  (not found)
        Run Scripts/build-skit-release.sh to produce a self-contained
        release bundle under .build/skit-release/.
        """)
  }

  private func isLibDir(_ path: String) -> Bool {
    let fm = FileManager.default
    var isDir: ObjCBool = false
    guard fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else { return false }
    return fm.fileExists(atPath: "\(path)/\(dylibFilename(forLibrary: "SyntaxKit"))")
  }

  // MARK: - Toolchain check

  /// Filename for the bundle's recorded build-toolchain version.
  internal let toolchainStampFilename = "swift-version.txt"

  internal enum ToolchainCheckResult {
    /// Bundle stamp matches the local `swift --version` exactly.
    case match
    /// `<libPath>/swift-version.txt` is missing (older bundle that predates
    /// the stamp). skit prints a one-line note and proceeds.
    case stampMissing
    case mismatch(bundle: String, local: String)
  }

  /// Compares `<libPath>/swift-version.txt` to `captureSwiftVersion()`.
  /// The swiftmodule format isn't reliably forward-compatible across even
  /// patch-level Swift releases (originating bug: 6.3.0 → 6.3.2 rejected the
  /// swiftmodule), so the comparison is exact-string after normalising
  /// trailing whitespace.
  internal func toolchainCheck(libPath: String) async -> ToolchainCheckResult {
    let stampURL = URL(fileURLWithPath: libPath).appendingPathComponent(toolchainStampFilename)
    guard let stampData = try? Data(contentsOf: stampURL),
      let stampRaw = String(data: stampData, encoding: .utf8)
    else {
      FileHandle.standardError.write(
        Data("skit: bundle has no toolchain stamp; skipping check\n".utf8)
      )
      return .stampMissing
    }
    guard let localRaw = await captureSwiftVersion() else {
      FileHandle.standardError.write(
        Data("skit: could not capture local `swift --version`; skipping toolchain check\n".utf8)
      )
      return .stampMissing
    }
    let bundle = stampRaw.trimmingCharacters(in: .whitespacesAndNewlines)
    let local = localRaw.trimmingCharacters(in: .whitespacesAndNewlines)
    return bundle == local ? .match : .mismatch(bundle: bundle, local: local)
  }

  internal func toolchainMismatchMessage(bundle: String, local: String) -> String {
    """
    skit: toolchain mismatch
      bundle: \(bundle)
      local:  \(local)
    The bundle's libSyntaxKit was built against a different `swift` than the
    one on your PATH. Swift swiftmodules aren't reliably compatible across
    versions, so spawning `swift` would fail with a cryptic module-version
    diagnostic.

    Rebuild the bundle with:
      Scripts/build-skit-release.sh
    Or pass --no-toolchain-check to try anyway.

    """
  }

  // MARK: - Single-file mode

  internal func runSingleFile(
    inputPath: String,
    outputPath: String?,
    libPath: String,
    helpers: CompiledHelpers?,
    useCache: Bool,
    timeoutSeconds: Int
  ) async throws {
    let result = try await processFile(
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

  internal func runDirectory(
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
      FileHandle.standardError.write(Data("skit: failed to walk \(inputDir): \(error)\n".utf8))
      return 1
    }

    if inputs.isEmpty {
      FileHandle.standardError.write(Data("skit: no .swift inputs under \(inputDir)\n".utf8))
      return 0
    }

    let maxConcurrent = max(1, ProcessInfo.processInfo.activeProcessorCount)

    var outcomes: [FileOutcome] = []
    var iterator = inputs.makeIterator()

    await withTaskGroup(of: FileOutcome.self) { group in
      for _ in 0..<maxConcurrent {
        guard let next = iterator.next() else { break }
        group.addTask {
          await runOne(
            next, libPath: libPath, helpers: helpers,
            useCache: useCache, timeoutSeconds: timeoutSeconds
          )
        }
      }
      for await outcome in group {
        outcomes.append(outcome)
        if let next = iterator.next() {
          group.addTask {
            await runOne(
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
        "skit: \(outcomes.count - failed)/\(outcomes.count) succeeded\n".utf8
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
  ) async -> FileOutcome {
    do {
      let result = try await processFile(
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

  private struct ProcessResult: Sendable {
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
  ) async throws -> ProcessResult {
    let inputURL = URL(fileURLWithPath: inputPath).standardizedFileURL
    let absoluteInputPath = inputURL.path
    let source = try String(contentsOf: inputURL, encoding: .utf8)

    let cacheKey: String? =
      useCache
      ? await outputCacheKey(inputSource: source, helpers: helpers, libPath: libPath)
      : nil
    if let cacheKey, let cached = lookupCachedOutput(key: cacheKey) {
      return ProcessResult(exitCode: 0, stdout: cached, stderr: "")
    }

    let wrapped = wrap(source: source, originalPath: absoluteInputPath)

    let tmpDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("skit-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmpDir) }

    let wrappedURL = tmpDir.appendingPathComponent("Input.wrapped.swift")
    try wrapped.write(to: wrappedURL, atomically: true, encoding: .utf8)

    let raw = try await runSwift(
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
      let __skit_root = Group {
      #sourceLocation(file: "\(escapedPath)", line: \(firstBodyLine))
      \(body)
      #sourceLocation()
      }

      print(__skit_root.generateCode())
      """
  }

  // MARK: - Spawning swift

  /// Exit code returned when the spawned `swift` is killed by skit's timeout
  /// watchdog. Matches POSIX `timeout(1)`.
  private let timeoutExitCode: Int32 = 124

  /// Bounded output capacity for the spawned `swift` (16 MiB). Generated DSL
  /// output above this size is exotic; if we ever hit it we'll see a clear
  /// SubprocessError rather than a silent truncation.
  private let stdoutLimitBytes: Int = 16 * 1_024 * 1_024
  private let stderrLimitBytes: Int = 1 * 1_024 * 1_024

  private enum SwiftRunOutcome: Sendable {
    case completed(exitCode: Int32, stdout: Data, stderr: String)
    case timedOut
  }

  private func runSwift(
    wrappedPath: String,
    libPath: String,
    helpers: CompiledHelpers?,
    timeoutSeconds: Int
  ) async throws -> ProcessResult {
    let cShimsInclude = "\(libPath)/_SwiftSyntaxCShims-include"

    var arguments: [String] = [
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
    let argumentsCopy = arguments

    let invocation: @Sendable () async throws -> SwiftRunOutcome = {
      let record = try await run(
        .name("swift"),
        arguments: Arguments(argumentsCopy),
        output: .string(limit: stdoutLimitBytes),
        error: .string(limit: stderrLimitBytes)
      )
      return .completed(
        exitCode: exitCode(from: record.terminationStatus),
        stdout: Data((record.standardOutput ?? "").utf8),
        stderr: record.standardError ?? ""
      )
    }

    let outcome: SwiftRunOutcome
    if timeoutSeconds <= 0 {
      outcome = try await invocation()
    } else {
      outcome = try await withThrowingTaskGroup(of: SwiftRunOutcome.self) { group in
        group.addTask { try await invocation() }
        group.addTask {
          try await Task.sleep(for: .seconds(timeoutSeconds))
          return .timedOut
        }
        let first = try await group.next()!
        group.cancelAll()
        return first
      }
    }

    switch outcome {
    case .completed(let exitCode, let stdout, let stderr):
      return ProcessResult(exitCode: exitCode, stdout: stdout, stderr: stderr)
    case .timedOut:
      return ProcessResult(
        exitCode: timeoutExitCode,
        stdout: Data(),
        stderr: "skit: timed out after \(timeoutSeconds)s\n"
      )
    }
  }

  private func exitCode(from status: TerminationStatus) -> Int32 {
    switch status {
    case .exited(let code):
      return Int32(truncatingIfNeeded: code)
    #if !os(Windows)
      case .signaled(let signal):
        // Match shell convention: 128 + signal number.
        return 128 + Int32(truncatingIfNeeded: signal)
    #endif
    }
  }

#endif
