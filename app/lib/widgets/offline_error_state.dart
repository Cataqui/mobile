import 'package:cataqui_app/gen/illustrations.g.dart';
import 'package:flutter/material.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class OfflineErrorState extends StatelessWidget {
  const OfflineErrorState({required this.title, this.description, this.retry, super.key});

  static Future<void> precacheImages(BuildContext context) {
    return $IllustrationsCache.precacheWifiExclamation(context, height: _illustrationHeight);
  }

  static const _illustrationHeight = 140.0;

  final String title;
  final String? description;
  final ({String label, VoidCallback onRetry})? retry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = MateoTheme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          $Illustrations.wifiExclamation(height: _illustrationHeight),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(fontSize: 18, color: colorScheme.text.primary, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            FractionallySizedBox(
              widthFactor: 0.7,
              child: Text(
                description!,
                style: TextStyle(fontSize: 16, color: colorScheme.text.secondary, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (retry != null) ...[
            const SizedBox(height: 20),
            MateoButton(
              presentation: MateoButtonPresentation.label(
                variant: MateoButtonVariant.secondary,
                width: .fit,
                label: retry!.label,
                leadingIcon: const MateoIcon(.arrowRotateClockwise),
              ),
              onPressed: retry!.onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
