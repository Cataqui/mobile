import 'package:cataqui_app/core/repositories/auth_repository/auth_repository.dart';
import 'package:cataqui_app/core/repositories/feed_repository.dart';
import 'package:cataqui_app/core/repositories/job_repository.dart';
import 'package:cataqui_app/core/repositories/maps_repository/maps_repository.dart';
import 'package:cataqui_app/core/repositories/user_repository.dart';
import 'package:cataqui_app/widgets/login_sheet/login_sheet_controller.dart';
import 'package:dio/dio.dart';
import 'package:file/file.dart' show File;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDio extends Mock implements Dio {}

class MockDeviceLocation extends Mock implements DeviceLocation {}

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFeedRepository extends Mock implements FeedRepository {}

class MockMapsRepository extends Mock implements MapsRepository {}

class MockJobRepository extends Mock implements JobRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockLoginSheetController extends Mock implements LoginSheetController {}

class MockWhatsapp extends Mock implements Whatsapp {}

class MockPhoneNumber extends Mock implements PhoneNumber {}

class MockSharedPreferencesAsync extends Mock implements SharedPreferencesAsync {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockStaticMapCacheManager extends Mock implements BaseCacheManager {}

class MockStaticMapFile extends Mock implements File {}

class MockStaticMapFileSystem extends Mock implements FileSystem {}

class MockStaticMapFileService extends Mock implements FileService {}

class MockStaticMapFileServiceResponse extends Mock implements FileServiceResponse {}
