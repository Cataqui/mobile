import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/post/contact/post_contact_view.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class ContactChip extends ConsumerWidget {
  const ContactChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = switch (MateoTheme.of(context).brightness) {
      Brightness.light => (
        background: MateoTheme.of(context).palette.violet[2],
        foreground: MateoTheme.of(context).palette.violet[9],
      ),
      Brightness.dark => throw UnsupportedError('ContactChip does not support dark mode.'),
    };
    final contact = ref.watch(postStateProvider.select((postData) => postData.contact));
    final isPublishing = ref.watch(postStateProvider.select((postData) => postData.isPublishing));

    return Opacity(
      opacity: isPublishing ? 0.5 : 1,
      child: MateoPress(
        animation: MateoPressAnimationType.scale,
        onPressed: isPublishing ? null : (_) => PostContactView.push(context: context),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 40),
          child: MateoSurface(
            key: const ValueKey('post_contact_chip'),
            color: colors.background,
            shape: const .capsule(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  contact?.contactMethod.icon(size: 20, color: colors.foreground) ??
                      MateoIcon(.phone, size: 20, color: colors.foreground),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      contact?.contactMethod.displayIdentifier(contact.identifier) ??
                          ref.watch(translationProvider).post.contact.chipTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.foreground,
                        fontFamily: MateoTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: MateoTypography.letterSpacing,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
