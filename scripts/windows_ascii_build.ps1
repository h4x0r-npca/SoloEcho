param(
  [Parameter(Mandatory = $true)]
  [string]$DesktopClientId,

  [string]$DesktopClientSecret = "",

  [ValidateSet("run", "build")]
  [string]$Mode = "run"
)

$ErrorActionPreference = "Stop"

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutter) {
  $flutterExe = $flutter.Source
} elseif (Test-Path "C:\src\flutter\flutter\bin\flutter.bat") {
  $flutterExe = "C:\src\flutter\flutter\bin\flutter.bat"
} else {
  throw "Flutter was not found on PATH or at C:\src\flutter\flutter\bin\flutter.bat"
}

$source = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$target = Join-Path $env:LOCALAPPDATA "SoloEchoBuild"
$targetFull = [System.IO.Path]::GetFullPath($target)
$localAppDataFull = [System.IO.Path]::GetFullPath($env:LOCALAPPDATA)

if (-not $targetFull.StartsWith($localAppDataFull, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Refusing to mirror into an unsafe path: $targetFull"
}

New-Item -ItemType Directory -Force -Path $targetFull | Out-Null

robocopy $source $targetFull /MIR /XD .git .dart_tool build .idea .vscode ephemeral /XF .flutter-plugins .flutter-plugins-dependencies
if ($LASTEXITCODE -gt 7) {
  exit $LASTEXITCODE
}

Push-Location $targetFull
try {
  & $flutterExe pub get
  $dartDefines = @(
    "--dart-define=SOLOECHO_DESKTOP_CLIENT_ID=$DesktopClientId"
  )
  if (-not [string]::IsNullOrWhiteSpace($DesktopClientSecret)) {
    $dartDefines += "--dart-define=SOLOECHO_DESKTOP_CLIENT_SECRET=$DesktopClientSecret"
  }

  if ($Mode -eq "build") {
    & $flutterExe build windows @dartDefines
  } else {
    & $flutterExe run -d windows @dartDefines
  }
} finally {
  Pop-Location
}
