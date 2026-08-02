[CmdletBinding()]
param(
    [string]$Version = '1.1.1',
    [string]$JellyfinVersion = '10.11.11',
    [string]$DotnetPath
)

$ErrorActionPreference = 'Stop'
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw 'Version must use stable semantic versioning, for example 1.0.0.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$localDotnet = Join-Path $repoRoot '.dotnet\dotnet.exe'
$dotnet = if (-not [string]::IsNullOrWhiteSpace($DotnetPath)) {
    (Resolve-Path -LiteralPath $DotnetPath -ErrorAction Stop).Path
} elseif (Test-Path -LiteralPath $localDotnet) {
    $localDotnet
} else {
    (Get-Command dotnet -ErrorAction Stop).Source
}

$archiveName = "Jellyfin.SmartResolver_${Version}_jellyfin-$JellyfinVersion.zip"
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
& $dotnet build (Join-Path $repoRoot 'Jellyfin.SmartResolver.sln') -c Release --no-restore -p:Version=$Version
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
if ((Get-Item -LiteralPath $dll).VersionInfo.FileVersion -ne "$Version.0") {
    throw 'Published plugin DLL version does not match the requested version.'
}
Copy-Item -LiteralPath $dll -Destination $stage

$meta = @{
    category = 'General'
    changelog = 'Enable reliable automatic updates from the Jellyfin plugin repository.'
    description = 'Safely finds media stored in extra folders and reads movie names from video files.'
    guid = 'c61d7897-a923-4a6d-9d4d-c6c911f28e73'
    name = 'Jellyfin Smart Resolver'
    overview = 'Finds series stored one folder deeper and reads movie names from video files.'
    imageUrl = 'https://raw.githubusercontent.com/Lootfullin/jellyfin-smart-resolver/main/assets/icon.svg'
    owner = 'Lootfullin'
    targetAbi = "$JellyfinVersion.0"
    timestamp = [DateTime]::UtcNow.ToString('o')
    version = "$Version.0"
    status = 'Active'
    autoUpdate = $true
}
$metaPath = Join-Path $stage 'meta.json'
$metaJson = ConvertTo-Json -InputObject $meta
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($metaPath, "$metaJson`n", $utf8NoBom)

New-Item -ItemType Directory -Path $artifacts -Force | Out-Null
$archive = Join-Path $artifacts $archiveName
if (Test-Path -LiteralPath $archive) {
    Remove-Item -LiteralPath $archive -Force
}
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $archive

Add-Type -AssemblyName System.IO.Compression.FileSystem
$package = [System.IO.Compression.ZipFile]::OpenRead($archive)
try {
    $entries = @($package.Entries | Where-Object { $_.Name } | ForEach-Object FullName)
    $expectedEntries = @('meta.json', 'Jellyfin.Plugin.SmartResolver.dll')
    if (@(Compare-Object $entries $expectedEntries).Count -ne 0) {
        throw "Package root is invalid: $($entries -join ', ')."
    }

    $metaEntry = $package.GetEntry('meta.json')
    $reader = [System.IO.StreamReader]::new($metaEntry.Open())
    try {
        $packagedMeta = $reader.ReadToEnd() | ConvertFrom-Json
    } finally {
        $reader.Dispose()
    }

    if ($packagedMeta.autoUpdate -ne $true) {
        throw 'Packaged meta.json must set autoUpdate to true.'
    }
    if ($packagedMeta.version -ne "$Version.0") {
        throw "Packaged version is '$($packagedMeta.version)'."
    }
    if ($packagedMeta.targetAbi -ne "$JellyfinVersion.0") {
        throw "Packaged target ABI is '$($packagedMeta.targetAbi)'."
    }
} finally {
    $package.Dispose()
}

$checksum = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
$checksumPath = "$archive.sha256"
"$checksum  $archiveName" | Set-Content -LiteralPath $checksumPath -Encoding ascii

Write-Host "Package: $archive"
Write-Host "SHA256:  $checksumPath"
