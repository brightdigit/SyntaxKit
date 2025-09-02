#!/bin/bash

set -e  # Exit on any error

ERRORS=0
WARNINGS=0

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
    SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
    PACKAGE_DIR="${SCRIPT_DIR}/.."
else
    PACKAGE_DIR="${SRCROOT}"     
fi

pushd "$PACKAGE_DIR" > /dev/null

# Function to validate external URLs
validate_external_urls() {
    echo -e "\n${BLUE}🌐 Validating External URLs...${NC}"
    
    # Extract URLs from all markdown files
    local urls_file=$(mktemp)
    
    # Extract URLs more precisely
    {
        # Extract from markdown links [text](url)
        grep -h -o '\](https\?://[^)]*)'  Sources/SyntaxKit/Documentation.docc/**/*.md README.md CONTRIBUTING-DOCS.md 2>/dev/null | \
            sed 's/](\(https\?:\/\/[^)]*\)).*/\1/' 
            
        # Extract standalone URLs (not in markdown links or Swift package syntax)
        grep -h -o 'https\?://[^[:space:])]*' Sources/SyntaxKit/Documentation.docc/**/*.md README.md CONTRIBUTING-DOCS.md 2>/dev/null | \
            grep -v -E '(\.git"|from:|package\(|url:)' | \
            sed 's/[,;."`]*$//'
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
    local docc_links=$(grep -h -o '<doc:[^>]*>' Sources/SyntaxKit/Documentation.docc/**/*.md 2>/dev/null | sort -u || true)
    
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
    local symbol_refs=$(grep -h -o '``[^`]*``' Sources/SyntaxKit/Documentation.docc/**/*.md 2>/dev/null | sort -u || true)
    
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
    local cross_refs=$(grep -h -o '\[.*\]([^)]*\.md)' Sources/SyntaxKit/Documentation.docc/**/*.md 2>/dev/null | sort -u || true)
    
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
        SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
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
    local temp_dir=$(mktemp -d)
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
    
    # Build SyntaxKit first for type checking
    echo -e "${BLUE}🏗️  Building SyntaxKit for type checking...${NC}"
    if ! swift build --quiet; then
        echo -e "${RED}❌ Failed to build SyntaxKit. Cannot validate code examples.${NC}"
        rm -rf "$temp_dir"
        ((ERRORS++))
        return 1
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
                    
                    # Try to typecheck the extracted Swift code
                    if swift -frontend -typecheck \
                        -sdk "$(xcrun --show-sdk-path)" \
                        -I "$PWD/.build/debug" \
                        "$swift_file" 2>/dev/null; then
                        echo -e "${GREEN}✅ Valid${NC}"
                        ((examples_valid++))
                    else
                        echo -e "${RED}❌ Invalid${NC}"
                        echo -e "${YELLOW}    Code:${NC}"
                        sed 's/^/      /' "$swift_file"
                        echo -e "${YELLOW}    Errors:${NC}"
                        swift -frontend -typecheck \
                            -sdk "$(xcrun --show-sdk-path)" \
                            -I "$PWD/.build/debug" \
                            "$swift_file" 2>&1 | sed 's/^/      /' || true
                        ((examples_failed++))
                        ((ERRORS++))
                    fi
                fi
            done <<< "$swift_files"
        fi
    done < <(find Sources/SyntaxKit/Documentation.docc -name "*.md" -type f; \
             find . -maxdepth 1 -name "README.md" -type f; \
             find Examples -name "README.md" -type f 2>/dev/null || true)
    
    # Clean up
    rm -rf "$temp_dir"
    
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

# Main validation workflow
main() {
    validate_external_urls
    validate_docc_links  
    validate_swift_symbols
    validate_cross_references
    validate_api_coverage
    validate_code_examples
    
    echo -e "\n${BLUE}📊 Validation Summary${NC}"
    echo "═══════════════════════════════════"
    
    if [ $ERRORS -eq 0 ]; then
        echo -e "${GREEN}✅ All documentation links are valid!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Found $ERRORS validation error(s)${NC}"
        if [ $WARNINGS -gt 0 ]; then
            echo -e "${YELLOW}⚠️  Found $WARNINGS warning(s)${NC}"
        fi
        exit 1
    fi
}

# Allow script to be sourced for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

popd > /dev/null