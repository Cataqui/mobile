import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:cataqui_app/gen/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

part 'animated_splash_logo_bytes_loader.dart';
part 'animated_splash_logo_painter.dart';
part 'app_animated_splash_overlay_painter.dart';

class AppAnimatedSplash extends StatefulWidget {
  const AppAnimatedSplash({required this.child, super.key});

  static const animationDuration = Duration(milliseconds: 400);
  static const anticipationDuration = Duration(milliseconds: 180);

  static Duration get revealDuration => animationDuration;

  static const _assetViewBox = Size(641, 686);
  static const _apertureCenterInAsset = Offset(294.649, 307.786);
  static const _apertureRadiusInAsset = 49.575;
  static const _initialLogoSize = Size(160.25, 171.5);
  static const _viewportCoverageMargin = 2.0;
  static final _animatedSplashIcon = Assets.splash.animatedSplashIconSvg;
  static final _animatedSplashIconLoader = _SplashLogoBytesLoader(_animatedSplashIcon.path);
  static const _systemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
  );

  final Widget child;

  @override
  State<AppAnimatedSplash> createState() => _AppAnimatedSplashState();
}

class _AppAnimatedSplashState extends State<AppAnimatedSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  Timer? _handoffDelayTimer;
  Completer<void>? _handoffDelayCompleter;

  bool _hasScheduledHandoff = false;
  bool _isSplashVisible = true;
  Future<PictureInfo>? _logoPrecache;
  PictureInfo? _logoPictureInfo;

  double get _assetLogicalScale => AppAnimatedSplash._initialLogoSize.width / AppAnimatedSplash._assetViewBox.width;

  Offset get _apertureOffsetFromLogoCenter {
    final apertureCenter = AppAnimatedSplash._apertureCenterInAsset * _assetLogicalScale;
    return apertureCenter - AppAnimatedSplash._initialLogoSize.center(Offset.zero);
  }

  double get _initialApertureRadius => AppAnimatedSplash._apertureRadiusInAsset * _assetLogicalScale;

  void _scheduleNativeHandoff() {
    if (_hasScheduledHandoff) return;

    _hasScheduledHandoff = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _removeNativeSplashAndStart());
  }

  Future<PictureInfo> _precacheLogo() {
    return _logoPrecache ??= vg.loadPicture(AppAnimatedSplash._animatedSplashIconLoader, context);
  }

  Future<void> _playSplashAnimationFromNextFrame() {
    final animationCompleter = Completer<void>();

    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (!mounted) {
        animationCompleter.complete();
        return;
      }

      _animationController
          .forward(from: 0)
          .orCancel
          .then<void>((_) {
            animationCompleter.complete();
          })
          .catchError((Object _) {
            if (animationCompleter.isCompleted) return;

            animationCompleter.complete();
          });
    });

    SchedulerBinding.instance.scheduleFrame();

    return animationCompleter.future;
  }

  Future<void> _waitBeforeSplashAnimation() {
    final delayCompleter = Completer<void>();
    _handoffDelayCompleter = delayCompleter;

    _handoffDelayTimer = Timer(AppAnimatedSplash.anticipationDuration, () {
      _handoffDelayTimer = null;

      if (!delayCompleter.isCompleted) delayCompleter.complete();
    });

    return delayCompleter.future;
  }

  void _hideSplash() {
    final logoPictureInfo = _logoPictureInfo;

    setState(() {
      _logoPictureInfo = null;
      _isSplashVisible = false;
    });

    logoPictureInfo?.picture.dispose();
  }

  Future<void> _removeNativeSplashAndStart() async {
    if (!mounted) return;

    final logoPictureInfo = await _precacheLogo();
    if (!mounted) {
      logoPictureInfo.picture.dispose();
      return;
    }

    if (_logoPictureInfo == null) {
      setState(() {
        _logoPictureInfo = logoPictureInfo;
      });
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    FlutterNativeSplash.remove();

    if (MediaQuery.disableAnimationsOf(context)) {
      _hideSplash();
      return;
    }

    await _waitBeforeSplashAnimation();
    if (!mounted) return;

    await _playSplashAnimationFromNextFrame();
    if (!mounted) return;

    _hideSplash();
  }

  double _revealProgress(double animationValue) {
    return Curves.easeInCubic.transform(animationValue);
  }

  double _apertureFadeOpacity(double revealProgress) {
    if (revealProgress == 0) return 1;

    return 1 - Curves.easeOutCubic.transform(revealProgress);
  }

  double _scale({required double animationValue, required Size viewportSize}) {
    final farthestCornerDistance = Offset(viewportSize.width / 2, viewportSize.height / 2).distance;
    final viewportCoveringScale =
        (farthestCornerDistance + AppAnimatedSplash._viewportCoverageMargin) / _initialApertureRadius;

    return lerpDouble(1, viewportCoveringScale, _revealProgress(animationValue))!;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: AppAnimatedSplash.animationDuration, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleNativeHandoff();
  }

  @override
  void dispose() {
    _handoffDelayTimer?.cancel();

    if (!(_handoffDelayCompleter?.isCompleted ?? true)) {
      _handoffDelayCompleter?.complete();
    }

    _logoPictureInfo?.picture.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [widget.child, if (_isSplashVisible) _buildSplashOverlay(context)]);
  }

  Widget _buildSplashOverlay(BuildContext context) {
    final splashColor = context.mateo.palette.primary[9];

    return Positioned.fill(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppAnimatedSplash._systemUiOverlayStyle,
        child: AbsorbPointer(
          child: RepaintBoundary(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewportSize = constraints.biggest;
                final viewportCenter = viewportSize.center(Offset.zero);

                return AnimatedBuilder(
                  animation: _animationController,
                  child: RepaintBoundary(child: _buildLogo()),
                  builder: (context, logo) {
                    final animationValue = _animationController.value;
                    final revealProgress = _revealProgress(animationValue);
                    final scale = _scale(animationValue: animationValue, viewportSize: viewportSize);
                    final logoTranslation = _apertureOffsetFromLogoCenter * (1 - revealProgress - scale);
                    final apertureCenter = viewportCenter + logoTranslation + _apertureOffsetFromLogoCenter * scale;
                    final apertureRadius = _initialApertureRadius * scale;
                    final apertureFadeOpacity = _apertureFadeOpacity(revealProgress);

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          isComplex: true,
                          willChange: true,
                          painter: _SplashOverlayPainter(
                            apertureCenter: apertureCenter,
                            apertureRadius: apertureRadius,
                            apertureFadeOpacity: apertureFadeOpacity,
                            color: splashColor,
                          ),
                        ),
                        Center(
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..translateByDouble(logoTranslation.dx, logoTranslation.dy, 0, 1)
                              ..scaleByDouble(scale, scale, scale, 1),
                            child: logo,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final logoPictureInfo = _logoPictureInfo;

    if (logoPictureInfo == null) {
      return const SizedBox.shrink();
    }

    return SizedBox.fromSize(
      size: AppAnimatedSplash._initialLogoSize,
      child: CustomPaint(painter: _SplashLogoPainter(logoPictureInfo)),
    );
  }
}
