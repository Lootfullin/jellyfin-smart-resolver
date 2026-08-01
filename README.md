# Jellyfin Smart Resolver

<p align="center">
  <img src="assets/icon.svg" width="160" alt="Jellyfin Smart Resolver icon">
</p>

Jellyfin Smart Resolver is a read-only plugin that helps Jellyfin understand
media layouts whose navigation folders do not describe the actual media.

Version `1.1.0` targets **Jellyfin Server 10.11.11**. The plugin is a
platform-neutral .NET assembly and requires .NET 9 only when building it.

## What it solves

### Nested series

Given this structure:

```text
P:\Shows
└── (2025) Alien Earth
    └── Alien Earth (2025)
        ├── tvshow.nfo
        ├── poster.jpg
        └── Season 01
```

Jellyfin normally treats `(2025) Alien Earth` as the series root. Smart
Resolver maps it to:

```text
P:\Shows\(2025) Alien Earth\Alien Earth (2025)
```

Local series artwork, season artwork, NFO files and ordinary metadata
providers can then operate on the actual series folder.

### Movie filenames

Given:

```text
P:\Movies\(1979) Moonraker\Moonraker (1979) [WEB-DL].mkv
```

the plugin derives `Moonraker` and `1979` from the video filename. The folder
name is used only for navigation. Cyrillic and other Unicode movie names are
preserved. Provider IDs in `[tmdbid-123]` and `[imdbid-tt1234567]` form are
also preserved.

Numeric movie titles are preserved as titles rather than mistaken for release
years. For example, `2012 (2009).mkv` resolves to title `2012` and year `2009`,
while `1917 (2019).mkv` resolves to title `1917` and year `2019`.

Multiple files for the same title and year are retained as alternate versions.
Files ending in `CD1`, `CD2`, `Disc 1`, `Part 2` and similar markers are kept
as consecutive parts. A movie may also live one additional folder level below
its navigation folder.

## Safety

- The plugin never writes, moves, renames or deletes media files.
- It runs only for TV Shows and Movies libraries.
- Ambiguous structures are rejected and passed back to Jellyfin's normal
  resolvers.
- Multiple primary videos are accepted only when Jellyfin parses them as
  versions or parts of the same title and year.
- Nested series paths must be safe direct child directories.

## Installation

### Plugin catalog

In Jellyfin, open **Dashboard → Plugins → Repositories**, add:

```text
https://raw.githubusercontent.com/Lootfullin/jellyfin-smart-resolver/main/manifest.json
```

The catalog contains three independent plugins:

- **Jellyfin Smart Resolver** — resolves nested series folders and movie names
  from video files.
- **Choose your Meta!** — controls RU/EN metadata, posters, and logos for
  movies and collections.
- **Cowabunga Custom Artwork** — provides custom posters and logos from a
  private Cowabunga cloud.

Install either plugin from the catalog and restart Jellyfin.

### Manual installation

Download the release ZIP and extract it into a dedicated folder below the
Jellyfin plugins directory:

- Windows tray install:
  `%ProgramData%\Jellyfin\Server\plugins\Jellyfin Smart Resolver`
- Native Linux:
  `/var/lib/jellyfin/plugins/Jellyfin Smart Resolver`
- Official Linux container:
  `/config/plugins/Jellyfin Smart Resolver`
- Native macOS:
  `~/Library/Application Support/Jellyfin/plugins/Jellyfin Smart Resolver`

Then restart Jellyfin and scan the affected libraries again.

### Build from source

Windows:

```powershell
.\scripts\package.ps1
.\scripts\build-and-install.ps1
```

Linux or macOS:

```bash
./scripts/package.sh
sudo ./scripts/build-and-install.sh /var/lib/jellyfin
```

For the official container, copy or extract the release into the host
directory mounted as `/config/plugins`; do not build inside the container.

## Configuration

- **Enable Smart Resolver** is the global switch.
- **Nested Series** can use:
  - `YearPrefix` — safe default for `(2025) Title`;
  - `AnySingleNestedSeries` — accepts any outer name when the structure is
    otherwise unambiguous;
  - `CustomRegex` — matches the outer folder name with a user expression.
- **Movies** controls filename-based movie resolution.
- Successful and rejected-candidate logging can be enabled separately.

The settings page automatically uses Russian when the Jellyfin web interface
is opened with a Russian browser language; otherwise it uses English.

### Diagnostics

The settings page includes:

- a read-only folder check that shows what Smart Resolver would choose without
  starting a library scan;
- the latest 200 accepted and skipped folder decisions since server startup;
- a short reason for every skipped folder;
- the detected title, year, destination path and structural evidence.

Diagnostic endpoints require an administrator account.

Search the Jellyfin log for:

```text
Jellyfin Smart Resolver mapped
```

## Supported environments

The same release DLL is built for every OS. GitHub Actions validates the code
on Windows, Ubuntu Linux and macOS. The official Jellyfin container uses the
Linux build and needs no separate package.

CI also boots real Jellyfin containers, loads the plugin and checks its
administrator-only diagnostics API:

- Jellyfin 10.11.11 on .NET 9;
- Jellyfin 12.0 RC3 preview on .NET 10.

Runtime behavior has been manually exercised with Jellyfin Server 10.11.11 on
Windows:

- automatic series recognition;
- TMDb and Russian Metadata;
- local custom series posters;
- local season posters;
- nested series folders;
- movie titles derived from English and Russian filenames.

Jellyfin Server 10.11.11 is the current supported stable release. Jellyfin
12.0 RC3 is continuously tested as a preview but will receive an official
catalog package only after Jellyfin 12 becomes stable.

## Known limitations

- A nested series outer folder must resolve to exactly one eligible child.
- Trailers and extras recognized by Jellyfin are ignored. Multiple primary
  files with different parsed titles or years remain intentionally ambiguous.
- The plugin does not control the order or speed of metadata providers.
- Metadata providers can still confuse numeric titles. Add a provider ID to
  the filename, such as `1917 (2019) [tmdbid-530915].mkv`, when exact matching
  is required.
- Changing settings requires rescanning affected libraries.

See [troubleshooting](docs/troubleshooting.md) for common problems.
The [compatibility matrix](docs/compatibility.md) lists tested operating systems
and Jellyfin versions.

## Development

```text
dotnet restore
dotnet build -c Release
dotnet test -c Release
dotnet publish -c Release
```

The project is licensed under `GPL-3.0-only`.
