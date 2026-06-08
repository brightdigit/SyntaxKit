//
//  Subprocess.Configuration+Swift.swift
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

  import Subprocess

  extension Subprocess.Configuration {
    /// A configuration that runs the `swift` interpreter on `wrappedPath`,
    /// linked against `libSyntaxKit` in `libPath`.
    ///
    /// Builds the full flag set: link against libSyntaxKit, include the CShims
    /// headers, and set rpath so the dylib loads at runtime. The executable is
    /// resolved by name on `PATH`.
    internal static func swift(libPath: String, wrappedPath: String) -> Self {
      let cShimsInclude = "\(libPath)/_SwiftSyntaxCShims-include"
      let arguments: [String] = [
        "-suppress-warnings",
        "-I", libPath,
        "-L", libPath,
        "-lSyntaxKit",
        "-Xcc", "-I", "-Xcc", cShimsInclude,
        "-Xlinker", "-rpath", "-Xlinker", libPath,
        wrappedPath,
      ]
      return Self(executable: .name("swift"), arguments: Arguments(arguments))
    }
  }

#endif
