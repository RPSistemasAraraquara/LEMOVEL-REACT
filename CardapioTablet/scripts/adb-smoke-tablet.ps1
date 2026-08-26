param(
  [string]$ApkPath = '',
  [string]$DeviceId = '',
  [switch]$NoInstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$distDir = Join-Path $projectRoot 'dist'
$packageId = 'br.com.sistemalechef.cardapiotablet'

function Resolve-AndroidSdk {
  $candidates = @(@(
    $env:ANDROID_HOME,
    $env:ANDROID_SDK_ROOT,
    (Join-Path $env:LOCALAPPDATA 'Android\Sdk'),
    'C:\Users\Rafael\AppData\Local\Android\Sdk'
  ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) })

  if ($candidates.Count -eq 0) {
    throw 'Android SDK nao encontrado. Defina ANDROID_HOME ou ANDROID_SDK_ROOT.'
  }

  return [string]$candidates[0]
}

function Invoke-Adb {
  param([string[]]$AdbArgs)

  $fullArgs = @()
  if ($DeviceId) {
    $fullArgs += @('-s', $DeviceId)
  }
  $fullArgs += $AdbArgs

  & $script:adb @fullArgs
}

Push-Location $projectRoot
try {
  $androidSdk = Resolve-AndroidSdk
  $script:adb = Join-Path $androidSdk 'platform-tools\adb.exe'
  if (-not (Test-Path -LiteralPath $script:adb)) {
    throw "adb.exe nao encontrado em $androidSdk."
  }

  if (-not $ApkPath) {
    $latestApk = Get-ChildItem -LiteralPath $distDir -Filter 'CardapioTablet-*-homologacao-debugsigned.apk' -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 1

    if (-not $latestApk) {
      throw 'Nenhum APK de release encontrado em dist. Gere o release antes de rodar o smoke ADB.'
    }

    $ApkPath = $latestApk.FullName
  }

  if (-not (Test-Path -LiteralPath $ApkPath)) {
    throw "APK nao encontrado: $ApkPath"
  }

  $deviceOutput = & $script:adb devices
  $deviceLines = @($deviceOutput | Where-Object { $_ -match "`tdevice$" })
  if (-not $DeviceId) {
    if ($deviceLines.Count -eq 0) {
      throw 'Nenhum tablet ADB conectado em estado device.'
    }
    $DeviceId = ($deviceLines[0] -split "`t")[0]
  }

  $installOutput = 'Instalacao ignorada por -NoInstall.'
  if (-not $NoInstall) {
    $installOutput = (Invoke-Adb @('install', '-r', $ApkPath)) -join [Environment]::NewLine
  }

  $launchOutput = (Invoke-Adb @('shell', 'monkey', '-p', $packageId, '-c', 'android.intent.category.LAUNCHER', '1')) -join [Environment]::NewLine
  Start-Sleep -Seconds 2

  $packageDump = (Invoke-Adb @('shell', 'dumpsys', 'package', $packageId)) -join [Environment]::NewLine
  $activityDump = (Invoke-Adb @('shell', 'dumpsys', 'activity', 'activities')) -join [Environment]::NewLine
  $lockTaskDump = (Invoke-Adb @('shell', 'dumpsys', 'activity')) -join [Environment]::NewLine

  New-Item -ItemType Directory -Force -Path $distDir | Out-Null
  $reportPath = Join-Path $distDir 'adb-smoke-cardapio-tablet.txt'
  $createdAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

  $packageLines = ($packageDump -split "`r?`n") | Where-Object { $_ -match 'versionName|versionCode|firstInstallTime|lastUpdateTime' }
  $activityLines = (($activityDump + [Environment]::NewLine + $lockTaskDump) -split "`r?`n") |
    Where-Object { $_ -match 'mLockTaskModeState|LOCK_TASK|LockTask|cardapiotablet|topResumedActivity|ResumedActivity' }

  $report = @(
    'Cardapio Tablet - ADB smoke',
    "Gerado em: $createdAt",
    "Device: $DeviceId",
    "APK: $ApkPath",
    '',
    'adb devices:',
    ($deviceOutput -join [Environment]::NewLine),
    '',
    'install:',
    $installOutput,
    '',
    'launch:',
    $launchOutput,
    '',
    'package:',
    ($packageLines -join [Environment]::NewLine),
    '',
    'activity/kiosk:',
    ($activityLines -join [Environment]::NewLine)
  ) -join [Environment]::NewLine

  Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8

  Write-Host "Smoke ADB finalizado: $reportPath"
} finally {
  Pop-Location
}
