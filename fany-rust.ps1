param(
    [string]$Command,
    [string]$Func
)

$binaryFile = ".\src\bin\fany_rust.rs"
$cargoTomlFile = ".\Cargo.toml"

function Show-Help {
    echo ""
    Write-Host "🦀 " -ForegroundColor Red -NoNewline
    Write-Host "fany-rust" -ForegroundColor Yellow -NoNewline
    Write-Host " - Simple Rust function tester" -ForegroundColor White
    Write-Host ""
    Write-Host "📖 Usage:" -ForegroundColor Cyan
    Write-Host "  .\fany-rust.ps1 " -ForegroundColor White -NoNewline
    Write-Host "--tes " -ForegroundColor Green -NoNewline
    Write-Host "<function_name>" -ForegroundColor Yellow
    Write-Host "  .\fany-rust.ps1 " -ForegroundColor White -NoNewline
    Write-Host "--help" -ForegroundColor Green
    Write-Host ""
    exit
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Progress {
    param([string]$Message)
    Write-Host "🔄 $Message" -ForegroundColor Magenta
}

function Get-PackageName {
    if (-Not (Test-Path $cargoTomlFile)) {
        Write-Error "Cargo.toml tidak ditemukan! Pastikan Anda berada di root project Rust."
        exit 1
    }
    
    $cargoContent = Get-Content $cargoTomlFile -Raw
    if ($cargoContent -match 'name\s*=\s*"([^"]+)"') {
        return $matches[1]
    } else {
        Write-Error "Tidak dapat menemukan nama package di Cargo.toml"
        exit 1
    }
}

if ($Command -eq "--help" -or $Command -eq "-h" -or !$Command) {
    Show-Help
}

if ($Command -ne "--tes" -or -not $Func) {
    Show-Help
}

# Dapatkan nama package dari Cargo.toml
$packageName = Get-PackageName
Write-Info "Detected package name: '$packageName'"

# Jika file bin belum ada → buat otomatis
if (-Not (Test-Path $binaryFile)) {
    Write-Progress "Membuat file $binaryFile secara otomatis..."
    New-Item -ItemType Directory -Force -Path (Split-Path $binaryFile) | Out-Null
@"
use $packageName;

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 3 || args[1] != "--tes" {
        println!("Usage: fany-rust --tes <function_name>");
        return;
    }
    
    let func = &args[2];
    match func.as_str() {
        _ => println!("Function '{{}}' not found.", func),
    }
}
"@ | Set-Content $binaryFile
    Write-Success "File template berhasil dibuat dengan package '$packageName'!"
}

# Read current content
$content = Get-Content $binaryFile -Raw

# Pastikan menggunakan package name yang benar
if ($content -notmatch "use $packageName;") {
    Write-Warning "Memperbarui package name menjadi '$packageName'..."
    $content = $content -replace 'use\s+[^;]+;', "use $packageName;"
    Set-Content $binaryFile $content
}

# Check if function already exists
if ($content -notmatch "`"$Func`"") {
    Write-Progress "Menambahkan stub untuk function '$Func'..."
    
    # Delete the current file and recreate with the new function
    $functions = @()
    
    # Extract existing functions from current content
    $matches = [regex]::Matches($content, '"`([^"]+)`" => {[^}]+' + [regex]::Escape($packageName) + '::([^(]+)\([^}]+}')
    foreach ($match in $matches) {
        if ($match.Groups[1].Value -ne $Func) {
            $functions += $match.Groups[1].Value
        }
    }
    
    # Add the new function
    $functions += $Func
    
    # Generate new file content
    $newContent = @"
use $packageName;

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 3 || args[1] != "--tes" {
        println!("Usage: fany-rust --tes <function_name>");
        return;
    }
    
    let func = &args[2];
    match func.as_str() {
"@

    # Add all function cases
    foreach ($fn in $functions) {
        $newContent += @"

        "$fn" => {
            let result = ${packageName}::$fn();
            println!("{}", serde_json::to_string_pretty(&result).unwrap());
        },
"@
    }
    
    # Add default case
    $newContent += @"

        _ => println!("Function '{}' not found.", func),
    }
}
"@

    Set-Content $binaryFile $newContent
    Write-Success "Function '$Func' berhasil ditambahkan ke package '$packageName'!"
    
    if ($functions.Count -gt 1) {
        Write-Info "Functions yang tersedia dalam package '$packageName':"
        foreach ($fn in $functions) {
            if ($fn -eq $Func) {
                Write-Host "  • " -ForegroundColor Green -NoNewline
                Write-Host "$fn" -ForegroundColor Yellow -NoNewline
                Write-Host " (baru)" -ForegroundColor Green
            } else {
                Write-Host "  • " -ForegroundColor White -NoNewline
                Write-Host "$fn" -ForegroundColor Gray
            }
        }
    }
} else {
    Write-Info "Function '$Func' sudah ada di package '$packageName', menggunakan yang sudah ada..."
}

Write-Host ""
Write-Host "🚀 " -ForegroundColor Yellow -NoNewline
Write-Host "Menjalankan function " -ForegroundColor White -NoNewline
Write-Host "'$Func'" -ForegroundColor Cyan -NoNewline
Write-Host " dari package " -ForegroundColor White -NoNewline
Write-Host "'$packageName'" -ForegroundColor Yellow -NoNewline
Write-Host "..." -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

cargo run --bin fany_rust -- --tes $Func

$exitCode = $LASTEXITCODE
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

if ($exitCode -eq 0) {
    Write-Success "Function dari package '$packageName' berhasil dijalankan!"
} else {
    Write-Error "Function gagal dijalankan dengan exit code: $exitCode"
}