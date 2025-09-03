#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
DARK_GRAY='\033[1;30m'
NC='\033[0m' # No Color

BINARY_FILE="./src/bin/fany_rust.rs"
CARGO_TOML_FILE="./Cargo.toml"

show_help() {
    echo ""
    echo -e "🦀 ${YELLOW}fany-rust${NC} - Simple Rust function tester"
    echo ""
    echo -e "📖 ${CYAN}Usage:${NC}"
    echo -e "  ./fany-rust.sh ${GREEN}--tes${NC} ${YELLOW}<function_name>${NC}"
    echo -e "  ./fany-rust.sh ${GREEN}--help${NC}"
    echo ""
    exit 0
}

write_success() {
    echo -e "✅ ${GREEN}$1${NC}"
}

write_info() {
    echo -e "ℹ️  ${CYAN}$1${NC}"
}

write_warning() {
    echo -e "⚠️  ${YELLOW}$1${NC}"
}

write_error() {
    echo -e "❌ ${RED}$1${NC}"
}

write_progress() {
    echo -e "🔄 ${PURPLE}$1${NC}"
}

get_package_name() {
    if [[ ! -f "$CARGO_TOML_FILE" ]]; then
        write_error "Cargo.toml tidak ditemukan! Pastikan Anda berada di root project Rust."
        exit 1
    fi
    
    local package_name
    package_name=$(grep -E '^name\s*=' "$CARGO_TOML_FILE" | head -1 | sed -E 's/.*name\s*=\s*"([^"]+)".*/\1/')
    
    if [[ -z "$package_name" ]]; then
        write_error "Tidak dapat menemukan nama package di Cargo.toml"
        exit 1
    fi
    
    echo "$package_name"
}

# Parse arguments
COMMAND=""
FUNC=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            ;;
        --tes)
            COMMAND="--tes"
            FUNC="$2"
            shift 2
            ;;
        *)
            show_help
            ;;
    esac
done

# Check if command and function are provided
if [[ "$COMMAND" != "--tes" || -z "$FUNC" ]]; then
    show_help
fi

# Get package name from Cargo.toml
PACKAGE_NAME=$(get_package_name)
write_info "Detected package name: '$PACKAGE_NAME'"

# Create binary file if it doesn't exist
if [[ ! -f "$BINARY_FILE" ]]; then
    write_progress "Membuat file $BINARY_FILE secara otomatis..."
    mkdir -p "$(dirname "$BINARY_FILE")"
    
    cat > "$BINARY_FILE" << EOF
use $PACKAGE_NAME;

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 3 || args[1] != "--tes" {
        println!("Usage: fany-rust --tes <function_name>");
        return;
    }
    
    let func = &args[2];
    match func.as_str() {
        _ => println!("Function '{}' not found.", func),
    }
}
EOF
    write_success "File template berhasil dibuat dengan package '$PACKAGE_NAME'!"
fi

# Read current content
CONTENT=$(cat "$BINARY_FILE")

# Make sure we're using the correct package name
if ! echo "$CONTENT" | grep -q "use $PACKAGE_NAME;"; then
    write_warning "Memperbarui package name menjadi '$PACKAGE_NAME'..."
    sed -i.bak "s/^use [^;]*;/use $PACKAGE_NAME;/" "$BINARY_FILE"
    rm -f "${BINARY_FILE}.bak" 2>/dev/null
    CONTENT=$(cat "$BINARY_FILE")
fi

# Check if function already exists
if ! echo "$CONTENT" | grep -q "\"$FUNC\""; then
    write_progress "Menambahkan stub untuk function '$FUNC'..."
    
    # Extract existing functions
    FUNCTIONS=()
    while IFS= read -r line; do
        if [[ "$line" =~ \"([^\"]+)\"[[:space:]]*=\>[[:space:]]*\{ ]]; then
            func_name="${BASH_REMATCH[1]}"
            if [[ "$func_name" != "$FUNC" ]]; then
                FUNCTIONS+=("$func_name")
            fi
        fi
    done <<< "$CONTENT"
    
    # Add the new function
    FUNCTIONS+=("$FUNC")
    
    # Generate new file content
    cat > "$BINARY_FILE" << EOF
use $PACKAGE_NAME;

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 3 || args[1] != "--tes" {
        println!("Usage: fany-rust --tes <function_name>");
        return;
    }
    
    let func = &args[2];
    match func.as_str() {
EOF

    # Add all function cases
    for fn in "${FUNCTIONS[@]}"; do
        cat >> "$BINARY_FILE" << EOF
        "$fn" => {
            let result = ${PACKAGE_NAME}::$fn();
            println!("{}", serde_json::to_string_pretty(&result).unwrap());
        },
EOF
    done
    
    # Add default case
    cat >> "$BINARY_FILE" << 'EOF'
        _ => println!("Function '{}' not found.", func),
    }
}
EOF

    write_success "Function '$FUNC' berhasil ditambahkan ke package '$PACKAGE_NAME'!"
    
    if [[ ${#FUNCTIONS[@]} -gt 1 ]]; then
        write_info "Functions yang tersedia dalam package '$PACKAGE_NAME':"
        for fn in "${FUNCTIONS[@]}"; do
            if [[ "$fn" == "$FUNC" ]]; then
                echo -e "  • ${YELLOW}$fn${NC} ${GREEN}(baru)${NC}"
            else
                echo -e "  • ${GRAY}$fn${NC}"
            fi
        done
    fi
else
    write_info "Function '$FUNC' sudah ada di package '$PACKAGE_NAME', menggunakan yang sudah ada..."
fi

echo ""
echo -e "🚀 ${WHITE}Menjalankan function ${CYAN}'$FUNC'${WHITE} dari package ${YELLOW}'$PACKAGE_NAME'${WHITE}...${NC}"
echo -e "${DARK_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cargo run --bin fany_rust -- --tes "$FUNC"
EXIT_CODE=$?

echo -e "${DARK_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ $EXIT_CODE -eq 0 ]]; then
    write_success "Function dari package '$PACKAGE_NAME' berhasil dijalankan!"
else
    write_error "Function gagal dijalankan dengan exit code: $EXIT_CODE"
fi