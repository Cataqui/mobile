part of 'repository_paths.dart';

final class DistributionDirectory {
  DistributionDirectory._({required Directory repositoryRoot})
    : releases = ReleasesDirectory._(directory: Directory(path.join(repositoryRoot.path, 'distribution', 'releases')));

  final ReleasesDirectory releases;
}
