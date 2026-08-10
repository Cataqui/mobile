import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state.g.dart';

@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  AuthSessionDto? build() => null;

  // setSession is an authentication command rather than a property-style setter.
  // ignore: use_setters_to_change_properties
  void setSession(AuthSessionDto session) {
    state = session;
  }
}
