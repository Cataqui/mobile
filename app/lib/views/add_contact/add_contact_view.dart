import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/logos.g.dart';
import 'package:cataqui_app/views/post/post_route.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class AddContactView extends ConsumerStatefulWidget {
  const AddContactView({super.key});

  @override
  ConsumerState<AddContactView> createState() => _AddContactViewState();
}

class _AddContactViewState extends ConsumerState<AddContactView> {
  PhoneNumber? _phoneNumber;

  void _saveContact() {
    final phoneNumber = _phoneNumber;
    if (phoneNumber == null) return;

    ref.read(postStateProvider.notifier).selectContact(contactMethod: .whatsapp, identifier: phoneNumber.e164);

    final navigator = Navigator.of(context);
    if (!navigator.canPop()) {
      const PostRoute().go(context);
      return;
    }

    navigator
      ..removeRouteBelow(ModalRoute.of(context)!)
      ..pop();
  }

  void _updatePhoneNumber(String value) {
    final parsedPhoneNumber = PhoneNumber.tryParse(value);
    final phoneNumber = (parsedPhoneNumber?.isValid ?? false) ? parsedPhoneNumber : null;
    if ((_phoneNumber != null) == (phoneNumber != null)) {
      _phoneNumber = phoneNumber;
      return;
    }
    setState(() => _phoneNumber = phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);

    return MateoView(
      header: MateoViewHeader(
        leading: MateoButton(
          key: const ValueKey('add_contact_close_button'),
          presentation: .icon(
            variant: .primary.base,
            elevation: 1,
            semanticLabel: i18n.addContact.closeButtonSemanticLabel,
            icon: const MateoIcon(.cross),
          ),
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
              return;
            }
            const PostRoute().go(context);
          },
        ),
      ),
      footer: MateoViewFooter(
        principal: MateoButton(
          key: const ValueKey('add_contact_save_button'),
          presentation: .label(label: i18n.addContact.saveButtonTitle, variant: .primary.success, width: .fill),
          onPressed: _phoneNumber == null ? null : _saveContact,
        ),
      ),
      surface: .new(
        shape: const .none(),
        padding: const .symmetric(horizontal: 32, vertical: 40),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text.rich(
                key: const ValueKey('add_contact_title'),
                TextSpan(
                  children: [
                    TextSpan(text: i18n.addContact.title),
                    const TextSpan(text: '\u00A0'),
                    WidgetSpan(
                      alignment: .middle,
                      child: Padding(
                        padding: const .only(left: 6),
                        child: ExcludeSemantics(
                          child: $Logos.whatsapp(
                            key: const ValueKey('add_contact_whatsapp_logo'),
                            width: 29,
                            height: 29,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontFamily: MateoTypography.fontFamily,
                  letterSpacing: MateoTypography.letterSpacing,
                  fontSize: 26,
                  fontWeight: .w600,
                  color: MateoTheme.of(context).colorScheme.text.primary,
                ),
              ),
              const SizedBox(height: 12),
              MateoTextInput(
                key: const ValueKey('add_contact_phone_input'),
                placeholder: i18n.addContact.phonePlaceholder,
                presentation: const .phone(size: .large),
                onChanged: _updatePhoneNumber,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
