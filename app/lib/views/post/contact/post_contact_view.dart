import 'package:cataqui_app/core/enums/contact_method.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/add_contact/add_contact_route.dart';
import 'package:cataqui_app/views/post/contact/post_contact_option.dart';
import 'package:cataqui_app/views/post/contact/post_contact_state.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class PostContactView extends ConsumerStatefulWidget {
  const PostContactView({super.key});

  static Future<void> push({required BuildContext context}) {
    final i18n = ProviderScope.containerOf(context, listen: false).read(translationProvider);

    return showMateoSheet<void>(
      context: context,
      maxExtent: 380,
      view: MateoSheetView(
        header: const MateoSheetViewHeader(presentation: .handle()),
        footer: MateoSheetViewFooter(
          principal: Builder(
            builder: (context) => MateoButton(
              key: const ValueKey('post_contact_add_button'),
              presentation: .label(
                label: i18n.post.contact.addButtonTitle,
                variant: .secondary.neutral,
                width: .fill,
                trailingIcon: const MateoIcon(.plusSignal, size: 18),
              ),
              onPressed: () async {
                final sheetRoute = ModalRoute.of(context)!;
                final didSaveContact = await const AddContactRoute().push<bool>(context);
                if (didSaveContact != true || !context.mounted || !sheetRoute.isActive) return;

                Navigator.of(context).removeRoute(sheetRoute);
              },
            ),
          ),
        ),
        surface: MateoSheetViewSurface(
          key: const ValueKey('post_contact_sheet_surface'),
          edgeEffect: .fade(),
          child: const PostContactView(),
        ),
      ),
    );
  }

  @override
  ConsumerState<PostContactView> createState() => _PostContactViewState();
}

class _PostContactViewState extends ConsumerState<PostContactView> {
  final ScrollController _contactsScrollController = ScrollController();

  void _selectContact(BuildContext context, PostContactOption option) {
    ref
        .read(postStateProvider.notifier)
        .selectContact(contactMethod: option.contact.method, identifier: option.contact.identifier);

    Navigator.of(context).pop();
  }

  ({Color background, Color foreground}) _contactIconColors(BuildContext context, ContactMethod contactMethod) {
    return switch (MateoTheme.of(context).brightness) {
      .light => switch (contactMethod) {
        .whatsapp => (background: const Color(0xFF25D366), foreground: MateoTheme.of(context).palette.neutral[1]),
        .phoneCall => (
          background: MateoTheme.of(context).palette.violet[9],
          foreground: MateoTheme.of(context).palette.neutral[1],
        ),
        .unknown => throw UnsupportedError('Unknown job contact method.'),
      },
      .dark => throw UnsupportedError('PostContactView does not support dark mode.'),
    };
  }

  @override
  void dispose() {
    _contactsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final contacts = ref.watch(postContactStateProvider);

    return SizedBox.expand(
      key: const ValueKey('post_contact_view'),
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 600),
        reverseDuration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 30),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        layoutBuilder: (currentChild, previousChildren) {
          if (previousChildren.isNotEmpty) return previousChildren.last;
          return currentChild ?? const SizedBox.shrink();
        },
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: contacts.when(
          data: (options) {
            if (options.isEmpty) {
              return Center(
                key: const ValueKey('post_contact_empty'),
                heightFactor: 1,
                child: Text(
                  i18n.post.contact.empty,
                  textAlign: .center,
                  style: TextStyle(
                    color: MateoTheme.of(context).colorScheme.text.tertiary,
                    fontSize: 16,
                    fontWeight: .w500,
                  ),
                ),
              );
            }

            return ListView.separated(
              key: const ValueKey('post_contact_options'),
              controller: _contactsScrollController,
              padding: EdgeInsets.zero,
              clipBehavior: .none,
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final option = options[index];
                return MateoPress(
                  animation: .scaleFade,
                  onPressed: (_) => _selectContact(context, option),
                  child: _buildContactRow(
                    context,
                    key: ValueKey('post_contact_option_${option.contact.contactId}'),
                    contactMethod: option.contact.method,
                    displayIdentifier: option.displayIdentifier,
                  ),
                );
              },
            );
          },
          error: (_, _) => Center(
            key: const ValueKey('post_contact_error'),
            heightFactor: 1,
            child: Text(
              i18n.post.contact.error,
              textAlign: .center,
              style: TextStyle(
                color: MateoTheme.of(context).colorScheme.text.tertiary,
                fontSize: 16,
                fontWeight: .w500,
              ),
            ),
          ),
          loading: () => Skeleton(
            key: const ValueKey('post_contact_skeleton'),
            semanticsLabel: i18n.post.contact.loadingSemanticLabel,
            style: SkeletonStyle(
              color: MateoTheme.of(context).palette.neutral[4],
              effect: const SkeletonFadeEffect(),
              shape: const MateoRoundedShapeBorder.capsule(),
            ),
            child: Column(
              mainAxisSize: .min,
              children: [
                for (var index = 0; index < 2; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _buildContactRow(
                      context,
                      key: ValueKey('post_contact_skeleton_row_$index'),
                      contactMethod: index.isEven ? .whatsapp : .phoneCall,
                      displayIdentifier: index.isEven ? '+55 11 96923-0546' : '+1 202-555-0123',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(
    BuildContext context, {
    required Key key,
    required ContactMethod contactMethod,
    required String displayIdentifier,
  }) {
    final iconColors = _contactIconColors(context, contactMethod);

    return Container(
      key: key,
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          contactMethod.icon(size: 42, color: iconColors.foreground, backgroundColor: iconColors.background),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              displayIdentifier,
              maxLines: 1,
              overflow: .ellipsis,
              style: TextStyle(color: MateoTheme.of(context).colorScheme.text.primary, fontSize: 17, fontWeight: .w600),
            ),
          ),
        ],
      ),
    );
  }
}
