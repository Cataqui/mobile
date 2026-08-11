import 'package:cataqui_app/core/repositories/auth_repository/auth_repository.dart';
import 'package:cataqui_app/core/repositories/feed_repository.dart';
import 'package:cataqui_app/core/repositories/job_repository.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDio extends Mock implements Dio {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFeedRepository extends Mock implements FeedRepository {}

class MockJobRepository extends Mock implements JobRepository {}

class MockWhatsapp extends Mock implements Whatsapp {}

class MockTelephony extends Mock implements Telephony {}

class MockSharedPreferencesAsync extends Mock implements SharedPreferencesAsync {}
