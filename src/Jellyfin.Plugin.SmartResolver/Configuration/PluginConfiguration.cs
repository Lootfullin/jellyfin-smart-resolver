using MediaBrowser.Model.Plugins;

namespace Jellyfin.Plugin.SmartResolver.Configuration;

public sealed class PluginConfiguration : BasePluginConfiguration
{
    public bool Enabled { get; set; } = true;

    public bool NestedSeriesEnabled { get; set; } = true;

    public ResolverMode NestedSeriesMode { get; set; } = ResolverMode.YearPrefix;

    public string CustomRegex { get; set; } = string.Empty;

    public bool RequireExactlyOneEligibleChild { get; set; } = true;

    public bool MoviesEnabled { get; set; } = true;

    public bool NestedMoviesEnabled { get; set; } = true;

    public bool EnableResolutionLogs { get; set; } = true;

    public bool EnableRejectionLogs { get; set; }
}
