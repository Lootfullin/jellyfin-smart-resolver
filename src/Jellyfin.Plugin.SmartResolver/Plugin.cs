using System;
using System.Collections.Generic;
using Jellyfin.Plugin.SmartResolver.Configuration;
using MediaBrowser.Common.Configuration;
using MediaBrowser.Common.Plugins;
using MediaBrowser.Model.Plugins;
using MediaBrowser.Model.Serialization;

namespace Jellyfin.Plugin.SmartResolver;

public sealed class Plugin : BasePlugin<PluginConfiguration>, IHasWebPages
{
    public const string PluginGuid = "c61d7897-a923-4a6d-9d4d-c6c911f28e73";

    public Plugin(IApplicationPaths applicationPaths, IXmlSerializer xmlSerializer)
        : base(applicationPaths, xmlSerializer)
    {
        Instance = this;
    }

    public static Plugin? Instance { get; private set; }

    public override string Name => "Jellyfin Smart Resolver";

    public override Guid Id => Guid.Parse(PluginGuid);

    public override string Description =>
        "Resolves nested series roots and derives movie metadata from video file names.";

    public IEnumerable<PluginPageInfo> GetPages()
    {
        yield return new PluginPageInfo
        {
            Name = "SmartResolver",
            DisplayName = Name,
            EmbeddedResourcePath =
                $"{GetType().Namespace}.Configuration.ConfigPage.html"
        };
    }

    internal static PluginConfiguration GetConfiguration()
    {
        return Instance?.Configuration ?? new PluginConfiguration();
    }
}
