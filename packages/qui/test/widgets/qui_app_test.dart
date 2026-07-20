import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

class _TestRouterDelegate extends RouterDelegate<Object> with ChangeNotifier {
  _TestRouterDelegate({this.onBuild});

  final void Function(BuildContext)? onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild?.call(context);
    return const SizedBox.shrink();
  }

  @override
  Future<void> setNewRoutePath(Object configuration) async {}

  @override
  Future<bool> popRoute() async => false;

  @override
  Object? get currentConfiguration => null;
}

class _TestRouteInformationParser extends RouteInformationParser<Object> {
  static final RouteInformation _rootRouteInformation = RouteInformation(
    uri: Uri.parse('/'),
  );

  @override
  Future<Object> parseRouteInformation(
    RouteInformation routeInformation,
  ) async => Object();

  @override
  RouteInformation restoreRouteInformation(Object configuration) =>
      _rootRouteInformation;
}

RouterConfig<Object> _createConfig({void Function(BuildContext)? onBuild}) {
  return RouterConfig<Object>(
    routeInformationParser: _TestRouteInformationParser(),
    routerDelegate: _TestRouterDelegate(onBuild: onBuild),
    routeInformationProvider: PlatformRouteInformationProvider(
      initialRouteInformation:
          _TestRouteInformationParser._rootRouteInformation,
    ),
  );
}

void main() {
  group('QuiApp.router', () {
    testWidgets(
      'when configured with a color, it should render the child widget',
      (tester) async {
        await tester.pumpWidget(
          QuiApp.router(
            title: 'Test App',
            color: (
              primary: const Color(0xFFFF4A4B),
              onPrimary: const Color(0xFFFFFFFF),
            ),
            routerConfig: _createConfig(),
          ),
        );

        expect(find.byType(MaterialApp), findsOneWidget);
      },
    );

    testWidgets(
      'when configured with a color, it should apply the QUI palette from the given primary',
      (tester) async {
        await tester.pumpWidget(
          QuiApp.router(
            title: 'Test App',
            color: (
              primary: const Color(0xFF123456),
              onPrimary: const Color(0xFFFFFFFF),
            ),
            routerConfig: _createConfig(),
            builder: (context, child) => child ?? const SizedBox.shrink(),
          ),
        );

        final messenger = tester.widget<QuiToastMessenger>(
          find.byType(QuiToastMessenger),
        );
        final messengerContext = tester.element(find.byType(QuiToastMessenger));
        final quiTheme = Theme.of(messengerContext).extension<QuiThemeData>()!;
        final expectedPalette = QuiPalette(
          primaryColor: const Color(0xFF123456),
        );

        expect(quiTheme.palette.primary[9], equals(expectedPalette.primary[9]));
      },
    );

    testWidgets(
      'when configured with a builder, it should auto-inject the QuiToastMessenger',
      (tester) async {
        await tester.pumpWidget(
          QuiApp.router(
            title: 'Test App',
            color: (
              primary: const Color(0xFFFF4A4B),
              onPrimary: const Color(0xFFFFFFFF),
            ),
            routerConfig: _createConfig(),
            builder: (context, child) => child ?? const SizedBox.shrink(),
          ),
        );

        expect(find.byType(QuiToastMessenger), findsOneWidget);
      },
    );

    testWidgets(
      'when inside the router, it should find the QuiToastMessenger via context lookup',
      (tester) async {
        late BuildContext routerContext;

        await tester.pumpWidget(
          QuiApp.router(
            title: 'Test App',
            color: (
              primary: const Color(0xFFFF4A4B),
              onPrimary: const Color(0xFFFFFFFF),
            ),
            routerConfig: _createConfig(
              onBuild: (context) {
                routerContext = context;
              },
            ),
          ),
        );

        final messenger = QuiToastMessenger.maybeOf(routerContext);

        expect(messenger, isNotNull);
      },
    );

    testWidgets(
      'when showing a toast from inside the router, it should find the messenger and show the message',
      (tester) async {
        late BuildContext routerContext;

        await tester.pumpWidget(
          QuiApp.router(
            title: 'Test App',
            color: (
              primary: const Color(0xFFFF4A4B),
              onPrimary: const Color(0xFFFFFFFF),
            ),
            routerConfig: _createConfig(
              onBuild: (context) {
                routerContext = context;
              },
            ),
          ),
        );

        QuiToast.show(routerContext, message: 'Hello from QuiApp');
        await tester.pump();

        expect(find.text('Hello from QuiApp'), findsOneWidget);
      },
    );
  });
}
