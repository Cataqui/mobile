import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/post/location/post_location_view.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class LocationChip extends ConsumerWidget {
  const LocationChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = switch (MateoTheme.of(context).brightness) {
      Brightness.light => (
        background: MateoTheme.of(context).palette.red[2],
        foreground: MateoTheme.of(context).palette.red,
      ),
      Brightness.dark => throw UnsupportedError('LocationChip does not support dark mode.'),
    };

    final locationTitle = ref.watch(postStateProvider.select((postData) => postData.locationTitle));

    return MateoPress(
      animation: .scale,
      onPressed: (_) => PostLocationView.push(context: context),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 40),
        child: MateoSurface(
          key: const ValueKey('post_location_chip'),
          color: colors.background,
          shape: const .capsule(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MateoIcon(.mapPin, size: 20, color: colors.foreground),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    locationTitle ?? ref.watch(translationProvider).post.location.chipTitle,
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
    );
  }
}
