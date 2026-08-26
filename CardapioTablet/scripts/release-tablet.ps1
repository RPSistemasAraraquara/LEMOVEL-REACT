param(
  [string]$Version = '',
  [string]$ApkSource = '',
  [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$distDir = Join-Path $projectRoot 'dist'

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

function Resolve-BuildTools {
  param([string]$AndroidSdk)

  $buildToolsRoot = Join-Path $AndroidSdk 'build-tools'
  if (-not (Test-Path -LiteralPath $buildToolsRoot)) {
    throw "Pasta build-tools nao encontrada em $AndroidSdk."
  }

  $buildTools = Get-ChildItem -LiteralPath $buildToolsRoot -Directory |
    Sort-Object Name -Descending |
    Select-Object -First 1

  if (-not $buildTools) {
    throw "Nenhuma versao de build-tools encontrada em $buildToolsRoot."
  }

  return $buildTools.FullName
}

function Get-Sha256Hash {
  param([string]$Path)

  $getFileHashCommand = Get-Command Get-FileHash -ErrorAction SilentlyContinue
  if ($getFileHashCommand) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
  }

  $stream = [System.IO.File]::OpenRead($Path)
  $sha = $null
  try {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    return ([System.BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '')
  } finally {
    if ($sha) {
      $sha.Dispose()
    }
    $stream.Dispose()
  }
}

Push-Location $projectRoot
try {
  $packageJson = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'package.json') | ConvertFrom-Json
  if (-not $Version) {
    $Version = [string]$packageJson.version
  }

  if (-not $Version) {
    throw 'Versao nao informada e package.json sem version.'
  }

  Write-Host "Cardapio Tablet - release Android $Version"
  & npm run test:smoke
  if ($LASTEXITCODE -ne 0) {
    throw 'Smoke local falhou.'
  }

  if (-not $SkipBuild) {
    Push-Location (Join-Path $projectRoot 'android')
    try {
      & .\gradlew.bat assembleRelease
      if ($LASTEXITCODE -ne 0) {
        throw 'Gradle assembleRelease falhou.'
      }
    } finally {
      Pop-Location
    }
  }

  if (-not $ApkSource) {
    $ApkSource = Join-Path $projectRoot 'android\app\build\outputs\apk\release\app-release.apk'
  }

  if (-not (Test-Path -LiteralPath $ApkSource)) {
    throw "APK fonte nao encontrado: $ApkSource"
  }

  New-Item -ItemType Directory -Force -Path $distDir | Out-Null

  $outputApk = Join-Path $distDir "CardapioTablet-$Version-homologacao-debugsigned.apk"
  Copy-Item -LiteralPath $ApkSource -Destination $outputApk -Force

  $androidSdk = Resolve-AndroidSdk
  $buildTools = Resolve-BuildTools -AndroidSdk $androidSdk
  $aapt = Join-Path $buildTools 'aapt.exe'
  $apksigner = Join-Path $buildTools 'apksigner.bat'

  if (-not (Test-Path -LiteralPath $aapt)) {
    throw "aapt.exe nao encontrado em $buildTools."
  }
  if (-not (Test-Path -LiteralPath $apksigner)) {
    throw "apksigner.bat nao encontrado em $buildTools."
  }

  $badging = & $aapt dump badging $outputApk
  if ($LASTEXITCODE -ne 0) {
    throw 'aapt dump badging falhou.'
  }

  $signature = & $apksigner verify --verbose $outputApk
  if ($LASTEXITCODE -ne 0) {
    throw 'apksigner verify falhou.'
  }

  $hash = Get-Sha256Hash -Path $outputApk
  $apkInfo = Get-Item -LiteralPath $outputApk
  $infoPath = Join-Path $distDir "CardapioTablet-$Version-release-info.txt"
  $createdAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

  $report = @(
    "Cardapio Tablet - Release Android",
    "Gerado em: $createdAt",
    "Versao: $Version",
    "APK: $outputApk",
    "Tamanho bytes: $($apkInfo.Length)",
    "SHA256: $hash",
    "",
    "aapt badging:",
    ($badging -join [Environment]::NewLine),
    "",
    "apksigner:",
    ($signature -join [Environment]::NewLine)
  ) -join [Environment]::NewLine

  Set-Content -LiteralPath $infoPath -Value $report -Encoding UTF8

  Write-Host "APK: $outputApk"
  Write-Host "SHA256: $hash"
  Write-Host "Evidencia: $infoPath"
} finally {
  Pop-Location
}
