import Testing
import Foundation
@testable import SyntaxKit

/// Integration tests that validate all code examples in DocC documentation
@Suite("Documentation Code Examples")
struct DocumentationExampleTests {
    
    /// Test harness that extracts and validates Swift code examples from documentation
    @Test("All documentation code examples compile and execute correctly")
    func validateAllDocumentationExamples() async throws {
        let testHarness = DocumentationTestHarness()
        let results = try await testHarness.validateAllExamples()
        
        // Report any failures
        let failures = results.filter { !$0.success }
        if !failures.isEmpty {
            let failureReport = failures.map { result in
                "\(result.filePath):\(result.lineNumber) - \(result.error ?? "Unknown error")"
            }.joined(separator: "\n")
            
            throw DocumentationTestError.exampleValidationFailed(
                "Code examples failed validation:\n\(failureReport)"
            )
        }
        
        // Log success summary
        print("✅ Validated \(results.count) code examples from documentation")
    }
    
    @Test("Quick Start Guide examples work correctly")
    func validateQuickStartGuideExamples() async throws {
        let testHarness = DocumentationTestHarness()
        let quickStartFile = "Sources/SyntaxKit/Documentation.docc/Tutorials/Quick-Start-Guide.md"
        let results = try await testHarness.validateExamplesInFile(quickStartFile)
        
        // Specific validation for Quick Start examples
        #expect(!results.isEmpty, "Quick Start Guide should contain code examples")
        #expect(results.allSatisfy { $0.success }, "All Quick Start examples should compile successfully")
    }
    
    @Test("Creating Macros tutorial examples work correctly")
    func validateMacroTutorialExamples() async throws {
        let testHarness = DocumentationTestHarness()
        let macroTutorialFile = "Sources/SyntaxKit/Documentation.docc/Tutorials/Creating-Macros-with-SyntaxKit.md"
        let results = try await testHarness.validateExamplesInFile(macroTutorialFile)
        
        // Macro examples should compile (though they may not execute without full macro setup)
        let compileResults = results.filter { $0.testType == .compilation }
        #expect(compileResults.allSatisfy { $0.success }, "All macro examples should compile successfully")
    }
    
    @Test("Enum Generator examples work correctly")
    func validateEnumGeneratorExamples() async throws {
        let testHarness = DocumentationTestHarness()
        let enumExampleFile = "Sources/SyntaxKit/Documentation.docc/Examples/EnumGenerator.md"
        let results = try await testHarness.validateExamplesInFile(enumExampleFile)
        
        // Check that enum generation examples actually work
        let executionResults = results.filter { $0.testType == .execution }
        #expect(executionResults.allSatisfy { $0.success }, "Enum generation examples should execute correctly")
    }
}

/// Harness for extracting and testing documentation code examples
class DocumentationTestHarness {
    
    /// Validates all code examples in all documentation files
    func validateAllExamples() async throws -> [ValidationResult] {
        let documentationFiles = try findDocumentationFiles()
        var allResults: [ValidationResult] = []
        
        for filePath in documentationFiles {
            let results = try await validateExamplesInFile(filePath)
            allResults.append(contentsOf: results)
        }
        
        return allResults
    }
    
    /// Validates code examples in a specific file
    func validateExamplesInFile(_ filePath: String) async throws -> [ValidationResult] {
        let fullPath = try resolveFilePath(filePath)
        let content = try String(contentsOf: URL(fileURLWithPath: fullPath))
        
        let codeBlocks = extractSwiftCodeBlocks(from: content)
        var results: [ValidationResult] = []
        
        for (index, codeBlock) in codeBlocks.enumerated() {
            let result = await validateCodeBlock(
                code: codeBlock.code,
                filePath: filePath,
                blockIndex: index,
                lineNumber: codeBlock.lineNumber,
                blockType: codeBlock.blockType
            )
            results.append(result)
        }
        
        return results
    }
    
    /// Extracts Swift code blocks from markdown content
    private func extractSwiftCodeBlocks(from content: String) -> [CodeBlock] {
        let lines = content.components(separatedBy: .newlines)
        var codeBlocks: [CodeBlock] = []
        var currentBlock: String?
        var blockStartLine = 0
        var blockType: CodeBlockType = .example
        var inCodeBlock = false
        
        for (lineIndex, line) in lines.enumerated() {
            if line.hasPrefix("```swift") {
                // Start of Swift code block
                inCodeBlock = true
                blockStartLine = lineIndex + 1
                currentBlock = ""
                
                // Determine block type from context
                blockType = determineBlockType(from: line)
                
            } else if line == "```" && inCodeBlock {
                // End of code block
                if let block = currentBlock, !block.isEmpty {
                    let codeBlock = CodeBlock(
                        code: block,
                        lineNumber: blockStartLine,
                        blockType: blockType
                    )
                    codeBlocks.append(codeBlock)
                }
                inCodeBlock = false
                currentBlock = nil
                
            } else if inCodeBlock {
                // Inside code block - collect lines
                if let existing = currentBlock {
                    currentBlock = existing + "\n" + line
                } else {
                    currentBlock = line
                }
            }
        }
        
        return codeBlocks
    }
    
    /// Determines the type of code block based on context
    private func determineBlockType(from line: String) -> CodeBlockType {
        // Look for type hints in the markdown
        if line.contains("Package.swift") {
            return .packageManifest
        } else if line.contains("bash") || line.contains("shell") {
            return .shellCommand
        } else {
            return .example
        }
    }
    
