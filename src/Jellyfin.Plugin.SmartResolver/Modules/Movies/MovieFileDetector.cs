using Emby.Naming.Common;
using Jellyfin.Plugin.SmartResolver.Core;
using MediaBrowser.Model.IO;
using JellyfinVideoResolver = Emby.Naming.Video.VideoResolver;

namespace Jellyfin.Plugin.SmartResolver.Modules.Movies;

public sealed class MovieFileDetector
{
    private readonly NamingOptions _namingOptions;

    public MovieFileDetector(NamingOptions namingOptions)
    {
        _namingOptions = namingOptions;
    }

    public ResolverDecision Detect(
        string folderPath,
        IReadOnlyCollection<FileSystemMetadata> fileSystemChildren)
    {
        var videos = fileSystemChildren
            .Where(entry => !entry.IsDirectory)
            .Select(entry => JellyfinVideoResolver.ResolveFile(
                entry.FullName,
                _namingOptions,
                Path.GetDirectoryName(folderPath)))
            .Where(video => video is not null && video.ExtraType is null)
            .ToArray();

        if (videos.Length == 0)
        {
            return ResolverDecision.Reject(
                folderPath,
                ResolverReasonCode.ChildHasNoMovieEvidence,
                "The folder has no primary video file recognized by Jellyfin.");
        }

        if (videos.Length != 1)
        {
            return ResolverDecision.Reject(
                folderPath,
                ResolverReasonCode.MultipleMovieFiles,
                "The folder contains more than one primary video file.");
        }

        var video = videos[0]!;
        return ResolverDecision.Accept(
            folderPath,
            video.Path,
            video.Name,
            video.Year,
            ResolverEvidence.MovieVideoFile);
    }
}
