import Foundation

/// Extracts Swift code blocks from markdown content
internal class CodeBlockExtraction {
  // MARK: - Properties

  /// The lines of content being parsed
  private var lines: [String] = []

  /// Array of extracted code blocks
  private var codeBlocks: [CodeBlock] = []

  /// Current code block being built
  private var currentBlock: String?

  /// Line number where the current block started
  private var blockStartLine = 0

  /// Type of the current code block
  private var blockType: CodeBlockType = .example

  /// Whether we're currently inside a code block
  private var inCodeBlock = false

  /// Whether to skip the current block
  private var skipBlock = false

  /// Whether the extractor has already been used
  private var hasBeenUsed = false

  // MARK: - Public Methods

  internal func callAsFunction(_ content: String) throws(CodeBlockExtractorError) -> [CodeBlock] {
    try self.extractSwiftCodeBlocks(from: content)
  }

  /// Extracts Swift code blocks from markdown content
  /// - Parameter content: The markdown content to parse
  /// - Returns: Array of extracted code blocks
  /// - Throws: SwiftCodeBlockExtractorError if the extractor has already been used
  internal func extractSwiftCodeBlocks(from content: String) throws(CodeBlockExtractorError)
    -> [CodeBlock]
  {
    guard !hasBeenUsed else {
      throw CodeBlockExtractorError.alreadyUsed
    }

    hasBeenUsed = true
    lines = content.components(separatedBy: .newlines)

    for (lineIndex, line) in lines.enumerated() {
      processLine(line, at: lineIndex)
    }

    return codeBlocks
  }

  // MARK: - Private Methods

  /// Processes a single line during parsing
  /// - Parameters:
  ///   - line: The line to process
  ///   - lineIndex: The index of the line
  private func processLine(_ line: String, at lineIndex: Int) {
    if line.hasPrefix("```swift") {
      startCodeBlock(at: lineIndex, with: line)
    } else if line == "```" && inCodeBlock {
      endCodeBlock()
    } else if inCodeBlock {
      addLineToCurrentBlock(line)
    }
  }

  /// Starts a new code block
  /// - Parameters:
  ///   - lineIndex: The index of the line starting the block
  ///   - line: The line containing the code block marker
  private func startCodeBlock(at lineIndex: Int, with line: String) {
    inCodeBlock = true
    blockStartLine = lineIndex + 1
    currentBlock = ""
    skipBlock = false

    // Determine block type from context
    blockType = determineBlockType(from: line)

    // Check for HTML comment skip markers in the preceding lines
    checkForSkipMarkers(around: lineIndex)
  }

  /// Ends the current code block
  private func endCodeBlock() {
    if let block = currentBlock, !block.isEmpty, !skipBlock {
      let codeBlock = CodeBlock(
        code: block,
        lineNumber: blockStartLine,
        blockType: blockType
      )
      codeBlocks.append(codeBlock)
    }

    // Reset state for next block
    inCodeBlock = false
    currentBlock = nil
    skipBlock = false
  }

  /// Adds a line to the current code block
  /// - Parameter line: The line to add
  private func addLineToCurrentBlock(_ line: String) {
    if let existing = currentBlock {
      currentBlock = existing + "\n" + line
    } else {
      currentBlock = line
    }
  }

  /// Checks for skip markers in the lines around the given index
  /// - Parameter lineIndex: The index of the current line
  private func checkForSkipMarkers(around lineIndex: Int) {
    let precedingLines = lines[max(0, lineIndex - 3)...lineIndex]
    for precedingLine in precedingLines
    where precedingLine.contains("<!-- skip-test -->")
      || precedingLine.contains("<!-- no-test -->")
      || precedingLine.contains("<!-- incomplete -->")
      || precedingLine.contains("<!-- example-only -->")
    {
      skipBlock = true
      break
    }
  }

  /// Determines the type of code block based on context
  /// - Parameter line: The line containing the code block marker
  /// - Returns: The determined code block type
  private func determineBlockType(from line: String) -> CodeBlockType {
    if line.contains("bash") || line.contains("shell") {
      return .shellCommand
    } else {
      return .example
    }
  }
}

extension CodeBlockExtraction {
  internal static func callAsFunction(_ content: String) throws(CodeBlockExtractorError)
    -> [CodeBlock]
  {
    let extraction = CodeBlockExtraction()
    return try extraction(content)
  }
}