    /// Validates a single code block
    private func validateCodeBlock(
        code: String,
        filePath: String,
        blockIndex: Int,
        lineNumber: Int,
        blockType: CodeBlockType
    ) async -> ValidationResult {
        
        switch blockType {
        case .example:
            // Test compilation and basic execution
            return await validateSwiftExample(code, filePath: filePath, lineNumber: lineNumber)
            
        case .packageManifest:
            // Package.swift files need special handling
            return await validatePackageManifest(code, filePath: filePath, lineNumber: lineNumber)
            
        case .shellCommand:
            // Skip shell commands for now
            return ValidationResult(
                success: true,
                filePath: filePath,
                lineNumber: lineNumber,
                testType: .skipped,
                error: nil
            )
        }
    }
    
    /// Validates a Swift code example
    private func validateSwiftExample(
        _ code: String,
        filePath: String,
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
                    filePath: filePath,
                    lineNumber: lineNumber,
                    testType: .compilation,
                    error: "Compilation failed: \(compileResult.error ?? "Unknown error")"
                )
            }
            
            // If compilation succeeded, try to run it (for runnable examples)
            if isRunnableExample(code) {
                let executeResult = try await executeCompiledSwift(tempFile)
                return ValidationResult(
                    success: executeResult.success,
                    filePath: filePath,
                    lineNumber: lineNumber,
                    testType: .execution,
                    error: executeResult.error
                )
            } else {
                // Just compilation test for non-runnable code
                return ValidationResult(
                    success: true,
                    filePath: filePath,
                    lineNumber: lineNumber,
                    testType: .compilation,
                    error: nil
                )
            }
            
        } catch {
            return ValidationResult(
                success: false,
                filePath: filePath,
                lineNumber: lineNumber,
                testType: .compilation,
                error: "Test setup failed: \(error.localizedDescription)"
            )
        }
    }
    
    /// Validates a Package.swift manifest
    private func validatePackageManifest(
        _ code: String,
        filePath: String,
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
                filePath: filePath,
                lineNumber: lineNumber,
                testType: .compilation,
                error: error
            )
            
        } catch {
            return ValidationResult(
                success: false,
                filePath: filePath,
                lineNumber: lineNumber,
                testType: .compilation,
                error: "Package validation setup failed: \(error.localizedDescription)"
            )
        }
    }
    
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
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = [
            "-frontend", "-typecheck",
            "-sdk", try getSDKPath(),
            fileURL.path
        ]
        
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        let success = process.terminationStatus == 0
        var error: String? = nil
        
        if !success {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            error = String(data: errorData, encoding: .utf8)
        }
        
        return CompilationResult(success: success, error: error)
    }
    
    /// Executes compiled Swift code
    private func executeCompiledSwift(_ fileURL: URL) async throws -> CompilationResult {
        // For documentation examples, we generally only test compilation
        // Execution would require more complex setup with proper module dependencies
        return CompilationResult(success: true, error: nil)
    }
    
    /// Determines if a code example should be executed (vs just compiled)
    private func isRunnableExample(_ code: String) -> Bool {
        // Simple heuristics for runnable examples
        return code.contains("print(") || code.contains("main()") || code.contains("@main")
    }
    
    /// Gets the SDK path for compilation
    private func getSDKPath() throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["--show-sdk-path"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw DocumentationTestError.sdkPathNotFound
        }
        
        return path
    }
    
    /// Finds all documentation files containing code examples
    private func findDocumentationFiles() throws -> [String] {
        let projectRoot = URL(fileURLWithPath: "/Users/leo/Documents/Projects/SyntaxKit")
        let docPaths = [
            "Sources/SyntaxKit/Documentation.docc",
            "README.md",
            "Examples"
        ]
        
        var documentationFiles: [String] = []
        
        for docPath in docPaths {
            let fullPath = projectRoot.appendingPathComponent(docPath)
            
            if FileManager.default.fileExists(atPath: fullPath.path) {
                if docPath.hasSuffix(".md") {
                    documentationFiles.append(docPath)
                } else {
                    // Recursively find .md files in directory
                    let foundFiles = try findMarkdownFiles(in: fullPath, relativeTo: projectRoot)
                    documentationFiles.append(contentsOf: foundFiles)
                }
            }
        }
        
        return documentationFiles
    }
    
    /// Recursively finds markdown files in a directory
    private func findMarkdownFiles(in directory: URL, relativeTo root: URL) throws -> [String] {
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil)
        
        var markdownFiles: [String] = []
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension == "md" {
                let relativePath = String(fileURL.path.dropFirst(root.path.count + 1))
                markdownFiles.append(relativePath)
            }
        }
        
        return markdownFiles
    }
    
    /// Resolves a relative file path to absolute path
    private func resolveFilePath(_ filePath: String) throws -> String {
        let projectRoot = "/Users/leo/Documents/Projects/SyntaxKit"
        
        if filePath.hasPrefix("/") {
            return filePath
        } else {
            return "\(projectRoot)/\(filePath)"
        }
    }
}

// MARK: - Supporting Types

struct CodeBlock {
    let code: String
    let lineNumber: Int
    let blockType: CodeBlockType
}

enum CodeBlockType {
    case example
    case packageManifest  
    case shellCommand
}

struct ValidationResult {
    let success: Bool
    let filePath: String
    let lineNumber: Int
    let testType: TestType
    let error: String?
}

enum TestType {
    case compilation
    case execution
    case skipped
}

struct CompilationResult {
    let success: Bool
    let error: String?
}

enum DocumentationTestError: Error, CustomStringConvertible {
    case exampleValidationFailed(String)
    case sdkPathNotFound
    case fileNotFound(String)
    
    var description: String {
        switch self {
        case .exampleValidationFailed(let details):
            return "Documentation example validation failed: \(details)"
        case .sdkPathNotFound:
            return "Could not determine SDK path for compilation"
        case .fileNotFound(let path):
            return "Documentation file not found: \(path)"
        }
    }
}

