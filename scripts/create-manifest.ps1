[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Repository,

    [Parameter(Mandatory = $true)]
    [string]$Checksum,

    [string]$ReleaseTag = 'v0.1.0-beta',

    [string]$Timestamp = ([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))
)

$ErrorActionPreference = 'Stop'
$archiveName = 'Jellyfin.SmartResolver_0.1.0-beta_jellyfin-10.11.11.zip'
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
                version = '0.1.0.0'
                changelog = 'Initial beta with nested series and movie filename resolvers.'
                targetAbi = '10.11.11.0'
                sourceUrl = "https://github.com/$Repository/releases/download/$ReleaseTag/$archiveName"
                checksum = $Checksum.ToLowerInvariant()
                timestamp = $Timestamp
            }
        )
    }
)

$manifest |
    ConvertTo-Json -Depth 6 |
    Set-Content -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'manifest.json') -Encoding utf8
