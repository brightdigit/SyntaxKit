//
//  String+DylibFilename.swift
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

extension String {
  /// Shared-library filename prefix (`lib`).
  private static let dylibPrefix = "lib"
  #if os(Linux)
    /// Linux shared-library filename extension.
    private static let linuxDylibExtension = ".so"
  #else
    /// macOS shared-library filename extension.
    private static let macOSDylibExtension = ".dylib"
  #endif

  /// Treats `self` as a Swift library product name and returns the
  /// platform-specific shared-library filename (`libFoo.dylib` on macOS,
  /// `libFoo.so` on Linux).
  internal var dylibFilename: String {
    #if os(Linux)
      return "\(Self.dylibPrefix)\(self)\(Self.linuxDylibExtension)"
    #else
      return "\(Self.dylibPrefix)\(self)\(Self.macOSDylibExtension)"
    #endif
  }
}
