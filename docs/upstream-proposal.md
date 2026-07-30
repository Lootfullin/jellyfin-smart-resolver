# Upstream proposal: single nested series root

## Problem

Some libraries use an outer navigation folder and keep the real Jellyfin
series root one directory deeper:

```text
(2025) Alien Earth/
└── Alien Earth (2025)/
    ├── tvshow.nfo
    ├── poster.jpg
    └── Season 01/
```

The built-in resolver selects the outer directory, so local metadata and
artwork in the inner root are missed.

## Proposed behavior

Add a TV-library option named **Enable smart nested series resolution**,
disabled by default. When enabled, treat a single nested directory as the
series root only when it contains strong series evidence.

## Safety constraints

- TV Shows libraries only.
- Exactly one non-service child directory.
- The child must be a safe direct path without a filesystem link.
- Require a season folder, episode filename, `tvshow.nfo`, or local artwork
  accompanied by video content.
- Do nothing when the outer folder already contains series evidence.
- Return to current resolver behavior on any uncertainty or I/O failure.

## Tests

Cover year-prefixed and arbitrary outer names, season and episode evidence,
local metadata, ignored service directories, multiple children, inaccessible
paths, recursive links and items already below a Series or Season.

## Integration

The check belongs immediately before the normal TV `SeriesResolver` commits
the outer path. It should reuse Jellyfin naming and filesystem abstractions.

## Compatibility and migration

The setting is off by default, so existing libraries keep identical behavior.
Enabling it requires a library rescan but no filesystem migration.

## Plugin comparison

The plugin proves the behavior through an `IItemResolver` with
`ResolverPriority.First`. Core integration would provide a per-library option
and reuse internal naming APIs more directly, while the plugin remains useful
for experimentation and older deployments. This repository does not modify
Jellyfin Core and does not create an upstream pull request automatically.
