import 'dart:async';

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/post/payment/enums/post_payment_morph_tag.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

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
        barrierColor: Colors.transparent,
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
  late final TextEditingController _paymentTextController;
  final FocusNode _paymentFocusNode = FocusNode();
  late final MateoToggleController _negotiableToggleController;
  void _close() {
    Navigator.of(context).pop();
  }

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
    if (mounted) _close();
  }

  @override
  void initState() {
    super.initState();
    final payment = ref.read(postStateProvider).payment;
    _paymentTextController = TextEditingController(text: payment);
    _negotiableToggleController = MateoToggleController(
      value: payment == ref.read(translationProvider).post.payment.negotiable.inputText,
    );
  }

  @override
  void dispose() {
    _paymentTextController.dispose();
    _paymentFocusNode.dispose();
    _negotiableToggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final colors = switch (MateoTheme.of(context).brightness) {
      Brightness.light => (
        surface: MateoTheme.of(context).palette.green[9],
        surfaceText: MateoTheme.of(context).palette.neutral[12].withValues(alpha: 0.5),
        inputText: Colors.white,
        actionBackground: MateoTheme.of(context).palette.neutral[1],
        actionForeground: MateoTheme.of(context).palette.neutral[12],
      ),

      Brightness.dark => throw UnsupportedError('PostPaymentView does not support dark mode.'),
    };

    return MateoView(
      animation: .transform(target: PostPaymentMorphTag.surfaceTarget, shape: const .rounded(radius: 42)),
      key: const ValueKey('post_payment_view'),
      header: MateoViewHeader(
        principal: Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            MateoButton(
              key: const ValueKey('post_payment_close_button'),
              onPressed: _close,
              presentation: .icon(
                variant: .primary.base,
                elevation: 1,
                semanticLabel: i18n.post.payment.closeButtonSemanticLabel,
                icon: const MateoIcon(.cross),
                colorScheme: MateoButtonColorScheme(
                  background: colors.actionBackground,
                  foreground: colors.actionForeground,
                  backgroundDisabled: MateoTheme.of(context).palette.neutral[4],
                  foregroundDisabled: MateoTheme.of(context).palette.neutral[9],
                ),
              ),
            ),
            MateoPress(
              onPressed: (_) {
                final animation = _negotiableToggleController.toggle();
                _setNegotiable(_negotiableToggleController.value);
                return animation;
              },
              animation: MateoPressAnimationType.none,
              child: Container(
                key: const ValueKey('post_payment_negotiable_control'),
                padding: const EdgeInsets.only(left: 20, right: 8),
                decoration: BoxDecoration(color: colors.actionBackground, borderRadius: BorderRadius.circular(42)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Text(
                      i18n.post.payment.negotiable.toggleTitle,
                      style: TextStyle(
                        color: colors.actionForeground,
                        fontFamily: MateoTypography.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: MateoTypography.letterSpacing,
                      ),
                    ),
                    const SizedBox(width: 12),
                    MateoToggle(
                      key: const ValueKey('post_payment_negotiable_toggle'),
                      controller: _negotiableToggleController,
                      semanticsLabel: i18n.post.payment.negotiable.toggleSemanticLabel,
                      onChanged: _setNegotiable,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      footer: MateoViewFooter(
        trailing: MateoButton(
          key: const ValueKey('post_payment_confirm_button'),
          onPressed: _confirmPayment,
          presentation: .icon(
            variant: .primary.base,
            elevation: 1,
            semanticLabel: i18n.post.payment.confirmButtonSemanticLabel,
            size: .standard,
            icon: const MateoIcon(.checkmark),
            colorScheme: MateoButtonColorScheme(
              background: colors.actionBackground,
              foreground: colors.actionForeground,
              backgroundDisabled: MateoTheme.of(context).palette.neutral[4],
              foregroundDisabled: MateoTheme.of(context).palette.neutral[9],
            ),
          ),
        ),
      ),
      surface: MateoViewSurface(
        key: const ValueKey('post_payment_view_surface'),
        color: colors.surface,
        shape: const .none(),
        child: Material(
          type: MaterialType.transparency,
          child: TextField(
            key: const ValueKey('post_payment_input'),
            controller: _paymentTextController,
            focusNode: _paymentFocusNode,

            autofocus: true,
            maxLength: 30,
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
              counterText: '',
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
    );
  }
}
