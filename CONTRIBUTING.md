# Contributing

Keep changes small, read-only and limited to media resolution. A resolver must
return `null` whenever evidence is ambiguous so Jellyfin can continue with its
standard behavior.

Before submitting a change:

```powershell
dotnet restore
dotnet build -c Release
dotnet test -c Release
```

Add tests for accepted and rejected structures. Do not add media mutation,
telemetry or support claims for untested Jellyfin versions.
