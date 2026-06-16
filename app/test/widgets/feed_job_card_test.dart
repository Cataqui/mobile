import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_location_dto.dart';
import 'package:cataqui_app/core/dtos/job_enums.dart';
import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:cataqui_app/widgets/feed_job_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_app.dart';

FeedJobDto _fixture({JobPaymentDto? payment, String? title, String? descriptionSummary}) {
  return FeedJobDto(
    jobId: 'job_123',
    title: title ?? 'Garçom para Fim de Semana',
    createdAt: DateTime(2025, 6, 15),
    payment: payment ??
        const JobPaymentDto(
          type: JobPaymentType.fixed,
          minAmount: 120,
          amountPeriod: JobPaymentAmountPeriod.daily,
          currency: 'BRL',
        ),
    location: const FeedJobLocationDto(
      neighborhood: 'Pinheiros',
      latitude: -23.556391,
      longitude: -46.844076,
      areaRadius: 2000,
    ),
    descriptionSummary: descriptionSummary ?? 'Experiente em atendimento ao cliente.',
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    child: TestApp(child: child),
  );
}

void main() {
  group('FeedJobCard', () {
    group('rendering', () {
      testWidgets('when created with a job, it should display the title', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture(), onTap: () async {})));

        expect(find.text('Garçom para Fim de Semana'), findsOneWidget);
      });

      testWidgets('when created with a job, it should display the payment', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture(), onTap: () async {})));

        expect(find.textContaining(r'R$'), findsOneWidget);
        expect(find.textContaining('120'), findsOneWidget);
        expect(find.textContaining('/dia'), findsOneWidget);
      });

      testWidgets('when created with a job, it should display the description', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture(), onTap: () async {})));

        expect(find.text('Experiente em atendimento ao cliente.'), findsOneWidget);
      });

      testWidgets('when created, the card should have 24px border radius', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture(), onTap: () async {})));

        final container = tester.widget<Container>(find.byType(Container).first);
        final decoration = container.decoration! as BoxDecoration;

        expect(decoration.borderRadius, equals(BorderRadius.circular(24)));
      });

      testWidgets('when created, the title should use semi-bold weight', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture(), onTap: () async {})));

        final text = tester.widget<Text>(find.text('Garçom para Fim de Semana'));

        expect(text.style!.fontWeight, equals(FontWeight.w600));
      });

      testWidgets('when created, the title should use 22px font size', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture(), onTap: () async {})));

        final text = tester.widget<Text>(find.text('Garçom para Fim de Semana'));

        expect(text.style!.fontSize, equals(22));
      });

      testWidgets('when created, the payment should use 25px font size', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture(), onTap: () async {})));

        final paymentText = find.textContaining(r'R$');
        final text = tester.widget<Text>(paymentText);

        expect(text.style!.fontSize, equals(25));
      });

      testWidgets('when created, the payment should use money color', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture(), onTap: () async {})));

        final paymentText = find.textContaining(r'R$');
        final text = tester.widget<Text>(paymentText);

        expect(text.style!.color, equals(const Color(0xFF00DD55)));
      });

      testWidgets('when created, the description should use 15.7px font size', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture(), onTap: () async {})));

        final text = tester.widget<Text>(find.text('Experiente em atendimento ao cliente.'));

        expect(text.style!.fontSize, equals(15.7));
      });

      testWidgets('when created, the description should use secondary text color', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture(), onTap: () async {})));

        final text = tester.widget<Text>(find.text('Experiente em atendimento ao cliente.'));

        expect(text.style!.color, equals(const Color(0xFFB3B3B3)));
      });
    });

    group('interaction', () {
      testWidgets('when the card is tapped, it should call onTap', (tester) async {
        var tapCount = 0;
        Future<void> onTap() async {
          tapCount += 1;
        }

        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture(), onTap: onTap)));

        await tester.tap(find.text('Garçom para Fim de Semana'));
        await tester.pump(const Duration(milliseconds: 800));

        expect(tapCount, equals(1));
      });
    });
  });
}
