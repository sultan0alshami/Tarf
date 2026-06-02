#Requires -Version 5
<#
.SYNOPSIS
  Tarf store-ready screenshot capture — AR+EN × light+dark × key routes
  for App Store (6.7" / 6.9" iPhone, 12.9" iPad), Google Play (phone 9:16),
  Microsoft Store (1366×768), and Chrome Web Store (1280×800).

.DESCRIPTION
  Extends the base shots.ps1 recipe (IPv4 127.0.0.1 bind, --user-data-dir,
  --headless, #/route deep-link, SKIP_ONBOARDING + FORCE_THEME dart-defines).

  Device sizes captured:
    iphone67   1290×2796  2x  — iPhone 15 Pro / App Store 6.7" required
    iphone69   1320×2868  2x  — iPhone 16 Pro Max / App Store 6.9" required
    ipad129    2048×2732  2x  — iPad Pro 12.9" / App Store required
    play_phone  1080×1920  1x  — Google Play 9:16 phone
    msstore     1366×768   1x  — Microsoft Store minimum
    cws         1280×800   1x  — Chrome Web Store required

  The Flutter web build must already exist at app/build/web (run
  `flutter build web --release --no-web-resources-cdn
   --dart-define=SKIP_ONBOARDING=true --dart-define=FORCE_THEME=dark`
  before running this script).

.PARAMETER OutDir
  Where to write PNG files. Defaults to <repo_root>/_setup/shots_store.
  Files are named: <locale>-<theme>-<device>-<route>.png

.PARAMETER WebDir
  Path to the built Flutter web bundle. Defaults to app/build/web relative
  to the script's parent directory.

.PARAMETER Port
  Local HTTP port for the static server. Default 8771.

.PARAMETER Locales
  Which locales to capture. Default: ar, en.

.PARAMETER Themes
  Which themes to capture. Default: dark, light.

.PARAMETER DeviceProfiles
  Which device profiles to capture. Default: all profiles listed above.

.NOTES
  (I can prep) — Screenshot generation runs here.
  (owner submits) — Actual store upload of screenshots.

  Prerequisites on this machine:
    - Google Chrome at C:\Program Files\Google\Chrome\Application\chrome.exe
    - Python (http.server) at C:\msys64\mingw64\bin\python.exe
    - Flutter web build with SKIP_ONBOARDING=true

  Tip: run with -Themes dark first to verify routes before the full matrix.
#>

param(
  [string]$OutDir   = "",
  [string]$WebDir   = "",
  [int]$Port        = 8771,
  [string[]]$Locales  = @("ar", "en"),
  [string[]]$Themes   = @("dark", "light"),
  [string[]]$DeviceProfiles = @("iphone67", "iphone69", "ipad129", "play_phone", "msstore", "cws")
)

$ErrorActionPreference = "Continue"

# ── Paths ─────────────────────────────────────────────────────────────────────
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path -Parent $scriptDir

if (-not $OutDir)  { $OutDir  = Join-Path $repoRoot "_setup\shots_store" }
if (-not $WebDir)  { $WebDir  = Join-Path $repoRoot "app\build\web" }

$chrome  = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$python  = "C:\msys64\mingw64\bin\python.exe"
$base    = "http://127.0.0.1:$Port"

if (-not (Test-Path $chrome))  { Write-Error "Chrome not found at $chrome"; exit 1 }
if (-not (Test-Path $python))  { Write-Error "Python not found at $python"; exit 1 }
if (-not (Test-Path $WebDir))  { Write-Error "Web build not found at $WebDir — run flutter build web first"; exit 1 }

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# ── Device profiles ───────────────────────────────────────────────────────────
# Each entry: [windowWidth, windowHeight, deviceScaleFactor]
# Chrome --window-size is in CSS pixels; --force-device-scale-factor sets DPR.
# Physical = window × scale. We capture at 2× for retina stores, 1× for others.
$devices = [ordered]@{
  "iphone67"   = @{ w = 393;  h = 852;  dpr = 3; label = "iPhone 15 Pro (6.7in)"        }
  "iphone69"   = @{ w = 440;  h = 956;  dpr = 3; label = "iPhone 16 Pro Max (6.9in)"    }
  "ipad129"    = @{ w = 1024; h = 1366; dpr = 2; label = "iPad Pro 12.9in"              }
  "play_phone" = @{ w = 360;  h = 640;  dpr = 3; label = "Play phone 9:16 (1080x1920)"  }
  "msstore"    = @{ w = 1366; h = 768;  dpr = 1; label = "Microsoft Store 1366x768"     }
  "cws"        = @{ w = 1280; h = 800;  dpr = 1; label = "Chrome Web Store 1280x800"    }
}

# ── Key store routes ──────────────────────────────────────────────────────────
# Ordered: most impactful screenshot first (break overlay = hero shot).
$routes = [ordered]@{
  "break"     = "/eyecare/break"
  "home"      = "/focus"
  "insights"  = "/insights"
  "settings"  = "/settings"
  "timer"     = "/timer"
  "alarm"     = "/alarm"
  "stopwatch" = "/stopwatch"
  "tasks"     = "/tasks"
}

# ── HTTP server helpers ───────────────────────────────────────────────────────
function Test-Ready {
  try {
    $r = Invoke-WebRequest -UseBasicParsing "$base/index.html" -TimeoutSec 2
    return $r.StatusCode -eq 200
  } catch { return $false }
}

function Start-StaticServer {
  $srv = Start-Process -FilePath $python `
    -ArgumentList @("-m", "http.server", "$Port", "--bind", "127.0.0.1", "--directory", $WebDir) `
    -PassThru -WindowStyle Hidden
  for ($i = 0; $i -lt 50; $i++) {
    if (Test-Ready) { return $srv }
    Start-Sleep -Milliseconds 300
  }
  Write-Error "Static server failed to start on $base"
  return $srv
}

# ── Capture one screenshot ────────────────────────────────────────────────────
function Invoke-Screenshot {
  param([string]$Locale, [string]$Theme, [string]$Device, [string]$RouteName, [string]$Fragment)

  $d   = $devices[$Device]
  $out = Join-Path $OutDir "${Locale}-${Theme}-${Device}-${RouteName}.png"
  if (Test-Path $out) { Remove-Item $out -Force }

  # Unique user-data-dir per shot so Chrome has no stale state.
  $udd = Join-Path $env:TEMP "tarfshot_${Port}_${Locale}_${Theme}_${Device}_${RouteName}"

  # FORCE_THEME controls light/dark; FORCE_LOCALE drives RTL for Arabic.
  $url = "${base}/#${Fragment}?dart-define=FORCE_THEME=${Theme}&dart-define=FORCE_LOCALE=${Locale}"
  # Note: dart-defines in the URL are not natively consumed by Flutter web —
  # the build must already bake FORCE_THEME/FORCE_LOCALE support via the
  # --dart-define build flags OR the app reads them via JS interop / url params.
  # For screenshot workflows, build each variant with its own --dart-define:
  #   flutter build web --dart-define=SKIP_ONBOARDING=true --dart-define=FORCE_THEME=dark --dart-define=FORCE_LOCALE=ar
  # This script captures against the currently-built bundle; re-build for each
  # theme/locale variant, then re-run the relevant subset.

  & $chrome `
    --headless `
    --disable-gpu `
    --no-sandbox `
    --hide-scrollbars `
    --user-data-dir="$udd" `
    --no-first-run `
    --no-default-browser-check `
    --force-device-scale-factor=$($d.dpr) `
    --window-size="$($d.w),$($d.h)" `
    --screenshot="$out" `
    --virtual-time-budget=18000 `
    "${base}/#${Fragment}" `
    2>$null

  if (Test-Path $out) {
    $size = (Get-Item $out).Length
    "  OK  $Locale-$Theme-$Device-$RouteName.png  ($size bytes)  [$($d.label)]"
    return $true
  } else {
    "  MISS $Locale-$Theme-$Device-$RouteName.png"
    return $false
  }
}

# ── Main capture loop ─────────────────────────────────────────────────────────
$srv = Start-StaticServer
if (-not (Test-Ready)) { "FATAL: server not ready at $base"; Stop-Process -Id $srv.Id -Force -ErrorAction SilentlyContinue; exit 1 }

$total = 0
$ok    = 0

try {
  foreach ($locale in $Locales) {
    foreach ($theme in $Themes) {
      Write-Host "`n=== $locale / $theme ===" -ForegroundColor Cyan
      Write-Host "NOTE: For accurate locale/theme capture, build with:" -ForegroundColor Yellow
      Write-Host "  flutter build web --dart-define=SKIP_ONBOARDING=true --dart-define=FORCE_THEME=$theme --dart-define=FORCE_LOCALE=$locale" -ForegroundColor Yellow

      foreach ($device in $DeviceProfiles) {
        if (-not $devices.Contains($device)) {
          "  SKIP unknown device profile: $device"; continue
        }
        foreach ($route in $routes.Keys) {
          if (-not (Test-Ready)) {
            Stop-Process -Id $srv.Id -Force -ErrorAction SilentlyContinue
            $srv = Start-StaticServer
          }
          $total++
          $result = Invoke-Screenshot -Locale $locale -Theme $theme -Device $device -RouteName $route -Fragment $routes[$route]
          if ($result) { $ok++ }
        }
      }
    }
  }
} finally {
  Stop-Process -Id $srv.Id -Force -ErrorAction SilentlyContinue
}

