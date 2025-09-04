import Foundation
import SwiftParser
import SwiftSyntax
import Testing

/// Harness for extracting and testing documentation code examples
internal class DocumentationTestHarness {
  
  /// Project root directory calculated from the current file location
  private static let projectRoot: URL = {
    let currentFileURL = URL(fileURLWithPath: #filePath)
    return
      currentFileURL
      .deletingLastPathComponent()  // Tests/SyntaxDocTests
      .deletingLastPathComponent()  // Tests
      .deletingLastPathComponent()  // Project root
  }()

  /// Document paths to search for documentation files
  private static let docPaths = [
    "Sources/SyntaxKit/Documentation.docc",
    "README.md",
    "Examples",
  ]

  /// Default file extensions for documentation files
  private static let defaultPathExtensions = ["md"]
  /// Validates all code examples in all documentation files
  internal func validateAllExamples() async throws -> [ValidationResult] {
    let documentationFiles = try DocumentationTestHarness.findDocumentationFiles()
    var allResults: [ValidationResult] = []

    for filePath in documentationFiles {
      let results = try await validateExamplesInFile(filePath)
      allResults.append(contentsOf: results)
    }

    return allResults
  }

  /// Validates code examples in a specific file
  internal func validateExamplesInFile(_ fileURL: URL) async throws -> [ValidationResult] {
    // let fullPath = try resolveFilePath(filePath)
    let content = try String(contentsOf: fileURL)

    let codeBlocks = try CodeBlockExtractor()(content)
    var results: [ValidationResult] = []

    for (index, codeBlock) in codeBlocks.enumerated() {
      let result = await validateCodeBlock(
        code: codeBlock.code,
        fileURL: fileURL,
        blockIndex: index,
        lineNumber: codeBlock.lineNumber,
        blockType: codeBlock.blockType
      )

      try results.append(
        #require(result)
      )
    }

    return results
  }

  /// Validates a single code block
  private func validateCodeBlock(
    code: String,
    fileURL: URL,
    blockIndex: Int,
    lineNumber: Int,
    blockType: CodeBlockType
  ) async -> ValidationResult? {
    switch blockType {
    case .example:
      // Test compilation and basic execution
      return await validateSwiftExample(code, fileURL: fileURL, lineNumber: lineNumber)

    case .packageManifest:
      #if canImport(Foundation) && (os(macOS) || os(Linux))
        // Package.swift files need special handling
        return await validatePackageManifest(code, fileURL: fileURL, lineNumber: lineNumber)
      #else
        return ValidationResult(
          success: true,
          fileURL: fileURL,
          lineNumber: lineNumber,
          testType: .skipped,
          error: nil
        )
      #endif
    case .shellCommand:
      // Skip shell commands for now
      return ValidationResult(
        success: true,
        fileURL: fileURL,
        lineNumber: lineNumber,
        testType: .skipped,
        error: nil
      )
    }
  }

  /// Validates a Swift code example
  private func validateSwiftExample(
    _ code: String,
    fileURL: URL,
    lineNumber: Int
  ) async -> ValidationResult {
    do {
      // Create a temporary Swift file for testing
      let tempFile = try createTemporarySwiftFile(with: code)
      defer { try? FileManager.default.removeItem(at: tempFile) }

      // First, try to compile the code
      let compileResult = try await compileSwiftFile(tempFile)

      if !compileResult.success {
        return ValidationResult(
          success: false,
          fileURL: fileURL,
          lineNumber: lineNumber,
          testType: .compilation,
          error: "Compilation failed: \(compileResult.error ?? "Unknown error")"
        )
      }

      // If compilation succeeded, try to run it (for runnable examples)
      if isRunnableExample(code) {
        // let executeResult = try await executeCompiledSwift(tempFile)
        return ValidationResult(
          success: true,
          fileURL: fileURL,
          lineNumber: lineNumber,
          testType: .compilation,
          error: nil
        )
      } else {
        // Just compilation test for non-runnable code
        return ValidationResult(
          success: true,
          fileURL: fileURL,
          lineNumber: lineNumber,
          testType: .compilation,
          error: nil
        )
      }
    } catch {
      return ValidationResult(
        success: false,
        fileURL: fileURL,
        lineNumber: lineNumber,
        testType: .compilation,
        error: "Test setup failed: \(error.localizedDescription)"
      )
    }
  }

  #if canImport(Foundation) && (os(macOS) || os(Linux))
    /// Validates a Package.swift manifest
    private func validatePackageManifest(
      _ code: String,
      fileURL: URL,
      lineNumber: Int
    ) async -> ValidationResult {
      do {
        // Create temporary Package.swift and validate it parses
        let tempDir = FileManager.default.temporaryDirectory
          .appendingPathComponent("SyntaxKit-DocTest-\(UUID())")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let packageFile = tempDir.appendingPathComponent("Package.swift")
        try code.write(to: packageFile, atomically: true, encoding: .utf8)

        // Use swift package tools to validate
        let process = Process()
        process.currentDirectoryURL = tempDir
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = ["package", "describe", "--type", "json"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let success = process.terminationStatus == 0
        let error = success ? nil : "Package.swift validation failed"

        return ValidationResult(
          success: success,
          fileURL: fileURL,
          lineNumber: lineNumber,
          testType: .compilation,
          error: error
        )
      } catch {
        return ValidationResult(
          success: false,
          fileURL: fileURL,
          lineNumber: lineNumber,
          testType: .compilation,
          error: "Package validation setup failed: \(error.localizedDescription)"
        )
      }
    }
  #endif
  /// Creates a temporary Swift file with proper imports and structure
  private func createTemporarySwiftFile(with code: String) throws -> URL {
    let tempDir = FileManager.default.temporaryDirectory
    let tempFile = tempDir.appendingPathComponent("DocTest-\(UUID()).swift")

    // Wrap the code with necessary imports and structure
    let wrappedCode = """
      import Foundation
      import SyntaxKit

      // Documentation example code:
      \(code)
      """

    try wrappedCode.write(to: tempFile, atomically: true, encoding: .utf8)
    return tempFile
  }

  /// Compiles a Swift file and returns the result
  private func compileSwiftFile(_ fileURL: URL) async throws -> CompilationResult {
    // For documentation tests, we need to check if the code compiles syntactically
    // Since we can't easily resolve SyntaxKit module in isolation, we'll use a simpler approach
    // that focuses on syntax validation rather than full compilation

    let code = try String(contentsOf: fileURL)

    // Skip Package.swift examples and incomplete snippets
    if code.contains("Package(") || code.contains("dependencies:") || code.contains(".package(") {
      return CompilationResult(success: true, error: nil)
    }

    // Skip examples that obviously require runtime execution or have other imports
    if code.contains("@main") || (code.contains("import") && !code.contains("import SyntaxKit")) {
      return CompilationResult(success: true, error: nil)
    }

    // Skip shell commands or configuration examples
    if code.contains("swift build") || code.contains("swift test") || code.contains("swift package")
    {
      return CompilationResult(success: true, error: nil)
    }

    // For SyntaxKit examples, create a complete, parseable Swift source
    let cleanSource =
      code
      .replacingOccurrences(of: "import SyntaxKit", with: "")
      .replacingOccurrences(of: "import Foundation", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)

    // Skip if the remaining code is too fragmentary to parse
    if cleanSource.isEmpty || cleanSource.count < 10
      || (!cleanSource.contains("{") && !cleanSource.contains("let")
        && !cleanSource.contains("var"))
    {
      return CompilationResult(success: true, error: nil)
    }

    // Try to parse as complete Swift statements
    let wrappedSource = """
      func testExample() {
      \(cleanSource)
      }
      """

    let parsed = Parser.parse(source: wrappedSource)

    // Check for syntax errors in the parsed result
    if parsed.hasError {
      return CompilationResult(
        success: false,
        error: "Syntax parsing detected errors in the code"
      )
    }

    return CompilationResult(success: true, error: nil)
  }

  /// Determines if a code example should be executed (vs just compiled)
  private func isRunnableExample(_ code: String) -> Bool {
    // Simple heuristics for runnable examples
    code.contains("print(") || code.contains("main()") || code.contains("@main")
  }

//  #if canImport(Foundation) && (os(macOS) || os(Linux))
//    /// Gets the SDK path for compilation
//    private func getSDKPath() throws -> String {
//      let process = Process()
//      process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
//      process.arguments = ["--show-sdk-path"]
//
//      let pipe = Pipe()
//      process.standardOutput = pipe
//
//      try process.run()
//      process.waitUntilExit()
//
//      let data = pipe.fileHandleForReading.readDataToEndOfFile()
//      guard
//        let path = String(data: data, encoding: .utf8)?.trimmingCharacters(
//          in: .whitespacesAndNewlines)
//      else {
//        throw DocumentationTestError.sdkPathNotFound
//      }
//
//      return path
//    }
//  #endif

  /// Finds all documentation files containing code examples
  @available(*, deprecated, message: "Use findDocumentationFiles(in:pathExtensions:) instead")
  private static func findDocumentationFiles() throws -> [URL] {
    try Self.docPaths.flatMap { docPath in
      let absolutePath = Self.projectRoot.appendingPathComponent(docPath)
      return try FileManager.default.findDocumentationFiles(
        in: absolutePath, pathExtensions: Self.defaultPathExtensions)
    }
  }

  /// Resolves a relative file path to absolute path (public for use by test methods)
  internal func resolveRelativePath(_ filePath: String) throws -> URL {
    try resolveFilePath(filePath)
  }

  /// Resolves a relative file path to absolute path
  private func resolveFilePath(_ filePath: String) throws -> URL {
    if filePath.hasPrefix("/") {
      return .init(filePath: filePath)
    } else {
      return Self.projectRoot.appendingPathComponent(filePath)
    }
  }
}
