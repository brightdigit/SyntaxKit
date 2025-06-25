//
//  main.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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
import SyntaxKit

// Read Swift code from stdin
internal let code =
  String(data: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) ?? ""

do {
  // Parse the code using SyntaxKit
  let response = try SyntaxParser.parse(code: code, options: ["fold"])

  // Output the JSON to stdout
  print(response.syntaxJSON)
} catch {
  // If there's an error, output it as JSON
  let errorResponse = ["error": error.localizedDescription]
  if let jsonData = try? JSONSerialization.data(withJSONObject: errorResponse),
    let jsonString = String(data: jsonData, encoding: .utf8)
  {
    print(jsonString)
  }
  exit(1)
}
