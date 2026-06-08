//
//  Runner+Directory.swift
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

extension Runner {
  /// Walks `inputDir` for `.swift` inputs, processes them concurrently (up to
  /// the active core count), and mirrors the rendered output into `outputDir`.
  /// A failure on one input does not abort the batch — successful peers are
  /// still written. Returns 0 if every input succeeded, 1 otherwise.
  internal func runDirectory(inputDir: String, outputDir: String) async -> Int32 {
    let inputURL = URL(fileURLWithPath: inputDir).standardizedFileURL
    let outputURL = URL(fileURLWithPath: outputDir).standardizedFileURL

    // Phase 1: enumerate inputs.
    let inputs: [URL]
    do {
      inputs = try Self.collectInputs(at: inputURL)
    } catch {
      FileHandle.standardError.write(Data("skit: failed to walk \(inputDir): \(error)\n".utf8))
      return 1
    }

    if inputs.isEmpty {
      FileHandle.standardError.write(Data("skit: no .swift inputs under \(inputDir)\n".utf8))
      return 0
    }

    // Phase 2: bounded-concurrency processing. Cap is the active core count
    // so a 200-file batch doesn't fork 200 simultaneous `swift` processes.
    let maxConcurrent = max(1, ProcessInfo.processInfo.activeProcessorCount)

    var outcomes: [FileOutcome] = []
    var iterator = inputs.makeIterator()

    await withTaskGroup(of: FileOutcome.self) { group in
      // Seed the group up to the concurrency cap…
      for _ in 0..<maxConcurrent {
        guard let next = iterator.next() else { break }
        group.addTask { await self.runOne(next) }
      }
      // …then refill one task for every completion until inputs are exhausted.
      for await outcome in group {
        outcomes.append(outcome)
        if let next = iterator.next() {
          group.addTask { await self.runOne(next) }
        }
      }
    }

    // Phase 3: write outputs and surface diagnostics. Successes are always
    // written, even when other files in the batch failed (Tuist-analog batch
    // semantics).
    var failed = 0
    for outcome in outcomes {
      let relative = outcome.input.path.dropFirst(inputURL.path.count + 1)
      let destination = outputURL.appendingPathComponent(String(relative))

      switch outcome.result {
      case .failure(let error):
        failed += 1
        FileHandle.standardError.write(Data("\(outcome.input.path): \(error)\n".utf8))
      case .success(let processResult):
        // Per-input stderr is fenced with a header so the batch log stays
        // readable when several files emit diagnostics.
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

    // Phase 4: one-line batch summary + overall exit code.
    FileHandle.standardError.write(
      Data(
        "skit: \(outcomes.count - failed)/\(outcomes.count) succeeded\n".utf8
      ))

    return failed == 0 ? 0 : 1
  }

  /// `processFile` adapter that catches errors into the `FileOutcome` result
  /// so a single failure doesn't tear down the surrounding `TaskGroup`.
  private func runOne(_ input: URL) async -> FileOutcome {
    do {
      let result = try await processFile(inputPath: input.path)
      return FileOutcome(input: input, result: .success(result))
    } catch {
      return FileOutcome(input: input, result: .failure(error))
    }
  }

  /// Returns every `.swift` file under `inputDir` (recursive), sorted, with
  /// hidden files and files prefixed by `_` removed. Sorted output keeps
  /// batch behaviour deterministic across runs.
  private static func collectInputs(at inputDir: URL) throws -> [URL] {
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
      // Directories aren't outputs.
      if values.isDirectory == true { continue }
      // Filter for `.swift` regular files, skipping the `_`-prefixed
      // convention for "not an input" sources.
      guard values.isRegularFile == true else { continue }
      guard url.pathExtension == "swift" else { continue }
      guard !url.lastPathComponent.hasPrefix("_") else { continue }
      result.append(url.standardizedFileURL)
    }
    return result.sorted { $0.path < $1.path }
  }
}
