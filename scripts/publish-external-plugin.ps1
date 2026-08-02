[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('ChooseYourMeta', 'CustomArtwork')]
    [string]$Plugin,

    [Parameter(Mandatory = $true)]
    [string]$Version,

    [Parameter(Mandatory = $true)]
    [uri]$SourceUrl,

    [Parameter(Mandatory = $true)]
    [string]$Changelog,

    [string]$ArchivePath,

    [string]$ManifestPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'manifest.json'),

    [string]$Timestamp = ([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))
)

$ErrorActionPreference = 'Stop'
if ($Version -notmatch '^\d+\.\d+\.\d+\.\d+$') {
    throw 'Version must contain four numeric components.'
}
if ($SourceUrl.Scheme -ne 'https') {
    throw 'SourceUrl must use HTTPS.'
}
if (-not (Test-Path -LiteralPath $ManifestPath)) {
    throw "Manifest was not found: $ManifestPath"
}
$ManifestPath = (Resolve-Path -LiteralPath $ManifestPath).Path

$contracts = @{
    ChooseYourMeta = @{
        Guid = 'a8f3c2e1-4b5d-6e7f-8a9b-0c1d2e3f4a5b'
        Entries = @('meta.json', 'RussianMetadata.dll')
    }
    CustomArtwork = @{
        Guid = '6f2d1a54-9c6e-4f2b-9a7d-5c1e2b8a44f1'
        Entries = @('Jellyfin.Plugin.CustomArtwork.dll', 'logo.png', 'meta.json')
    }
}
$contract = $contracts[$Plugin]
$downloadedArchive = $false
if ([string]::IsNullOrWhiteSpace($ArchivePath)) {
    $ArchivePath = Join-Path ([System.IO.Path]::GetTempPath()) (
        "cowabunga-plugin-$([Guid]::NewGuid().ToString('N')).zip"
    )
    Invoke-WebRequest -Uri $SourceUrl -OutFile $ArchivePath
    $downloadedArchive = $true
}

try {
    $ArchivePath = (Resolve-Path -LiteralPath $ArchivePath -ErrorAction Stop).Path
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        $entries = @($archive.Entries | Where-Object { $_.Name } | ForEach-Object FullName)
        if (@(Compare-Object $entries $contract.Entries).Count -ne 0) {
            throw "Release archive root is invalid: $($entries -join ', ')."
        }

        $metaEntry = $archive.GetEntry('meta.json')
        $reader = [System.IO.StreamReader]::new($metaEntry.Open())
        try {
            $meta = $reader.ReadToEnd() | ConvertFrom-Json
        } finally {
            $reader.Dispose()
        }
    } finally {
        $archive.Dispose()
    }

    if ($meta.guid -ne $contract.Guid) {
        throw "Release GUID is '$($meta.guid)'."
    }
    if ($meta.version -ne $Version) {
        throw "Release version is '$($meta.version)', expected '$Version'."
    }
    if ($meta.autoUpdate -ne $true) {
        throw 'Release meta.json must set autoUpdate to true.'
    }
    if ($meta.targetAbi -notmatch '^10\.11\.\d+\.0$') {
        throw "Release target ABI is '$($meta.targetAbi)'."
    }

    $checksum = (Get-FileHash -LiteralPath $ArchivePath -Algorithm MD5).Hash.ToLowerInvariant()
    $parsed = ConvertFrom-Json -InputObject (Get-Content -Raw -LiteralPath $ManifestPath)
    $manifest = @($parsed | ForEach-Object { $_ })
    $catalogPlugin = $manifest | Where-Object { $_.guid -eq $contract.Guid } | Select-Object -First 1
    if ($null -eq $catalogPlugin) {
        throw "Plugin $Plugin is absent from the catalog."
    }

    $newVersion = [pscustomobject]@{
        version = $Version
        changelog = $Changelog
        targetAbi = $meta.targetAbi
        sourceUrl = $SourceUrl.AbsoluteUri
        checksum = $checksum
        timestamp = $Timestamp
    }
    $catalogPlugin.versions = @($newVersion) + @($catalogPlugin.versions | Where-Object {
        $_.version -ne $Version
    })

    $json = ConvertTo-Json -InputObject @($manifest) -Depth 6
    $null = ConvertFrom-Json -InputObject $json
    $temporaryManifest = "$ManifestPath.$([Guid]::NewGuid().ToString('N')).tmp"
    $backupManifest = "$ManifestPath.$([Guid]::NewGuid().ToString('N')).bak"
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    try {
        [System.IO.File]::WriteAllText($temporaryManifest, "$json`n", $utf8NoBom)
        [System.IO.File]::Replace($temporaryManifest, $ManifestPath, $backupManifest)
    } finally {
        if (Test-Path -LiteralPath $temporaryManifest) {
            Remove-Item -LiteralPath $temporaryManifest -Force
        }
        if (Test-Path -LiteralPath $backupManifest) {
            Remove-Item -LiteralPath $backupManifest -Force
        }
    }

    Write-Host "Catalog updated: $Plugin $Version ($checksum)"
} finally {
    if ($downloadedArchive -and (Test-Path -LiteralPath $ArchivePath)) {
        Remove-Item -LiteralPath $ArchivePath -Force
    }
}
