import 'package:flutter/animation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

final jobViewTransformTargetsProvider = Provider.autoDispose
    .family<({MateoTransformTarget surface, MorphTarget header}), String>(
      (ref, jobId) => (
        surface: MateoTransformTarget(curve: Curves.fastOutSlowIn),
        header: MorphTarget(tag: (jobId: jobId, element: #header), curve: Curves.fastOutSlowIn),
      ),
    );
