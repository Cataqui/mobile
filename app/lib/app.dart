import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:cataqui_app/widgets/feed_job_card.dart';
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
    final i18n = ref.watch(translationProvider);

    return MaterialApp.router(
      title: i18n.app.name,
      routerConfig: router,
      theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
      locale: i18n.$meta.locale.flutterLocale,
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 250),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 280,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Stack(
                    children: [
                      QuiLocationRadiusMap(
                        tileUrlTemplate:
                            'https://staging.maptiles.cataqui.com/regions/br/2026-06-09/{z}/{x}/{y}.mvt?v=1&sig=ff83557175c2b29719df6e0f2ea5bd01413179e4550191768fecc070b96b9ad3&exp=1781565202',
                        location: (
                          // latitude: -23.556391,
                          // longitude: -46.844076,
                          latitude: -23.551043,
                          longitude: -46.633413,
                          // latitude: -22.885941,
                          // longitude: -48.444118,
                        ),
                        fontConfig: (
                          fontStack: 'inter',
                          glyphUrlTemplate:
                              'https://staging.maptiles.cataqui.com/glyphs/{fontstack}/{range}.pbf?v=1&sig=ff83557175c2b29719df6e0f2ea5bd01413179e4550191768fecc070b96b9ad3&exp=1781565202',
                        ),
                        radiusInMeters: 2000,
                        tileMinZoom: 1,
                        tileMaxZoom: 14,
                        zoom: 14,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: FeedJobCard(feedJob: FeedJobDto.fixture(), onTap: () async {}),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
