import 'package:cataqui_app/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class UseCurrentLocationButton extends ConsumerStatefulWidget {
  const UseCurrentLocationButton({super.key});

  @override
  ConsumerState<UseCurrentLocationButton> createState() => _CurrentLocationButtonState();
}

class _CurrentLocationButtonState extends ConsumerState<UseCurrentLocationButton> {
  ({Color background, Color indicator}) get _widgetColors => switch (Theme.of(context).brightness) {
    Brightness.light => (background: context.mateo.palette.neutral[2], indicator: context.mateo.palette.red),
    Brightness.dark => throw UnsupportedError('CurrentLocationButton does not support dark mode.'),
  };

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);

    return Semantics(
      button: true,
      label: i18n.createJob.location.currentLocationTitle,
      child: MateoTap(
        animation: MateoTapAnimationType.scale,
        onPressed: (_) async {},
        child: Container(
          key: const ValueKey('create_job_current_location'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(color: _widgetColors.background, borderRadius: BorderRadius.circular(99)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                i18n.createJob.location.currentLocationTitle,
                style: TextStyle(
                  color: context.mateo.colorScheme.text.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Container(
                    key: const ValueKey('create_job_current_location_circle'),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: _widgetColors.indicator, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      i18n.createJob.location.locationPermissionGuidance,
                      key: const ValueKey('create_job_location_permission_guidance'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.mateo.colorScheme.text.tertiary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
