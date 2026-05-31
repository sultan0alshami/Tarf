param(
  [string]$Theme = "dark",
  [int]$Port = 8770,
  [string]$OutDir = "C:\Users\sulta\Claude_Code\EyeCure_20\_setup\shots"
)

$ErrorActionPreference = "Continue"
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$web = "C:\Users\sulta\Claude_Code\EyeCure_20\app\build\web"
$python = "C:\msys64\mingw64\bin\python.exe"
$base = "http://127.0.0.1:$Port"

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Test-Ready {
  try {
    $r = Invoke-WebRequest -UseBasicParsing "$base/index.html" -TimeoutSec 2
    return $r.StatusCode -eq 200
  } catch { return $false }
}

function Start-Server {
  # Bind explicitly to IPv4 so Chrome's 127.0.0.1 always connects.
  $s = Start-Process -FilePath $python `
    -ArgumentList @("-m", "http.server", "$Port", "--bind", "127.0.0.1", "--directory", "$web") `
    -PassThru -WindowStyle Hidden
  for ($i = 0; $i -lt 40; $i++) {
    if (Test-Ready) { break }
    Start-Sleep -Milliseconds 400
  }
  return $s
}

$routes = [ordered]@{
  "home"      = "/focus"
  "timer"     = "/timer"
  "alarm"     = "/alarm"
  "stopwatch" = "/stopwatch"
  "insights"  = "/insights"
  "todos"     = "/tasks"
  "settings"  = "/settings"
  "eyecare"   = "/settings/eyecare"
  "account"   = "/settings/account"
  "break"     = "/eyecare/break"
}

$srv = Start-Server
if (-not (Test-Ready)) { "FATAL: server not ready at $base"; exit 1 }

try {
  foreach ($name in $routes.Keys) {
    if (-not (Test-Ready)) {
      Stop-Process -Id $srv.Id -Force -ErrorAction SilentlyContinue
      $srv = Start-Server
    }
    $frag = $routes[$name]
    $out = Join-Path $OutDir "$Theme-$name.png"
    if (Test-Path $out) { Remove-Item $out -Force }
    $udd = Join-Path $env:TEMP "tarfshot_${Port}_$name"
    & $chrome --headless --disable-gpu --no-sandbox --hide-scrollbars --user-data-dir="$udd" --no-first-run --no-default-browser-check --force-device-scale-factor=2 --window-size=460,980 --screenshot="$out" --virtual-time-budget=16000 "$base/#$frag" 2>$null
    if (Test-Path $out) {
      "OK  $Theme-$name.png  ($((Get-Item $out).Length) bytes)"
    } else {
      "MISS $Theme-$name.png"
    }
  }
}
finally {
  Stop-Process -Id $srv.Id -Force -ErrorAction SilentlyContinue
}
