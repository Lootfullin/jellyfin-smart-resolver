using System.Reflection;
using Xunit;

namespace Jellyfin.Plugin.SmartResolver.Tests;

public sealed class ConfigPageLocalizationTests
{
    [Fact]
    public void EmbeddedSettingsPage_ContainsPlainLanguageRussianLabels()
    {
        var assembly = typeof(Plugin).Assembly;
        var resourceName = Assert.Single(
            assembly.GetManifestResourceNames(),
            name => name.EndsWith(
                ".Configuration.ConfigPage.html",
                StringComparison.Ordinal));
        using var stream = assembly.GetManifestResourceStream(resourceName);
        Assert.NotNull(stream);
        using var reader = new StreamReader(stream);
        var html = reader.ReadToEnd();

        Assert.Contains("Сериалы во вложенных папках", html, StringComparison.Ordinal);
        Assert.Contains("Как определять внешнюю папку", html, StringComparison.Ordinal);
        Assert.Contains("Проверка папки без пересканирования", html, StringComparison.Ordinal);
        Assert.Contains("Последние решения", html, StringComparison.Ordinal);
        Assert.Contains("Медиафайлы никогда не изменяются", html, StringComparison.Ordinal);
    }
}
