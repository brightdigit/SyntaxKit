//
//  PoundIfTests.swift
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

internal struct PoundIfTests {
  /// Renders a `#if` block wrapping a single import, normalized for assertions.
  private func rendered(_ condition: some PoundIf.Condition) -> String {
    PoundIf(condition) { Import("Foundation") }.generateCode().normalize()
  }

  @Test internal func testCanImport() {
    let block = PoundIf(.canImport("SwiftUI")) {
      Import("SwiftUI")
    }
    let generated = block.generateCode().normalize()
    #expect(generated.contains("#if canImport(SwiftUI)"))
    #expect(generated.contains("import SwiftUI"))
    #expect(generated.contains("#endif"))
  }

  @Test internal func testFlag() {
    let block = PoundIf(.flag("DEBUG")) {
      Import("Foundation")
    }
    let generated = block.generateCode().normalize()
    #expect(generated.contains("#if DEBUG"))
    #expect(generated.contains("import Foundation"))
    #expect(generated.contains("#endif"))
  }

  @Test internal func testOS() {
    let block = PoundIf(.os(.iOS)) {
      Import("UIKit")
    }
    let generated = block.generateCode().normalize()
    #expect(generated.contains("#if os(iOS)"))
    #expect(generated.contains("import UIKit"))
  }

  @Test internal func testAnyAppleOS() {
    let block = PoundIf(.os(.anyAppleOS)) {
      Import("Foundation")
    }
    let generated = block.generateCode().normalize()
    #expect(generated.contains("#if os(anyAppleOS)"))
  }

  @Test internal func testArch() {
    let block = PoundIf(.arch(.arm64)) {
      Import("Foundation")
    }
    let generated = block.generateCode().normalize()
    #expect(generated.contains("#if arch(arm64)"))
  }

  @Test internal func testTargetEnvironment() {
    let block = PoundIf(.targetEnvironment(.simulator)) {
      Import("Foundation")
    }
    let generated = block.generateCode().normalize()
    #expect(generated.contains("#if targetEnvironment(simulator)"))
  }

  @Test internal func testSwiftVersion() {
    let block = PoundIf(.swift(.atLeast(5, 9))) {
      Import("Foundation")
    }
    let generated = block.generateCode().normalize()
    #expect(generated.contains("#if swift(>=5.9)"))
  }

  @Test internal func testCompilerVersion() {
    let block = PoundIf(.compiler(.atLeast(5, 9))) {
      Import("Foundation")
    }
    let generated = block.generateCode().normalize()
    #expect(generated.contains("#if compiler(>=5.9)"))
  }

  @Test internal func testVersionComparisons() {
    #expect(rendered(.swift(.greaterThan(6))).contains("#if swift(>6)"))
    #expect(rendered(.compiler(.atMost(6, 1))).contains("#if compiler(<=6.1)"))
    #expect(rendered(.swift(.lessThan(7))).contains("#if swift(<7)"))
    #expect(rendered(.compiler(.exact(6, 0, 1))).contains("#if compiler(==6.0.1)"))
  }

  @Test internal func testHasFeature() {
    let block = PoundIf(.hasFeature("StrictConcurrency")) {
      Import("Foundation")
    }
    let generated = block.generateCode().normalize()
    #expect(generated.contains("#if hasFeature(StrictConcurrency)"))
  }

  @Test internal func testHasAttribute() {
    let block = PoundIf(.hasAttribute("retroactive")) {
      Import("Foundation")
    }
    let generated = block.generateCode().normalize()
    #expect(generated.contains("#if hasAttribute(retroactive)"))
  }

  @Test internal func testAnd() {
    let generated = rendered(.and(.os(.iOS), .arch(.arm64)))
    #expect(generated.contains("os(iOS) && arch(arm64)"))
  }

  @Test internal func testOrNot() {
    let generated = rendered(.or(.canImport("UIKit"), .not(.os(.macOS))))
    #expect(generated.contains("canImport(UIKit) || !os(macOS)"))
  }

  @Test internal func testNestedBinaryParenthesization() {
    let generated = rendered(.and(.or(.os(.iOS), .os(.macOS)), .arch(.arm64)))
    #expect(generated.contains("(os(iOS) || os(macOS)) && arch(arm64)"))
  }

  @Test internal func testRawStringCondition() {
    let block = PoundIf("CUSTOM_FLAG") {
      Import("Foundation")
    }
    let generated = block.generateCode().normalize()
    #expect(generated.contains("#if CUSTOM_FLAG"))
  }

  @Test internal func testCodeBlockCondition() {
    let block = PoundIf(VariableExp("MY_FLAG")) {
      Import("Foundation")
    }
    let generated = block.generateCode().normalize()
    #expect(generated.contains("#if MY_FLAG"))
  }

  @Test internal func testElseif() {
    let block =
      PoundIf(.canImport("SwiftUI")) {
        Import("SwiftUI")
      }
      .elseif(.canImport("UIKit")) {
        Import("UIKit")
      }
    let generated = block.generateCode().normalize()
    #expect(generated.contains("#if canImport(SwiftUI)"))
    #expect(generated.contains("#elseif canImport(UIKit)"))
    #expect(generated.contains("import UIKit"))
  }

  @Test internal func testElse() {
    let block =
      PoundIf(.canImport("SwiftUI")) {
        Import("SwiftUI")
      }
      .else {
        Import("Foundation")
      }
    let generated = block.generateCode().normalize()
    #expect(generated.contains("#if canImport(SwiftUI)"))
    #expect(generated.contains("#else"))
    #expect(generated.contains("import Foundation"))
    #expect(generated.contains("#endif"))
  }

  @Test internal func testElseifElse() {
    let block =
      PoundIf(.canImport("SwiftUI")) {
        Import("SwiftUI")
      }
      .elseif(.canImport("UIKit")) {
        Import("UIKit")
      }
      .else {
        Import("Foundation")
      }
    let generated = block.generateCode().normalize()
    #expect(generated.contains("#if canImport(SwiftUI)"))
    #expect(generated.contains("#elseif canImport(UIKit)"))
    #expect(generated.contains("#else"))
    #expect(generated.contains("import Foundation"))
    #expect(generated.contains("#endif"))
  }

  @Test internal func testFormerIfCanImportShape() {
    let block = PoundIf(.canImport("Foundation")) {
      Import("Foundation")
    }
    let generated = block.generateCode().normalize()
    #expect(generated.contains("#if canImport(Foundation)"))
    #expect(generated.contains("import Foundation"))
    #expect(generated.contains("#endif"))
  }
}
