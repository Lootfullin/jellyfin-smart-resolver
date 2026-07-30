# Troubleshooting

## Plugin does not appear

- Confirm Jellyfin Server is exactly version 10.11.11.
- Put the DLL in its own folder under the Jellyfin plugins directory.
- Restart the Jellyfin server.
- Check file permissions and the first startup errors in the server log.

## The Plugins page fails

Install the latest `1.1.0` DLL. The plugin uses Jellyfin's standard
configurable `BasePlugin`, which initializes the assembly path required by the
Plugins page.

## A nested series was not resolved

- Confirm the library type is **TV Shows**.
- In `YearPrefix` mode, use an outer name such as `(2025) Title`.
- Keep exactly one eligible inner folder.
- Place a season folder, episode file or `tvshow.nfo` inside the inner folder.
- Enable rejection logs and rescan the library.

## A movie was not resolved

- Confirm the library type is **Movies**.
- Keep one primary video in the movie folder.
- Put the title and year in the video filename, for example
  `Moonraker (1979) [WEB-DL].mkv`.
- Do not rely on the parent folder for the title.
- For multiple versions, keep the parsed title and year identical, for example
  `Movie (2025) - 1080p.mkv` and `Movie (2025) - 2160p.mkv`.
- For multiple parts, use suffixes such as `CD1` and `CD2`.

## Check a folder without rescanning

Open the Smart Resolver settings page, find **Check a folder without
rescanning**, enter a path visible to the Jellyfin server and choose the media
type. The check reads directory entries but never changes them.

The recent-decisions section keeps the latest 200 results in memory. The list
is cleared when Jellyfin restarts or when an administrator selects **Clear
history**.

## A numeric movie title matched the wrong film

Smart Resolver keeps the title and release year separate: `2012 (2009).mkv`
becomes title `2012`, year `2009`, and `1917 (2019).mkv` becomes title `1917`,
year `2019`. If a metadata provider still chooses the wrong film, add its ID
to the filename, for example `1917 (2019) [tmdbid-530915].mkv`, and rescan it.

## The title is temporarily English

Smart Resolver creates the item from the filename first. Metadata providers
run afterward and may replace the title. Russian Metadata may need IMDb/TMDb
identifiers found by an earlier provider, so the translated title can appear
later during the same scan.
