# Compatibility

The plugin contains no operating-system-specific code. Release archives contain
one managed .NET assembly and can be installed on every platform supported by
the matching Jellyfin Server version.

| Environment | Jellyfin | Validation |
| --- | --- | --- |
| Windows | 10.11.11 | Catalog installation and a large real-library scan confirmed |
| Linux container | 10.11.11 | Automated build plus a real server boot with the plugin loaded |
| Linux container | 12.0 RC3 | Preview build on .NET 10 plus a real server boot |
| Linux host | 10.11.11 | Covered by the same managed assembly and Linux container runtime |
| macOS | 10.11.11 | Compiled and tested by CI; physical-server smoke test still welcome |

Jellyfin 10.11.11 is the stable release target. Jellyfin 12 support remains
preview-only until Jellyfin 12 itself is stable; it requires a separate
`net10.0` build and must not be installed on Jellyfin 10.

The GitHub Actions workflow prevents accidental regressions by building and
testing on Windows, Linux and macOS, then starting real Jellyfin containers for
the supported stable server and the current Jellyfin 12 release candidate.
