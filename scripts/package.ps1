[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$localDotnet = Join-Path $repoRoot '.dotnet\dotnet.exe'
$dotnet = if (Test-Path -LiteralPath $localDotnet) {
    $localDotnet
} else {
    (Get-Command dotnet -ErrorAction Stop).Source
}

$version = '0.1.0-beta'
$archiveName = "Jellyfin.SmartResolver_${version}_jellyfin-10.11.11.zip"
$artifacts = Join-Path $repoRoot 'artifacts'
$publish = Join-Path $repoRoot 'publish'
$stage = Join-Path $artifacts 'package'

foreach ($path in @($publish, $stage)) {
    $resolved = [System.IO.Path]::GetFullPath($path)
    $resolvedRoot = [System.IO.Path]::GetFullPath($repoRoot)
    if (-not $resolved.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Refusing to clean a path outside the repository.'
    }

    if (Test-Path -LiteralPath $resolved) {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}

New-Item -ItemType Directory -Path $stage -Force | Out-Null

& $dotnet restore (Join-Path $repoRoot 'Jellyfin.SmartResolver.sln')
if ($LASTEXITCODE -ne 0) { throw 'dotnet restore failed.' }
& $dotnet build (Join-Path $repoRoot 'Jellyfin.SmartResolver.sln') -c Release --no-restore
if ($LASTEXITCODE -ne 0) { throw 'dotnet build failed.' }
& $dotnet test (Join-Path $repoRoot 'Jellyfin.SmartResolver.sln') -c Release --no-build
if ($LASTEXITCODE -ne 0) { throw 'dotnet test failed.' }

$project = Join-Path $repoRoot 'src\Jellyfin.Plugin.SmartResolver\Jellyfin.Plugin.SmartResolver.csproj'
& $dotnet publish $project -c Release --no-build -o $publish
if ($LASTEXITCODE -ne 0) { throw 'dotnet publish failed.' }

$dll = Join-Path $publish 'Jellyfin.Plugin.SmartResolver.dll'
if (-not (Test-Path -LiteralPath $dll)) {
    throw 'Published plugin DLL was not found.'
}
Copy-Item -LiteralPath $dll -Destination $stage

$meta = @{
    category = 'General'
    changelog = 'Initial beta with nested series and movie filename resolvers.'
    description = 'Safe, read-only media structure resolvers for Jellyfin.'
    guid = 'c61d7897-a923-4a6d-9d4d-c6c911f28e73'
    name = 'Jellyfin Smart Resolver'
    overview = 'Resolves nested series roots and derives movie metadata from video filenames.'
    owner = 'Lootfullin'
    targetAbi = '10.11.11.0'
    timestamp = [DateTime]::UtcNow.ToString('o')
    version = '0.1.0.0'
    status = 'Active'
    autoUpdate = $false
}
$meta | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $stage 'meta.json') -Encoding utf8

New-Item -ItemType Directory -Path $artifacts -Force | Out-Null
$archive = Join-Path $artifacts $archiveName
if (Test-Path -LiteralPath $archive) {
    Remove-Item -LiteralPath $archive -Force
}
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $archive

$checksum = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
$checksumPath = "$archive.sha256"
"$checksum  $archiveName" | Set-Content -LiteralPath $checksumPath -Encoding ascii

Write-Host "Package: $archive"
Write-Host "SHA256:  $checksumPath"
