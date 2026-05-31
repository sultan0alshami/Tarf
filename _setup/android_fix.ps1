$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$sdk  = 'C:\dev\android-sdk'
$sdkm = "$sdk\cmdline-tools\latest\bin\sdkmanager.bat"
$jdk  = "$env:USERPROFILE\scoop\apps\temurin17-jdk\current"
$fb   = 'C:\dev\flutter\bin\flutter.bat'
$log  = 'C:\Users\sulta\Claude_Code\EyeCure_20\_setup\android_fix.log'
$done = 'C:\Users\sulta\Claude_Code\EyeCure_20\_setup\android_fix.DONE'
Remove-Item $done -ErrorAction SilentlyContinue
function Log($m){ "$((Get-Date).ToString('HH:mm:ss'))  $m" | Out-File $log -Append -Encoding utf8 }

$env:JAVA_HOME = $jdk; $env:Path = "$jdk\bin;$env:Path"
$env:ANDROID_HOME = $sdk; $env:ANDROID_SDK_ROOT = $sdk

# 1) Pre-accept licenses by writing the well-known SHA1 hash files (CI-standard method)
$lic = "$sdk\licenses"
New-Item -ItemType Directory -Force -Path $lic | Out-Null
$nl = "`n"
# android-sdk-license: include the commonly-required hashes across SDK versions
("" , "8933bad161af4178b1185d1a37fbf41ea5269c55", "d56f5187479451eabf01fb78af6dfcb131a6481e", "24333f8a63b6825ea9c5514f83c2829b004d1fee") -join $nl | Out-File "$lic\android-sdk-license" -Encoding ascii -NoNewline
("", "84831b9409646a918e30573bab4c9c91346d8abd") -join $nl | Out-File "$lic\android-sdk-preview-license" -Encoding ascii -NoNewline
("", "33b6a2b64607f11b759f320ef9dff4ae5c47d97a") -join $nl | Out-File "$lic\google-gdk-license" -Encoding ascii -NoNewline
("", "859f317696f67ef3d7f30a50a5560e7834b43903") -join $nl | Out-File "$lic\android-sdk-arm-dbt-license" -Encoding ascii -NoNewline
Log "Wrote license hash files to $lic"

# 2) Install packages (licenses pre-accepted -> no prompt)
Log "Installing platform-tools + android-34 + build-tools 34.0.0 ..."
& $sdkm --sdk_root=$sdk "platform-tools" "platforms;android-34" "build-tools;34.0.0" *>&1 |
  Where-Object { $_ -notmatch '%\]|Fetch remote|Loading|Computing|Unzipping' } | ForEach-Object { Log "[pkg] $_" }

# 3) Verify + wire flutter
$ok = (Test-Path "$sdk\platform-tools") -and (Test-Path "$sdk\platforms\android-34") -and (Test-Path "$sdk\build-tools")
Log "packages present: platform-tools=$([bool](Test-Path "$sdk\platform-tools")) android-34=$([bool](Test-Path "$sdk\platforms\android-34")) build-tools=$([bool](Test-Path "$sdk\build-tools"))"
& $fb config --android-sdk $sdk *>&1 | ForEach-Object { Log "[cfg] $_" }
& $fb config --jdk-dir $jdk *>&1 | ForEach-Object { Log "[cfg] $_" }
Log "=== flutter doctor (android only) ==="
& $fb doctor *>&1 | Where-Object { $_ -match 'Android|✓|✗|!' } | ForEach-Object { Log "[doctor] $_" }

if ($ok) { "OK $(Get-Date -Format o)" | Out-File $done -Encoding utf8; Log "ANDROID FIX COMPLETE" }
else { "FAILED" | Out-File $done -Encoding utf8; Log "ANDROID FIX FAILED" }
