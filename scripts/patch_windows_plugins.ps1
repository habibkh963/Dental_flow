# Lowers cmake_minimum_required for plugins that block VS bundled CMake 3.20.
# Run after `flutter pub get` on Windows when build fails with CMake 3.22/3.23 errors.

$ErrorActionPreference = "Stop"
$repoRoot = if ($PSScriptRoot) { Split-Path -Parent $PSScriptRoot } else { $PWD }

function Patch-CMakeMinimum {
  param([string]$FilePath)

  if (-not (Test-Path $FilePath)) { return $false }

  $content = Get-Content -Raw -Path $FilePath
  $updated = $content -replace 'cmake_minimum_required\(VERSION 3\.2[23]\)', 'cmake_minimum_required(VERSION 3.14)'
  if ($updated -eq $content) { return $false }

  Set-Content -Path $FilePath -Value $updated -NoNewline
  Write-Host "Patched: $FilePath"
  return $true
}

$patched = 0

$pubRoot = Join-Path $env:LOCALAPPDATA "Pub\Cache\hosted\pub.dev"
if (Test-Path $pubRoot) {
  Get-ChildItem -Path $pubRoot -Filter "record_windows-*" -Directory | ForEach-Object {
    $cmake = Join-Path $_.FullName "windows\CMakeLists.txt"
    if (Patch-CMakeMinimum $cmake) { $script:patched++ }
  }
}

$symlink = Join-Path $repoRoot "windows\flutter\ephemeral\.plugin_symlinks\record_windows\windows\CMakeLists.txt"
if (Patch-CMakeMinimum $symlink) { $patched++ }

if ($patched -eq 0) {
  Write-Host "No plugin CMake files needed patching (already OK or record_windows not fetched yet)."
} else {
  Write-Host "Patched $patched file(s). You can run: flutter build windows"
}
