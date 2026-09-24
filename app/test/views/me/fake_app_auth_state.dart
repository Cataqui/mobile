import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';

class FakeAppAuthState extends AppAuthState {
  FakeAppAuthState(this.initialSession);

  final AuthSessionDto? initialSession;

  @override
  AuthSessionDto? build() => initialSession;

  AuthSessionDto? get currentSession => state;

  set currentSession(AuthSessionDto? session) => state = session;
}
