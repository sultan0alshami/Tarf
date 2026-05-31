#requires -Version 5.1
# ============================================================================
# Tarf (طَرْف) - Toolchain installer
# Installs: Flutter SDK (stable), Temurin JDK 17, Android command-line tools + SDK
# Safe to re-run (idempotent-ish). Logs everything to _setup\install.log
# ============================================================================
$ErrorActionPreference = 'Continue'
$ProgressPreference     = 'SilentlyContinue'

$root = 'C:\Users\sulta\Claude_Code\EyeCure_20\_setup'
New-Item -ItemType Directory -Force -Path $root | Out-Null
$log  = Join-Path $root 'install.log'
$done = Join-Path $root 'install.DONE'
$fail = Join-Path $root 'install.FAILED'
Remove-Item $done,$fail -ErrorAction SilentlyContinue

function Log($m){ $ts=(Get-Date).ToString('HH:mm:ss'); $line="$ts  $m"; $line | Out-File -FilePath $log -Append -Encoding utf8; Write-Output $line }

Log "================ INSTALL START ================"
Log "User: $env:USERNAME  Host: $env:COMPUTERNAME"

# ---------------------------------------------------------------------------
# 1) FLUTTER (git clone, stable channel) -- enables Web/PWA/Extension/Windows
# ---------------------------------------------------------------------------
$flutterDir = 'C:\dev\flutter'
$flutterBin = "$flutterDir\bin"
$flutterExe = "$flutterBin\flutter.bat"
try {
  if (-not (Test-Path $flutterExe)) {
    Log "Cloning Flutter (stable, shallow) -> $flutterDir"
    New-Item -ItemType Directory -Force -Path 'C:\dev' | Out-Null
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git $flutterDir 2>&1 | ForEach-Object { Log "[git] $_" }
  } else {
    Log "Flutter already present at $flutterDir (skip clone)"
  }
  # persist + session PATH
  $userPath = [Environment]::GetEnvironmentVariable('Path','User')
  if ($userPath -notlike "*$flutterBin*") {
    [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ';' + $flutterBin), 'User')
    Log "Added $flutterBin to USER PATH"
  }
  if ($env:Path -notlike "*$flutterBin*") { $env:Path = "$env:Path;$flutterBin" }

  Log "flutter --version (downloads Dart SDK on first run)..."
  & $flutterExe --version 2>&1 | ForEach-Object { Log "[flutter] $_" }
  Log "Enabling web + windows desktop..."
  & $flutterExe config --enable-web --enable-windows-desktop --no-analytics 2>&1 | ForEach-Object { Log "[flutter] $_" }
  Log "Precaching web + windows artifacts..."
  & $flutterExe precache --web --windows 2>&1 | ForEach-Object { Log "[flutter] $_" }
} catch { Log "ERROR (flutter stage): $($_.Exception.Message)" }

# ---------------------------------------------------------------------------
# 2) JDK 17 (Temurin) via scoop -- required by Android Gradle Plugin 8.x
# ---------------------------------------------------------------------------
$jdk17 = $null
try {
  Log "Ensuring scoop buckets (java, extras)..."
  scoop bucket add java  2>&1 | ForEach-Object { Log "[scoop] $_" }
  scoop bucket add extras 2>&1 | ForEach-Object { Log "[scoop] $_" }
  Log "Installing temurin17-jdk via scoop..."
  scoop install temurin17-jdk 2>&1 | ForEach-Object { Log "[scoop] $_" }
  $cand = "$env:USERPROFILE\scoop\apps\temurin17-jdk\current"
  if (Test-Path "$cand\bin\java.exe") { $jdk17 = $cand; Log "JDK 17 at $jdk17" }
  else { Log "WARN: temurin17 not found at expected path" }
} catch { Log "ERROR (jdk stage): $($_.Exception.Message)" }

# ---------------------------------------------------------------------------
# 3) ANDROID SDK (command-line tools, direct download) -> APK builds
# ---------------------------------------------------------------------------
$androidSdk = 'C:\dev\android-sdk'
try {
  New-Item -ItemType Directory -Force -Path "$androidSdk\cmdline-tools" | Out-Null
  $sdkmgr = "$androidSdk\cmdline-tools\latest\bin\sdkmanager.bat"
  if (-not (Test-Path $sdkmgr)) {
    $zip = Join-Path $env:TEMP 'android-clt.zip'
    $url = 'https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip'
    Log "Downloading Android command-line tools..."
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    $tmp = Join-Path $env:TEMP 'android-clt-extract'
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    # zip contains a 'cmdline-tools' folder; SDK expects it under cmdline-tools\latest
    New-Item -ItemType Directory -Force -Path "$androidSdk\cmdline-tools\latest" | Out-Null
    Copy-Item -Path "$tmp\cmdline-tools\*" -Destination "$androidSdk\cmdline-tools\latest" -Recurse -Force
    Log "Android cmdline-tools placed at $androidSdk\cmdline-tools\latest"
  } else { Log "Android cmdline-tools already present" }

  [Environment]::SetEnvironmentVariable('ANDROID_HOME',     $androidSdk, 'User')
  [Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', $androidSdk, 'User')
  $env:ANDROID_HOME = $androidSdk; $env:ANDROID_SDK_ROOT = $androidSdk

  if ($jdk17) { $env:JAVA_HOME = $jdk17; $env:Path = "$jdk17\bin;$env:Path" }

  if (Test-Path $sdkmgr) {
    Log "Installing SDK packages (platform-tools, android-34, build-tools 34.0.0)..."
    & $sdkmgr --sdk_root=$androidSdk "platform-tools" "platforms;android-34" "build-tools;34.0.0" 2>&1 | ForEach-Object { Log "[sdk] $_" }
    Log "Accepting Android SDK licenses..."
    $yes = ("y`r`n" * 60)
    $yes | & $sdkmgr --sdk_root=$androidSdk --licenses 2>&1 | ForEach-Object { Log "[lic] $_" }
  } else { Log "ERROR: sdkmanager.bat not found, skipping SDK package install" }
} catch { Log "ERROR (android stage): $($_.Exception.Message)" }

# ---------------------------------------------------------------------------
# 4) Wire Flutter -> Android SDK + JDK 17, then doctor
# ---------------------------------------------------------------------------
try {
  if (Test-Path $flutterExe) {
    if (Test-Path "$androidSdk\platform-tools") {
      & $flutterExe config --android-sdk $androidSdk 2>&1 | ForEach-Object { Log "[flutter] $_" }
    }
    if ($jdk17) { & $flutterExe config --jdk-dir $jdk17 2>&1 | ForEach-Object { Log "[flutter] $_" } }
    Log "Accepting Android licenses via flutter..."
    $yes2 = ("y`r`n" * 60)
    $yes2 | & $flutterExe doctor --android-licenses 2>&1 | ForEach-Object { Log "[lic2] $_" }
    Log "===== flutter doctor -v ====="
    & $flutterExe doctor -v 2>&1 | ForEach-Object { Log "[doctor] $_" }
  }
} catch { Log "ERROR (wire stage): $($_.Exception.Message)" }

Log "================ INSTALL COMPLETE ================"
"OK $(Get-Date -Format o)" | Out-File -FilePath $done -Encoding utf8
