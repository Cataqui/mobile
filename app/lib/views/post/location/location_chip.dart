import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/post/location/enums/post_location_morph_tag.dart';
import 'package:cataqui_app/views/post/location/post_location_view.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class LocationChip extends ConsumerWidget {
  const LocationChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = switch (Theme.brightnessOf(context)) {
      Brightness.light => (background: context.mateo.palette.red[2], foreground: context.mateo.palette.red),
      Brightness.dark => throw UnsupportedError('LocationChip does not support dark mode.'),
    };
    final locationTitle = ref.watch(postStateProvider.select((postData) => postData.locationTitle));
    final backgroundDecoration = BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(35));

    return MateoTap(
      animation: MateoTapAnimationType.scale,
      onPressed: (_) => PostLocationView.push(context: context),
      child: Morph(
        tag: PostLocationMorphTag.surface,
        curve: Curves.easeOutCubic,
        switchThreshold: 0.2,
        watchDestination: true,
        child: Container(
          key: const ValueKey('post_location_chip'),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 40),
          decoration: backgroundDecoration,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: MorphDescendant(
              flightBehavior: MorphDescendantFlightBehavior.snapshot,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MateoIcon.mapPin(width: 18, height: 18, color: colors.foreground),
                  const SizedBox(width: 12),
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
      ),
    );
  }
}
