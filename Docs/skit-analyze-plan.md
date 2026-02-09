# Plan: SyntaxKit Analyzer CLI Tool

## Context

We need to create a CLI tool that uses the Claude API to automatically update the SyntaxKit library with missing features. The tool will:

1. Take an **input folder** containing:
   - `dsl.swift` - Swift DSL code (desired API)
   - `expected.swift` - Expected Swift code output
2. Take a **SyntaxKit library path** (existing sources)
3. **Auto-generate AST** from `expected.swift` using existing SyntaxParser
4. Analyze what's missing using Claude API
5. **Generate updated SyntaxKit library** with the missing features implemented
6. Write updated library to an **output folder**

This addresses the problem of implementing missing SyntaxKit features. Instead of manual implementation after identifying gaps, this tool automates the entire process: analysis → code generation → updated library output. Developers provide examples of what they want to generate, and the tool implements the necessary SyntaxKit features.

## Implementation Approach

### 1. Create New Executable Target: `skit-analyze`

**Location**: `Sources/skit-analyze/`

**Dependencies**:
- `SyntaxParser` (existing) - for parsing Swift code to AST
- `ConfigKeyKit` (existing in project) - for configuration key management
- `swift-configuration` - for CLI argument and environment variable handling
- Foundation (URLSession) - for HTTP requests to Claude API

### 2. Core Components

#### A. Configuration Structure (`AnalyzerConfiguration.swift`)

Configuration using ConfigKeyKit pattern:

```swift
import Configuration
import ConfigKeyKit

struct AnalyzerConfiguration: ConfigurationParseable {
    typealias ConfigReader = Configuration.ConfigReader
    typealias BaseConfig = Never

    // Configuration keys
    static let syntaxKitPathKey = ConfigKey(
        "syntaxkit.path",
        default: "Sources/SyntaxKit"
    )

    static let apiKeyKey = OptionalConfigKey<String>(
        cli: "api-key",
        env: "ANTHROPIC_API_KEY"
    )

    static let modelKey = ConfigKey(
        "model",
        default: "claude-opus-4-6"
    )

    static let verboseKey = ConfigKey("verbose", default: false)

    // Properties
    let inputFolderPath: String       // Folder containing dsl.swift, expected.swift
    let syntaxKitPath: String         // Path to existing SyntaxKit sources
    let outputFolderPath: String      // Where to write updated library
    let apiKey: String
    let model: String
    let verbose: Bool

    init(configuration: ConfigReader, base: Never?) async throws {
        // Read positional arguments from command line
        let args = CommandLine.arguments.dropFirst()  // Skip executable name
        let positionalArgs = args.filter { !$0.hasPrefix("--") }

        guard positionalArgs.count >= 3 else {
            throw AnalyzerError.missingRequiredArguments(
                "Usage: skit-analyze <input-folder> <syntaxkit-path> <output-folder> [options]"
            )
        }

        self.inputFolderPath = positionalArgs[0]
        self.syntaxKitPath = positionalArgs[1]
        self.outputFolderPath = positionalArgs[2]

        // Read from configuration (CLI flags and env vars)
        self.model = configuration.string(forKey: Self.modelKey)
        self.verbose = configuration.bool(forKey: Self.verboseKey)

        // API key is required - check CLI flag, then env var
        guard let key = configuration.string(forKey: Self.apiKeyKey) else {
            throw AnalyzerError.missingAPIKey(
                "API key required. Provide via --api-key flag or ANTHROPIC_API_KEY environment variable"
            )
        }
        self.apiKey = key

        // Validate paths exist
        try validatePaths()
    }

    private func validatePaths() throws {
        let fm = FileManager.default

        guard fm.fileExists(atPath: inputFolderPath) else {
            throw AnalyzerError.invalidPath("Input folder does not exist: \(inputFolderPath)")
        }

        guard fm.fileExists(atPath: syntaxKitPath) else {
            throw AnalyzerError.invalidPath("SyntaxKit path does not exist: \(syntaxKitPath)")
        }
    }
}

enum AnalyzerError: Error {
    case missingRequiredArguments(String)
    case missingAPIKey(String)
    case invalidPath(String)
    case missingInputFile(String)
    case astGenerationError(String)
    case apiError(String)
    case codeGenerationError(String)
}
```

