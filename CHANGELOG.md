# Changelog

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
