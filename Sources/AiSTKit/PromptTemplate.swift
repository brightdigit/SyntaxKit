//
//  PromptTemplate.swift
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

/// Builds the prompts sent to the Claude API by the `skit analyze` subcommand.
///
/// The template combines an analysis section — asking Claude to compare the
/// current SyntaxKit library against an expected Swift output, its syntax
/// tree, and a DSL sample — with code-generation instructions requesting
/// complete, compilable source files marked with XML-style
/// `<file path="...">` blocks.
public enum PromptTemplate {
  /// Opening section stating the role and the two-part task.
  private static let taskDescription = """
    You are an expert Swift developer extending SyntaxKit, a Swift package providing a
    declarative, result-builder-based DSL for generating Swift source code on top of
    Apple's SwiftSyntax. Your task has two parts: first analyze why the current library
    cannot generate a target piece of Swift code from a given DSL sample, then implement
    the missing functionality as complete, compilable Swift source files.
    """

  /// Instructions for the structured analysis that precedes code generation.
  private static let analysisInstructions = """
    First, work through the analysis inside <analysis> tags:

    <analysis>
    1. Walk the DSL code construct by construct. For each construct, check whether the
      library already provides it (type, initializer, modifier method, or
      result-builder support) with exactly the names, labels, and argument types the
      DSL uses.
    2. For each missing or mismatched construct, identify the SwiftSyntax nodes in the
      syntax tree that it must produce.
    3. Decide how each gap should be implemented in terms of the library's existing
      architecture: conform new types to `CodeBlock`, reuse `PatternConvertible` and
      `TypeRepresentable` where patterns or types are involved, and extend the
      existing result builders rather than inventing parallel mechanisms.
    4. Determine the minimal set of files to create or modify, and where each belongs
      in the source layout (Declarations/, Expressions/, Functions/, Variables/,
      ControlFlow/, Collections/, Parameters/, Patterns/, Utilities/, ErrorHandling/).
    </analysis>

    Then write a concise summary of the required changes as plain text: what you are
    adding or modifying, where, and why the DSL needs it. Do not wrap the summary in
    any tags or code fences.
    """

  /// The strict output contract for the generated implementation files.
  private static let outputRules = """
    Finally, emit the implementation. Strict output rules:

    - Emit one block per created or modified file, in exactly this form:
      <file path="Declarations/Subscript.swift">
      // complete Swift source
      </file>
    - The path is relative to the SyntaxKit sources root.
    - Every block must contain the COMPLETE file content. Never emit diffs, fragments,
      placeholders, or elisions such as "// rest of file unchanged". For a modified
      file, reproduce the entire file with your changes applied.
    - Do not wrap file blocks in markdown code fences, and do not put any text between
      or after them.
    - Every file must compile: the whole library must build with `swift build` under
      Swift 6.1 with SwiftSyntax 601. Include all imports each file needs. Do not
      reference symbols you have not defined or that do not exist in the library.
    - Define exactly one type (or one extension) per file, in a file named after it.
    - Match the existing code style: two-space indentation, explicit access control on
      every declaration, documentation comments on public API, no global functions or
      variables, no force unwrapping.
    """

  /// Creates the combined analysis and code-generation prompt for one
  /// `skit analyze` run.
  ///
  /// - Parameters:
  ///   - syntaxKitLibrary: Concatenated source of the current SyntaxKit library.
  ///   - expectedSwift: The Swift code the DSL is expected to generate.
  ///   - swiftAST: Syntax tree of `expectedSwift` as JSON, produced by SyntaxParser.
  ///   - swiftDSL: The DSL code that should generate `expectedSwift`.
  /// - Returns: The full prompt to send as a single user message to the Claude API.
  public static func createAnalysisAndCodeGeneration(
    syntaxKitLibrary: String,
    expectedSwift: String,
    swiftAST: String,
    swiftDSL: String
  ) -> String {
    [
      Self.taskDescription,
      Self.inputsSection(
        syntaxKitLibrary: syntaxKitLibrary,
        expectedSwift: expectedSwift,
        swiftAST: swiftAST,
        swiftDSL: swiftDSL
      ),
      Self.analysisInstructions,
      Self.outputRules,
    ].joined(separator: "\n\n")
  }

  /// Wraps the four inputs in the XML tags the analysis instructions refer to.
  private static func inputsSection(
    syntaxKitLibrary: String,
    expectedSwift: String,
    swiftAST: String,
    swiftDSL: String
  ) -> String {
    """
    Here are your inputs:

    The current SyntaxKit library sources:
    <syntaxkit_library>
    \(syntaxKitLibrary)
    </syntaxkit_library>

    The exact Swift code the DSL must generate:
    <swift_code>
    \(expectedSwift)
    </swift_code>

    The syntax tree of that Swift code (JSON, produced by SwiftParser):
    <swift_ast>
    \(swiftAST)
    </swift_ast>

    The DSL code that must generate the Swift code above:
    <swift_dsl>
    \(swiftDSL)
    </swift_dsl>
    """
  }
}
