import 'dart:convert';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:release/src/app_version.dart';
import 'package:release/src/directories/directories.dart';

part 'release_candidate_manifest.freezed.dart';
part 'release_candidate_manifest.g.dart';

@freezed
abstract class ReleaseCandidateManifest with _$ReleaseCandidateManifest {
  const factory ReleaseCandidateManifest({
    required String version,
    required String versionName,
    required int buildNumber,
    required String environment,
    required String commitHash,
    required String codeHash,
  }) = _ReleaseCandidateManifest;

  factory ReleaseCandidateManifest.fromJson(Map<String, Object?> json) => _$ReleaseCandidateManifestFromJson(json);

  factory ReleaseCandidateManifest.current() {
    final decoded = jsonDecode(_manifestFile(version: AppVersion.current()).readAsStringSync());

    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Candidate manifest must be a JSON map.');
    }

    return ReleaseCandidateManifest.fromJson(decoded);
  }

  static Future<File> write({required String commitHash}) async {
    if (!_gitHashPattern.hasMatch(commitHash)) {
      throw ArgumentError.value(commitHash, 'commitHash', 'Commit hash must be a full lowercase Git hash.');
    }

    final version = AppVersion.current();
    final manifestFile = _manifestFile(version: version);
    final manifest = ReleaseCandidateManifest(
      version: version.toString(),
      versionName: version.name,
      buildNumber: version.buildNumber,
      environment: 'production',
      commitHash: commitHash,
      codeHash: await Directories.app.codeHash(),
    );

    await manifestFile.parent.create(recursive: true);
    await manifestFile.writeAsString('${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n');
    return manifestFile;
  }

  static final RegExp _gitHashPattern = RegExp(r'^[0-9a-f]{40}$');

  static File _manifestFile({required AppVersion version}) {
    return Directories.distribution.releases[version.name].manifest;
  }
}
