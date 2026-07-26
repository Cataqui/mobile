import 'package:release/src/directories/directories.dart';
import 'package:yaml_edit/yaml_edit.dart';

final class AppVersion {
  AppVersion({required this.name, required this.buildNumber}) {
    if (buildNumber < 0) throw ArgumentError.value(buildNumber, 'buildNumber', 'Build number cannot be negative.');
  }

  factory AppVersion.current() {
    final pubspecFile = Directories.app.pubspecFile;
    final yamlEditor = YamlEditor(pubspecFile.readAsStringSync());
    final version = yamlEditor.parseAt(['version'], orElse: () => wrapAsYamlNode(null)).value;

    if (version == null) throw StateError('Missing version in ${pubspecFile.path}');
    if (version is! String) throw StateError('Invalid version in ${pubspecFile.path}');

    final match = _versionPattern.firstMatch(version);
    if (match == null) throw StateError('Invalid version in ${pubspecFile.path}');

    return AppVersion(name: match.group(1)!, buildNumber: int.parse(match.group(2) ?? '0'));
  }

  static final RegExp _versionPattern = RegExp(r'^(\d+\.\d+\.\d+)(?:\+(\d+))?$');

  final String name;
  final int buildNumber;

  AppVersion setBuildNumber({required int buildNumber}) {
    final upcomingVersion = AppVersion(name: name, buildNumber: buildNumber);
    final pubspecFile = Directories.app.pubspecFile;
    final yamlEditor = YamlEditor(pubspecFile.readAsStringSync());
    final currentVersionString = yamlEditor.parseAt(['version'], orElse: () => wrapAsYamlNode(null)).value;

    if (currentVersionString == null) throw StateError('Could not update version in ${pubspecFile.path}');

    yamlEditor.update(['version'], upcomingVersion.toString());
    pubspecFile.writeAsStringSync(yamlEditor.toString());

    return upcomingVersion;
  }

  @override
  String toString() => '$name+$buildNumber';
}
