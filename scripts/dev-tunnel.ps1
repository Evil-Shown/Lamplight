# Runs the Flutter web app and exposes it over HTTPS via a Cloudflare quick
# tunnel, so phone browsers (iOS included) allow camera access for the QR
# scanner. Usage:  .\scripts\dev-tunnel.ps1 [-Port 8080] [-Dev]
param(
  [int]$Port = 8080,
  [switch]$Dev
)

$ErrorActionPreference = 'Stop'

# Find cloudflared even when PATH was not refreshed after install.
$cf = (Get-Command cloudflared -ErrorAction SilentlyContinue).Source
if (-not $cf) {
  $cf = @(
    "${env:ProgramFiles(x86)}\cloudflared\cloudflared.exe",
    "$env:ProgramFiles\cloudflared\cloudflared.exe"
  ) | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $cf) {
  Write-Host 'cloudflared not found. Install it: winget install Cloudflare.cloudflared' -ForegroundColor Red
  exit 1
}

# Tunnel runs in the background; its log is watched for the public URL.
$log = Join-Path $env:TEMP "lamplight-tunnel-$Port.log"
Remove-Item $log -ErrorAction SilentlyContinue
$tunnel = Start-Process -FilePath $cf `
  -ArgumentList @('tunnel', '--url', "http://localhost:$Port") `
  -RedirectStandardError $log -WindowStyle Hidden -PassThru

try {
  $url = $null
  for ($i = 0; $i -lt 60 -and -not $url; $i++) {
    Start-Sleep -Milliseconds 500
    if (Test-Path $log) {
      $m = Select-String -Path $log -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' |
        Select-Object -First 1
      if ($m) { $url = $m.Matches[0].Value }
    }
  }
  if ($url) {
    Write-Host ''
    Write-Host "  Open on your phone (HTTPS, camera works):  $url" -ForegroundColor Green
    Write-Host '  It goes live once Flutter prints "Serving at".' -ForegroundColor DarkGray
    Write-Host ''
  } else {
    Write-Host "Tunnel URL not found yet; check $log" -ForegroundColor Yellow
  }

  $mode = if ($Dev) { '--debug' } else { '--release' }
  flutter run -d web-server --web-hostname 0.0.0.0 --web-port $Port $mode
} finally {
  # Closing Flutter (q / Ctrl+C) also closes the tunnel.
  if (-not $tunnel.HasExited) { Stop-Process -Id $tunnel.Id -Force }
}
