import 'package:cataqui_app/core/repositories/feed_repository.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockFeedRepository extends Mock implements FeedRepository {}
