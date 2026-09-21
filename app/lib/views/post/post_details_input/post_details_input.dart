import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/post/contact/contact_chip.dart';
import 'package:cataqui_app/views/post/location/location_chip.dart';
import 'package:cataqui_app/views/post/payment/payment_chip.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

part 'post_description_height.dart';
part 'render_post_description_height.dart';

class PostDetailsInput extends ConsumerStatefulWidget {
  const PostDetailsInput({super.key});

  @override
  ConsumerState<PostDetailsInput> createState() => _PostDetailsInputState();
}

class _PostDetailsInputState extends ConsumerState<PostDetailsInput> with SingleTickerProviderStateMixin {
  static const _descriptionTextStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    fontFamily: MateoTypography.fontFamily,
    letterSpacing: MateoTypography.letterSpacing,
  );
  static const _motionDuration = Duration(milliseconds: 200);
  static const Curve _motionCurve = Curves.easeOutCubic;

  final _descriptionFocusNode = FocusNode();
  final _paymentSurfaceTransformTarget = MateoTransformTarget();

  late final TextEditingController _descriptionController;

  Color get _descriptionSelectionColor => switch (MateoTheme.of(context).brightness) {
    .light => MateoTheme.of(context).palette.accent[4],
    .dark => throw UnsupportedError('Dark post description inputs are not supported.'),
  };

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: ref.read(postStateProvider).descriptionText);
  }

  @override
  void dispose() {
    _descriptionFocusNode.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyedSubtree(
          key: const ValueKey('post_description_layout'),
          child: _PostDescriptionHeight(
            duration: _motionDuration,
            curve: _motionCurve,
            vsync: this,
            animationsDisabled: MediaQuery.disableAnimationsOf(context),
            child: Semantics(
              textField: true,
              label: i18n.post.description.inputSemanticLabel,
              child: DefaultSelectionStyle(
                cursorColor: MateoTheme.of(context).colorScheme.accent,
                selectionColor: _descriptionSelectionColor,
                child: Material(
                  type: .transparency,
                  child: TextField(
                    key: const ValueKey('post_description_input'),
                    controller: _descriptionController,
                    focusNode: _descriptionFocusNode,
                    autofocus: true,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    maxLines: null,
                    scrollPhysics: const NeverScrollableScrollPhysics(),
                    scrollPadding: EdgeInsets.zero,
                    cursorColor: MateoTheme.of(context).colorScheme.accent,
                    cursorWidth: 2,
                    style: _descriptionTextStyle.copyWith(color: MateoTheme.of(context).colorScheme.text.primary),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      hintText: i18n.post.description.placeholder,
                      hintStyle: _descriptionTextStyle.copyWith(
                        color: MateoTheme.of(context).colorScheme.text.tertiary,
                      ),
                    ),
                    onTapOutside: (_) {},
                    onChanged: ref.read(postStateProvider.notifier).setDescription,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            key: const ValueKey('post_description_focus_area'),
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: _descriptionFocusNode.requestFocus,
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 20),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LocationChip(),
            const SizedBox(height: 8),
            PaymentChip(surfaceTransformTarget: _paymentSurfaceTransformTarget),
            const SizedBox(height: 8),
            const ContactChip(),
          ],
        ),
      ],
    );
  }
}
