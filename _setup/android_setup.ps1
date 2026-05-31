$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$sdk  = 'C:\dev\android-sdk'
$sdkm = "$sdk\cmdline-tools\latest\bin\sdkmanager.bat"
$jdk  = "$env:USERPROFILE\scoop\apps\temurin17-jdk\current"
$fb   = 'C:\dev\flutter\bin\flutter.bat'
$log  = 'C:\Users\sulta\Claude_Code\EyeCure_20\_setup\android.log'
$done = 'C:\Users\sulta\Claude_Code\EyeCure_20\_setup\android.DONE'
Remove-Item $done -ErrorAction SilentlyContinue
function Log($m){ "$((Get-Date).ToString('HH:mm:ss'))  $m" | Out-File $log -Append -Encoding utf8 }

$env:JAVA_HOME = $jdk
$env:Path = "$jdk\bin;$env:Path"
$env:ANDROID_HOME = $sdk
$env:ANDROID_SDK_ROOT = $sdk

if (-not (Test-Path $sdkm)) { Log "FATAL: sdkmanager not at $sdkm"; "FAILED" | Out-File $done; exit 1 }

# 60 'y' lines, delivered as separate pipeline items -> one stdin line each
$yes = 1..60 | ForEach-Object { 'y' }

Log "=== accept licenses (before install) ==="
$yes | & $sdkm --sdk_root=$sdk --licenses *>&1 | ForEach-Object { Log "[lic] $_" }

Log "=== install platform-tools + android-34 + build-tools 34.0.0 ==="
$yes | & $sdkm --sdk_root=$sdk "platform-tools" "platforms;android-34" "build-tools;34.0.0" *>&1 | ForEach-Object { Log "[pkg] $_" }

Log "=== wire flutter -> android sdk + jdk17 ==="
& $fb config --android-sdk $sdk *>&1 | ForEach-Object { Log "[cfg] $_" }
& $fb config --jdk-dir $jdk *>&1 | ForEach-Object { Log "[cfg] $_" }

Log "=== flutter doctor --android-licenses ==="
$yes | & $fb doctor --android-licenses *>&1 | ForEach-Object { Log "[lic2] $_" }

Log "=== flutter doctor -v ==="
& $fb doctor -v *>&1 | ForEach-Object { Log "[doctor] $_" }

Log "=== verify packages ==="
Log ("platform-tools : " + (Test-Path "$sdk\platform-tools"))
Log ("android-34     : " + (Test-Path "$sdk\platforms\android-34"))
Log ("build-tools    : " + (Test-Path "$sdk\build-tools"))

Log "ANDROID SETUP COMPLETE"
"OK $(Get-Date -Format o)" | Out-File $done -Encoding utf8
