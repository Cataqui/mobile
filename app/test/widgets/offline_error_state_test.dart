import 'package:cataqui_app/widgets/offline_error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_app.dart';

const _title = 'Sem conexão';
const _description = 'Verifique sua internet e tente novamente.';
const _label = 'Tentar novamente';

void _noop() {}
const _retryRecord = (label: _label, onRetry: _noop);

void main() {
  group('OfflineErrorState', () {
    Widget _buildApp(Widget child) {
      return TestApp(child: child);
    }

    testWidgets('when rendered with a title, it should display the title', (tester) async {
      await tester.pumpWidget(_buildApp(const OfflineErrorState(title: _title)));

      expect(find.text(_title), findsOneWidget);
    });

    testWidgets('when a description is provided, it should display the description', (tester) async {
      await tester.pumpWidget(_buildApp(const OfflineErrorState(title: _title, description: _description)));

      expect(find.text(_description), findsOneWidget);
    });

    testWidgets('when a description is not provided, it should not render the description', (tester) async {
      await tester.pumpWidget(_buildApp(const OfflineErrorState(title: _title)));

      expect(find.text(_description), findsNothing);
    });

    testWidgets('when retry is provided, it should display the retry button label', (tester) async {
      await tester.pumpWidget(_buildApp(const OfflineErrorState(title: _title, retry: _retryRecord)));

      expect(find.text(_label), findsOneWidget);
    });

    testWidgets('when retry is not provided, it should not render the retry button', (tester) async {
      await tester.pumpWidget(_buildApp(const OfflineErrorState(title: _title)));

      expect(find.text(_label), findsNothing);
    });

    testWidgets('when the retry button is tapped, it should invoke the onRetry callback', (tester) async {
      var invoked = false;
      await tester.pumpWidget(
        _buildApp(OfflineErrorState(title: _title, retry: (label: _label, onRetry: () => invoked = true))),
      );

      await tester.tap(find.text(_label));
      await tester.pump(const Duration(milliseconds: 800));
      expect(invoked, isTrue);
    });
  });
}
