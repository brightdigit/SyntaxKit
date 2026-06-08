//
//  WrappedSource.swift
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

/// A SyntaxKit DSL input split into hoisted `import` declarations and a verbatim
/// body, ready to be `rendered` into a complete Swift program that runs SyntaxKit
/// on the body.
///
/// The body is fenced in `#sourceLocation` directives so compiler diagnostics in
/// the body reference the original input file and line numbers.
internal struct WrappedSource {
  /// The original input path, used for the `#sourceLocation` directive.
  private let originalPath: String
  /// Top-level `import` declarations hoisted above the wrapper body, each already
  /// trimmed of surrounding whitespace.
  private let hoistedImports: [String]
  /// The input source from the first non-import byte onward, verbatim.
  private let body: String
  /// The 1-based line number the body starts on in the original file.
  private let firstBodyLine: Int

  /// Parses `source`, hoisting leading `import` declarations and capturing the
  /// remaining body along with the line it begins on. Everything before the first
  /// non-import statement that *is* an import gets hoisted; anything before that
  /// which is *not* an import stays in the body (e.g. a leading `// comment`).
  internal init(source: String, originalPath: String) {
    self.originalPath = originalPath

    // Parse the input with SwiftSyntax. The location converter is needed to
    // map the body's starting byte offset back to a 1-based line number for
    // the `#sourceLocation` directive.
    let tree = Parser.parse(source: source)
    let locConverter = SourceLocationConverter(fileName: originalPath, tree: tree)

    // Scan top-level statements for hoistable imports.
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

    self.hoistedImports = hoisted

    // Compute the body slice (source from the first non-import byte onward)
    // and the 1-based line number it lives on in the original file.
    if let firstBodyByte {
      let start = source.utf8.index(source.utf8.startIndex, offsetBy: firstBodyByte.utf8Offset)
      self.body = String(source[start...])
      self.firstBodyLine = locConverter.location(for: firstBodyByte).line
    } else {
      self.body = ""
      self.firstBodyLine = 1
    }
  }

  /// A complete Swift program that imports SyntaxKit, runs the body inside a
  /// `Group { … }` builder, and prints the generated code.
  internal var rendered: String {
    // Render the hoisted-imports block. Trailing newline only if non-empty so
    // the wrapper doesn't grow an extra blank line in the common no-imports
    // case.
    let hoistedBlock = hoistedImports.isEmpty ? "" : hoistedImports.joined(separator: "\n") + "\n"

    // #sourceLocation must use a forward-slash path; escape backslashes/quotes
    // defensively even though macOS paths shouldn't contain them.
    let escapedPath =
      originalPath
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")

    // Build the final wrapper. Layout: SyntaxKit import → hoisted imports →
    // Group { #sourceLocation(...) <body> #sourceLocation() } → print.
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
}
