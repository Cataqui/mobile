import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/static_map/enums/static_map_size.dart';
import 'package:cataqui_app/core/static_map/static_map_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'enums/job_location_image_feedback_state.dart';

part 'job_location_image_feedback.dart';
part 'job_location_image_loading_bounce_curve.dart';

class JobLocationImage extends ConsumerStatefulWidget {
  const JobLocationImage({required this.imageUrl, this.size = .square, this.enabled = true, super.key});

  static const attributionBottomSpacing = 48.0;

  final String imageUrl;
  final StaticMapSize size;
  final bool enabled;

  @override
  ConsumerState<JobLocationImage> createState() => _JobLocationImageState();
}

class _JobLocationImageState extends ConsumerState<JobLocationImage> {
  GlobalKey<_JobLocationImageFeedbackState> _feedbackKey = GlobalKey<_JobLocationImageFeedbackState>();
  int _retry = 0;
  bool _retrying = false;
  String? _requestKey;

  ({Color background, Color loadingIndicator}) get _colors => switch (Theme.of(context).brightness) {
    .light => (
      background: MateoTheme.of(context).palette.neutral[2],
      loadingIndicator: MateoTheme.of(context).palette.neutral[6],
    ),
    .dark => throw UnsupportedError('JobLocationImage does not support dark mode.'),
  };

  Future<void> _retryImage({required StaticMapRequest? request}) async {
    if (_retrying || request == null || !widget.enabled) return;
    final cacheManager = ref.read(staticMapCacheManagerProvider);
    _retrying = true;
    try {
      await CachedNetworkImage.evictFromCache(request.url, cacheKey: request.cacheKey, cacheManager: cacheManager);
    } on Object {
      // Keep the retry available if the cached file cannot be removed.
      return;
    } finally {
      _retrying = false;
    }
    if (!mounted || !widget.enabled || _requestKey != request.cacheKey) return;
    setState(() => _retry++);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider).jobLocationImage;
    return ColoredBox(
      color: _colors.background,
      child: widget.enabled
          ? LayoutBuilder(
              builder: (context, constraints) {
                final request = StaticMapRequest.forSize(imageUrl: widget.imageUrl, size: widget.size);
                final requestKey = request?.cacheKey ?? widget.imageUrl;
                if (_requestKey != requestKey) {
                  _requestKey = requestKey;
                  _feedbackKey = GlobalKey<_JobLocationImageFeedbackState>();
                }
                return Semantics(
                  container: true,
                  explicitChildNodes: true,
                  image: true,
                  label: i18n.semanticLabel,
                  child: request == null
                      ? _buildFeedback(state: .error)
                      : CachedNetworkImage(
                          key: ValueKey((request.cacheKey, _retry)),
                          imageUrl: request.url,
                          cacheKey: request.cacheKey,
                          cacheManager: ref.watch(staticMapCacheManagerProvider),
                          fit: BoxFit.cover,
                          filterQuality: .medium,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholder: (context, url) => _buildFeedback(state: .loading, request: request),
                          errorWidget: (context, url, error) => _buildFeedback(state: .error, request: request),
                          imageBuilder: (context, provider) => Stack(
                            children: [
                              Positioned.fill(
                                child: Image(
                                  image: provider,
                                  fit: BoxFit.cover,
                                  filterQuality: .medium,
                                  excludeFromSemantics: true,
                                ),
                              ),
                              Positioned(
                                left: 24,
                                right: 24,
                                bottom: 16,
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      child: MateoPress(
                                        semanticLabel: 'OpenStreetMap',
                                        onPressed: (_) async => launchUrl(
                                          Uri.parse('https://www.openstreetmap.org/copyright'),
                                          mode: LaunchMode.externalApplication,
                                        ),
                                        child: MateoText(
                                          '© OpenStreetMap',
                                          presentation: .interface(
                                            fontSize: 10,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                );
              },
            )
          : const SizedBox.expand(),
    );
  }

  Widget _buildFeedback({required JobLocationImageFeedbackState state, StaticMapRequest? request}) => Semantics(
    container: true,
    explicitChildNodes: true,
    child: _JobLocationImageFeedback(
      key: _feedbackKey,
      state: state,
      color: _colors.loadingIndicator,
      onRetry: () => unawaited(_retryImage(request: request)),
    ),
  );
}
