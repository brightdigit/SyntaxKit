//
//  KeyValues.swift
//  SimulatorServices
//
//  Created by Leo Dion.
//  Copyright © 2024 BrightDigit.
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

import SwiftSyntax

internal struct KeyValues {
  internal private(set) var lastKey: Int?
  internal private(set) var dictionary = [Int: String]()

  internal var count: Int {
    dictionary.count
  }

  internal var nextKey: Int {
    (lastKey ?? -1) + 1
  }

  internal mutating func append(value: String, withKey key: Int? = nil) throws {
    let key = key ?? nextKey
    guard dictionary[key] == nil else {
      throw InvalidDeclError.rawValue(key)
    }
    lastKey = key
    dictionary[key] = value
  }

  internal func get(_ key: Int) -> String? {
    dictionary[key]
  }
}

extension KeyValues {
  internal init(caseElements: [EnumCaseElementSyntax]) throws {
    self.init()
    for caseElement in caseElements {
      let intText = caseElement.rawValue?.value
        .as(IntegerLiteralExprSyntax.self)?.literal.text
      let key = intText.flatMap { Int($0) }
      let value =
        caseElement.name.trimmed.text
      try append(value: value, withKey: key)
    }
  }
}
