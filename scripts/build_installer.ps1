# Build Dental Flow Windows installer locally.
# Requires: Flutter SDK, Inno Setup 6 (ISCC.exe on PATH or default install path)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$versionLine = Select-String -Path "pubspec.yaml" -Pattern "^version:" | Select-Object -First 1
$version = ($versionLine.Line -split "\s+")[1].Split("+")[0]

Write-Host "Building Dental Flow v$version ..."

flutter pub get
flutter build windows --release --build-name=$version

$buildDir = Join-Path $repoRoot "build\windows\x64\runner\Release"
$outputDir = Join-Path $repoRoot "release"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$iscc = "ISCC.exe"
if (-not (Get-Command $iscc -ErrorAction SilentlyContinue)) {
  $iscc = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
  if (-not (Test-Path $iscc)) {
    $iscc = "${env:ProgramFiles}\Inno Setup 6\ISCC.exe"
  }
}
if (-not (Test-Path $iscc)) {
  throw "Inno Setup not found. Install from https://jrsoftware.org/isinfo.php"
}

$outputName = "DentalFlow-v$version-setup"
& $iscc `
  "$repoRoot\scripts\dental_flow_setup.iss" `
  "/DMyAppVersion=$version" `
  "/DBuildDir=$buildDir" `
  "/DOutputDir=$outputDir" `
  "/DOutputBaseFilename=$outputName"

$installer = Join-Path $outputDir "$outputName.exe"
Write-Host "Installer ready: $installer"
