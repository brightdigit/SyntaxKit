//
//  AnalyzerConfiguration.swift
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

/// Configuration for the SyntaxKit analyzer, assembled by the `skit analyze`
/// subcommand from parsed command-line arguments and handed to
/// `SyntaxKitAnalyzer`.
public struct AnalyzerConfiguration: Sendable {
  /// Folder containing `dsl.swift` and `expected.swift`.
  public let inputFolderPath: String
  /// Path to the existing SyntaxKit library sources.
  public let syntaxKitPath: String
  /// Where to write the updated library.
  public let outputFolderPath: String
  /// Claude API key.
  public let apiKey: String
  /// Claude model identifier.
  public let model: String
  /// Enables verbose progress output.
  public let verbose: Bool

  /// Creates an analyzer configuration.
  ///
  /// - Parameters:
  ///   - inputFolderPath: Folder containing `dsl.swift` and `expected.swift`.
  ///   - syntaxKitPath: Path to the existing SyntaxKit library sources.
  ///   - outputFolderPath: Where to write the updated library.
  ///   - apiKey: Claude API key.
  ///   - model: Claude model identifier.
  ///   - verbose: Enables verbose progress output.
  public init(
    inputFolderPath: String,
    syntaxKitPath: String,
    outputFolderPath: String,
    apiKey: String,
    model: String,
    verbose: Bool
  ) {
    self.inputFolderPath = inputFolderPath
    self.syntaxKitPath = syntaxKitPath
    self.outputFolderPath = outputFolderPath
    self.apiKey = apiKey
    self.model = model
    self.verbose = verbose
  }
}
