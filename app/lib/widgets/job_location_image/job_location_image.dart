import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/static_map/enums/static_map_size.dart';
import 'package:cataqui_app/core/static_map/static_map_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import 'enums/job_location_image_feedback_state.dart';

part 'job_location_image_feedback.dart';
part 'job_location_image_loading_bounce_curve.dart';

class JobLocationImage extends ConsumerStatefulWidget {
  const JobLocationImage({required this.imageUrl, required this.size, this.enabled = true, super.key});

  final String imageUrl;
  final StaticMapSize size;
  final bool enabled;

  @override
  ConsumerState<JobLocationImage> createState() => _JobLocationImageState();
}

class _JobLocationImageState extends ConsumerState<JobLocationImage> {
  static const _imageFadeDuration = Duration(milliseconds: 300);
  GlobalKey<_JobLocationImageFeedbackState> _feedbackKey = GlobalKey<_JobLocationImageFeedbackState>();
  int _retry = 0;

  ({Color background, Color loadingIndicator}) get _colors => switch (Theme.of(context).brightness) {
    .light => (
      background: MateoTheme.of(context).palette.neutral[2],
      loadingIndicator: MateoTheme.of(context).palette.neutral[6],
    ),
    .dark => throw UnsupportedError('JobLocationImage does not support dark mode.'),
  };

  void _retryImage() {
    setState(() => _retry++);
  }

  @override
  void didUpdateWidget(covariant JobLocationImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl || oldWidget.size != widget.size) {
      _feedbackKey = GlobalKey<_JobLocationImageFeedbackState>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider).jobLocationImage;
    final request = StaticMapRequest(imageUrl: widget.imageUrl, size: widget.size);
    return ColoredBox(
      color: _colors.background,
      child: widget.enabled
          ? LayoutBuilder(
              builder: (context, constraints) {
                return CachedNetworkImage(
                  key: ValueKey((request.cacheKey, _retry)),
                  imageUrl: request.url,
                  cacheKey: request.cacheKey,
                  cacheManager: ref.watch(staticMapCacheManagerProvider),
                  fit: .cover,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  fadeInDuration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : _imageFadeDuration,
                  fadeOutDuration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : _imageFadeDuration,
                  imageBuilder: (context, imageProvider) => Image(
                    image: imageProvider,
                    fit: .cover,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    semanticLabel: i18n.semanticLabel,
                  ),
                  placeholder: (context, url) => _JobLocationImageFeedback(
                    key: _feedbackKey,
                    state: .loading,
                    color: _colors.loadingIndicator,
                    onRetry: _retryImage,
                  ),
                  errorWidget: (context, url, error) => _JobLocationImageFeedback(
                    key: _feedbackKey,
                    state: .error,
                    color: _colors.loadingIndicator,
                    onRetry: _retryImage,
                  ),
                );
              },
            )
          : const SizedBox.expand(),
    );
  }
}
