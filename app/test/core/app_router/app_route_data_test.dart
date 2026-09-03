import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/post/post_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('when a route does not override authentication, it should remain public', () {
    expect(const FeedRoute().requiresAuthentication, isFalse);
  });

  test('when entering the post flow, it should require authentication', () {
    expect(const PostRoute().requiresAuthentication, isTrue);
  });
}
