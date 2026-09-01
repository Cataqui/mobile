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
  static const _descriptionTextStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.w500);
  static const _motionDuration = Duration(milliseconds: 200);
  static const Curve _motionCurve = Curves.easeOutCubic;

  final _descriptionFocusNode = FocusNode();

  late final TextEditingController _descriptionController;

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
    final textAreaColorScheme = context.mateo.colorScheme.textArea;

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 20, end: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 20),
            child: KeyedSubtree(
              key: const ValueKey('post_description_layout'),
              child: ClipRect(
                child: _PostDescriptionHeight(
                  duration: _motionDuration,
                  curve: _motionCurve,
                  vsync: this,
                  animationsDisabled: MediaQuery.disableAnimationsOf(context),
                  child: Semantics(
                    textField: true,
                    label: i18n.post.description.inputSemanticLabel,
                    child: DefaultSelectionStyle(
                      cursorColor: textAreaColorScheme.caret,
                      selectionColor: textAreaColorScheme.selectionHighlight,
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
                        cursorColor: textAreaColorScheme.caret,
                        cursorWidth: 2,
                        style: _descriptionTextStyle.copyWith(color: textAreaColorScheme.text),
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
                          hintStyle: _descriptionTextStyle.copyWith(color: context.mateo.colorScheme.text.tertiary),
                        ),
                        onTapOutside: (_) {},
                        onChanged: ref.read(postStateProvider.notifier).setDescription,
                      ),
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
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 16, bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [LocationChip(), SizedBox(height: 8), PaymentChip(), SizedBox(height: 8), ContactChip()],
            ),
          ),
        ],
      ),
    );
  }
}
