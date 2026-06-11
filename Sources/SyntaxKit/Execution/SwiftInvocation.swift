//
//  SwiftInvocation.swift
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

/// The inputs needed to invoke `swift` on one wrapped DSL program: the lib
/// directory (for `-I`/`-L`/`-rpath`) and the path to the wrapped source.
/// `Runner` hands this to its `run` closure, which performs the actual spawn —
/// the seam that keeps the engine free of any Subprocess dependency.
public struct SwiftInvocation: Sendable {
  /// Directory holding `libSyntaxKit` + swiftmodules, used for the spawned
  /// `swift`'s `-I`/`-L`/`-rpath` flags.
  public let libPath: String
  /// Path to the wrapped DSL source the spawned `swift` should compile and run.
  public let wrappedPath: String
}
