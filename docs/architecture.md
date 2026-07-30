# Architecture

Jellyfin Smart Resolver runs as an inference layer between Jellyfin's library
scanner and its built-in item resolvers.

```text
ItemResolveArgs
  → library and parent safety checks
  → module detector
  → ResolverDecision with reason and evidence
  → Jellyfin item or null
```

`MovieFileResolver` and `NestedSeriesResolver` contain only Jellyfin
integration. Their detectors make testable decisions without a running
server. All accepted and rejected outcomes use `ResolverDecision`; normal
rejections do not use exceptions.

Both resolvers use `ResolverPriority.First`. They are restricted to their
matching library types and return `null` on uncertainty, allowing the standard
Jellyfin resolvers to continue.

`ResolutionHistory` keeps at most 200 in-memory decisions and never writes
media paths to disk. `SmartResolverController` exposes the history and a
read-only folder preview to authenticated administrators. Preview uses the
same detectors as a library scan, so diagnostics cannot drift into a second
recognition implementation.

Movie resolution preserves Jellyfin's representation of multipart files and
alternate versions. A one-level nested movie is accepted only when the outer
folder contains exactly one safe direct child with unambiguous movie evidence.

The plugin never changes the filesystem. Future evidence providers can add
signals without changing this boundary.
