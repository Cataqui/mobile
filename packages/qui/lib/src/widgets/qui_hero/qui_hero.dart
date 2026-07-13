library;

import 'package:flutter/material.dart';
import 'package:qui/qui.dart' show QuiHeroExtension, QuiHeroPage, QuiHeroSwipeToPopExtension;
import 'package:qui/src/theme/qui_theme_data.dart';
import 'package:qui/src/widgets/qui_edge_fade/qui_edge_fade.dart'
    show QuiEdgeFade, QuiEdgeFadePosition, QuiEdgeFadeStyle;
import 'package:qui/src/widgets/qui_hero/heroes/background/qui_hero_background.dart';
import 'package:qui/src/widgets/qui_hero/heroes/text/qui_hero_text.dart';

import 'heroes/background/qui_hero_background.dart' show QuiHeroBackground;
import 'heroes/group/qui_hero_group.dart' show QuiHeroGroup;
import 'heroes/text/qui_hero_text.dart' show QuiHeroText, QuiHeroTextFlightMetrics;

part 'qui_hero_edge_fade.dart';
part 'qui_hero_enums.dart';
part 'qui_hero_lifecycle/_qui_hero_lifecycle_endpoint.dart';
part 'qui_hero_lifecycle/_qui_hero_lifecycle_flight_shuttle.dart';

/// A shared-element hero widget that animates visual state across screen
/// transitions.
///
/// Place a [QuiHero] on the source screen and a sibling with the same [tag]
/// on the destination screen. When the destination route is pushed — typically
/// via [QuiHeroPage] — the source element "flies" across to the destination
/// position while its appearance morphs between the source and destination
/// configuration. The source route stays composited underneath so the flight
/// is visible against the previous screen.
///
/// ## Flight lifecycle
///
/// Every hero flight goes through three phases:
///
///  1. **Departure** — the animation begins. The **departing** (source-on-push,
///     destination-on-pop) hero fires [onStart].
///  2. **Transition** — the flight shuttle interpolates between the source and
///     destination configurations. Content and layout switch from the departing
///     hero to the receiving hero at the midpoint of the animation.
///  3. **Settle** — the flight reaches its end value. The departing hero fires
///     [onEnd] and the **receiving** hero fires [onReceived].
///
/// The receiving hero is the one whose route becomes active after the
/// transition:
///  * On **push** — the destination (new route) receives the flight.
///  * On **pop** — the source (previous route) receives the flight.
///
/// All callbacks fire exactly once per flight, at the frame where the
/// animation settles.
///
/// ## Choosing a variant
///
/// Use one of the concrete subclasses directly:
///
///  * [QuiHeroText] — animates text content, [TextStyle], and wrapping
///    behavior. Text content and layout constraints switch at the flight
///    midpoint.
///  * [QuiHeroBackground] — animates a [BoxDecoration] (color, border radius,
///    gradient) and clips its child with the animated shape. Includes an
///    [QuiHeroEdgeFade] for content edges and supports width/height
///    interpolation.
///  * [QuiHeroGroup] — flies multiple heterogenous [QuiHero] instances as a
///    single shared element. Each child animates independently within the
///    group's layout.
///
/// ### Endpoint tags
///
/// Concrete subclasses provide a variant-specific default [tag] when none is
/// given. This keeps simple routes lightweight: one tagless [QuiHeroText],
/// one tagless [QuiHeroBackground], and one tagless [QuiHeroGroup] can
/// coexist on a route and each animates independently to its matching variant
/// on the destination. If a route has multiple active heroes of the same
/// tagless variant, Flutter asserts at navigation time — pass explicit tags
/// for those cases.
///
/// ### Nested heroes
///
/// A [QuiHeroBackground] can contain [QuiHeroText] or [QuiHeroGroup] children
/// that share a tag with counterparts on the destination. Each paired hero
/// animates independently during the same navigation, producing a layered
/// transition where the outer container flies while its inner text also
/// morphs.
///
/// ## Reduced motion
///
/// When [MediaQuery.disableAnimationsOf] returns `true`, [QuiHeroPage] sets
/// the route durations to [Duration.zero] and disables the [HeroMode]
/// entirely. No hero flight occurs and neither [onStart], [onEnd], nor
/// [onReceived] fire — the destination appears immediately with all content
/// visible.
///
/// ## Performance on low-end devices
///
/// Flight shuttles are wrapped in [RepaintBoundary] to isolate repaint work
/// during the transition. Decoration and text interpolation use
/// [Curves.easeOutCubic], a cost-effective easing curve that performs well on
/// low-end GPUs. Repaint work on the underlying routes does not affect the
/// flight's frame budget.
///
/// ```dart
/// // Source — a rounded card with title and payment
/// QuiHeroBackground(
///   tag: 'job-card',
///   decoration: BoxDecoration(
///     color: surfaceColor,
///     borderRadius: BorderRadius.circular(38),
///   ),
///   child: Column(
///     children: [
///       QuiHeroText(
///         tag: 'job-title',
///         text: 'Garçom para Fim de Semana',
///         style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
///       ),
///     ],
///   ),
/// )
///
/// // Destination — same tags animate the card and title independently
/// QuiHeroBackground(
///   tag: 'job-card',
///   decoration: BoxDecoration(color: bgColor),
///   child: Column(
///     children: [
///       QuiHeroText(
///         tag: 'job-title',
///         text: 'Garçom para Fim de Semana',
///         style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// See also:
///  * [QuiHeroPage], the destination [Page] that enables transparent route
///    compositing and reduced-motion support.
///  * [QuiHeroExtension], the base class for reusable behaviors attached to
///    hero variants.
///  * [QuiHeroSwipeToPopExtension], a built-in extension that adds
///    swipe-to-pop gestures to hero destinations.
///  * Flutter's [Hero], the underlying widget that [QuiHero] wraps.
abstract class QuiHero extends StatelessWidget {
  /// Creates a QUI hero with the given shared animation configuration.
  ///
  /// Rather than calling this constructor directly, use one of the concrete
  /// subclasses: [QuiHeroText], [QuiHeroBackground], or [QuiHeroGroup].
  const QuiHero({
    required this.tag,
    required this.flightShuttleBuilder,
    this.onStart,
    this.onEnd,
    this.onReceived,
    super.key,
  });