#### B. Command Implementation (`AnalyzeCommand.swift`)

Command using ConfigKeyKit Command protocol:

```swift
import ConfigKeyKit
import Configuration

struct AnalyzeCommand: Command {
    typealias Config = AnalyzerConfiguration

    static let commandName = "analyze"
    static let abstract = "Generate updated SyntaxKit library with missing features"
    static let helpText = """
        OVERVIEW: Automatically implement missing SyntaxKit features using Claude API

        USAGE: skit-analyze <input-folder> <syntaxkit-path> <output-folder> [options]

        ARGUMENTS:
          <input-folder>      Folder containing:
                             - dsl.swift: Swift DSL code (desired API)
                             - expected.swift: Expected Swift code output
                             Note: AST is auto-generated from expected.swift

          <syntaxkit-path>    Path to existing SyntaxKit library sources

          <output-folder>     Where to write the updated SyntaxKit library

        OPTIONS:
          --api-key <key>            Claude API key (or set ANTHROPIC_API_KEY)
          --model <name>             Claude model to use (default: claude-opus-4-6)
          --verbose                  Enable verbose output
          -h, --help                 Show help information

        EXAMPLE:
          mkdir examples/subscript-feature
          echo 'Subscript("Item") { ... }' > examples/subscript-feature/dsl.swift
          echo 'subscript(index: Int) -> Item { ... }' > examples/subscript-feature/expected.swift

          export ANTHROPIC_API_KEY="sk-ant-..."
          skit-analyze examples/subscript-feature Sources/SyntaxKit output/SyntaxKit
        """

    let config: Config

    init(config: Config) {
        self.config = config
    }

    static func createInstance() async throws -> Self {
        // Create providers
        let envProvider = EnvironmentVariablesProvider()
        let cliProvider = CommandLineArgumentsProvider()

        // Provider hierarchy: CLI args override environment variables
        let reader = ConfigReader(providers: [cliProvider, envProvider])

        // Parse configuration
        let configuration = try await Config(configuration: reader)

        return Self(config: configuration)
    }

    func execute() async throws {
        // Delegate to analyzer
        let analyzer = SyntaxKitAnalyzer(config: config)
        try await analyzer.run()
    }
}
```

#### C. Main Entry Point (`main.swift`)

```swift
@main
enum SkitAnalyze {
    static func main() async {
        do {
            let command = try await AnalyzeCommand.createInstance()
            try await command.execute()
        } catch {
            print("Error: \(error)")
            exit(1)
        }
    }
}
```

#### D. Main Analyzer (`SyntaxKitAnalyzer.swift`)

Core analyzer that orchestrates the entire workflow:

```swift
struct SyntaxKitAnalyzer {
    let config: AnalyzerConfiguration

    func run() async throws {
        if config.verbose {
            print("Generating updated SyntaxKit library...")
            print("Input Folder: \(config.inputFolderPath)")
            print("SyntaxKit Path: \(config.syntaxKitPath)")
            print("Output Folder: \(config.outputFolderPath)")
        }

        // 1. Read input files from folder
        let inputReader = InputFolderReader(folderPath: config.inputFolderPath)
        let inputs = try inputReader.readInputs()

        if config.verbose {
            print("Found: DSL (\(inputs.dslCode.count) chars), " +
                  "Expected Swift (\(inputs.expectedSwift.count) chars)")
        }

        // 2. Generate AST from expected.swift using SyntaxParser
        if config.verbose { print("Generating AST from expected.swift...") }
        let astGenerator = ASTGenerator()
        let swiftAST = try astGenerator.generateAST(from: inputs.expectedSwift)

        // 3. Collect library code
        if config.verbose { print("Collecting SyntaxKit library code...") }
        let collector = LibraryCollector()
        let libraryCode = try collector.collectLibraryCode(from: config.syntaxKitPath)

        if config.verbose {
            print("Library: \(libraryCode.split(separator: "\n").count) lines from " +
                  "\(collector.fileCount) files")
        }

        // 4. Call Claude API for analysis AND code generation
        if config.verbose { print("Calling Claude API (\(config.model))...") }
        let client = ClaudeAPIClient(apiKey: config.apiKey, model: config.model)
        let result = try await client.generateUpdatedLibrary(
            syntaxKitLibrary: libraryCode,
            expectedSwift: inputs.expectedSwift,
            swiftAST: swiftAST,
            swiftDSL: inputs.dslCode
        )

        if config.verbose {
            print("Received \(result.updatedFiles.count) updated files")
        }

        // 5. Write updated library to output folder
        try writeUpdatedLibrary(result)

        print("✓ Updated SyntaxKit library written to: \(config.outputFolderPath)")
    }

    private func writeUpdatedLibrary(_ result: LibraryUpdateResult) throws {
        let writer = LibraryWriter(outputPath: config.outputFolderPath)
        try writer.writeUpdatedLibrary(result)

        if config.verbose {
            print("\nUpdated files:")
            for file in result.updatedFiles {
                print("  - \(file.path)")
            }
            if !result.newFiles.isEmpty {
                print("\nNew files:")
                for file in result.newFiles {
                    print("  + \(file.path)")
                }
            }
        }
    }
}
```

