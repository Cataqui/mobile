import 'package:path/path.dart' as path;
import 'package:release/src/repository_paths/repository_paths.dart';
import 'package:test/test.dart';

void main() {
  test('when accessing releases, it should return the releases directory', () {
    expect(
      Directories.distribution.releases.directory.path,
      path.join(Directories.root.path, 'distribution', 'releases'),
    );
  });
}
