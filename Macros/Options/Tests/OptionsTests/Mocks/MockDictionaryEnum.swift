//
//  MockDictionaryEnum.swift
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

import Options

#if swift(>=5.10)
  // swiftlint:disable identifier_name
  @Options
  internal enum MockDictionaryEnum: Int, Sendable {
    case a = 2
    case b = 5
    case c = 6
    case d = 12
  }
#else
  // swiftlint:disable identifier_name
  internal enum MockDictionaryEnum: Int, MappedValueDictionaryRepresented, Codable {
    case a = 2
    case b = 5
    case c = 6
    case d = 12
    internal typealias MappedType = String
    internal static var mappedValues = [
      2: "a",
      5: "b",
      6: "c",
      12: "d"
    ]
  }

  typealias MockDictionaryEnumSet = EnumSet<MockDictionaryEnum>
#endif