#### E. Input Folder Reader (`InputFolderReader.swift`)

Reads and validates files from the input folder:

```swift
struct InputFolderReader {
    let folderPath: String

    struct Inputs {
        let dslCode: String
        let expectedSwift: String
    }

    func readInputs() throws -> Inputs {
        let fm = FileManager.default

        // Required: dsl.swift
        let dslPath = "\(folderPath)/dsl.swift"
        guard fm.fileExists(atPath: dslPath) else {
            throw AnalyzerError.missingInputFile("Missing required file: dsl.swift")
        }
        let dslCode = try String(contentsOfFile: dslPath)

        // Required: expected.swift
        let expectedPath = "\(folderPath)/expected.swift"
        guard fm.fileExists(atPath: expectedPath) else {
            throw AnalyzerError.missingInputFile("Missing required file: expected.swift")
        }
        let expectedSwift = try String(contentsOfFile: expectedPath)

        return Inputs(
            dslCode: dslCode,
            expectedSwift: expectedSwift
        )
    }
}
```

#### F. Library Code Collector (`LibraryCollector.swift`)

Responsible for gathering all SyntaxKit source files:

```swift
struct LibraryCollector {
    private(set) var fileCount: Int = 0  // Track number of files collected

    /// Recursively collects all .swift files from SyntaxKit directory
    mutating func collectLibraryCode(from path: String) throws -> String

    /// Formats collected code with file markers for clarity
    private func formatWithFileMarkers(_ files: [(path: String, content: String)]) -> String
}
```

Implementation will:
- Recursively scan the SyntaxKit directory
- Read all `.swift` files
- Concatenate with clear file path markers for each file
- Track file count for verbose output
- Skip test files and build artifacts
- Preserve relative paths for later reference

#### G. Library Writer (`LibraryWriter.swift`)

Writes the updated library files to the output folder:

```swift
struct LibraryWriter {
    let outputPath: String

    func writeUpdatedLibrary(_ result: LibraryUpdateResult) throws {
        let fm = FileManager.default

        // Create output directory if it doesn't exist
        try fm.createDirectory(atPath: outputPath, withIntermediateDirectories: true)

        // Write updated files
        for file in result.updatedFiles {
            let fullPath = "\(outputPath)/\(file.relativePath)"
            let directory = (fullPath as NSString).deletingLastPathComponent
            try fm.createDirectory(atPath: directory, withIntermediateDirectories: true)
            try file.content.write(toFile: fullPath, atomically: true, encoding: .utf8)
        }

        // Write new files
        for file in result.newFiles {
            let fullPath = "\(outputPath)/\(file.relativePath)"
            let directory = (fullPath as NSString).deletingLastPathComponent
            try fm.createDirectory(atPath: directory, withIntermediateDirectories: true)
            try file.content.write(toFile: fullPath, atomically: true, encoding: .utf8)
        }

        // Copy unchanged files (optional - could skip and only write changes)
        if result.includeUnchangedFiles {
            for file in result.unchangedFiles {
                let fullPath = "\(outputPath)/\(file.relativePath)"
                let directory = (fullPath as NSString).deletingLastPathComponent
                try fm.createDirectory(atPath: directory, withIntermediateDirectories: true)
                try fm.copyItem(atPath: file.sourcePath, toPath: fullPath)
            }
        }
    }
}
```

