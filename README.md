# 🦀 fany-rust

A simple and colorful Rust function tester that automatically generates test runners for your Rust library functions.

## ✨ Features

- 🎯 **Simple CLI** - Easy-to-use command line interface
- 🔄 **Auto-generation** - Automatically creates test runners for your functions
- 🌈 **Colorful output** - Beautiful colored terminal output with emojis
- 🔧 **Cross-platform** - Works on Windows (PowerShell) and Unix-like systems (Bash)
- 📦 **Function management** - Keeps track of all your tested functions
- ⚡ **Fast execution** - Quick function testing with JSON-formatted output

## 📋 Prerequisites

- [Rust](https://rustup.rs/) installed on your system
- A Rust project with a `rust_core` library containing your functions
- PowerShell (Windows) or Bash (macOS/Linux)

## 🚀 Quick Start

### Windows (PowerShell)

1. **Download the script:**
   ```powershell
   # Place fany-rust.ps1 in your Rust project root
   ```

2. **Run your function:**
   ```powershell
   .\fany-rust.ps1 --tes generate_device_info
   ```

### macOS/Linux (Bash)

1. **Download and make executable:**
   ```bash
   chmod +x fany-rust.sh
   ```

2. **Run your function:**
   ```bash
   ./fany-rust.sh --tes generate_device_info
   ```

## 📖 Usage

### Command Line Options

```bash
# Test a specific function
./fany-rust.sh --tes <function_name>

# Show help
./fany-rust.sh --help
./fany-rust.sh -h
```

### Examples

```bash
# Test a function called generate_device_info
./fany-rust.sh --tes generate_device_info

# Test a function called process_data
./fany-rust.sh --tes process_data

# Show help
./fany-rust.sh --help
```

## 🎨 Output Example

```
🦀 fany-rust - Simple Rust function tester

🔄 Menambahkan stub untuk function 'generate_device_info'...
✅ Function 'generate_device_info' berhasil ditambahkan!
ℹ️  Functions yang tersedia:
  • generate_device_info (baru)

🚀 Menjalankan function 'generate_device_info'...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Compiling rust_core v0.1.0
    Finished dev [unoptimized + debuginfo] target(s)
     Running `target/debug/fany_rust --tes generate_device_info`
{
  "device_id": "abc123",
  "platform": "windows",
  "version": "1.0.0"
}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Function berhasil dijalankan!
```

## 📁 Project Structure

```
your_rust_project/
├── src/
│   ├── lib.rs              # Your rust_core library
│   └── bin/
│       └── fany_rust.rs    # Auto-generated test runner
├── fany-rust.ps1           # Windows PowerShell script
├── fany-rust.sh            # Unix/Linux Bash script
├── Cargo.toml
└── README.md
```

## 🔧 How It Works

1. **Auto-detection**: The script checks if a test runner exists for your project
2. **Code generation**: If not found, it creates a `src/bin/fany_rust.rs` file automatically
3. **Function registration**: When you test a new function, it gets added to the match statement
4. **Execution**: Your function is called and the result is displayed in pretty JSON format

## 📋 Requirements for Your Functions

Your functions must:
- Be public (`pub fn`)
- Return a type that implements `Serialize` (from serde)
- Take no parameters (for now)
- Be part of the `rust_core` crate

Example:
```rust
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct MyResult {
    pub success: bool,
    pub message: String,
}

pub fn my_test_function() -> MyResult {
    MyResult {
        success: true,
        message: "Hello from Rust!".to_string(),
    }
}
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


## 🐛 Issues

Found a bug? Have a feature request? Please open an issue on GitHub!

## ⭐ Support

If you find this tool helpful, please give it a star on GitHub!

---

Made with ❤️ by ICK Network Team