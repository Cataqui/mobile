import 'dart:async';

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/post/enums/post_morph_tag.dart';
import 'package:cataqui_app/views/post/payment/enums/post_payment_morph_tag.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class PostPaymentView extends ConsumerStatefulWidget {
  const PostPaymentView({super.key});

  static Future<void> push({required BuildContext context}) {
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);

    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierLabel: ProviderScope.containerOf(
          context,
          listen: false,
        ).read(translationProvider).post.payment.closeButtonSemanticLabel,
        barrierColor: context.mateo.colorScheme.background.withValues(alpha: 0),
        transitionDuration: animationsDisabled ? Duration.zero : const Duration(milliseconds: 270),
        reverseTransitionDuration: animationsDisabled ? Duration.zero : const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) => const PostPaymentView(),
      ),
    );
  }

  @override
  ConsumerState<PostPaymentView> createState() => _PostPaymentViewState();
}

class _PostPaymentViewState extends ConsumerState<PostPaymentView> {
  late final MateoTextController _paymentTextController;
  late final MateoToggleController _negotiableToggleController;

  void _close() => Navigator.of(context).pop();

  void _setNegotiable(bool isNegotiable) {
    if (!isNegotiable) {
      _paymentTextController.clear();
      return;
    }

    final inputText = ref.read(translationProvider).post.payment.negotiable.inputText;

    _paymentTextController.value = TextEditingValue(
      text: inputText,
      selection: TextSelection.collapsed(offset: inputText.length),
    );
  }

  void _handlePaymentTextChanged(String payment) {
    final inputText = ref.read(translationProvider).post.payment.negotiable.inputText;
    final isNegotiable = payment.trim().toLowerCase() == inputText.toLowerCase();
    if (_negotiableToggleController.value == isNegotiable) return;

    unawaited(_negotiableToggleController.setValue(isNegotiable));
  }

  void _confirmPayment() {
    ref.read(postStateProvider.notifier).setPayment(_paymentTextController.text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _close();
    });
  }

  @override
  void initState() {
    super.initState();
    final payment = ref.read(postStateProvider).payment;
    _paymentTextController = MateoTextController(text: payment);
    _negotiableToggleController = MateoToggleController(
      value: payment == ref.read(translationProvider).post.payment.negotiable.inputText,
    );
  }

  @override
  void dispose() {
    _paymentTextController.dispose();
    _negotiableToggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final colors = switch (Theme.brightnessOf(context)) {
      Brightness.light => (
        surface: context.mateo.palette.green[9],
        surfaceText: context.mateo.palette.neutral[12].withValues(alpha: 0.5),
        inputText: context.mateo.palette.neutral[1],
        actionBackground: context.mateo.palette.neutral[1],
        actionForeground: context.mateo.palette.neutral[12],
      ),

      Brightness.dark => throw UnsupportedError('PostPaymentView does not support dark mode.'),
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: MateoView(
          key: const ValueKey('post_payment_view'),
          padding: const EdgeInsets.all(15),
          edgeFade: null,
          backgroundBuilder: (_, body) => Morph(
            tag: PostPaymentMorphTag.surface,
            duration: Duration.zero,
            curve: Curves.easeOutCubic,
            watchDestination: true,
            switchThreshold: 0.2,
            child: Container(
              key: const ValueKey('post_payment_view_surface'),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(36)),
              child: body,
            ),
          ),
          header: MateoViewHeader(
            title: const SizedBox.shrink(),
            leading: Morph(
              tag: PostMorphTag.closeButton,
              curve: Curves.decelerate,
              watchDestination: true,
              switchThreshold: 1,
              child: MateoFloatingActionButton(
                key: const ValueKey('post_payment_close_button'),
                onPressed: _close,
                semanticLabel: i18n.post.payment.closeButtonSemanticLabel,
                backgroundColor: colors.actionBackground,
                foregroundColor: colors.actionForeground,
                borderSide: BorderSide.none,
                iconSize: 16,
                size: 50,
                iconBuilder: (state) =>
                    MateoIcon.cross(width: state.iconSize, height: state.iconSize, color: state.foregroundColor),
              ),
            ),
            trailing: MorphSibling(
              tag: PostPaymentMorphTag.surface,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: const Interval(0.3, 1)),
                child: child,
              ),
              child: MateoTap(
                onPressed: (_) {
                  final animation = _negotiableToggleController.toggle();
                  _setNegotiable(_negotiableToggleController.value);
                  return animation;
                },
                animation: MateoTapAnimationType.none,
                child: Container(
                  key: const ValueKey('post_payment_negotiable_control'),
                  padding: const EdgeInsets.only(left: 20, right: 12),
                  decoration: BoxDecoration(color: colors.actionBackground, borderRadius: BorderRadius.circular(42)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      Text(
                        i18n.post.payment.negotiable.toggleTitle,
                        style: TextStyle(
                          color: colors.actionForeground,
                          fontFamily: MateoTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: MateoTypography.letterSpacing,
                        ),
                      ),
                      const SizedBox(width: 12),
                      MateoToggle(
                        key: const ValueKey('post_payment_negotiable_toggle'),
                        controller: _negotiableToggleController,
                        semanticsLabel: i18n.post.payment.negotiable.toggleSemanticLabel,
                        onChanged: (value, _) => _setNegotiable(value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          footer: MorphSibling(
            tag: PostPaymentMorphTag.surface,
            paintAboveMorph: true,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: const Interval(0.3, 1)),
              child: child,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // const SizedBox(width: 40),
                Padding(
                  padding: const EdgeInsets.only(left: 1, bottom: 2),
                  child: MateoCharacterCounter(
                    key: const ValueKey('post_payment_character_counter'),
                    textController: _paymentTextController,
                    limit: 50,
                    variant: MateoCharacterCounterVariant.floating,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    fontSize: 15,
                  ),
                ),
                MateoFloatingActionButton(
                  key: const ValueKey('post_payment_confirm_button'),
                  onPressed: _confirmPayment,
                  semanticLabel: i18n.post.payment.confirmButtonSemanticLabel,
                  backgroundColor: colors.actionBackground,
                  foregroundColor: colors.actionForeground,
                  borderSide: BorderSide.none,
                  size: 50,
                  iconSize: 18,
                  iconBuilder: (state) =>
                      MateoIcon.checkmark(width: state.iconSize, height: state.iconSize, color: state.foregroundColor),
                ),
              ],
            ),
          ),
          body: MorphDescendant(
            flightBehavior: MorphDescendantFlightBehavior.snapshot,
            child: TextField(
              key: const ValueKey('post_payment_input'),
              controller: _paymentTextController,
              focusNode: _paymentTextController.focusNode,
              autofocus: true,
              expands: true,
              minLines: null,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              textAlignVertical: TextAlignVertical.center,
              textAlign: TextAlign.center,
              cursorColor: colors.surfaceText,
              style: TextStyle(
                color: colors.inputText,
                fontFamily: MateoTypography.fontFamily,
                fontSize: 32,
                fontWeight: FontWeight.w600,
                letterSpacing: MateoTypography.letterSpacing,
                height: 1.2,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintText: i18n.post.payment.inputPlaceholder,
                hintStyle: TextStyle(
                  color: colors.surfaceText,
                  fontFamily: MateoTypography.fontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: MateoTypography.letterSpacing,
                  height: 1.2,
                ),
              ),
              onTapOutside: (_) {},
              onChanged: _handlePaymentTextChanged,
            ),
          ),
        ),
      ),
    );
  }
}
