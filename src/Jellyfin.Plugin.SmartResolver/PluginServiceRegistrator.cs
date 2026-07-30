using Jellyfin.Plugin.SmartResolver.Modules.Movies;
using Jellyfin.Plugin.SmartResolver.Modules.NestedSeries;
using MediaBrowser.Controller;
using MediaBrowser.Controller.Plugins;
using MediaBrowser.Controller.Resolvers;
using Microsoft.Extensions.DependencyInjection;

namespace Jellyfin.Plugin.SmartResolver;

public sealed class PluginServiceRegistrator : IPluginServiceRegistrator
{
    public void RegisterServices(
        IServiceCollection serviceCollection,
        IServerApplicationHost applicationHost)
    {
        serviceCollection.AddSingleton<MovieFileDetector>();
        serviceCollection.AddSingleton<OuterFolderMatcher>();
        serviceCollection.AddSingleton<SeriesRootEvidenceDetector>();
        serviceCollection.AddSingleton<NestedSeriesDetector>();
        serviceCollection.AddSingleton<IItemResolver, MovieFileResolver>();
        serviceCollection.AddSingleton<IItemResolver, NestedSeriesResolver>();
    }
}