#### H. AST Generator (`ASTGenerator.swift`)

Wraps existing SyntaxParser to produce formatted AST:

```swift
import SyntaxParser

struct ASTGenerator {
    /// Generates formatted AST from Swift code using SyntaxParser
    func generateAST(from swiftCode: String) throws -> String {
        // Use existing SyntaxParser to parse Swift code
        let treeNodes = SyntaxParser.parse(code: swiftCode)

        // Format TreeNode array as readable hierarchical text or JSON
        return formatAST(treeNodes)
    }

    /// Formats TreeNode array as readable hierarchical text or JSON
    private func formatAST(_ nodes: [TreeNode]) -> String {
        // Could output as JSON or formatted text
        // JSON is probably better for Claude to parse
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(nodes),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }

        return json
    }
}
```

**Key Points**:
- Reuses existing `SyntaxParser.parse(code:)` from `Sources/SyntaxParser/`
- Returns JSON representation of the AST (TreeNode array)
- This is the same code path used by the `skit` executable
- No need for external AST generation - it's built-in!

#### I. Claude API Client (`ClaudeAPIClient.swift`)

Handles communication with Claude API for code generation:

```swift
struct ClaudeAPIClient {
    let apiKey: String
    let model: String

    /// Sends request to generate updated library code
    func generateUpdatedLibrary(
        syntaxKitLibrary: String,
        expectedSwift: String,
        swiftAST: String,
        swiftDSL: String
    ) async throws -> LibraryUpdateResult

    /// Formats the API request payload with code generation instructions
    private func createRequestPayload(...) -> [String: Any]

    /// Parses API response containing generated code
    private func parseCodeGenerationResponse(_ data: Data) throws -> LibraryUpdateResult
}

struct LibraryUpdateResult: Codable {
    struct UpdatedFile: Codable {
        let relativePath: String  // e.g., "Declarations/Subscript.swift"
        let content: String
        let changeDescription: String
    }

    struct NewFile: Codable {
        let relativePath: String
        let content: String
        let purpose: String
    }

    let updatedFiles: [UpdatedFile]
    let newFiles: [NewFile]
    let unchangedFiles: [FileReference]
    let includeUnchangedFiles: Bool
    let summary: String  // Claude's explanation of changes
}

struct FileReference: Codable {
    let relativePath: String
    let sourcePath: String
}
```

API request structure:
- Endpoint: `https://api.anthropic.com/v1/messages`
- Headers: `x-api-key`, `anthropic-version: 2023-06-01`, `content-type: application/json`
- Body: Enhanced prompt asking Claude to generate actual Swift code, not just describe changes

Modified Prompt Strategy:
- Still uses the Workbench prompt for analysis
- **Additionally** asks Claude to generate the actual implementation code
- Requests output in structured format using XML-style markers
- Each code file marked with: `<file path="relative/path.swift">...code...</file>`

**Response Parsing**:
The API client will parse Claude's response by:
1. Extract all `<file>` blocks using regex or XML parsing
2. For each file block:
   - Extract `path` attribute (relative path like "Declarations/Subscript.swift")
   - Extract content between tags (complete Swift code)
   - Determine if it's a new file or modification (check against library file list)
3. Build `LibraryUpdateResult` with categorized files
4. Include Claude's analysis summary from the response

**Code Generation Reliability**:
- Claude Opus 4.6 is excellent at generating complete, valid Swift code
- The prompt emphasizes: "provide COMPLETE file content, not diffs"
- Each file should be self-contained and compilable
- The tool can optionally run `swift build` on output to verify validity

#### J. Prompt Template (`PromptTemplate.swift`)

Contains enhanced version of Workbench prompt with code generation instructions:

```swift
struct PromptTemplate {
    static func createAnalysisAndCodeGeneration(
        syntaxKitLibrary: String,
        expectedSwift: String,
        swiftAST: String,
        swiftDSL: String
    ) -> String {
        // Original Workbench prompt for analysis
        // PLUS additional instructions for code generation
    }
}
```

