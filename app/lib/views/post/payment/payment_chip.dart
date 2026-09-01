import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/post/payment/enums/post_payment_morph_tag.dart';
import 'package:cataqui_app/views/post/payment/post_payment_view.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class PaymentChip extends ConsumerWidget {
  const PaymentChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = switch (Theme.brightnessOf(context)) {
      Brightness.light => (background: context.mateo.palette.green[3], foreground: context.mateo.palette.green[10]),
      Brightness.dark => throw UnsupportedError('PaymentChip does not support dark mode.'),
    };

    final paymentText = ref.watch(postStateProvider.select((postData) => postData.payment));

    return MateoTap(
      animation: MateoTapAnimationType.scale,
      onPressed: (_) => PostPaymentView.push(context: context),
      child: Morph(
        tag: PostPaymentMorphTag.surface,
        duration: const Duration(milliseconds: 270),
        curve: Curves.easeOutCubic,
        watchDestination: true,
        switchThreshold: 0.2,
        child: Container(
          key: const ValueKey('post_payment_chip'),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 40),
          decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(32)),
          child: MorphDescendant(
            flightBehavior: MorphDescendantFlightBehavior.snapshot,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MateoIcon.gift(width: 18, height: 18, color: colors.foreground),
                  const SizedBox(width: 14),
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
      ),
    );
  }
}
