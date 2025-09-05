//
//  CodeBlockValidationParameters.swift
//  SyntaxKit
//
//  Created by Leo Dion on 9/5/25.
//

import Foundation

/// Parameters for validating code blocks with additional metadata
internal struct CodeBlockValidationParameters: ValidationParameters, Sendable {
  internal let codeBlock: CodeBlock
  internal let fileURL: URL
  internal let blockIndex: Int

  // MARK: - ValidationParameters conformance
  internal var code: String {
    codeBlock.code
  }

  internal var lineNumber: Int {
    codeBlock.lineNumber
  }
}

extension URL {
  internal func codeBlock(_ codeBlock: CodeBlock, at blockIndex: Int)
    -> CodeBlockValidationParameters
  {
    .init(codeBlock: codeBlock, fileURL: self, blockIndex: blockIndex)
  }
}
