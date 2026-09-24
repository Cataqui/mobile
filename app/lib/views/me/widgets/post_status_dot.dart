import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class MyPostStatusDot extends ConsumerWidget {
  const MyPostStatusDot({required this.status, super.key});

  final JobStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = MateoTheme.of(context);
    final i18n = ref.watch(translationProvider);
    final presentation = switch (status) {
      .active => (color: theme.colorScheme.text.profit, label: i18n.me.activePostStatus),
      .archived || .unknown => (color: theme.colorScheme.text.tertiary, label: i18n.me.inactivePostStatus),
    };

    return Semantics(
      container: true,
      label: presentation.label,
      child: Motion(
        startup: status == .active ? .play : .skip,
        effect: const PulseFadeMotionEffect(minOpacity: 0.2, duration: Duration(milliseconds: 1800)),
        child: SizedBox(
          key: const ValueKey('my_post_status_dot'),
          width: 10,
          height: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: presentation.color),
          ),
        ),
      ),
    );
  }
}
