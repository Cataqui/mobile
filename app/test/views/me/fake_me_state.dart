import 'dart:async';

import 'package:cataqui_app/core/dtos/user_profile_dto.dart';
import 'package:cataqui_app/views/me/me_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FakeMeState extends MeState {
  FakeMeState(this.initialValue);

  final AsyncValue<UserProfileDto?> initialValue;

  @override
  Future<UserProfileDto?> build() {
    state = initialValue;
    return Completer<UserProfileDto?>().future;
  }
}
