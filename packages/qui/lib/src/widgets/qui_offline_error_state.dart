import 'package:flutter/material.dart';
import 'package:qui/src/icons/qui_icons.dart';
import 'package:qui/src/theme/qui_theme_context.dart';
import 'package:qui/src/three_d/qui_3d.dart';
import 'package:qui/src/widgets/qui_button/qui_button.dart';

part 'qui_offline_error_state_types.dart';

/// An offline/connection error state for the QUI design system.
///
/// Displays a 3D wifi-exclamation icon, a title, an optional description,
/// and an optional retry button wired through a [QuiOfflineErrorStateRetry].
///
/// ```dart
/// QuiOfflineErrorState(
///   title: 'Sem conexão',
///   description: 'Verifique sua internet e tente novamente.',
///   retry: (
///     label: 'Tentar novamente',
///     onRetry: () {},
///   ),
/// )
/// ```
class QuiOfflineErrorState extends StatelessWidget {
  /// Creates a QUI offline error state.
  const QuiOfflineErrorState({required this.title, this.description, this.retry, super.key});

  /// Primary message displayed below the icon.
  final String title;

  /// Supporting message shown under [title].
  ///
  /// When null, the description area is omitted entirely.
  final String? description;

  /// Optional record pairing the retry button [String label] with its
  /// [VoidCallback onRetry].
  ///
  /// When null, the retry button is omitted entirely.
  final QuiOfflineErrorStateRetry? retry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.qui.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Qui3d.instance.build(context, (assets) => assets.wifiExclamation, height: 140),
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
            QuiButton(
              variant: QuiButtonVariant.secondary,
              label: retry!.label,
              leadingIconBuilder: (state) => QuiIcons.instance.build(
                (assets) => assets.arrowRotateClockwise,
                height: 15,
                width: 15,
                colorFilter: ColorFilter.mode(state.foregroundColor, BlendMode.srcIn),
              ),
              leadingIconSpacing: 10,
              onPressed: retry!.onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
