//
//  RenderInput.swift
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

public import Foundation

/// One in-memory input for a batch render: the source bytes paired with the
/// URL that identifies them. `Runner.render(sources:)` never opens `url` — it
/// is a *label*, used for `#sourceLocation` mapping and stderr path-rewriting,
/// and carried back on the matching `FileOutcome` so the caller can map the
/// rendered output to a destination (e.g. by rerooting `url` onto an output
/// tree). The caller is responsible for reading the file into `source`.
public struct RenderInput: Sendable {
  /// The URL identifying this input. Used as a diagnostic label and as the
  /// key the caller reroots when writing output; never opened by the SDK.
  public let url: URL
  /// The input's source bytes, already read into memory by the caller.
  public let source: String

  /// Pairs an identifying `url` with its already-loaded `source`.
  public init(url: URL, source: String) {
    self.url = url
    self.source = source
  }
}
