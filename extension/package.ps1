# Packages the Tarf Chrome extension into a Web-Store-ready zip.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$out = Join-Path $here 'tarf-extension.zip'
Remove-Item $out -ErrorAction SilentlyContinue

$include = @(
  'manifest.json', 'background.js', 'offscreen.html', 'offscreen.js',
  'popup.html', 'popup.css', 'popup.js', 'i18n.js', 'dhikr.json',
  'sidepanel.html', 'sidepanel.js',
  'icon16.png', 'icon48.png', 'icon128.png'
) | Where-Object { Test-Path (Join-Path $here $_) } | ForEach-Object { Join-Path $here $_ }

Compress-Archive -Path $include -DestinationPath $out -Force
"Wrote $out ({0:N0} bytes)" -f (Get-Item $out).Length
