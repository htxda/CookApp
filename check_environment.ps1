# PowerShell script to check HarmonyOS project environment
Write-Host "=== HarmonyOS Project Environment Check ===" -ForegroundColor Green

# Check Java version
try {
    $javaVersion = java -version 2>&1
    Write-Host "Java Version:" -ForegroundColor Yellow
    $javaVersion
} catch {
    Write-Host "Java not found or configuration error" -ForegroundColor Red
}

# Check project files
Write-Host "`nProject Structure:" -ForegroundColor Yellow
if (Test-Path "entry\src\main\ets") {
    Write-Host "✓ ArkTS source directory exists" -ForegroundColor Green
    $etsFiles = Get-ChildItem "entry\src\main\ets" -Recurse -Filter "*.ets"
    Write-Host "Found $($etsFiles.Count) ArkTS files" -ForegroundColor Cyan
}

if (Test-Path "build-profile.json5") {
    Write-Host "✓ Build configuration file exists" -ForegroundColor Green
}

# Check for Java files
$javaFiles = Get-ChildItem -Recurse -Filter "*.java"
if ($javaFiles.Count -eq 0) {
    Write-Host "✓ No Java files found (Pure ArkTS project)" -ForegroundColor Green
} else {
    Write-Host "! Java files found, need cleanup" -ForegroundColor Red
}

Write-Host "`nRecommendations:" -ForegroundColor Magenta
Write-Host "1. Use embedded JDK in DevEco Studio" -ForegroundColor Cyan
Write-Host "2. Project is pure ArkTS, no Java development needed" -ForegroundColor Cyan
Write-Host "3. Build system needs Java runtime, but development language is ArkTS" -ForegroundColor Cyan