part of 'use_current_location_button.dart';

class _LocationPermissionSheet extends ConsumerWidget {
  const _LocationPermissionSheet({required this.onOpenSettings});

  static Future<void> show({required BuildContext context, required Future<void> Function() onOpenSettings}) {
    return MateoBottomSheet.show<void>(
      context,
      child: _LocationPermissionSheet(onOpenSettings: onOpenSettings),
      avoidKeyboardInset: false,
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
              layer1Color: context.mateo.palette.blue[6],
              layer2Color: context.mateo.palette.blue[6],
              layer3Color: context.mateo.palette.blue[6],
              layer4Color: context.mateo.palette.blue[6],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          i18n.useCurrentLocationButton.permissionSheet.title,
          key: const ValueKey('current_location_permission_sheet_title'),
          textAlign: TextAlign.center,
          style: TextStyle(color: context.mateo.colorScheme.text.primary, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        FractionallySizedBox(
          widthFactor: .9,
          child: Text(
            i18n.useCurrentLocationButton.permissionSheet.description,
            key: const ValueKey('current_location_permission_sheet_description'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.mateo.colorScheme.text.tertiary,
              fontSize: 16,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 32),
        MateoButton(
          key: const ValueKey('current_location_permission_sheet_settings_button'),
          variant: MateoButtonVariant.primary,
          fit: MateoButtonFit.expand,
          leadingIconBuilder: (state) => MateoIcon.gear(color: state.foregroundColor, height: 18),
          colorScheme: MateoButtonColorScheme(
            background: context.mateo.palette.blue[9],
            backgroundPressed: context.mateo.palette.blue[9],
            backgroundDisabled: context.mateo.palette.neutral[7],
            foreground: context.mateo.palette.blue[1],
            foregroundDisabled: context.mateo.palette.neutral[9],
          ),
          label: i18n.useCurrentLocationButton.permissionSheet.openSettings,
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
