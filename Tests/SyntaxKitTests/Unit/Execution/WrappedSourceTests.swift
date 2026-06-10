//
//  WrappedSourceTests.swift
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
import Testing

@testable import SyntaxKit

@Suite internal struct WrappedSourceTests {
  private static let path = "/tmp/input.swift"

  private func rendered(_ source: String) -> String {
    WrappedSource(source: source, originalPath: Self.path).rendered
  }

  /// The wrapper always opens with the SyntaxKit import and emits the
  /// `Group { … }` + `print(...)` scaffold, regardless of input.
  private func expectScaffold(_ rendered: String) {
    #expect(rendered.contains("import SyntaxKit"))
    #expect(rendered.contains("let __skit_root = Group {"))
    #expect(rendered.contains("print(__skit_root.generateCode())"))
    #expect(rendered.contains("#sourceLocation(file: \"\(Self.path)\""))
  }

  @Test("No-import source is left in the body, starting at line 1")
  internal func noImports() {
    let out = rendered("Struct(\"Foo\") {}")
    expectScaffold(out)
    #expect(out.contains("Struct(\"Foo\") {}"))
    #expect(out.contains("#sourceLocation(file: \"\(Self.path)\", line: 1)"))
  }

  @Test("Leading imports are hoisted above the wrapper body")
  internal func importsOnly() {
    let out = rendered("import Foundation\nimport SwiftSyntax\n")
    expectScaffold(out)
    #expect(out.contains("import Foundation"))
    #expect(out.contains("import SwiftSyntax"))
    // Imports-only input has no body, so the fence starts at line 1.
    #expect(out.contains("#sourceLocation(file: \"\(Self.path)\", line: 1)"))
  }

  @Test("Imports are hoisted and the body fence reports the body's line")
  internal func mixedImportsAndBody() {
    let out = rendered("import Foundation\nlet x = 1\n")
    expectScaffold(out)
    #expect(out.contains("import Foundation"))
    #expect(out.contains("let x = 1"))
    // The body slice starts at the newline that is leading trivia of `let`, so
    // the fence reports line 1 and the retained leading newline keeps `let x = 1`
    // aligned to its original line 2.
    #expect(out.contains("#sourceLocation(file: \"\(Self.path)\", line: 1)"))

    // The hoisted import must sit ahead of the `Group {` scaffold, not inside it.
    let importIndex = try? #require(out.range(of: "import Foundation"))
    let groupIndex = try? #require(out.range(of: "let __skit_root = Group {"))
    if let importIndex, let groupIndex {
      #expect(importIndex.lowerBound < groupIndex.lowerBound)
    }
  }

  @Test("A comment before a non-import statement stays in the body")
  internal func leadingCommentBeforeBody() {
    let out = rendered("// note\nlet x = 1\n")
    expectScaffold(out)
    // The comment is leading trivia of the first (non-import) statement, so the
    // body slice — and thus the rendered output — retains it.
    #expect(out.contains("// note"))
    #expect(out.contains("let x = 1"))
    #expect(out.contains("#sourceLocation(file: \"\(Self.path)\", line: 1)"))
  }

  @Test("Empty source still renders the scaffold")
  internal func emptySource() {
    let out = rendered("")
    expectScaffold(out)
    #expect(out.contains("#sourceLocation(file: \"\(Self.path)\", line: 1)"))
  }

  @Test("Backslashes and quotes in the path are escaped in #sourceLocation")
  internal func escapesPathSpecials() {
    // A path with a literal quote and backslash would otherwise produce a
    // syntactically invalid #sourceLocation string literal.
    let out = WrappedSource(
      source: "Struct(\"Foo\") {}",
      originalPath: #"/tmp/a"b\c.swift"#
    ).rendered
    // " → \" and \ → \\, so the rendered fence carries the escaped form.
    #expect(out.contains(#"#sourceLocation(file: "/tmp/a\"b\\c.swift""#))
  }
}
