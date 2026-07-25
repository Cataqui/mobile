import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:release/src/app_version.dart';
import 'package:release/src/repository_paths/repository_paths.dart';

part 'release_candidate_manifest.freezed.dart';
part 'release_candidate_manifest.g.dart';

@freezed
abstract class ReleaseCandidateManifest with _$ReleaseCandidateManifest {
  const factory ReleaseCandidateManifest({
    required String version,
    required String versionName,
    required int buildNumber,
    required String environment,
    required String cataquiApiUrl,
    required String commitHash,
    required String codeHash,
    required String androidApkHash,
  }) = _ReleaseCandidateManifest;

  factory ReleaseCandidateManifest.fromJson(Map<String, Object?> json) => _$ReleaseCandidateManifestFromJson(json);

  factory ReleaseCandidateManifest.current() {
    final decoded = jsonDecode(_manifestFile(version: AppVersion.current()).readAsStringSync());

    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Candidate manifest must be a JSON map.');
    }

    return ReleaseCandidateManifest.fromJson(decoded);
  }

  static Future<File> write({required String commitHash, required String apiUrl, required File apk}) async {
    if (!_gitHashPattern.hasMatch(commitHash)) {
      throw ArgumentError.value(commitHash, 'commitHash', 'Commit hash must be a full lowercase Git hash.');
    }

    _validateApiUrl(apiUrl);

    final version = AppVersion.current();
    final manifestFile = _manifestFile(version: version);
    final manifest = ReleaseCandidateManifest(
      version: version.toString(),
      versionName: version.name,
      buildNumber: version.buildNumber,
      environment: 'production',
      cataquiApiUrl: apiUrl,
      commitHash: commitHash,
      codeHash: await Directories.app.codeHash(),
      androidApkHash: await _fileHash(apk),
    );

    await manifestFile.parent.create(recursive: true);
    await manifestFile.writeAsString('${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n');
    return manifestFile;
  }

  static final RegExp _gitHashPattern = RegExp(r'^[0-9a-f]{40}$');

  static void _validateApiUrl(String apiUrl) {
    final uri = Uri.tryParse(apiUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.fragment.isNotEmpty ||
        apiUrl.contains(RegExp(r'\s'))) {
      throw const FormatException('Candidate API URL must be an HTTPS URL without credentials, queries, or fragments.');
    }
  }

  static File _manifestFile({required AppVersion version}) {
    return Directories.distribution.releases[version.name].manifest;
  }

  static Future<String> _fileHash(File file) async {
    if (!file.existsSync()) {
      throw StateError('Missing candidate artifact ${file.path}.');
    }
    return (await sha256.bind(file.openRead()).first).toString();
  }
}
