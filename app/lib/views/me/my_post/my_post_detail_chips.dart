import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/me/my_post/my_post_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class MyPostDetailChips extends ConsumerWidget {
  const MyPostDetailChips({this.data, super.key});

  static const iconSize = 20.0;
  static const verticalPadding = 9.0;
  static const height = iconSize + 2 * verticalPadding;
  static const _resizeDuration = Duration(milliseconds: 260);

  final MyPostData? data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unknownLabel = ref.watch(translationProvider).me.myPost.unknown;
    return SingleChildScrollView(
      scrollDirection: .horizontal,
      clipBehavior: .none,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: _buildRow(context, unknownLabel: unknownLabel),
      ),
    );
  }

  Widget _buildRow(BuildContext context, {required String unknownLabel}) {
    final theme = MateoTheme.of(context);
    final contact = data?.detail.contact;
    final contactPresentation = _contactPresentation(context, unknownLabel, contact: contact);
    return Row(
      mainAxisSize: .min,
      children: [
        if (_loading || contact != null) ...[
          _chip(context, chip: #contact, icon: contactPresentation.icon, text: contactPresentation.text),
          const SizedBox(width: 10),
        ],
        _chip(
          context,
          chip: #location,
          icon: MateoIcon(.mapPin, size: iconSize, color: theme.colorScheme.text.secondary),
          text: _loading ? unknownLabel : _locationTitle(unknownLabel),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, {required Symbol chip, required Widget icon, required String text}) {
    final theme = MateoTheme.of(context);
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : _resizeDuration;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: verticalPadding),
      child: Row(
        mainAxisSize: .min,
        children: [
          icon,
          const SizedBox(width: 6),
          Flexible(
            fit: .loose,
            child: Text(
              text,
              maxLines: 1,
              softWrap: false,
              overflow: .clip,
              style: TextStyle(fontSize: 15, fontWeight: .w600, color: theme.colorScheme.text.secondary),
            ),
          ),
        ],
      ),
    );
    return AnimatedContainer(
      key: ValueKey(chip),
      duration: duration,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: _loading ? theme.colorScheme.skeleton.bone : theme.colorScheme.buttons.secondary.neutral.background,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      clipBehavior: .antiAlias,
      child: AnimatedSize(
        duration: duration,
        curve: Curves.easeOutCubic,
        alignment: .centerLeft,
        child: AnimatedOpacity(duration: duration, opacity: _loading ? 0 : 1, child: content),
      ),
    );
  }

  ({Widget icon, String text}) _contactPresentation(
    BuildContext context,
    String unknownLabel, {
    required JobContactDto? contact,
  }) {
    final color = MateoTheme.of(context).colorScheme.text.secondary;
    if (contact == null || contact.identifier.trim().isEmpty) {
      return (icon: MateoIcon(.questionmark, size: iconSize, color: color), text: unknownLabel);
    }

    return (icon: contact.contactMethod.icon(size: iconSize, color: color), text: data?.contactLabel ?? unknownLabel);
  }

  String _locationTitle(String unknownLabel) {
    final title = data?.detail.location.title;
    if (title == null || title.trim().isEmpty) return unknownLabel;
    return title;
  }

  bool get _loading => data == null;
}
