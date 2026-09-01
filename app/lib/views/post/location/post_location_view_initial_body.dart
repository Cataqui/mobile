part of 'post_location_view.dart';

class _PostLocationViewInitialBody extends ConsumerWidget {
  const _PostLocationViewInitialBody({required this.onLocationSelected});

  final void Function(DeviceLocationAddress address) onLocationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      key: const ValueKey('post_location_view_content'),
      children: [
        UseCurrentLocationButton(
          key: const ValueKey('post_current_location_button'),
          onRequestedToUse: onLocationSelected,
        ),
        Expanded(
          child: Center(
            key: const ValueKey('post_location_empty_guidance'),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  $Lotties.bendingLocationPin(
                    key: const ValueKey('post_location_empty_guidance_icon'),
                    width: 82,
                    height: 82,
                    playback: LottiePlayback.loop,
                    duration: const Duration(milliseconds: 5000),
                    overrides: BendingLocationPinOverrides(
                      rigidPinPivotedAtTipColor: switch (Theme.brightnessOf(context)) {
                        Brightness.light => context.mateo.palette.neutral[4],
                        Brightness.dark => throw UnsupportedError('LocationChip does not support dark mode.'),
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    ref.watch(translationProvider).post.location.emptyGuidance,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: switch (Theme.brightnessOf(context)) {
                        Brightness.light => context.mateo.colorScheme.text.tertiary,
                        Brightness.dark => throw UnsupportedError('LocationChip does not support dark mode.'),
                      },
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
