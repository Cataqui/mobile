import 'package:cataqui_app/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class ContactChip extends ConsumerWidget {
  const ContactChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = switch (Theme.brightnessOf(context)) {
      Brightness.light => (background: context.mateo.palette.violet[2], foreground: context.mateo.palette.violet[9]),
      Brightness.dark => throw UnsupportedError('ContactChip does not support dark mode.'),
    };

    return MateoTap(
      animation: MateoTapAnimationType.scale,
      onPressed: (animation) => animation,
      child: Container(
        key: const ValueKey('post_contact_chip'),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(9999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MateoIcon.phone(width: 18, height: 18, color: colors.foreground),
            const SizedBox(width: 14),
            Text(
              ref.watch(translationProvider).post.contact.chipTitle,
              style: TextStyle(
                color: colors.foreground,
                fontFamily: MateoTypography.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: MateoTypography.letterSpacing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
