/// Canonical motion tokens.
///
/// Two families, and the distinction matters:
///
///  * [AppMotion] — M3 durations and easing. Used where an animation *appears*
///    (fading in, sliding away) and overshoot would read as a glitch.
///  * [AppSpring] — the M3 Expressive spring language. Used where something
///    *moves in space* — the nav pill, press states, list entry — so it carries
///    a little weight instead of sliding on rails.
///
/// Nothing in the app should invent a `Duration` or `Curve` literal.
library;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

abstract final class AppMotion {
  const AppMotion._();

  static const Duration shortest = Duration(milliseconds: 100);
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration long = Duration(milliseconds: 500);
  static const Duration longest = Duration(milliseconds: 700);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutExpo;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasizedExit = Curves.easeInExpo;
}

/// Material 3 Expressive spring tokens.
abstract final class AppSpring {
  const AppSpring._();

  /// Slightly bouncy — nav pill, press states, list entry.
  static final SpringDescription spatial =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 500),
        bounce: 0.35,
      );

  /// No bounce — colour and opacity, where overshoot reads as a glitch.
  static final SpringDescription effects =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 350),
        bounce: 0,
      );

  /// Upper bound on a spring's settle window, in seconds. M3 caps every
  /// animation at 500 ms; a spring's asymptotic tail beyond that is
  /// imperceptible, so it is trimmed rather than rendered.
  static const double _maxSeconds = 0.5;

  /// Replays [description] from 0 to 1 as a [Curve], which is what lets spring
  /// physics drive *implicit* animations (`AnimatedContainer`, `AnimatedSize`…).
  static Curve curve(SpringDescription description) =>
      _SpringCurve(description);

  /// Drives an explicit [AnimationController] with the spring simulation.
  static TickerFuture animate(
    AnimationController controller, {
    SpringDescription? description,
    bool spatial = true,
  }) {
    final spring =
        description ?? (spatial ? AppSpring.spatial : AppSpring.effects);
    return controller.animateWith(
      SpringSimulation(spring, controller.value, 1, 0),
    );
  }

  /// Whether animations should be suppressed.
  ///
  /// Two sources, OR-ed: the platform's own "remove animations" accessibility
  /// setting (`MediaQuery.disableAnimations`) and the in-app switch in Settings
  /// → Appearance. OR rather than override because a user can always ask for
  /// *less* motion than the platform does, never more.
  static bool isDisabled(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true ||
      MotionPreferences.of(context);

  static Duration durationOf(
    BuildContext context, {
    Duration fallback = AppMotion.medium,
  }) => isDisabled(context) ? Duration.zero : fallback;
}

/// A [Curve] backed by a real [SpringSimulation], normalised to 0→1 over the
/// spring's settle window.
class _SpringCurve extends Curve {
  _SpringCurve(SpringDescription description)
    : simulation = SpringSimulation(description, 0, 1, 0);

  final SpringSimulation simulation;

  double get _settleSeconds {
    for (var t = 0.02; t <= AppSpring._maxSeconds; t += 0.02) {
      if (simulation.isDone(t)) return t;
    }
    return AppSpring._maxSeconds;
  }

  @override
  double transformInternal(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    return simulation.x(t * _settleSeconds);
  }
}

/// The in-app "reduce motion" preference, published down the tree so
/// [AppSpring.isDisabled] can consult it from any widget.
///
/// An [InheritedWidget] rather than a provider: it is presentation state, it is
/// mounted once around the whole app in `app.dart`, and the read happens inside
/// `build` — a provider would only add a subscription to do the same thing.
class MotionPreferences extends InheritedWidget {
  const MotionPreferences({
    super.key,
    required this.reduceMotion,
    required super.child,
  });

  final bool reduceMotion;

  /// `false` outside an installed scope, so a widget can be pumped in a test
  /// without the app wrapper and still animate normally.
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<MotionPreferences>()
          ?.reduceMotion ??
      false;

  @override
  bool updateShouldNotify(MotionPreferences oldWidget) =>
      oldWidget.reduceMotion != reduceMotion;
}
