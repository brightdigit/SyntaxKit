//
//  PatternConvertibleTests.swift
//  SyntaxKitTests
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import SwiftSyntax
import Testing

@testable import SyntaxKit

internal struct PatternConvertibleTests {
  // MARK: - Let Binding Pattern Tests

  @Test internal func testLetBindingPattern() {
    let pattern = Pattern.let("x")
    let syntax = pattern.patternSyntax

    let generated = syntax.description
    #expect(generated.contains("let x"))
  }

  @Test internal func testLetBindingPatternInTuple() {
    let tuplePattern = Tuple.pattern([Pattern.let("x"), 0])
    let syntax = tuplePattern.patternSyntax

    let generated = syntax.description
    #expect(generated.contains("(let x, 0)"))
  }

  @Test internal func testLetBindingPatternInSwitchCase() {
    let switchCase = SwitchCase(Tuple.pattern([Pattern.let("x"), Pattern.let("y")])) {
      Call("print") {
        ParameterExp(name: "", value: "\"somewhere else at (\\(x), \\(y))\"")
      }
    }

    let generated = switchCase.generateCode()
    #expect(generated.contains("case (let x, let y):"))
    #expect(generated.contains("print(\"somewhere else at (\\(x), \\(y))\")"))
  }

  @Test internal func testLetBindingPatternWithSingleElement() {
    let pattern = Pattern.let("value")
    let syntax = pattern.patternSyntax

    let generated = syntax.description
    #expect(generated.contains("let value"))
  }

  @Test internal func testLetBindingPatternInComplexTuple() {
    let tuplePattern = Tuple.pattern([Pattern.let("x"), 0, Pattern.let("y")])
    let syntax = tuplePattern.patternSyntax

    let generated = syntax.description
    #expect(generated.contains("(let x, 0, let y)"))
  }

  @Test internal func testLetBindingPatternWithWildcard() {
    let tuplePattern = Tuple.pattern([Pattern.let("x"), nil, Pattern.let("y")])
    let syntax = tuplePattern.patternSyntax

    let generated = syntax.description
    #expect(generated.contains("(let x, _, let y)"))
  }
}
