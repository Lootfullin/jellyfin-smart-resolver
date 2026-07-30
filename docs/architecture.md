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

The plugin never changes the filesystem. Future evidence providers can add
signals without changing this boundary.
