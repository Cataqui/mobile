import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/post/payment/post_payment_view.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class PaymentChip extends ConsumerWidget {
  const PaymentChip({required this.surfaceTransformTarget, super.key});

  final MateoTransformTarget surfaceTransformTarget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = switch (MateoTheme.of(context).brightness) {
      Brightness.light => (
        background: MateoTheme.of(context).palette.green[3],
        foreground: MateoTheme.of(context).palette.green[10],
      ),
      Brightness.dark => throw UnsupportedError('PaymentChip does not support dark mode.'),
    };

    final paymentText = ref.watch(postStateProvider.select((postData) => postData.payment));

    return MateoPress(
      animation: MateoPressAnimationType.scale,
      onPressed: (_) => PostPaymentView.push(context: context, surfaceTransformTarget: surfaceTransformTarget),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 40),
        child: MateoSurface(
          key: const ValueKey('post_payment_chip'),
          color: colors.background,
          shape: const .rounded(radius: 32),
          animation: .transform(target: surfaceTransformTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MateoIcon(.gift, size: 18, color: colors.foreground),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    paymentText ?? ref.watch(translationProvider).post.payment.chipTitle,
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
