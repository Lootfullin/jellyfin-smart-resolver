using System.Reflection;
using Jellyfin.Plugin.SmartResolver.Configuration;
using MediaBrowser.Common.Configuration;
using MediaBrowser.Model.Serialization;
using Xunit;

namespace Jellyfin.Plugin.SmartResolver.Tests;

public sealed class PluginTests
{
    [Fact]
    public void Constructor_InitializesAssemblyFilePath()
    {
        var plugin = CreatePlugin();

        Assert.False(string.IsNullOrWhiteSpace(plugin.AssemblyFilePath));
        Assert.True(Path.IsPathFullyQualified(plugin.AssemblyFilePath));
        Assert.NotNull(plugin.Version);
    }

    [Fact]
    public void CanUninstall_DoesNotThrowAfterConstruction()
    {
        var plugin = CreatePlugin();

        var exception = Record.Exception(() => _ = plugin.CanUninstall);

        Assert.Null(exception);
    }

    [Fact]
    public void Configuration_HasSafeDefaults()
    {
        var configuration = CreatePlugin().Configuration;

        Assert.True(configuration.Enabled);
        Assert.True(configuration.NestedSeriesEnabled);
        Assert.True(configuration.MoviesEnabled);
        Assert.True(configuration.NestedMoviesEnabled);
        Assert.Equal(ResolverMode.YearPrefix, configuration.NestedSeriesMode);
        Assert.True(configuration.EnableResolutionLogs);
        Assert.False(configuration.EnableRejectionLogs);
    }

    private static Plugin CreatePlugin()
    {
        var paths = DispatchProxy.Create<IApplicationPaths, TestProxy>();
        var serializer = DispatchProxy.Create<IXmlSerializer, TestProxy>();
        return new Plugin(paths, serializer);
    }

    public class TestProxy : DispatchProxy
    {
        protected override object? Invoke(MethodInfo? targetMethod, object?[]? args)
        {
            if (targetMethod?.Name == "DeserializeFromFile")
            {
                return new PluginConfiguration();
            }

            var returnType = targetMethod?.ReturnType;
            if (returnType == typeof(string))
            {
                return Path.GetTempPath();
            }

            if (returnType is not null
                && returnType != typeof(void)
                && returnType.IsValueType)
            {
                return Activator.CreateInstance(returnType);
            }

            return null;
        }
    }
}
