//
//  RunInput.swift
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

  /// Whether an input path resolves to a single `.swift` file or a directory
  /// of them — the two modes a `Runner` caller dispatches into. Built by
  /// `resolve(input:output:)`, which stats the path and enforces the per-mode
  /// output rules so the caller can `switch` on a settled value instead of
  /// juggling an `ObjCBool`.
  package enum RunInput {
    /// A single input file. `outputPath` is whatever the caller intends to
    /// do with the rendered bytes (write to a file, ignore, etc.); `Runner`
    /// itself does not act on it.
    case singleFile(inputPath: String, outputPath: String?)
    /// A directory of inputs mirrored into `outputDir` (always required).
    case directory(inputDir: String, outputDir: String)

    /// Classifies `input` by stat: existing directory → `.directory`,
    /// existing file → `.singleFile`. Throws `RunError.invalidInput` if the path
    /// doesn't exist, or if a directory input wasn't given an explicit output.
    package static func resolve(input: String, output: String?) throws(RunError) -> RunInput {
      var isDirectory: ObjCBool = false
      guard FileManager.default.fileExists(atPath: input, isDirectory: &isDirectory) else {
        throw RunError.invalidInput("input does not exist: \(input)")
      }
      if isDirectory.boolValue {
        guard let output else {
          throw RunError.invalidInput("directory inputs require -o <output-dir>")
        }
        return .directory(inputDir: input, outputDir: output)
      }
      return .singleFile(inputPath: input, outputPath: output)
    }
  }

#endif
