[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Repository,

    [Parameter(Mandatory = $true)]
    [string]$Checksum,

    [string]$ReleaseTag = 'v1.0.0',

    [string]$PluginVersion = '1.0.0',

    [string]$JellyfinVersion = '10.11.11',

    [string]$Timestamp = ([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))
)

$ErrorActionPreference = 'Stop'
if ($PluginVersion -notmatch '^\d+\.\d+\.\d+$') {
    throw 'PluginVersion must use stable semantic versioning, for example 1.0.0.'
}

$archiveName = "Jellyfin.SmartResolver_${PluginVersion}_jellyfin-$JellyfinVersion.zip"
$manifest = @(
    @{
        guid = 'c61d7897-a923-4a6d-9d4d-c6c911f28e73'
        name = 'Jellyfin Smart Resolver'
        description = 'Safe, read-only media structure resolvers for Jellyfin.'
        overview = 'Resolves nested series roots and derives movie metadata from video filenames.'
        owner = 'Lootfullin'
        category = 'General'
        versions = @(
            @{
                version = "$PluginVersion.0"
                changelog = 'Stable release with nested series and filename-based movie resolution.'
                targetAbi = "$JellyfinVersion.0"
                sourceUrl = "https://github.com/$Repository/releases/download/$ReleaseTag/$archiveName"
                checksum = $Checksum.ToLowerInvariant()
                timestamp = $Timestamp
            }
        )
    }
)

$manifestPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'manifest.json'
$manifestJson = ConvertTo-Json -InputObject $manifest -Depth 6

if ($manifestJson.TrimStart()[0] -ne '[') {
    throw 'The Jellyfin plugin catalog manifest root must be a JSON array.'
}

$null = ConvertFrom-Json -InputObject $manifestJson

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($manifestPath, "$manifestJson`n", $utf8NoBom)
