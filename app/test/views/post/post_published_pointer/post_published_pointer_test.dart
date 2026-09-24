import 'package:cataqui_app/views/post/post_published_pointer/post_published_pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the pointer points down twice, pauses, and repeats', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Center(child: PostPublishedPointer())));
    final image = find.descendant(of: find.byType(PostPublishedPointer), matching: find.byType(Image));
    final restingTop = tester.getTopLeft(image).dy;

    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getTopLeft(image).dy, restingTop);

    await tester.pump(const Duration(milliseconds: 70));
    expect(tester.getTopLeft(image).dy, restingTop);
    await tester.pump(const Duration(milliseconds: 225));
    expect(tester.getTopLeft(image).dy, greaterThan(restingTop));

    await tester.pump(const Duration(milliseconds: 225));
    expect(tester.getTopLeft(image).dy, closeTo(restingTop, 0.01));

    await tester.pump(const Duration(milliseconds: 225));
    expect(tester.getTopLeft(image).dy, greaterThan(restingTop));

    await tester.pump(const Duration(milliseconds: 225));
    expect(tester.getTopLeft(image).dy, closeTo(restingTop, 0.01));

    await tester.pump(const Duration(milliseconds: 1125));
    expect(tester.getTopLeft(image).dy, greaterThan(restingTop));
  });

  testWidgets('the pointer stays still when animations are disabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(child: PostPublishedPointer()),
        ),
      ),
    );
    final image = find.descendant(of: find.byType(PostPublishedPointer), matching: find.byType(Image));
    final restingTop = tester.getTopLeft(image).dy;

    await tester.pump(const Duration(milliseconds: 450));
    expect(tester.getTopLeft(image).dy, restingTop);
  });
}
