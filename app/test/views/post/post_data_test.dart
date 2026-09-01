import 'package:cataqui_app/views/post/post_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostData', () {
    test('when description creation starts, it should not contain description text', () {
      const data = PostData();

      expect(data.descriptionText, isNull);
    });

    test('when copying with raw description text, it should preserve the text exactly', () {
      const data = PostData();

      expect(data.copyWith(descriptionText: '  descrição original  ').descriptionText, '  descrição original  ');
    });

    test('when post creation starts, it should not contain a payment', () {
      const data = PostData();

      expect(data.payment, isNull);
    });
  });
}
