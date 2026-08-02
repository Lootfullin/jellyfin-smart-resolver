[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Repository,

    [Parameter(Mandatory = $true)]
    [string]$Checksum,

    [string]$ReleaseTag = 'v1.1.0',

    [string]$PluginVersion = '1.1.0',

    [string]$JellyfinVersion = '10.11.11',

    [string]$Changelog = 'Enable reliable automatic updates from the Jellyfin plugin repository.',

    [string]$Timestamp = ([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')),

    [string]$ManifestPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'manifest.json')
)

$ErrorActionPreference = 'Stop'
if ($PluginVersion -notmatch '^\d+\.\d+\.\d+$') {
    throw 'PluginVersion must use stable semantic versioning, for example 1.0.0.'
}

$archiveName = "Jellyfin.SmartResolver_${PluginVersion}_jellyfin-$JellyfinVersion.zip"
$smartResolverGuid = 'c61d7897-a923-4a6d-9d4d-c6c911f28e73'
$newVersion = @{
    version = "$PluginVersion.0"
    changelog = $Changelog
    targetAbi = "$JellyfinVersion.0"
    sourceUrl = "https://github.com/$Repository/releases/download/$ReleaseTag/$archiveName"
    checksum = $Checksum.ToLowerInvariant()
    timestamp = $Timestamp
}

$otherPlugins = @()
if (Test-Path -LiteralPath $ManifestPath) {
    $parsedManifest = ConvertFrom-Json -InputObject (
        Get-Content -Raw -LiteralPath $ManifestPath
    )
    $existingManifest = @($parsedManifest | ForEach-Object { $_ })
    $otherPlugins = @($existingManifest | Where-Object {
        $_.guid -ne $smartResolverGuid
    })
}

$smartResolver = @{
    guid = $smartResolverGuid
    name = 'Jellyfin Smart Resolver'
    description = 'Safely finds media stored in extra folders and reads movie names from video files.'
    overview = 'Finds series stored one folder deeper and reads movie names from video files.'
    imageUrl = 'https://raw.githubusercontent.com/Lootfullin/jellyfin-smart-resolver/main/assets/icon.svg'
    owner = 'Lootfullin'
    category = 'General'
    # Keep only the current compatible build in the live catalog. Old builds
    # remain available on GitHub Releases, but publishing them here causes
    # Jellyfin to reconcile stale on-disk manifests and reactivate folders
    # which Windows could not remove while their DLLs were loaded.
    versions = @($newVersion)
}

$manifest = @($smartResolver) + $otherPlugins
$manifestJson = ConvertTo-Json -InputObject $manifest -Depth 6

if ($manifestJson.TrimStart()[0] -ne '[') {
    throw 'The Jellyfin plugin catalog manifest root must be a JSON array.'
}

$null = ConvertFrom-Json -InputObject $manifestJson

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($ManifestPath, "$manifestJson`n", $utf8NoBom)
