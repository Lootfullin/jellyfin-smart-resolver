using Emby.Naming.Common;
using Jellyfin.Plugin.SmartResolver.Core;
using Jellyfin.Plugin.SmartResolver.Modules.Movies;
using MediaBrowser.Model.IO;
using Xunit;

namespace Jellyfin.Plugin.SmartResolver.Tests;

public sealed class MovieFileDetectorTests
{
    [Fact]
    public void Detect_UsesVideoFileNameInsteadOfFolderName()
    {
        var folderPath = Path.Combine("Movies", "(1979) Completely Wrong Folder");
        var videoPath = Path.Combine(
            folderPath,
            "Moonraker (1979) [WEB-DL].mkv");

        var decision = CreateDetector().Detect(
            folderPath,
            [FileMetadata(videoPath)]);

        Assert.True(decision.Accepted);
        Assert.Equal(videoPath, decision.ResolvedPath);
        Assert.Equal("Moonraker", decision.DetectedName);
        Assert.Equal(1979, decision.DetectedYear);
        Assert.Equal([ResolverEvidence.MovieVideoFile], decision.Evidence);
    }

    [Theory]
    [InlineData("Movie (2025).mkv")]
    [InlineData("Movie (2025).mp4")]
    [InlineData("Movie (2025).avi")]
    public void Detect_AcceptsVideoFileRecognizedByJellyfin(string fileName)
    {
        var folderPath = Path.Combine("Movies", "Navigation Folder");
        var videoPath = Path.Combine(folderPath, fileName);

        var decision = CreateDetector().Detect(
            folderPath,
            [FileMetadata(videoPath)]);

        Assert.True(decision.Accepted);
        Assert.Equal("Movie", decision.DetectedName);
        Assert.Equal(2025, decision.DetectedYear);
    }

    [Theory]
    [InlineData("2012 (2009) [WEB-DL].mkv", "2012", 2009)]
    [InlineData("1917 (2019) [UHD].mkv", "1917", 2019)]
    [InlineData("1984 (1984).mkv", "1984", 1984)]
    public void Detect_PreservesNumericMovieTitle(
        string fileName,
        string expectedTitle,
        int expectedYear)
    {
        var folderPath = Path.Combine("Movies", "Navigation Folder");
        var videoPath = Path.Combine(folderPath, fileName);

        var decision = CreateDetector().Detect(
            folderPath,
            [FileMetadata(videoPath)]);

        Assert.True(decision.Accepted);
        Assert.Equal(expectedTitle, decision.DetectedName);
        Assert.Equal(expectedYear, decision.DetectedYear);
    }

    [Fact]
    public void Detect_DoesNotUseFolderYearAsFallback()
    {
        var folderPath = Path.Combine("Movies", "(1999) Navigation Folder");
        var videoPath = Path.Combine(folderPath, "Movie [WEB-DL].mkv");

        var decision = CreateDetector().Detect(
            folderPath,
            [FileMetadata(videoPath)]);

        Assert.True(decision.Accepted);
        Assert.Equal("Movie", decision.DetectedName);
        Assert.Null(decision.DetectedYear);
    }

    [Fact]
    public void Detect_IgnoresArtworkAndMetadataFiles()
    {
        var folderPath = Path.Combine("Movies", "Moonraker");
        var videoPath = Path.Combine(folderPath, "Moonraker (1979).mkv");

        var decision = CreateDetector().Detect(
            folderPath,
            [
                FileMetadata(videoPath),
                FileMetadata(Path.Combine(folderPath, "poster.jpg")),
                FileMetadata(Path.Combine(folderPath, "movie.nfo"))
            ]);

        Assert.True(decision.Accepted);
        Assert.Equal(videoPath, decision.ResolvedPath);
    }

    [Fact]
    public void Detect_IgnoresTrailerAlongsidePrimaryMovie()
    {
        var folderPath = Path.Combine("Movies", "Moonraker");
        var videoPath = Path.Combine(folderPath, "Moonraker (1979).mkv");

        var decision = CreateDetector().Detect(
            folderPath,
            [
                FileMetadata(videoPath),
                FileMetadata(Path.Combine(folderPath, "Moonraker (1979)-trailer.mkv"))
            ]);

        Assert.True(decision.Accepted);
        Assert.Equal(videoPath, decision.ResolvedPath);
    }

    [Fact]
    public void Detect_RejectsFolderWithoutPrimaryVideo()
    {
        var folderPath = Path.Combine("Movies", "Moonraker");

        var decision = CreateDetector().Detect(
            folderPath,
            [
                FileMetadata(Path.Combine(folderPath, "poster.jpg")),
                FileMetadata(Path.Combine(folderPath, "movie.nfo"))
            ]);

        Assert.False(decision.Accepted);
        Assert.Equal(ResolverReasonCode.ChildHasNoMovieEvidence, decision.ReasonCode);
    }

    [Fact]
    public void Detect_RejectsMultiplePrimaryVideoFiles()
    {
        var folderPath = Path.Combine("Movies", "Moonraker");

        var decision = CreateDetector().Detect(
            folderPath,
            [
                FileMetadata(Path.Combine(folderPath, "Moonraker (1979).mkv")),
                FileMetadata(Path.Combine(folderPath, "Moonraker Alternate (1979).mkv"))
            ]);

        Assert.False(decision.Accepted);
        Assert.Equal(ResolverReasonCode.MultipleMovieFiles, decision.ReasonCode);
    }

    private static MovieFileDetector CreateDetector()
    {
        return new MovieFileDetector(new NamingOptions());
    }

    private static FileSystemMetadata FileMetadata(string path)
    {
        return new FileSystemMetadata
        {
            Exists = true,
            FullName = path,
            IsDirectory = false,
            Name = Path.GetFileName(path)
        };
    }
}
