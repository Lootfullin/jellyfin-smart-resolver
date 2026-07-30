# Troubleshooting

## Plugin does not appear

- Confirm Jellyfin Server is exactly version 10.11.11.
- Put the DLL in its own folder under the Jellyfin plugins directory.
- Restart the Jellyfin server.
- Check file permissions and the first startup errors in the server log.

## The Plugins page fails

Install the latest `0.1.0-beta` DLL. The plugin uses Jellyfin's standard
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

## The title is temporarily English

Smart Resolver creates the item from the filename first. Metadata providers
run afterward and may replace the title. Russian Metadata may need IMDb/TMDb
identifiers found by an earlier provider, so the translated title can appear
later during the same scan.
