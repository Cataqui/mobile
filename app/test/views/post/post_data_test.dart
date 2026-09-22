import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/views/post/post_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostData', () {
    test('when post creation starts, it should not contain a contact', () {
      const data = PostData();

      expect(data.contact, isNull);
    });

    test('when description creation starts, it should not contain description text', () {
      const data = PostData();

      expect(data.descriptionText, isNull);
    });

    test('when copying with raw description text, it should preserve the text exactly', () {
      const data = PostData();

      expect(data.copyWith(descriptionText: '  descrição original  ').descriptionText, '  descrição original  ');
    });

    test('when post creation starts, it should not contain a payment', () {
      const data = PostData();

      expect(data.payment, isNull);
    });

    test('when every field and a selected address are present, it should be publishable', () {
      const data = PostData(
        addressSelection: (addressId: 'address-id', sessionToken: 'session-token'),
        contact: (contactMethod: JobContactMethod.whatsapp, identifier: '+5511999999999'),
        descriptionText: 'Preciso de ajuda hoje',
        locationTitle: 'Avenida Paulista',
        payment: r'R$ 150',
      );

      expect(data.canPublish, isTrue);
    });

    test('when every field and current coordinates are present, it should be publishable', () {
      const data = PostData(
        contact: (contactMethod: JobContactMethod.whatsapp, identifier: '+5511999999999'),
        descriptionText: 'Preciso de ajuda hoje',
        location: (latitude: -23.561684, longitude: -46.655981),
        locationTitle: 'Pinheiros, São Paulo',
        payment: r'R$ 150',
      );

      expect(data.canPublish, isTrue);
    });

    test('when any required field is missing, it should not be publishable', () {
      const completeData = PostData(
        addressSelection: (addressId: 'address-id', sessionToken: 'session-token'),
        contact: (contactMethod: JobContactMethod.whatsapp, identifier: '+5511999999999'),
        descriptionText: 'Preciso de ajuda hoje',
        locationTitle: 'Avenida Paulista',
        payment: r'R$ 150',
      );

      expect(
        (
          missingDescription: completeData.copyWith(descriptionText: null).canPublish,
          blankDescription: completeData.copyWith(descriptionText: '   ').canPublish,
          missingPayment: completeData.copyWith(payment: null).canPublish,
          blankPayment: completeData.copyWith(payment: '   ').canPublish,
          missingContact: completeData.copyWith(contact: null).canPublish,
          missingLocation: completeData.copyWith(addressSelection: null).canPublish,
        ),
        (
          missingDescription: false,
          blankDescription: false,
          missingPayment: false,
          blankPayment: false,
          missingContact: false,
          missingLocation: false,
        ),
      );
    });
  });
}
