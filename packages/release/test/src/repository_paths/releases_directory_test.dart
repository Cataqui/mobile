import 'package:path/path.dart' as path;
import 'package:release/src/repository_paths/repository_paths.dart';
import 'package:test/test.dart';

void main() {
  test('when selecting a release version, it should return its distribution directory', () {
    expect(
      Directories.distribution.releases['1.3.1'].directory.path,
      path.join(Directories.root.path, 'distribution', 'releases', 'v1.3.1'),
    );
  });

  test('when a release version contains a path separator, it should reject the version', () {
    expect(() => Directories.distribution.releases['../1.3.1'], throwsArgumentError);
  });
}
