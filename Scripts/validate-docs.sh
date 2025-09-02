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

# Main validation workflow
main() {
    validate_external_urls
    validate_docc_links  
    validate_swift_symbols
    validate_cross_references
    
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