  /// The identifier that pairs this hero with a counterpart on another route.
  ///
  /// The [tag] must be identical on both the source and destination instances
  /// of the same shared element. It must be unique among all heroes in the
  /// same route scope — Flutter's [Hero] uses the tag to find its counterpart
  /// and asserts uniqueness within a route.
  ///
  /// Concrete subclasses supply a variant-specific default when the user does
  /// not pass one explicitly. See [QuiHeroDefaultTag] for the defaults used by
  /// each variant.
  final Object tag;

  /// Builds the visual content of the flight shuttle, interpolating between
  /// the source and destination hero configurations over the flight animation.
  ///
  /// The builder receives both the source and destination hero child widgets
  /// and is responsible for wrapping them in the transition animation. Each
  /// concrete variant implements this to interpolate its specific properties:
  /// [QuiHeroText] lerps [TextStyle], [QuiHeroBackground] lerps
  /// [BoxDecoration], and [QuiHeroGroup] distributes the animation to its
  /// children.
  ///
  /// The builder is called during every frame of the hero flight and must
  /// return a widget that represents the state of the flight at the current
  /// `animation` value.
  ///
  /// See also:
  ///  * Flutter's [Hero.flightShuttleBuilder] for the complete contract of
  ///    this builder.
  final Widget Function(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
    Widget fromHeroChild,
    Widget toHeroChild,
  )
  flightShuttleBuilder;

  /// Called when the hero flight begins on the departing side.
  ///
  /// Fires once per flight, before the first frame of the animation.
  ///
  /// This callback fires on the **departing** hero (source on push,
  /// destination on pop). It does not fire when reduced motion is active.
  final VoidCallback? onStart;

  /// Called when the hero flight settles on the departing side.
  ///
  /// Fires once per flight, at the frame where the animation reaches its end
  /// value (completed or dismissed). [onEnd] fires after [onReceived] on the
  /// receiving side.
  ///
  /// Use [onEnd] to trigger side effects — haptic feedback, analytics events,
  /// or state transitions — that should happen after the flight completes.
  /// This callback fires on the **departing** hero (source on push,
  /// destination on pop). It does not fire when reduced motion is active.
  final VoidCallback? onEnd;

  /// Called when the hero flight settles on the receiving side.
  ///
  /// Fires once per flight, at the frame where the animation reaches its end
  /// value. [onReceived] fires before [onEnd] on the departing side at the
  /// same settle frame.
  ///
  /// The receiving hero is the one whose route becomes active after the
  /// transition: the **destination** on push, the **source** on pop.
  ///
  /// Use [onReceived] to do things that should only be done after after the
  /// flight lands — for example, fading in the back button. This
  /// is more reliable than a timer-based approach because it is synchronized
  /// with the actual settle frame, even when the animation duration changes.
  ///
  /// This callback does not fire when reduced motion is active.
  final VoidCallback? onReceived;

  /// Builds the widget that represents this hero at rest — when no flight is
  /// active.
  ///
  /// The returned widget appears inside the [Hero] on the source and
  /// destination routes. During a flight, the result of this method becomes
  /// the `fromHeroChild` or `toHeroChild` passed to
  /// [flightShuttleBuilder].
  Widget buildFlightChild(BuildContext context);

