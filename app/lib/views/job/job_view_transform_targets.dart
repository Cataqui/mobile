import 'package:flutter/animation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import 'enums/job_view_transform_tag.dart';

final jobViewTransformTargetsProvider = Provider.autoDispose
    .family<({MateoTransformTarget surface, MorphTarget header}), String>(
      (ref, jobId) => (
        surface: MateoTransformTarget(duration: null, curve: Curves.fastOutSlowIn),
        header: MorphTarget(
          tag: JobViewTransformTag.header.valueFor(jobId: jobId),
          curve: Curves.fastOutSlowIn,
        ),
      ),
    );
