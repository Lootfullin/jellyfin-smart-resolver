using Emby.Naming.Common;
using Jellyfin.Data.Enums;
using Jellyfin.Plugin.SmartResolver.Modules.Movies;
using MediaBrowser.Controller.Entities;
using MediaBrowser.Controller.Entities.Movies;
using MediaBrowser.Controller.Library;
using MediaBrowser.Controller.Resolvers;
using MediaBrowser.Model.Entities;
using MediaBrowser.Model.IO;
using Microsoft.Extensions.Logging;
using Xunit;

namespace Jellyfin.Plugin.SmartResolver.Tests;

public sealed class MovieFileResolverTests
{
    [Fact]
    public void Priority_IsFirst()
    {
        Assert.Equal(ResolverPriority.First, CreateResolver().Priority);
    }

    [Fact]
    public void ResolvePath_UsesMovieNameAndYearFromVideoFile()
    {
        var folderPath = Path.Combine("Movies", "(1979) Wrong Navigation Name");
        var videoPath = Path.Combine(
            folderPath,
            "Moonraker (1979) [WEB-DL].mkv");

        var result = CreateResolver().ResolvePath(CreateArgs(folderPath, [videoPath]));

        var movie = Assert.IsType<Movie>(result);
        Assert.Equal(videoPath, movie.Path);
        Assert.Equal("Moonraker", movie.Name);
        Assert.Equal(1979, movie.ProductionYear);
        Assert.False(movie.IsInMixedFolder);
        Assert.Equal(VideoType.VideoFile, movie.VideoType);
    }

    [Fact]
    public void ResolvePath_DoesNotRequireYearPrefixFolder()
    {
        var folderPath = Path.Combine("Movies", "Navigation Folder");
        var videoPath = Path.Combine(folderPath, "Moonraker (1979).mkv");

        var result = CreateResolver().ResolvePath(CreateArgs(folderPath, [videoPath]));

        var movie = Assert.IsType<Movie>(result);
        Assert.Equal("Moonraker", movie.Name);
        Assert.Equal(1979, movie.ProductionYear);
    }

    [Fact]
    public void ResolvePath_PreservesProviderIdsFromVideoPath()
    {
        var folderPath = Path.Combine("Movies", "(1979) Moonraker");
        var videoPath = Path.Combine(
            folderPath,
            "Moonraker (1979) [tmdbid-698] [imdbid-tt0079574].mkv");

        var result = CreateResolver().ResolvePath(CreateArgs(folderPath, [videoPath]));

        var movie = Assert.IsType<Movie>(result);
        Assert.Equal("698", movie.GetProviderId(MetadataProvider.Tmdb));
        Assert.Equal("tt0079574", movie.GetProviderId(MetadataProvider.Imdb));
    }

    [Theory]
    [InlineData(CollectionType.tvshows)]
    [InlineData(CollectionType.music)]
    [InlineData(CollectionType.books)]
    public void ResolvePath_RejectsNonMovieLibrary(CollectionType collectionType)
    {
        var folderPath = Path.Combine("Movies", "(1979) Moonraker");
        var videoPath = Path.Combine(folderPath, "Moonraker (1979).mkv");

        var result = CreateResolver().ResolvePath(
            CreateArgs(folderPath, [videoPath], collectionType: collectionType));

        Assert.Null(result);
    }

    [Fact]
    public void ResolvePath_RejectsMissingParent()
    {
        var folderPath = Path.Combine("Movies", "(1979) Moonraker");
        var videoPath = Path.Combine(folderPath, "Moonraker (1979).mkv");

        var result = CreateResolver().ResolvePath(
            CreateArgs(folderPath, [videoPath], includeParent: false));

        Assert.Null(result);
    }

    [Fact]
    public void ResolvePath_RejectsMultiplePrimaryVideos()
    {
        var folderPath = Path.Combine("Movies", "(1979) Moonraker");

        var result = CreateResolver().ResolvePath(
            CreateArgs(
                folderPath,
                [
                    Path.Combine(folderPath, "Moonraker (1979).mkv"),
                    Path.Combine(folderPath, "Moonraker Alternate (1979).mkv")
                ]));

        Assert.Null(result);
    }

    [Fact]
    public void ResolvePath_LogsSuccessfulResolution()
    {
        var logger = new RecordingLogger<MovieFileResolver>();
        var folderPath = Path.Combine("Movies", "(1979) Moonraker");
        var videoPath = Path.Combine(folderPath, "Moonraker (1979).mkv");

        var result = CreateResolver(logger).ResolvePath(CreateArgs(folderPath, [videoPath]));

        Assert.NotNull(result);
        var entry = Assert.Single(logger.Entries);
        Assert.Equal(LogLevel.Information, entry.Level);
        Assert.Contains(
            "Jellyfin Smart Resolver mapped movie folder",
            entry.Message,
            StringComparison.Ordinal);
        Assert.Contains(videoPath, entry.Message, StringComparison.Ordinal);
    }

    private static MovieFileResolver CreateResolver(
        ILogger<MovieFileResolver>? logger = null)
    {
        return new MovieFileResolver(
            new MovieFileDetector(new NamingOptions()),
            logger ?? new RecordingLogger<MovieFileResolver>());
    }

    private static ItemResolveArgs CreateArgs(
        string folderPath,
        IReadOnlyCollection<string> videoPaths,
        CollectionType collectionType = CollectionType.movies,
        bool includeParent = true)
    {
        return new ItemResolveArgs(null!, null!)
        {
            CollectionType = collectionType,
            FileInfo = new FileSystemMetadata
            {
                Exists = true,
                FullName = folderPath,
                IsDirectory = true,
                Name = Path.GetFileName(folderPath)
            },
            FileSystemChildren = videoPaths
                .Select(videoPath => new FileSystemMetadata
                {
                    Exists = true,
                    FullName = videoPath,
                    IsDirectory = false,
                    Name = Path.GetFileName(videoPath)
                })
                .ToArray(),
            Parent = includeParent ? new Folder() : null
        };
    }

    private sealed class RecordingLogger<T> : ILogger<T>
    {
        public List<LogEntry> Entries { get; } = [];

        public IDisposable? BeginScope<TState>(TState state)
            where TState : notnull
        {
            return null;
        }

        public bool IsEnabled(LogLevel logLevel)
        {
            return true;
        }

        public void Log<TState>(
            LogLevel logLevel,
            EventId eventId,
            TState state,
            Exception? exception,
            Func<TState, Exception?, string> formatter)
        {
            Entries.Add(new LogEntry(logLevel, formatter(state, exception)));
        }
    }

    private sealed record LogEntry(LogLevel Level, string Message);
}