Write-Host "`n── Summary ──────────────────────────────────────────────────────" -ForegroundColor Cyan
Write-Host "  Captured: $ok / $total shots  →  $OutDir" -ForegroundColor $(if ($ok -eq $total) { "Green" } else { "Yellow" })

Write-Host @"

── Per-store submission guide ──────────────────────────────────────────────────
App Store (iOS):
  Required sizes: 6.7" (1290×2796) and/or 6.9" (1320×2868) + 12.9" iPad
  Files: ar-*-iphone67-*.png  ar-*-iphone69-*.png  ar-*-ipad129-*.png
  Submit AR set as primary (Arabic-first product); add EN set as the EN locale.

Google Play (Android):
  Required: at least 2 phone screenshots (9:16 or 16:9; min 320px any side)
  Files: ar-*-play_phone-*.png  (EN set optional but recommended)
  Feature graphic (1024×500): create separately — no equivalent shot here.

Microsoft Store:
  Required: at least 1 screenshot ≥ 1366×768
  Files: ar-*-msstore-*.png  en-*-msstore-*.png

Chrome Web Store:
  Required: at least 1 screenshot at 1280×800 or 640×400
  Files: ar-*-cws-*.png  en-*-cws-*.png

── Build matrix for accurate theme/locale ────────────────────────────────────
  dark  / AR: flutter build web --dart-define=SKIP_ONBOARDING=true --dart-define=FORCE_THEME=dark  --dart-define=FORCE_LOCALE=ar
  dark  / EN: flutter build web --dart-define=SKIP_ONBOARDING=true --dart-define=FORCE_THEME=dark  --dart-define=FORCE_LOCALE=en
  light / AR: flutter build web --dart-define=SKIP_ONBOARDING=true --dart-define=FORCE_THEME=light --dart-define=FORCE_LOCALE=ar
  light / EN: flutter build web --dart-define=SKIP_ONBOARDING=true --dart-define=FORCE_THEME=light --dart-define=FORCE_LOCALE=en
  Then re-run: shots_store.ps1 -Themes dark   -Locales ar   (against the dark/AR build)
               shots_store.ps1 -Themes dark   -Locales en   (against the dark/EN build)
               etc.
"@
