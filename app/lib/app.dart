import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qui/qui.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [GoRoute(path: '/', builder: (context, state) => const _HomeScreen())],
  );
});

class CataquiApp extends ConsumerWidget {
  const CataquiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'Cataquí',
      routerConfig: router,
      theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}

class _HomeScreen extends StatefulWidget {
  const _HomeScreen();

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  final _controller = QuiSwipeListController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cataqui'), backgroundColor: Theme.of(context).colorScheme.primary),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: QuiLocationRadiusMap(
            tileUrlTemplate:
                'https://staging.maptiles.cataqui.com/br/2026-06-09/{z}/{x}/{y}.mvt?v=1&sig=8825c0d3b4584856a0f9de9f7825637ada282e964d00651eaa3825830c6f216d&exp=1781137280',
            location: QuiMapLocation(latitude: -23.55052, longitude: -46.633308),
            radiusInMeters: 500,
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(heroTag: 'dismiss', onPressed: _controller.dismiss, child: const Icon(Icons.close)),
          const SizedBox(height: 12),
          FloatingActionButton(heroTag: 'accept', onPressed: _controller.accept, child: const Icon(Icons.check)),
        ],
      ),
    );
  }
}