  /// Creates the [RectTween] used to animate the hero's position between
  /// routes.
  ///
  /// Returns a [RectTween] that linearly interpolates between the source and
  /// destination rectangles. This produces a straight-line flight path with
  /// no easing on the position itself — visual easing is applied via
  /// [Curves.easeOutCubic] on the flight shuttle content.
  static RectTween createRectTween(Rect? begin, Rect? end) {
    return RectTween(begin: begin, end: end);
  }

  /// The list of callbacks to invoke when the hero flight begins on this
  /// endpoint.
  ///
  /// Subclasses can override this to aggregate callbacks from child heroes.
  /// For example, [QuiHeroGroup] merges callbacks from its children so the
  /// parent flight fires every child's [onStart] alongside the group's own.
  List<VoidCallback> lifecycleStartCallbacks(BuildContext context) {
    final onStart = this.onStart;
    if (onStart == null) return const [];

    return [onStart];
  }

  /// The list of callbacks to invoke when the hero flight settles, fired
  /// from the departing endpoint.
  ///
  /// Subclasses can override this to aggregate callbacks from child heroes.
  /// See [lifecycleStartCallbacks] for the aggregation pattern.
  List<VoidCallback> lifecycleEndCallbacks(BuildContext context) {
    final onEnd = this.onEnd;
    if (onEnd == null) return const [];

    return [onEnd];
  }

  /// The list of callbacks to invoke when the hero flight settles, fired
  /// from the receiving endpoint.
  ///
  /// Subclasses can override this to aggregate callbacks from child heroes.
  /// See [lifecycleStartCallbacks] for the aggregation pattern.
  List<VoidCallback> lifecycleReceivedCallbacks(BuildContext context) {
    final onReceived = this.onReceived;
    if (onReceived == null) return const [];

    return [onReceived];
  }

  /// Builds the endpoint widget that wraps [buildFlightChild] with lifecycle
  /// callback wiring.
  ///
  /// The returned widget is inserted as the [Hero]'s child at rest. During a
  /// flight, the [buildLifecycleFlightShuttle] extracts the endpoint's
  /// callback lists to wire into the flight shuttle.
  Widget buildLifecycleEndpoint(BuildContext context) {
    return _QuiHeroLifecycleEndpoint(
      onStartCallbacks: lifecycleStartCallbacks(context),
      onEndCallbacks: lifecycleEndCallbacks(context),
      onReceivedCallbacks: lifecycleReceivedCallbacks(context),
      child: buildFlightChild(context),
    );
  }

  /// The [Hero.flightShuttleBuilder] implementation that wires lifecycle
  /// callbacks into the flight animation.
  ///
  /// Extracts the callback lists from the source and destination endpoints,
  /// then returns a flight shuttle that fires `onStartCallbacks` from the
  /// origin at takeoff and `onEndCallbacks` from the origin plus
  /// `onReceivedCallbacks` from the destination at settle.
  Widget buildLifecycleFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final fromEndpoint = _QuiHeroLifecycleEndpoint.fromHeroContext(fromHeroContext);
    final toEndpoint = _QuiHeroLifecycleEndpoint.fromHeroContext(toHeroContext);
    final originEndpoint = fromEndpoint;

    return _QuiHeroLifecycleFlightShuttle(
      animation: animation,
      flightDirection: flightDirection,
      onStartCallbacks: originEndpoint.onStartCallbacks,
      onEndCallbacks: originEndpoint.onEndCallbacks,
      onReceivedCallbacks: toEndpoint.onReceivedCallbacks,
      child: flightShuttleBuilder(
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
        fromEndpoint.child,
        toEndpoint.child,
      ),
    );
  }

  /// Creates a hero suitable for use as a child inside a [QuiHeroGroup]
  /// flight.
  ///
  /// During a grouped flight, each child hero receives a progress [value]
  /// between `0.0` and `1.0` and is asked to produce a hero that represents
  /// its state at that progress. This enables group-level interpolation where
  /// each child can switch its content independently.
  ///
  /// The default implementation asserts in non-group contexts — concrete
  /// subclasses that may appear inside [QuiHeroGroup] must override this.
  QuiHero buildForGroupFlight({
    required QuiHero end,
    required double value,
    required HeroFlightDirection flightDirection,
    QuiHeroTextFlightMetrics? flightMetrics,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      createRectTween: createRectTween,
      flightShuttleBuilder: buildLifecycleFlightShuttle,
      transitionOnUserGestures: true,
      child: buildLifecycleEndpoint(context),
    );
  }
}