**Prompt Structure**:
1. **Analysis Phase** (from Workbench): Analyze what needs to be added/modified
2. **Code Generation Phase** (added): Generate actual Swift implementation
3. **Output Format**: Structured response with:
   - Analysis summary
   - List of files to modify with complete new content
   - List of new files to create with complete content
   - Each file marked with: `<file path="Declarations/Subscript.swift">...</file>`

**Example Enhanced Prompt**:
```
[Original Workbench prompt...]

After your analysis, generate the actual Swift code needed to implement these changes:

<implementation>
For each required change you identified, provide the COMPLETE updated file content.
Mark each file with its path relative to the SyntaxKit root.

Format:
<file path="relative/path/to/File.swift">
// Complete file content here
</file>

Include:
- Modified existing files (full content, not diffs)
- New files that need to be created
- Updated Package.swift if new targets/dependencies needed
</implementation>
```

### 3. Workflow

```
User runs: skit-analyze examples/subscript-feature Sources/SyntaxKit output/SyntaxKit

1. main.swift: Entry point
2. AnalyzeCommand.createInstance():
   - Create EnvironmentVariablesProvider and CommandLineArgumentsProvider
   - Create ConfigReader with provider hierarchy (CLI > ENV)
   - Parse AnalyzerConfiguration from ConfigReader
   - Validate required arguments (input folder, syntaxkit path, output folder, API key)
   - Validate paths exist
3. AnalyzeCommand.execute():
   - Create SyntaxKitAnalyzer instance with config
   - Call analyzer.run()
4. SyntaxKitAnalyzer.run():
   a. Read input folder:
      - InputFolderReader reads dsl.swift and expected.swift
   b. Generate AST:
      - ASTGenerator.generateAST(from: expected.swift) using SyntaxParser
      - Returns JSON representation of TreeNode array
   c. Collect library code: LibraryCollector.collectLibraryCode() → syntaxKitLibrary
   d. Create Claude API client with API key and model
   e. Call API: client.generateUpdatedLibrary() → LibraryUpdateResult
      - Claude analyzes what's missing
      - Claude generates complete Swift implementation
      - Returns structured result with file contents
   f. Write updated library: LibraryWriter.writeUpdatedLibrary()
      - Create output directory structure
      - Write updated files with new content
      - Write new files
      - Optionally copy unchanged files
   g. Print success message with output path
```

### 4. Package.swift Changes

Add ConfigKeyKit as a local target and integrate swift-configuration:

```swift
// In dependencies (add swift-configuration):
.package(
    url: "https://github.com/apple/swift-configuration",
    from: "1.0.0",
    traits: ["CommandLineArguments"]  // Enable CLI args trait
),

// Add ConfigKeyKit as a target:
.target(
    name: "ConfigKeyKit",
    dependencies: [
        .product(name: "Configuration", package: "swift-configuration")
    ],
    swiftSettings: swiftSettings
),

// Add new executable target:
.executableTarget(
    name: "skit-analyze",
    dependencies: [
        "SyntaxParser",
        "ConfigKeyKit",
        .product(name: "Configuration", package: "swift-configuration")
    ],
    swiftSettings: swiftSettings
),

// In products:
.executable(
    name: "skit-analyze",
    targets: ["skit-analyze"]
),
```

**Note**: ConfigKeyKit already exists in the project directory, so we just need to add it as a target in Package.swift.

### 5. Configuration & Environment

**How swift-configuration + ConfigKeyKit Works Together**:

1. **ConfigKeyKit** provides the abstraction layer:
   - `ConfigKey<T>` for required values with defaults
   - `OptionalConfigKey<T>` for optional values
   - Automatic key naming transformations (e.g., `api.key` → `--api-key` or `API_KEY`)
   - Source-specific key generation (CLI vs ENV have different naming conventions)

2. **swift-configuration** provides the runtime:
   - `ConfigReader` reads from multiple providers
   - `CommandLineArgumentsProvider` parses `--flag value` style arguments
   - `EnvironmentVariablesProvider` reads from environment
   - Provider hierarchy: CLI arguments override environment variables

3. **Integration**:
   ```swift
   // Define key with both sources
   let apiKeyKey = OptionalConfigKey<String>(
       cli: "api-key",        // Becomes --api-key
       env: "ANTHROPIC_API_KEY"  // Reads from $ANTHROPIC_API_KEY
   )

   // Read with ConfigReader
   let apiKey = configuration.string(forKey: apiKeyKey)  // Checks CLI first, then ENV
   ```

