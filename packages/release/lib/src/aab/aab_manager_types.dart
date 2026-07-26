part of 'aab_manager.dart';

typedef _FileEntitySnapshot = ({
  FileSystemEntityType type,
  Uint8List? bytes,
  String? linkTarget,
  int? permissions,
  DateTime? modified,
});
