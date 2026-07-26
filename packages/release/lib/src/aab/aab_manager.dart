import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:release/src/aab/aab_build_config.dart';
import 'package:release/src/directories/directories.dart';

part 'aab_manager_types.dart';

final class AabManager {
  AabManager({required this.repositoryRoot, required this.aabConfig});

  final Directory repositoryRoot;
  final AabBuildConfig aabConfig;

  static Future<File> build({required AabBuildConfig aabConfig}) async {
    final appDirectory = Directories.app.absolutePath;
    final appBundle = File(path.join(appDirectory, 'build', 'app', 'outputs', 'bundle', 'release', 'app-release.aab'));
    final workspace = AabManager(repositoryRoot: Directories.root, aabConfig: aabConfig);

    await workspace.runWithSigning(
      action: () async {
        final proccess = await Process.start(
          'fvm',
          ['flutter', 'build', 'appbundle', '--release'],
          workingDirectory: appDirectory,
          mode: ProcessStartMode.inheritStdio,
        );

        final exitCode = await proccess.exitCode;

        if (exitCode != 0) {
          throw StateError('fvm flutter build appbundle --release failed with exit code $exitCode.');
        }

        if (!appBundle.existsSync()) {
          throw StateError('Flutter completed without creating ${appBundle.path}.');
        }
      },
    );

    return appBundle;
  }

  static _FileEntitySnapshot _captureEntity(String entityPath) {
    final type = FileSystemEntity.typeSync(entityPath, followLinks: false);

    return switch (type) {
      FileSystemEntityType.notFound => (type: type, bytes: null, linkTarget: null, permissions: null, modified: null),
      FileSystemEntityType.file => (
        type: type,
        bytes: File(entityPath).readAsBytesSync(),
        linkTarget: null,
        permissions: File(entityPath).statSync().mode & 0x1ff,
        modified: File(entityPath).lastModifiedSync(),
      ),
      FileSystemEntityType.link => (
        type: type,
        bytes: null,
        linkTarget: Link(entityPath).targetSync(),
        permissions: null,
        modified: null,
      ),
      _ => throw StateError('Expected $entityPath to be a file, symbolic link, or absent.'),
    };
  }

  static void _replaceWithFile({required String path, required String contents}) {
    _removeEntity(path);

    final file = File(path)..writeAsStringSync(contents, flush: true);
    _setPermissions(path: file.path, mode: '600');
  }

  static void _restoreEntity({required String path, required _FileEntitySnapshot snapshot}) {
    _removeEntity(path);

    switch (snapshot.type) {
      case FileSystemEntityType.notFound:
        return;
      case FileSystemEntityType.file:
        final file = File(path)..writeAsBytesSync(snapshot.bytes!, flush: true);
        _setPermissions(path: file.path, mode: snapshot.permissions!.toRadixString(8).padLeft(3, '0'));
        file.setLastModifiedSync(snapshot.modified!);
      case FileSystemEntityType.link:
        Link(path).createSync(snapshot.linkTarget!);
      case FileSystemEntityType.directory:
      case FileSystemEntityType.unixDomainSock:
      case FileSystemEntityType.pipe:
        throw StateError('Cannot restore unsupported file-system entity at $path.');
    }
  }

  static void _removeEntity(String entityPath) {
    final type = FileSystemEntity.typeSync(entityPath, followLinks: false);

    switch (type) {
      case FileSystemEntityType.notFound:
        return;
      case FileSystemEntityType.file:
        File(entityPath).deleteSync();
      case FileSystemEntityType.link:
        Link(entityPath).deleteSync();
      case FileSystemEntityType.directory:
      case FileSystemEntityType.unixDomainSock:
      case FileSystemEntityType.pipe:
        throw StateError('Refusing to replace unsupported file-system entity at $entityPath.');
    }
  }

  static void _setPermissions({required String path, required String mode}) {
    if (Platform.isWindows) return;

    final result = Process.runSync('chmod', [mode, path]);
    if (result.exitCode == 0) return;

    throw StateError('Could not restrict permissions for temporary Android signing material.');
  }

  Future<T> runWithSigning<T>({required Future<T> Function() action}) async {
    final aabSigningPropertiesPath = path.join(repositoryRoot.path, 'app', 'android', 'aab-signing.properties');
    final aabSigningPropertiesSnapshot = _captureEntity(aabSigningPropertiesPath);
    final temporaryDirectory = Directory.systemTemp.createTempSync('cataqui-aab-signing-');

    try {
      _setPermissions(path: temporaryDirectory.path, mode: '700');

      final keystore = File(path.join(temporaryDirectory.path, 'aab-signing-key.jks'))
        ..writeAsBytesSync(aabConfig.signingKeystoreBytes, flush: true);
      _setPermissions(path: keystore.path, mode: '600');

      _replaceWithFile(
        path: aabSigningPropertiesPath,
        contents: aabConfig.aabSigningPropertiesContents(keystorePath: keystore.path),
      );

      return await action();
    } finally {
      try {
        _restoreEntity(path: aabSigningPropertiesPath, snapshot: aabSigningPropertiesSnapshot);
      } finally {
        if (temporaryDirectory.existsSync()) {
          temporaryDirectory.deleteSync(recursive: true);
        }
      }
    }
  }
}