**API Key Management**:
- `--api-key` flag takes precedence (via CommandLineArgumentsProvider)
- Falls back to `ANTHROPIC_API_KEY` environment variable (via EnvironmentVariablesProvider)
- Error if neither is provided

**Positional Arguments**:
- Three required positional arguments (not flags):
  1. Input folder path (containing dsl.swift, expected.swift, optional ast files)
  2. SyntaxKit library path (existing sources to read)
  3. Output folder path (where to write updated library)
- Parsed manually from `CommandLine.arguments` in configuration initializer
- More intuitive than using flags for required paths
- Example: `skit-analyze examples/feature Sources/SyntaxKit output/updated`

**Default Values**:
- SyntaxKit library path: `Sources/SyntaxKit` (via `ConfigKey` default)
- Model: `claude-opus-4-6` (via `ConfigKey` default)
- Verbose: `false` (via `ConfigKey` default)
- Can all be overridden via CLI flags or environment variables

**Model Configuration**:
- Model: Default `claude-opus-4-6`, override with `--model`
- Max tokens: 20000 (hardcoded in API client)
- Temperature: 1 (hardcoded as specified in Workbench)

### 6. Error Handling

Comprehensive error handling for:
- Missing files (Swift code, DSL code)
- Invalid paths (SyntaxKit library not found)
- API errors (authentication, rate limits, network issues)
- Parsing errors (invalid Swift code)
- JSON encoding/decoding errors

Use Swift's error handling with descriptive error messages.

### 7. Output Format

**Standard Output** (default):
```
Analyzing SyntaxKit requirements...

Swift Code: target.swift (245 lines)
DSL Code: dsl.swift (89 lines)
Generated AST: 1,234 nodes
Library Code: 15,678 lines from 142 files

Calling Claude API (model: claude-opus-4-6)...
Response received (3,456 tokens)

REQUIRED CHANGES:
================

[Claude's analysis output here]
```

**File Output** (with `--output changes.md`):
Save just the required changes section to the specified file.

**Verbose Mode** (with `--verbose`):
Include full API request/response, intermediate parsing steps, file collection details.

## Critical Files to Create

1. **Sources/skit-analyze/main.swift** - Main entry point
2. **Sources/skit-analyze/AnalyzeCommand.swift** - Command implementation using ConfigKeyKit
3. **Sources/skit-analyze/AnalyzerConfiguration.swift** - Configuration structure using ConfigKeyKit
4. **Sources/skit-analyze/SyntaxKitAnalyzer.swift** - Core analyzer orchestration
5. **Sources/skit-analyze/InputFolderReader.swift** - Reads dsl.swift, expected.swift, ast files
6. **Sources/skit-analyze/LibraryCollector.swift** - Collects SyntaxKit source files
7. **Sources/skit-analyze/LibraryWriter.swift** - Writes updated library to output folder
8. **Sources/skit-analyze/ASTGenerator.swift** - Wraps SyntaxParser for AST generation
9. **Sources/skit-analyze/ClaudeAPIClient.swift** - Claude API communication for code generation
10. **Sources/skit-analyze/PromptTemplate.swift** - Enhanced Workbench prompt with code generation
11. **Sources/skit-analyze/Models.swift** - Data models (LibraryUpdateResult, UpdatedFile, NewFile, AnalyzerError)
12. **Package.swift** (modify) - Add ConfigKeyKit target, swift-configuration dependency, and executable target

## Verification Steps

1. **Build Test**:
   ```bash
   swift build -c release
   ```

2. **Create Test Input**:
   ```bash
   # Create input folder with test case
   mkdir -p examples/simple-property

   cat > examples/simple-property/dsl.swift << 'EOF'
   Struct("Person") {
       Variable("age", type: "Int")
   }
   EOF

   cat > examples/simple-property/expected.swift << 'EOF'
   struct Person {
       let age: Int
   }
   EOF
   ```

3. **Run Tool**:
   ```bash
   export ANTHROPIC_API_KEY="sk-ant-..."
   .build/release/skit-analyze \
       examples/simple-property \
       Sources/SyntaxKit \
       output/SyntaxKit-updated
   ```

