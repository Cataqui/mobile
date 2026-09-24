import 'dart:math' as math;

import 'package:cataqui_app/gen/icons.g.dart';
import 'package:cataqui_app/views/post/post_published_pointer/post_published_pointer_motion_effect.dart';
import 'package:flutter/widgets.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class PostPublishedPointer extends StatelessWidget {
  const PostPublishedPointer({super.key});

  @override
  Widget build(BuildContext context) {
    return Motion(
      key: const ValueKey('post_published_pointer'),
      effect: const PostPublishedPointerMotionEffect(),
      child: Transform.rotate(angle: math.pi, child: $Icons.pointerHandUp(width: 26, height: 26)),
    );
  }
}
