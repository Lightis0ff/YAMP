$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

# ---------------------------------------------------------------------------
# 1. Read the version from pubspec.yaml
# ---------------------------------------------------------------------------
$pubspecPath = Join-Path $root "..\pubspec.yaml"
if (-not (Test-Path $pubspecPath)) {
    throw "pubspec.yaml not found at $pubspecPath"
}

$versionLine = Select-String -Path $pubspecPath -Pattern '^version:\s*(.+)$' | Select-Object -First 1
if (-not $versionLine) {
    throw "No top-level 'version:' line found in pubspec.yaml"
}

$rawVersion  = $versionLine.Matches[0].Groups[1].Value.Trim()
$parts       = $rawVersion -split '\+'
$appVersion  = $parts[0]
$buildNumber = if ($parts.Count -gt 1) { $parts[1] } else { "0" }

Write-Host "App version from pubspec.yaml: $appVersion (build $buildNumber)" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 2. Build the Flutter Windows app
# ---------------------------------------------------------------------------
Write-Host "`nBuilding Flutter Windows app (release)..." -ForegroundColor Cyan
flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed (exit code $LASTEXITCODE)" }

$releaseDir = Join-Path $root "..\build\windows\x64\runner\Release"
if (-not (Test-Path $releaseDir)) {
    $releaseDir = Join-Path $root "..\build\windows\runner\Release"
}
if (-not (Test-Path $releaseDir)) {
    throw "Could not find the Release output folder under build\windows\..."
}
Write-Host "Release build found at: $releaseDir" -ForegroundColor DarkGray

# ---------------------------------------------------------------------------
# 3. Locate the Inno Setup compiler (ISCC.exe)
# ---------------------------------------------------------------------------
$isccCandidates = @(
    "${env:ProgramFiles(x86)}\Inno Setup 7\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 7\ISCC.exe",
    "$env:LOCALAPPDATA\Programs\Inno Setup 7\ISCC.exe"
)
$iscc = $isccCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $iscc) {
    $cmd = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($cmd) { $iscc = $cmd.Source }
}
if (-not $iscc) {
    throw "Could not find ISCC.exe. Install Inno Setup 7, or add its folder to PATH."
}

# ---------------------------------------------------------------------------
# 4. Compile the installer, handing the version to it via /D defines
# ---------------------------------------------------------------------------
$issScript = Join-Path $root "inno.iss"
if (-not (Test-Path $issScript)) { throw "inno.iss not found at $issScript" }

Write-Host "`nCompiling installer with ISCC..." -ForegroundColor Cyan
& $iscc "/DMyAppVersion=$appVersion" "/DMyAppBuild=$buildNumber" "$issScript"
if ($LASTEXITCODE -ne 0) { throw "Inno Setup compilation failed (exit code $LASTEXITCODE)" }

Write-Host "`nDone. Installer built for version $appVersion." -ForegroundColor Green