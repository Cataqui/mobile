import 'package:cataqui_app/views/me/my_post/my_post_morph_curve.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_post_morph_target.g.dart';

@riverpod
MorphTarget myPostMorphTarget(Ref ref, String jobId) => MorphTarget(
  tag: (jobId: jobId, element: #myPostHeader),
  curve: const MyPostMorphCurve(),
  reverseCurve: const MyPostMorphCurve(),
);
