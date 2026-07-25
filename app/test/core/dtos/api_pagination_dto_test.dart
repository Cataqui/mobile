import 'package:cataqui_app/core/dtos/api_pagination_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiPaginationDto', () {
    test('when parsing pagination, it should map has more', () {
      final pagination = ApiPaginationDto.fromJson(const <String, Object?>{
        'has_more': true,
        'next_cursor': 'next-feed-cursor',
      });

      expect(pagination.hasMore, isTrue);
    });

    test('when parsing pagination without cursor, it should keep cursor null', () {
      final pagination = ApiPaginationDto.fromJson(const <String, Object?>{'has_more': false});

      expect(pagination.nextCursor, isNull);
    });
  });
}
