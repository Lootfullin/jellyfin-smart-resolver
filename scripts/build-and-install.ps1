[CmdletBinding()]
param(
    [string]$JellyfinPath = 'C:\ProgramData\Jellyfin\Server',
    [switch]$RestartJellyfin
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$localDotnet = Join-Path $repoRoot '.dotnet\dotnet.exe'
$dotnet = if (Test-Path -LiteralPath $localDotnet) {
    $localDotnet
} else {
    (Get-Command dotnet -ErrorAction Stop).Source
}

$sdkVersion = & $dotnet --version
if ($LASTEXITCODE -ne 0 -or -not $sdkVersion.StartsWith('9.')) {
    throw 'Jellyfin Smart Resolver requires the .NET 9 SDK.'
}

$publishPath = Join-Path $repoRoot 'publish'
$resolvedRepo = [System.IO.Path]::GetFullPath($repoRoot)
$resolvedPublish = [System.IO.Path]::GetFullPath($publishPath)
if (-not $resolvedPublish.StartsWith($resolvedRepo, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Refusing to clean a publish path outside the repository.'
}

if (Test-Path -LiteralPath $resolvedPublish) {
    Remove-Item -LiteralPath $resolvedPublish -Recurse -Force
}

& $dotnet restore (Join-Path $repoRoot 'Jellyfin.SmartResolver.sln')
if ($LASTEXITCODE -ne 0) { throw 'dotnet restore failed.' }

& $dotnet build (Join-Path $repoRoot 'Jellyfin.SmartResolver.sln') -c Release --no-restore
if ($LASTEXITCODE -ne 0) { throw 'dotnet build failed.' }

& $dotnet test (Join-Path $repoRoot 'Jellyfin.SmartResolver.sln') -c Release --no-build
if ($LASTEXITCODE -ne 0) { throw 'dotnet test failed.' }

$project = Join-Path $repoRoot 'src\Jellyfin.Plugin.SmartResolver\Jellyfin.Plugin.SmartResolver.csproj'
& $dotnet publish $project -c Release --no-build -o $resolvedPublish
if ($LASTEXITCODE -ne 0) { throw 'dotnet publish failed.' }

$dll = Join-Path $resolvedPublish 'Jellyfin.Plugin.SmartResolver.dll'
if (-not (Test-Path -LiteralPath $dll)) {
    throw 'Published plugin DLL was not found.'
}

$pluginPath = Join-Path $JellyfinPath 'plugins\Jellyfin Smart Resolver'
New-Item -ItemType Directory -Path $pluginPath -Force | Out-Null
Copy-Item -LiteralPath $dll -Destination $pluginPath -Force

Write-Host "Installed: $pluginPath"
if ($RestartJellyfin) {
    Restart-Service -Name 'Jellyfin' -Force
    Write-Host 'Jellyfin service restarted.'
} else {
    Write-Host 'Restart Jellyfin before using the new DLL.'
}
