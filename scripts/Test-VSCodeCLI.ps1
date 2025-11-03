<#
.SYNOPSIS
  Tests whether VS Code's "code" command is available in PowerShell.
  Checks PATH, confirms code.cmd exists, and optionally suggests fixes.
#>

Write-Host "`n🔍 Checking VS Code CLI integration..." -ForegroundColor Cyan

# 1️⃣ Check if the "code" command is in PATH
$codeCmd = Get-Command code -ErrorAction SilentlyContinue

if ($null -ne $codeCmd) {
    Write-Host "✅ 'code' command is available at:" -ForegroundColor Green
    Write-Host "   $($codeCmd.Source)`n"
    try {
        $version = code --version
        Write-Host "   Version: $version"
        Write-Host "🎯 VS Code CLI is fully operational.`n" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ 'code' command found, but running it failed." -ForegroundColor Yellow
    }
    exit 0
}

Write-Host "❌ 'code' command not found in PATH." -ForegroundColor Red

# 2️⃣ Check common install paths
$pathsToCheck = @(
    "C:\Users\$env:USERNAME\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd",
    "C:\Program Files\Microsoft VS Code\bin\code.cmd",
    "C:\Program Files (x86)\Microsoft VS Code\bin\code.cmd"
)

$found = $false
foreach ($p in $pathsToCheck) {
    if (Test-Path $p) {
        Write-Host "📁 Found code.cmd at: $p" -ForegroundColor Yellow
        $found = $true
        Write-Host "`n👉 To permanently fix PATH, run:" -ForegroundColor Cyan
        Write-Host "setx PATH `"`$(`$env:PATH);$(Split-Path $p)`"" -ForegroundColor Gray
        break
    }
}

if (-not $found) {
    Write-Host "🚫 VS Code CLI not found in common locations." -ForegroundColor Red
    Write-Host "   Try reinstalling VS Code, or run inside VS Code:" -ForegroundColor Yellow
    Write-Host "   Ctrl+Shift+P → 'Shell Command: Install code command in PATH'" -ForegroundColor Gray
}

Write-Host "`n🧭 After applying any fix, restart PowerShell and run:" -ForegroundColor Cyan
Write-Host "   code --version" -ForegroundColor Gray
Write-Host ""