4. **Verify Output**:
   ```bash
   # Check that output directory was created
   ls -la output/SyntaxKit-updated

   # Verify updated files exist
   # Should see modified/new files for the feature

   # Check that generated code is valid Swift
   cd output/SyntaxKit-updated && swift build
   ```

5. **Test Generated Code**:
   ```bash
   # Create a test that uses the new feature
   # Verify it compiles and produces expected output
   ```

6. **Error Handling Tests**:
   ```bash
   # Test missing API key
   skit-analyze examples/test Sources/SyntaxKit output  # Should error

   # Test invalid input folder
   skit-analyze nonexistent Sources/SyntaxKit output  # Should error

   # Test missing required files
   mkdir -p examples/incomplete
   echo "test" > examples/incomplete/dsl.swift
   # Missing expected.swift - should error
   skit-analyze examples/incomplete Sources/SyntaxKit output
   ```

7. **Integration Test**: Use a real missing feature (e.g., subscript syntax) and verify:
   - Tool generates valid Swift code
   - Generated code follows SyntaxKit patterns
   - Generated code compiles
   - Feature actually works as expected

## 8. Test/Validation Mode

To ensure the prompt generates correct code changes reliably, we need a test mode that validates Claude's responses against known-good outputs.

### Overview

Test mode (`--test` flag) runs the tool against a suite of test cases with predefined inputs and expected outputs, then validates that Claude's generated code matches expectations.

### Test Case Structure

```
test-cases/
├── subscript-basic/
│   ├── input/
│   │   ├── dsl.swift           # Input DSL code
│   │   └── expected.swift      # Expected Swift output
│   ├── expected-changes/
│   │   ├── manifest.json       # List of expected file changes
│   │   └── Declarations/
│   │       └── Subscript.swift # Expected new/updated file content
│   └── test-config.json        # Test metadata (optional)
├── defer-statement/
│   └── ...
└── generic-function/
    └── ...
```

### Test Configuration Format

**manifest.json** - Describes expected changes:
```json
{
  "description": "Add subscript support to SyntaxKit",
  "expectedNewFiles": [
    "Declarations/Subscript.swift",
    "Declarations/SubscriptParameter.swift"
  ],
  "expectedUpdatedFiles": [
    "Core/CodeBlock.swift"
  ],
  "minimumNewFiles": 1,
  "minimumUpdatedFiles": 0,
  "validationStrategy": "structural",
  "buildRequired": true
}
```

**test-config.json** - Test metadata (optional):
```json
{
  "name": "Subscript Basic Support",
  "description": "Tests basic subscript declaration generation",
  "tags": ["declaration", "subscript", "basic"],
  "priority": "high",
  "model": "claude-opus-4-6",
  "timeout": 120
}
```

### Validation Strategies

1. **Structural Validation** (`structural`):
   - Verifies expected files were created/modified
   - Checks file paths match expectations
   - Does not validate exact content

2. **Content Validation** (`content`):
   - Compares generated file content against expected content
   - Allows for minor whitespace/formatting differences
   - Validates key code structures are present

3. **Build Validation** (`build`):
   - Runs `swift build` on generated library
   - Verifies no compilation errors
   - Does not compare against expected content

4. **Functional Validation** (`functional`):
   - Runs test suite against generated library
   - Verifies generated code produces correct output
   - Requires test files in test case

### Implementation Components

See the full implementation plan in the main plan file for detailed component specifications including:
- Updated AnalyzerConfiguration with test mode flags
- TestRunner for orchestrating test execution
- TestCaseDiscoverer for finding and loading test cases
- TestValidator for validating results against expectations
- TestModels for test data structures

### Usage

```bash
# Run all test cases
skit-analyze --test

# Run with verbose output
skit-analyze --test --verbose

# Stop on first failure
skit-analyze --test --test-stop-on-fail

# Run only tests matching "subscript"
skit-analyze --test --test-filter=subscript

# Run tests from custom path
skit-analyze --test --test-cases=custom-tests/
```

### Benefits

