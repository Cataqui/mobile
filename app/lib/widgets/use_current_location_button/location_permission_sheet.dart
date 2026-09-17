part of 'use_current_location_button.dart';

class _LocationPermissionSheet extends ConsumerWidget {
  const _LocationPermissionSheet({required this.onOpenSettings});

  static Future<void> show({required BuildContext context, required Future<void> Function() onOpenSettings}) {
    return showMateoSheet<void>(
      context: context,
      view: MateoSheetView(
        reserveHeaderSpace: false,
        header: const MateoSheetViewHeader(presentation: .closeButton()),
        surface: MateoSheetViewSurface(
          key: const ValueKey('location_permission_sheet_surface'),
          child: _LocationPermissionSheet(onOpenSettings: onOpenSettings),
        ),
      ),
    );
  }

  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(translationProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: $Lotties.pulse(
            height: 160,
            playback: LottiePlayback.loop,
            duration: const Duration(milliseconds: 2500),
            overrides: PulseOverrides(
              layer1Color: MateoTheme.of(context).palette.blue[6],
              layer2Color: MateoTheme.of(context).palette.blue[6],
              layer3Color: MateoTheme.of(context).palette.blue[6],
              layer4Color: MateoTheme.of(context).palette.blue[6],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          i18n.useCurrentLocationButton.permissionSheet.title,
          key: const ValueKey('current_location_permission_sheet_title'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: MateoTheme.of(context).colorScheme.text.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        FractionallySizedBox(
          widthFactor: .9,
          child: Text(
            i18n.useCurrentLocationButton.permissionSheet.description,
            key: const ValueKey('current_location_permission_sheet_description'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MateoTheme.of(context).colorScheme.text.tertiary,
              fontSize: 16,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 32),
        MateoButton(
          presentation: .label(
            variant: .primary,
            width: .fill,
            leadingIcon: const MateoIcon(.gear),
            colorScheme: MateoButtonColorScheme(
              background: MateoTheme.of(context).palette.blue[9],

              backgroundDisabled: MateoTheme.of(context).palette.neutral[7],
              foreground: MateoTheme.of(context).palette.blue[1],
              foregroundDisabled: MateoTheme.of(context).palette.neutral[9],
            ),
            label: i18n.useCurrentLocationButton.permissionSheet.openSettings,
          ),
          key: const ValueKey('current_location_permission_sheet_settings_button'),
          onPressed: () => _openSettingsAfterClosing(context),
        ),
      ],
    );
  }

  Future<void> _openSettingsAfterClosing(BuildContext context) async {
    final route = ModalRoute.of(context);
    Navigator.of(context).pop();
    await route?.completed;
    await onOpenSettings();
  }
}
