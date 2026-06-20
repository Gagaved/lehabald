<#
.SYNOPSIS
  Build and (re)start the Leha Bald stack.

.DESCRIPTION
  The Dart server (server/bin/server.dart) serves BOTH the WebSocket endpoint
  (/ws) and the built Flutter web client (client/build/web) on one port.

  - Backend (Dart) changes  -> the server process must be restarted.
  - Frontend (Flutter) changes -> the web client must be rebuilt; the running
    server then serves the fresh files on the next browser refresh (no restart
    needed, but this script restarts anyway so the running state is always
    consistent with the code on disk).

  Always run this after changing code. See the `restart-app` skill.

.PARAMETER Target
  all   (default) rebuild front + restart back
  front rebuild the Flutter web client only
  back  restart the Dart server only

.PARAMETER Port
  Server port (default 4173).

.EXAMPLE
  pwsh tools/dev.ps1            # full rebuild + restart
  pwsh tools/dev.ps1 -Target back
  pwsh tools/dev.ps1 -Target front
#>
param(
  [ValidateSet('all', 'front', 'back')]
  [string]$Target = 'all',
  [int]$Port = 4173
)

$ErrorActionPreference = 'Stop'

# Decode native-tool output as UTF-8 so flutter's lines aren't garbled in the log.
try {
  [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
  $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
} catch {}

$root = Split-Path -Parent $PSScriptRoot
$client = Join-Path $root 'client'
$server = Join-Path $root 'server'
$log = Join-Path $server 'server.run.log'
$devLog = Join-Path $PSScriptRoot 'dev.log'

# Fresh run log each invocation so `Get-Content -Wait` follows just this run.
"=== dev.ps1 start $(Get-Date -Format o) target=$Target port=$Port ===" |
  Out-File -FilePath $devLog -Encoding utf8

function Log {
  param([string]$Message)
  $line = "[{0:HH:mm:ss}] {1}" -f (Get-Date), $Message
  Write-Host $line -ForegroundColor Cyan
  Add-Content -Path $devLog -Value $line -Encoding UTF8
}

# Stream a native tool's output to console + log, line by line, in UTF-8.
function Write-Stream {
  process { Write-Host $_; Add-Content -Path $devLog -Value $_ -Encoding UTF8 }
}

function Stop-Server {
  param([int]$Port)
  Log "Stopping anything on port $Port (and stray dart server.dart)..."
  # Kill whatever owns the port, plus any lingering `dart ... server.dart`.
  try {
    Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop |
      Select-Object -ExpandProperty OwningProcess -Unique |
      ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
  } catch {}
  Get-CimInstance Win32_Process -Filter "Name='dart.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'server\.dart' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Milliseconds 400
}

function Build-Front {
  Log "Building Flutter web client (fvm flutter build web)."
  Log "NOTE: flutter compiles the web bundle mostly silently -- expect 1-4 min"
  Log "      with little output. A heartbeat below shows it's still alive."
  $sw = [Diagnostics.Stopwatch]::StartNew()

  # Heartbeat: a side process appends elapsed time to the log every 15s so a
  # silent compile doesn't look hung.
  $hb = Start-Job -ScriptBlock {
    param($logPath)
    $t = 0
    while ($true) {
      Start-Sleep -Seconds 15
      $t += 15
      Add-Content -Path $logPath -Encoding UTF8 -Value (
        "[{0:HH:mm:ss}] ...still building (+{1}s)" -f (Get-Date), $t)
    }
  } -ArgumentList $devLog

  Push-Location $client
  try {
    # 2>&1 on a native exe under -ErrorActionPreference Stop turns harmless
    # stderr notes (e.g. the wasm dry-run hint) into terminating errors. Relax
    # to Continue and merge all streams with *>&1, then check the real exit code.
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    # --pwa-strategy=none: no service worker, so the browser can't serve a
    # stale cached bundle after a rebuild (paired with no-store on the server).
    & fvm flutter build web --no-wasm-dry-run --pwa-strategy=none *>&1 | Write-Stream
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    if ($code -ne 0) { throw "flutter build web failed (exit $code)" }
  } finally {
    Pop-Location
    Stop-Job $hb -ErrorAction SilentlyContinue
    Remove-Job $hb -Force -ErrorAction SilentlyContinue
  }
  $sw.Stop()
  Log ("Front build done in {0:n1}s." -f $sw.Elapsed.TotalSeconds)
}

function Start-Server {
  param([int]$Port)
  Log "Starting Dart server on port $Port..."
  Push-Location $server
  try {
    Log "fvm dart pub get..."
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & fvm dart pub get *>&1 | Out-Null
    $ErrorActionPreference = $prev
    # Child inherits env; -Environment isn't available on Windows PowerShell 5.1.
    $env:PORT = "$Port"
    # Detached so the server keeps running after this script exits.
    Start-Process -FilePath 'fvm' `
      -ArgumentList @('dart', 'run', 'bin/server.dart') `
      -WorkingDirectory $server `
      -RedirectStandardOutput $log `
      -RedirectStandardError (Join-Path $server 'server.err.log') `
      -WindowStyle Hidden | Out-Null
  } finally { Pop-Location }

  # Wait until it answers.
  Log "Waiting for server to answer on http://127.0.0.1:$Port/ ..."
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 500
    try {
      $r = Invoke-WebRequest "http://127.0.0.1:$Port/" -UseBasicParsing -TimeoutSec 3
      if ($r.StatusCode -eq 200) {
        Log "Server up: http://127.0.0.1:$Port/ (HTTP 200)"
        return
      }
    } catch {}
  }
  Log "WARNING: server did not answer on port $Port within timeout. Check $log"
}

if ($Target -eq 'front' -or $Target -eq 'all') { Build-Front }
if ($Target -eq 'back' -or $Target -eq 'all') {
  Stop-Server -Port $Port
  Start-Server -Port $Port
}
if ($Target -eq 'front') {
  Log "Front rebuilt. Refresh the browser to load it."
}
Log "Done."
