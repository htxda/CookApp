# Verify HarmonyOS project setup
Write-Host "=== HarmonyOS Project Setup Verification ===" -ForegroundColor Green

# Check if DevEco Studio JDK exists
$devEcoJdk = "D:\DevEco Studio\jbr"
if (Test-Path $devEcoJdk) {
    Write-Host "✓ DevEco Studio JDK found at: $devEcoJdk" -ForegroundColor Green
} else {
    Write-Host "✗ DevEco Studio JDK not found" -ForegroundColor Red
}

# Check current Java
Write-Host "`nCurrent Java version:" -ForegroundColor Yellow
try {
    java -version 2>&1
} catch {
    Write-Host "Java not accessible" -ForegroundColor Red
}

# Check project files
Write-Host "`nProject status:" -ForegroundColor Yellow
if (Test-Path "entry\src\main\ets") {
    Write-Host "✓ ArkTS project structure OK" -ForegroundColor Green
}

Write-Host "`nNext steps in DevEco Studio:" -ForegroundColor Magenta
Write-Host "1. File -> Project Structure -> SDK Location" -ForegroundColor Cyan
Write-Host "2. Set JDK Location to: D:\\DevEco Studio\\jbr" -ForegroundColor Cyan
Write-Host "3. Click Apply -> OK" -ForegroundColor Cyan
Write-Host "4. Rebuild project (Build -> Build Project)" -ForegroundColor Cyan