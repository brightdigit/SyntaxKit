#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SOURCES_DIR="Sources"
FORMAT="text"
FAIL_ON_MISSING=false
THRESHOLD=100.0

print_usage() {
    echo "Usage: api-coverage.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --sources-dir PATH    Path to sources directory (default: Sources)"
    echo "  --format FORMAT       Output format: text, json (default: text)"
    echo "  --fail-on-missing     Exit with error code if any APIs lack documentation"
    echo "  --threshold PERCENT   Minimum coverage threshold (0-100, default: 100)"
    echo "  --help               Show this help message"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --sources-dir)
            SOURCES_DIR="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            if [[ ! "$FORMAT" =~ ^(text|json)$ ]]; then
                echo "Error: format must be 'text' or 'json'"
                exit 1
            fi
            shift 2
            ;;
        --fail-on-missing)
            FAIL_ON_MISSING=true
            shift
            ;;
        --threshold)
            THRESHOLD="$2"
            shift 2
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1"
            print_usage
            exit 1
            ;;
    esac
done

# Function to check if a line contains documentation comment
has_documentation() {
    local line="$1"
    [[ "$line" =~ ^[[:space:]]*/// || "$line" =~ ^[[:space:]]*\/\*\* ]]
}

# Function to extract public API declarations
analyze_swift_file() {
    local file="$1"
    local undocumented_apis=()
    local total_apis=0
    local documented_apis=0
    
    # Read file line by line
    local line_num=0
    local prev_line=""
    local has_doc=false
    
    while IFS= read -r line; do
        ((line_num++))
        
        # Check if previous line had documentation
        if has_documentation "$prev_line"; then
            has_doc=true
        elif [[ "$prev_line" =~ ^[[:space:]]*$ ]]; then
            # Empty line, keep current documentation status
            :
        elif [[ ! "$prev_line" =~ ^[[:space:]]*// ]]; then
            # Non-comment, non-empty line resets documentation status
            has_doc=false
        fi
        
        # Check for public API declarations
        if [[ "$line" =~ ^[[:space:]]*public[[:space:]]+(struct|class|enum|protocol|func|var|let|init|typealias) ]]; then
            ((total_apis++))
            
            # Extract API info
            local api_type
            if [[ "$line" =~ public[[:space:]]+(struct|class|enum|protocol|func|var|let|init|typealias) ]]; then
                api_type="${BASH_REMATCH[1]}"
            fi
            
            local api_name
            case "$api_type" in
                struct|class|enum|protocol|typealias)
                    api_name=$(echo "$line" | sed -E 's/.*public[[:space:]]+(struct|class|enum|protocol|typealias)[[:space:]]+([^[:space:]{<(]+).*/\2/')
                    ;;
                func)
                    api_name=$(echo "$line" | sed -E 's/.*func[[:space:]]+([^[:space:](]+).*/\1/')
                    ;;
                var|let)
                    api_name=$(echo "$line" | sed -E 's/.*public[[:space:]]+(var|let)[[:space:]]+([^[:space:]:=]+).*/\2/')
                    ;;
                init)
                    api_name="init"
                    ;;
            esac
            
            if [[ "$has_doc" == true ]]; then
                ((documented_apis++))
            else
                undocumented_apis+=("$file:$line_num - $api_type $api_name")
            fi
        fi
        
        prev_line="$line"
    done < "$file"
    
    # Return results via global variables (bash limitations)
    echo "$total_apis,$documented_apis,$(IFS='|'; echo "${undocumented_apis[*]}")"
}

main() {
    local total_apis=0
    local documented_apis=0
    local all_undocumented=()
    
    # Find all Swift files
    while IFS= read -r -d '' file; do
        local result
        result=$(analyze_swift_file "$file")
        
        local file_total file_documented file_undocumented
        IFS=',' read -r file_total file_documented file_undocumented <<< "$result"
        
        total_apis=$((total_apis + file_total))
        documented_apis=$((documented_apis + file_documented))
        
        if [[ -n "$file_undocumented" ]]; then
            IFS='|' read -ra undoc_array <<< "$file_undocumented"
            all_undocumented+=("${undoc_array[@]}")
        fi
        
    done < <(find "$SOURCES_DIR" -name "*.swift" -type f -print0)
    
    # Calculate coverage percentage
    local coverage=0
    if [[ $total_apis -gt 0 ]]; then
        coverage=$(echo "scale=1; $documented_apis * 100.0 / $total_apis" | bc -l 2>/dev/null || echo "0")
    else
        coverage=100.0
    fi
    
    # Output results
    case "$FORMAT" in
        json)
            echo "{"
            echo "  \"totalAPIs\": $total_apis,"
            echo "  \"documentedAPIs\": $documented_apis,"
            echo "  \"coveragePercentage\": $coverage,"
            echo "  \"undocumentedAPIs\": ["
            local first=true
            for api in "${all_undocumented[@]}"; do
                if [[ "$first" == true ]]; then
                    first=false
                else
                    echo ","
                fi
                local file_line api_info
                file_line="${api% - *}"
                api_info="${api#* - }"
                local file_path line_num
                file_path="${file_line%:*}"
                line_num="${file_line#*:}"
                local api_type api_name
                api_type="${api_info% *}"
                api_name="${api_info#* }"
                echo -n "    {\"name\": \"$api_name\", \"type\": \"$api_type\", \"filePath\": \"$file_path\", \"line\": $line_num}"
            done
            if [[ ${#all_undocumented[@]} -gt 0 ]]; then
                echo ""
            fi
            echo "  ]"
            echo "}"
            ;;
        *)
            echo -e "${BLUE}🔍 SyntaxKit API Documentation Coverage Report${NC}"
            echo "════════════════════════════════════════════"
            echo ""
            echo -e "${BLUE}📊 Coverage Summary:${NC}"
            echo "  Total public APIs: $total_apis"
            echo "  Documented APIs: $documented_apis"
            echo "  Coverage: ${coverage}%"
            echo ""
            
            if [[ ${#all_undocumented[@]} -gt 0 ]]; then
                echo -e "${RED}❌ Missing Documentation:${NC}"
                printf '%s\n' "${all_undocumented[@]}" | sort
                echo ""
            fi
            
            if (( $(echo "$coverage >= $THRESHOLD" | bc -l) )); then
                echo -e "${GREEN}✅ Coverage threshold met (${THRESHOLD}%)${NC}"
            else
                echo -e "${RED}❌ Coverage below threshold (${THRESHOLD}%)${NC}"
            fi
            ;;
    esac
    
    # Exit with appropriate code
    local should_fail=false
    if [[ "$FAIL_ON_MISSING" == true && ${#all_undocumented[@]} -gt 0 ]]; then
        should_fail=true
    fi
    if (( $(echo "$coverage < $THRESHOLD" | bc -l) )); then
        should_fail=true
    fi
    
    if [[ "$should_fail" == true ]]; then
        exit 1
    else
        exit 0
    fi
}

main "$@"