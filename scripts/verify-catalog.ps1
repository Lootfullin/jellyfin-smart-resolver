[CmdletBinding()]
param(
    [string]$ManifestPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'manifest.json')
)

$ErrorActionPreference = 'Stop'
$raw = Get-Content -Raw -LiteralPath $ManifestPath
if (-not $raw.TrimStart().StartsWith('[')) {
    throw 'Plugin catalog root must be a JSON array.'
}

$plugins = ConvertFrom-Json -InputObject $raw
$knownGuids = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($plugin in $plugins) {
    if (-not $knownGuids.Add([string]$plugin.guid)) {
        throw "Duplicate plugin GUID: $($plugin.guid)"
    }

    $versions = @($plugin.versions)
    if ($versions.Count -ne 1) {
        throw "Plugin '$($plugin.name)' must expose exactly one current compatible version; found $($versions.Count)."
    }

    $version = $versions[0]
    if ($version.sourceUrl -notmatch '^https://') {
        throw "Plugin '$($plugin.name)' has a non-HTTPS source URL."
    }
    if ($version.checksum -notmatch '^[0-9a-fA-F]{32}$') {
        throw "Plugin '$($plugin.name)' has an invalid MD5 catalog checksum."
    }
}

Write-Host "Catalog verified: $($plugins.Count) plugins, one current version each."
