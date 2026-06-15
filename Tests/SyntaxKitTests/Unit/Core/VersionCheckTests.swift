//
//  VersionCheckTests.swift
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

import Testing

@testable import SyntaxKit

internal struct VersionCheckTests {
  @Test internal func greaterThanOrEqualRendersOperatorAndVersion() {
    #expect(VersionCheck.greaterThanOrEqual(5, 9).rendered == ">=5.9")
  }

  @Test internal func greaterThanRendersOperatorAndVersion() {
    #expect(VersionCheck.greaterThan(6).rendered == ">6")
  }

  @Test internal func lessThanOrEqualRendersOperatorAndVersion() {
    #expect(VersionCheck.lessThanOrEqual(6, 1).rendered == "<=6.1")
  }

  @Test internal func lessThanRendersOperatorAndVersion() {
    #expect(VersionCheck.lessThan(7).rendered == "<7")
  }

  @Test internal func equalRendersOperatorAndVersion() {
    #expect(VersionCheck.equal(6, 0, 1).rendered == "==6.0.1")
  }

  @Test internal func versionDescriptionMatchesDottedForm() {
    #expect(Version(5).description == "5")
    #expect(Version(5, 9).description == "5.9")
    #expect(Version(5, 9, 1).description == "5.9.1")
  }
}
