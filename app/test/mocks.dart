import 'package:cataqui_app/core/repositories/feed_repository.dart';
import 'package:cataqui_app/core/repositories/job_repository.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class MockDio extends Mock implements Dio {}

class MockFeedRepository extends Mock implements FeedRepository {}

class MockJobRepository extends Mock implements JobRepository {}

class MockWhatsapp extends Mock implements Whatsapp {}

class MockTelephony extends Mock implements Telephony {}
