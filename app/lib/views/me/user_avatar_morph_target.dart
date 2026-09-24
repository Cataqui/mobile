import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

final userAvatarMorphTargetProvider = Provider.autoDispose<MorphTarget>((ref) => MorphTarget(tag: #meAvatar));
