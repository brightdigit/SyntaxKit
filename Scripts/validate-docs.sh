#!/bin/bash

#set -e  # Exit on any error

ERRORS=0
WARNINGS=0
SKIP_BUILD=true
SKIP_CODE_EXAMPLES=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --build)
            SKIP_BUILD=false
            shift
            ;;
        --skip-code-examples)
            SKIP_CODE_EXAMPLES=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --build              Force rebuild of SyntaxKit before validation"
            echo "  --skip-code-examples Skip validating Swift code examples"
            echo "  -h, --help          Show this help message"
            echo ""
            echo "By default, the script will use existing builds to speed up validation."
            echo "Use --build if you need to ensure a fresh build before validation."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 SyntaxKit Documentation Link Validator${NC}"
echo "═════════════════════════════════════════════"

# More portable way to get script directory
if [ -z "$SRCROOT" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    PACKAGE_DIR="${SCRIPT_DIR}/.."
else
    PACKAGE_DIR="${SRCROOT}"     
fi

pushd "$PACKAGE_DIR" > /dev/null

# Function to validate external URLs
validate_external_urls() {
    echo -e "\n${BLUE}🌐 Validating External URLs...${NC}"
    
    # Extract URLs from all markdown files
    if [ -n "$RUNNER_TEMP" ]; then
        local urls_file="$RUNNER_TEMP/urls_file.txt"
    else
        local urls_file=$(mktemp)
    fi
    
    # Extract URLs more precisely using find instead of bash globs for portability
    {
        # Find all markdown files and extract URLs from them
        find Sources/SyntaxKit/Documentation.docc -name "*.md" -type f 2>/dev/null | while read -r file; do
            # Extract from markdown links [text](url)
            grep -h -o '\](https\?://[^)]*)'  "$file" 2>/dev/null | sed 's/](\(https\?:\/\/[^)]*\)).*/\1/' || true
            # Extract standalone URLs (not in markdown links or Swift package syntax)
            grep -h -o 'https\?://[^[:space:])]*' "$file" 2>/dev/null | grep -v -E '(\.git"|from:|package\(|url:)' | sed 's/[,;."`]*$//' || true
        done
        
        # Also check root level files if they exist
        for file in README.md CONTRIBUTING-DOCS.md; do
            if [ -f "$file" ]; then
                grep -h -o '\](https\?://[^)]*)'  "$file" 2>/dev/null | sed 's/](\(https\?:\/\/[^)]*\)).*/\1/' || true
                grep -h -o 'https\?://[^[:space:])]*' "$file" 2>/dev/null | grep -v -E '(\.git"|from:|package\(|url:)' | sed 's/[,;."`]*$//' || true
            fi
        done
    } | grep -E '^https?://' | sort -u > "$urls_file" || true
    
    if [ ! -s "$urls_file" ]; then
        echo -e "${GREEN}✅ No external URLs found to validate${NC}"
        rm "$urls_file"
        return 0
    fi
    
    local url_count=$(wc -l < "$urls_file")
    echo -e "${BLUE}📊 Found $url_count unique external URLs to validate${NC}"
    
    local failed_urls=0
    
    while IFS= read -r url; do
        # Skip localhost and placeholder URLs
        if [[ "$url" =~ localhost|127\.0\.0\.1|example\.com|placeholder ]]; then
            echo -e "${YELLOW}⚠️  Skipping: $url (localhost/placeholder)${NC}"
            continue
        fi
        
        echo -n "Checking: $url ... "
        
        # Use curl with timeout and follow redirects
        if curl -s --max-time 10 --fail -L "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌ Failed${NC}"
            ((failed_urls++))
            ((ERRORS++))
        fi
    done < "$urls_file"
    
    rm "$urls_file"
    
    if [ $failed_urls -gt 0 ]; then
        echo -e "${RED}❌ $failed_urls external URL(s) failed validation${NC}"
    else
        echo -e "${GREEN}✅ All external URLs are accessible${NC}"
    fi
}

# Function to validate internal DocC links
validate_docc_links() {
    echo -e "\n${BLUE}📚 Validating DocC Internal Links...${NC}"
    
    # Find all DocC link references like <doc:Page-Name>
    local docc_links=$(find Sources/SyntaxKit/Documentation.docc -name "*.md" -type f -exec grep -h -o '<doc:[^>]*>' {} \; 2>/dev/null | sort -u || true)
    
    if [ -z "$docc_links" ]; then
        echo -e "${GREEN}✅ No DocC links found to validate${NC}"
        return 0
    fi
    
    echo -e "${BLUE}📊 Found DocC links to validate:${NC}"
    echo "$docc_links" | sed 's/^/  /'
    
    local failed_links=0
    
    while IFS= read -r link; do
        if [ -z "$link" ]; then continue; fi
        
        # Extract the document name from <doc:Document-Name>
        doc_name=$(echo "$link" | sed 's/<doc:\([^>]*\)>/\1/')
        
        echo -n "Checking DocC link: $doc_name ... "
        
        # Look for corresponding file (handle both .md and Tutorial directories)
        if find Sources/SyntaxKit/Documentation.docc -name "*${doc_name}*" -type f | grep -q .; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌ Document not found${NC}"
            ((failed_links++))
            ((ERRORS++))
        fi
    done <<< "$docc_links"
    
    if [ $failed_links -gt 0 ]; then
        echo -e "${RED}❌ $failed_links DocC link(s) failed validation${NC}"
    else
        echo -e "${GREEN}✅ All DocC internal links are valid${NC}"
    fi
}

# Function to validate Swift symbol references
validate_swift_symbols() {
    echo -e "\n${BLUE}🔧 Validating Swift Symbol References...${NC}"
    
    # Find all double-backtick symbol references in SyntaxKit docs
    local symbol_refs=$(find Sources/SyntaxKit/Documentation.docc -name "*.md" -type f -exec grep -h -o '``[^`]*``' {} \; 2>/dev/null | sort -u || true)
    
    if [ -z "$symbol_refs" ]; then
        echo -e "${GREEN}✅ No Swift symbol references found to validate${NC}"
        return 0
    fi
    
    echo -e "${BLUE}📊 Found Swift symbol references to validate:${NC}"
    echo "$symbol_refs" | sed 's/^/  /'
    
    # Create a simple symbol validation by checking if symbols exist in source files
    local failed_symbols=0
    
    while IFS= read -r symbol_ref; do
        if [ -z "$symbol_ref" ]; then continue; fi
        
        # Extract symbol name from ``SymbolName``
        symbol_name=$(echo "$symbol_ref" | sed 's/``\([^`]*\)``.*/\1/')
        
        echo -n "Checking symbol: $symbol_name ... "
        
        # Check if symbol exists in source files (struct, class, func, enum, protocol, typealias)
        if grep -r -q "^\s*\(public\|internal\|private\).*\(struct\|class\|func\|enum\|protocol\|typealias\|var\|let\).*\b$symbol_name\b" Sources/SyntaxKit/ 2>/dev/null; then
            echo -e "${GREEN}✅${NC}"
        elif grep -r -q "\b$symbol_name\b" Sources/SyntaxKit/ 2>/dev/null; then
            echo -e "${GREEN}✅ (found in sources)${NC}"
        else
            echo -e "${YELLOW}⚠️  Symbol not found in sources${NC}"
            ((WARNINGS++))
        fi
    done <<< "$symbol_refs"
    
    if [ $failed_symbols -gt 0 ]; then
        echo -e "${RED}❌ $failed_symbols Swift symbol(s) failed validation${NC}"
    else
        echo -e "${GREEN}✅ All Swift symbol references validated${NC}"
    fi
}

# Function to validate cross-references between tutorials
validate_cross_references() {
    echo -e "\n${BLUE}🔗 Validating Cross-References...${NC}"
    
    # Extract references to other tutorials and articles
    local cross_refs=$(find Sources/SyntaxKit/Documentation.docc -name "*.md" -type f -exec grep -h -o '\[.*\]([^)]*\.md)' {} \; 2>/dev/null | sort -u || true)
    
    if [ -z "$cross_refs" ]; then
        echo -e "${GREEN}✅ No cross-references found to validate${NC}"
        return 0
    fi
    
    echo -e "${BLUE}📊 Found cross-references to validate:${NC}"
    echo "$cross_refs" | sed 's/^/  /'
    
    local failed_refs=0
    
    while IFS= read -r ref; do
        if [ -z "$ref" ]; then continue; fi
        
        # Extract the file path from [text](path.md)
        file_path=$(echo "$ref" | sed 's/.*(\([^)]*\))/\1/')
        
        echo -n "Checking cross-reference: $file_path ... "
        
        # Check if the referenced file exists
        if [ -f "Sources/SyntaxKit/Documentation.docc/$file_path" ] || [ -f "$file_path" ]; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌ File not found${NC}"
            ((failed_refs++))
            ((ERRORS++))
        fi
    done <<< "$cross_refs"
    
    if [ $failed_refs -gt 0 ]; then
        echo -e "${RED}❌ $failed_refs cross-reference(s) failed validation${NC}"
    else
        echo -e "${GREEN}✅ All cross-references are valid${NC}"
    fi
}

# Function to validate API documentation coverage
validate_api_coverage() {
    echo -e "\n${BLUE}📊 Validating API Documentation Coverage...${NC}"
    
    # More portable way to get script directory
    if [ -z "$SRCROOT" ]; then
        SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
        PACKAGE_DIR="${SCRIPT_DIR}/.."
    else
        PACKAGE_DIR="${SRCROOT}"     
    fi
    
    local coverage_script="$PACKAGE_DIR/Scripts/api-coverage.sh"
    
    if [ ! -f "$coverage_script" ]; then
        echo -e "${YELLOW}⚠️  API coverage script not found at $coverage_script${NC}"
        ((WARNINGS++))
        return 0
    fi
    
    echo -e "${BLUE}🔍 Running API documentation coverage analysis...${NC}"
    
    # Run API coverage tool
    if "$coverage_script" --sources-dir "Sources/SyntaxKit" --threshold 90; then
        echo -e "${GREEN}✅ API documentation coverage meets threshold${NC}"
    else
        echo -e "${RED}❌ API documentation coverage below threshold${NC}"
        ((ERRORS++))
    fi
}

# Function to validate Swift code examples in documentation
validate_code_examples() {
    echo -e "\n${BLUE}💻 Validating Swift Code Examples...${NC}"
    
    # Create temporary directory for extracted code
    if [ -n "$RUNNER_TEMP" ]; then
        local temp_dir="$RUNNER_TEMP/code_examples"
        mkdir -p "$temp_dir"
    else
        local temp_dir=$(mktemp -d)
    fi
    local examples_found=0
    local examples_valid=0
    local examples_failed=0
    
    # Function to extract and validate Swift code from a file
    validate_file_examples() {
        local file="$1"
        local relative_path="${file#$PWD/}"
        
        echo -e "${BLUE}📄 Processing: $relative_path${NC}"
        
        # Extract Swift code blocks using awk
        awk -v temp_dir="$temp_dir" -v file_base="$(basename "$file" .md)" '
            BEGIN { block_num = 0 }
            /^```swift/ { 
                in_swift = 1
                block_num++
                output_file = temp_dir "/" file_base "_" block_num ".swift"
                print "import Foundation" > output_file
                print "import SyntaxKit" >> output_file
                print "" >> output_file
                next 
            }
            /^```$/ && in_swift { 
                in_swift = 0
                close(output_file)
                print output_file
                next 
            }
            in_swift { 
                print $0 >> output_file 
            }
        ' "$file"
    }
    
    # Build SyntaxKit first for type checking (only if not already built and not skipped)
    if [ "$SKIP_BUILD" = false ]; then
        if [ ! -d ".build" ] || [ ! -f ".build/debug/skit" ]; then
            echo -e "${BLUE}🏗️  Building SyntaxKit for type checking...${NC}"
            if ! swift build --quiet; then
                echo -e "${RED}❌ Failed to build SyntaxKit. Cannot validate code examples.${NC}"
                rm -rf "$temp_dir"
                ((ERRORS++))
                return 1
            fi
        else
            echo -e "${BLUE}♻️  Using existing SyntaxKit build for type checking...${NC}"
        fi
    else
        echo -e "${BLUE}⚡ Skipping SyntaxKit build (default behavior for speed)${NC}"
        if [ ! -d ".build" ]; then
            echo -e "${YELLOW}⚠️  Warning: No .build directory found, use --build flag to build first${NC}"
            ((WARNINGS++))
        fi
    fi
    
    # Process all documentation files
    while IFS= read -r doc_file; do
        local swift_files
        swift_files=$(validate_file_examples "$doc_file")
        
        if [ -n "$swift_files" ]; then
            while IFS= read -r swift_file; do
                if [ -f "$swift_file" ] && [ -s "$swift_file" ]; then
                    ((examples_found++))
                    
                    echo -n "  Validating $(basename "$swift_file"): "
                    
                    # Create a temporary Swift package to validate the code (reuse if possible)
                    if [ -z "$temp_package_dir" ]; then
                        if [ -n "$RUNNER_TEMP" ]; then
                            temp_package_dir="$RUNNER_TEMP/temp_package_validation"
                        else
                            temp_package_dir=$(mktemp -d)
                        fi
                        local package_swift="$temp_package_dir/Package.swift"
                        local sources_dir="$temp_package_dir/Sources/TestExample"
                        
                        # Create Package.swift with SyntaxKit dependency (only once)
                        mkdir -p "$sources_dir"
                        cat > "$package_swift" << EOF
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TestExample",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "$PWD")
    ],
    targets: [
        .executableTarget(
            name: "TestExample",
            dependencies: ["SyntaxKit"]
        )
    ]
)
EOF
                    fi
                    
                    # Copy example code to main.swift
                    local main_swift="$sources_dir/main.swift"
                    cp "$swift_file" "$main_swift"
                    
                    # Try to build the temporary package
                    if (cd "$temp_package_dir" && swift build --quiet 2>/dev/null); then
                        echo -e "${GREEN}✅ Valid${NC}"
                        ((examples_valid++))
                    else
                        echo -e "${RED}❌ Invalid${NC}"
                        echo -e "${YELLOW}    Code:${NC}"
                        sed 's/^/      /' "$swift_file"
                        echo -e "${YELLOW}    Build errors:${NC}"
                        (cd "$temp_package_dir" && swift build 2>&1 | sed 's/^/      /' || true)
                        ((examples_failed++))
                        ((ERRORS++))
                    fi
                    
                    # Note: temp_package_dir is cleaned up after all examples
                fi
            done <<< "$swift_files"
        fi
    done < <(find Sources/SyntaxKit/Documentation.docc -name "*.md" -type f 2>/dev/null; \
             find . -maxdepth 1 -name "README.md" -type f 2>/dev/null; \
             find Examples -name "README.md" -type f 2>/dev/null || true)
    
    # Clean up
    rm -rf "$temp_dir"
    if [ -n "$temp_package_dir" ]; then
        rm -rf "$temp_package_dir"
    fi
    
    # Report results
    echo -e "\n${BLUE}📊 Code Examples Summary:${NC}"
    echo "  Total examples found: $examples_found"
    echo "  Valid examples: $examples_valid"
    echo "  Failed examples: $examples_failed"
    
    if [ $examples_failed -eq 0 ]; then
        if [ $examples_found -eq 0 ]; then
            echo -e "${YELLOW}⚠️  No Swift code examples found in documentation${NC}"
        else
            echo -e "${GREEN}✅ All Swift code examples are valid!${NC}"
        fi
    else
        echo -e "${RED}❌ $examples_failed code example(s) failed validation${NC}"
    fi
}

