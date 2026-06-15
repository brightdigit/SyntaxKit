//
//  AnalyzerError.swift
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

/// Errors thrown by the `skit analyze` pipeline. Each case carries a
/// human-readable message; the subcommand decides how to present it.
public enum AnalyzerError: Error {
  /// Required command-line arguments were not provided.
  case missingRequiredArguments(String)
  /// No API key was provided via flag or the `ANTHROPIC_API_KEY`
  /// environment variable.
  case missingAPIKey(String)
  /// The input or SyntaxKit path does not exist.
  case invalidPath(String)
  /// A required input file (`dsl.swift`, `expected.swift`) was not found
  /// in the input folder.
  case missingInputFile(String)
  /// Generating the AST from the input sources failed.
  case astGenerationError(String)
  /// The Claude API call failed (network, authentication, rate limit, …).
  case apiError(String)
  /// Parsing the generated code out of Claude's response failed.
  case codeGenerationError(String)
}
