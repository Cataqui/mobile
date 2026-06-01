import 'package:cataqui/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CataquiApp renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CataquiApp()),
    );

    expect(find.text('Cataqui'), findsWidgets);
    expect(find.text('Bem-vindo ao Cataqui'), findsOneWidget);
  });
}
