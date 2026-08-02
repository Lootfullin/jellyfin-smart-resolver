# Changelog

## Plugin catalog — 2026-08-03

- Published Cowabunga Custom Artwork 2.4.1. Collection membership now wins over
  incorrect provider IDs and localized names when selecting collection artwork.
- Corrected the 2.4.1 catalog checksum to match the final public release asset,
  restoring installation and updates through Jellyfin.

## 1.1.1

- Kept only the current compatible build of each plugin in the live Jellyfin catalog.
- Added guarded cleanup of stale version directories, including retries for DLLs temporarily locked by Windows.
- Added catalog contract validation to CI and release publishing scripts.

## Plugin catalog — 2026-08-01

- Published Cowabunga Custom Artwork 2.3.0 with stable TMDB-based collection
  identities, nested and custom supercollection support, and automatic image
  provider priority.
- Published Choose your Meta! 1.4.3 with persistent Russian collection titles
  and coordinated Cowabunga Custom Artwork image priority.

## 1.1.0

- Added Russian and English settings with plain-language descriptions.
- Added a read-only folder preview and an administrator-only decision history.
- Added alternate movie versions, multipart movies and one-level nested movies.
- Added a plugin icon and catalog artwork metadata.
- Added live Jellyfin container checks for 10.11.11 and 12.0 RC3.
- Added Dependabot and structured GitHub issue forms.
- Replaced the abbreviated license notice with the complete GPL-3.0 text.

## 1.0.0

- Promoted the tested nested-series and movie filename resolvers to stable.
- Added regression coverage for numeric movie titles such as `2012`, `1917`
  and `1984`.
- Added a reusable stable release workflow for future version tags.
- Fixed Jellyfin plugin-catalog generation so its root is always a JSON array.
- Retained cross-platform packaging for Windows, Linux, macOS and containers.

## 0.1.0-beta

- Added safe nested-series root resolution.
- Added `YearPrefix`, `AnySingleNestedSeries` and `CustomRegex` modes.
- Added movie title and year resolution from the primary video filename.
- Added TMDb and IMDb identifier preservation.
- Added support for Russian and other Unicode movie titles.
- Added a standard Jellyfin configuration page and structured logging.
- Added build, install, package and CI workflows.
- Added cross-platform CI, Bash packaging and installation helpers.
- Added a Jellyfin plugin-catalog manifest release workflow.
- Fixed the Plugins page crash caused by an uninitialized assembly path.
