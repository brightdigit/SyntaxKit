//
//  TreeNode.swift
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

internal final class TreeNode: Codable {
  internal let id: Int
  internal var parent: Int?

  internal var text: String
  internal var range = SourceRange(
    startRow: 0,
    startColumn: 0,
    endRow: 0,
    endColumn: 0
  )
  internal var structure = [StructureProperty]()
  internal var type: SyntaxType
  internal var token: Token?

  internal init(id: Int, text: String, range: SourceRange, type: SyntaxType) {
    self.id = id
    self.text = text.escapeHTML()
    self.range = range
    self.type = type
  }
}

extension TreeNode: Equatable {
  internal static func == (lhs: TreeNode, rhs: TreeNode) -> Bool {
    lhs.id == rhs.id && lhs.parent == rhs.parent && lhs.text == rhs.text && lhs.range == rhs.range
      && lhs.structure == rhs.structure && lhs.type == rhs.type && lhs.token == rhs.token
  }
}

extension TreeNode: CustomStringConvertible {
  internal var description: String {
    """
    {
      id: \(id)
      parent: \(String(describing: parent))
      text: \(text)
      range: \(range)
      structure: \(structure)
      type: \(type)
      token: \(String(describing: token))
    }
    """
  }
}