1. **Prompt Validation**: Ensures the Claude prompt generates correct code
2. **Regression Prevention**: Catches when prompt changes break existing features
3. **Quality Assurance**: Validates generated code quality before deployment
4. **Documentation**: Test cases serve as examples of expected behavior
5. **Confidence**: Developers can iterate on prompts with confidence
6. **Debugging**: Failed tests pinpoint exactly what's wrong with generated code

## Future Enhancements (Not in Scope)

- **Validation Mode**: Run `swift build` on generated code and retry if compilation fails
- **Interactive Review**: Show diff before writing, allow user to approve/reject changes
- **Batch Processing**: Process multiple feature folders in one run
- **Incremental Updates**: Only update changed files, preserve git history
- **Test Generation**: Also generate unit tests for new features
- **Template Library**: Save/reuse common patterns across feature generations
- **Local Caching**: Cache library code and API responses to reduce API calls
- **Multi-Provider**: Support OpenAI, Google Gemini as alternative to Claude
- **Diff Output**: Optionally output unified diffs instead of complete files

## Dependencies Summary

**New Dependencies**:
- `swift-configuration` (1.0.0+) with `CommandLineArguments` trait - Configuration management

**Existing Dependencies** (reused):
- `ConfigKeyKit` (in project) - Configuration key abstraction
- `SwiftSyntax` (601.0.1+) - via SyntaxParser
- `SyntaxParser` (existing module) - AST generation
- Foundation - HTTP requests, file I/O

**Advantages of swift-configuration + ConfigKeyKit**:
- Unified handling of CLI args and environment variables
- Type-safe configuration keys with automatic naming transformations
- Composable provider hierarchy (CLI overrides ENV)
- Consistent with project's existing ConfigKeyKit architecture
- More flexible than ArgumentParser for complex configuration scenarios

## Build & Install

```bash
# Build
swift build -c release

# Install to system (optional)
cp .build/release/skit-analyze /usr/local/bin/

# Or run from build directory
.build/release/skit-analyze <args>
```

## Example Usage

### Basic Example: Add Subscript Support

```bash
# 1. Create input folder with feature specification
mkdir -p examples/subscript-feature

# 2. Define the desired DSL syntax
cat > examples/subscript-feature/dsl.swift << 'EOF'
Struct("Collection") {
    Subscript(parameters: [Parameter("index", type: "Int")], returnType: "Element") {
        Return(PropertyAccessExp("items", "index"))
    }
}
EOF

# 3. Define expected Swift output
cat > examples/subscript-feature/expected.swift << 'EOF'
struct Collection {
    subscript(index: Int) -> Element {
        return items[index]
    }
}
EOF

# 4. Run the tool
# Note: AST is automatically generated from expected.swift using SyntaxParser
export ANTHROPIC_API_KEY="sk-ant-..."
skit-analyze \
    examples/subscript-feature \
    Sources/SyntaxKit \
    output/SyntaxKit-with-subscripts
```

### Advanced Examples

```bash
# With custom model
skit-analyze examples/my-feature Sources/SyntaxKit output/updated \
    --model claude-sonnet-4-5

# With verbose output to see what's happening
skit-analyze examples/my-feature Sources/SyntaxKit output/updated \
    --verbose

# Using CLI flag for API key instead of environment
skit-analyze examples/my-feature Sources/SyntaxKit output/updated \
    --api-key sk-ant-...

# Show help
skit-analyze --help
```

### Full Workflow Example

```bash
# Step 1: Identify a missing feature (e.g., defer statements)
mkdir -p examples/defer-statement

# Step 2: Write the DSL you wish existed
cat > examples/defer-statement/dsl.swift << 'EOF'
Function("cleanup") {
    Defer {
        Call("closeFile")
    }
}
EOF

# Step 3: Write what Swift code it should generate
cat > examples/defer-statement/expected.swift << 'EOF'
func cleanup() {
    defer {
        closeFile()
    }
}
EOF

# Step 4: Generate updated SyntaxKit with defer support
export ANTHROPIC_API_KEY="sk-ant-..."
skit-analyze \
    examples/defer-statement \
    Sources/SyntaxKit \
    output/SyntaxKit-with-defer \
    --verbose

# Step 5: Verify it works
cd output/SyntaxKit-with-defer
swift build

# Step 6: Test the new feature
# Create a test file that uses Defer { ... }
# Run it and verify output matches expected
```
