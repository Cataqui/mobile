import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

part 'app_directory.dart';
part 'distribution_directory.dart';
part 'release_version_directory.dart';
part 'releases_directory.dart';

final class Directories {
  Directories._();

  static Directory get root => Zone.current[_rootZoneKey] as Directory? ?? _defaultRoot;
  static AppDirectory get app => AppDirectory._(repositoryRoot: root);
  static DistributionDirectory get distribution => DistributionDirectory._(repositoryRoot: root);

  static T runWithRootForTesting<T>({required Directory root, required T Function() body}) {
    return runZoned(body, zoneValues: {_rootZoneKey: root});
  }

  static final Object _rootZoneKey = Object();
  static final Directory _defaultRoot = _findRepositoryRoot();

  static Directory _findRepositoryRoot() {
    var directory = Directory(path.absolute(Directory.current.path));

    while (true) {
      final workspacePubspec = File(path.join(directory.path, 'pubspec.yaml'));
      final appPubspec = File(path.join(directory.path, 'app', 'pubspec.yaml'));
      if (workspacePubspec.existsSync() && appPubspec.existsSync()) return directory;

      final parent = directory.parent;

      if (parent.path == directory.path) throw StateError('Could not find the Cataquí repository root.');

      directory = parent;
    }
  }
}