# Function to provide error recovery suggestions
provide_error_recovery() {
    if [ $ERRORS -eq 0 ]; then
        return 0
    fi
    
    echo -e "\n${BLUE}💡 Error Recovery Suggestions${NC}"
    echo "═══════════════════════════════════"
    
    echo -e "${YELLOW}Common Documentation Issues & Fixes:${NC}"
    echo "• Broken external URLs:"
    echo "  → Update or remove outdated links"
    echo "  → Use web.archive.org for historical references"
    echo "  → Replace with current documentation URLs"
    echo ""
    echo "• Missing DocC files:"
    echo "  → Create referenced .md files in Documentation.docc/"
    echo "  → Fix typos in <doc:Page-Name> references"
    echo "  → Use proper DocC naming conventions (no spaces, use hyphens)"
    echo ""
    echo "• Invalid Swift symbols:"
    echo "  → Check symbol name spelling and capitalization"
    echo "  → Ensure symbols are public APIs (not internal/private)"
    echo "  → Update symbol references after API changes"
    echo ""
    echo "• Failed code examples:"
    echo "  → Add missing import statements"
    echo "  → Fix syntax errors in code blocks"
    echo "  → Ensure examples use current API signatures"
    echo "  → Test examples in Xcode playground first"
    echo ""
    echo "• Low API coverage:"
    echo "  → Add /// documentation comments to public APIs"
    echo "  → Use swift package generate-documentation to identify missing docs"
    echo "  → Follow DocC best practices for API documentation"
    echo ""
    echo -e "${BLUE}🔧 Quick Commands:${NC}"
    echo "• Fast validation (default): ./Scripts/validate-docs.sh"
    echo "• Skip slow code validation: ./Scripts/validate-docs.sh --skip-code-examples" 
    echo "• Full validation with rebuild: ./Scripts/validate-docs.sh --build"
    echo "• Generate docs: swift package generate-documentation"
    echo "• Check API coverage: ./Scripts/api-coverage.sh --threshold 90"
    echo "• Format code: ./Scripts/lint.sh"
}

# Main validation workflow
main() {
    validate_external_urls
    validate_docc_links  
    validate_swift_symbols
    validate_cross_references
    validate_api_coverage
    
    if [ "$SKIP_CODE_EXAMPLES" = false ]; then
        validate_code_examples
    else
        echo -e "\n${BLUE}⚡ Skipping Swift code examples validation${NC}"
    fi
    
    echo -e "\n${BLUE}📊 Validation Summary${NC}"
    echo "═══════════════════════════════════"
    
    if [ $ERRORS -eq 0 ]; then
        echo -e "${GREEN}✅ All documentation validation checks passed!${NC}"
        if [ $WARNINGS -gt 0 ]; then
            echo -e "${YELLOW}⚠️  Found $WARNINGS warning(s) - consider addressing these${NC}"
        fi
        exit 0
    else
        echo -e "${RED}❌ Found $ERRORS validation error(s)${NC}"
        if [ $WARNINGS -gt 0 ]; then
            echo -e "${YELLOW}⚠️  Found $WARNINGS warning(s)${NC}"
        fi
        
        provide_error_recovery
        exit 1
    fi
}

# Allow script to be sourced for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

popd > /dev/null