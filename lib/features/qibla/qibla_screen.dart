import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:mawaqit/core/qibla/qibla.dart';
import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/features/qibla/qibla_controller.dart';
import 'package:mawaqit/features/qibla/travel_screen.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/app_button.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Live Qibla compass, drawn as a small astrolabe.
///
/// The bearing is pure maths (see [qiblaBearing]); the only platform-dependent
/// part is the heading stream. The dial is deliberately a *relative* turn
/// instrument: screen-up is the direction the phone is pointing, the gold beam
/// at the top is the Qibla target, and the Kaaba-tipped needle is the direction
/// to Mecca. Rotating the phone until the needle sits in the beam means the
/// phone is facing the Qibla.
///
/// When a device has no magnetometer — every desktop and test host — the screen
/// keeps the correct bearing and says so plainly instead of showing a needle
/// that points nowhere.
class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Compass samples arrive around 30 times a second. Selecting only the
    // values this subtree renders keeps those frames inside the needle layer:
    // the scaffold, card, readouts and buttons do not rebuild per sample.
    final bearing = ref.watch(qiblaControllerProvider.select((s) => s.bearing));
    final distanceKm = ref.watch(
      qiblaControllerProvider.select((s) => s.distanceKm),
    );
    final locationName = ref.watch(
      qiblaControllerProvider.select((s) => s.locationName),
    );
    final status = ref.watch(qiblaControllerProvider.select((s) => s.status));
    final l10n = AppLocalizations.of(context);

    final hasLocation = bearing != null && distanceKm != null;
    final bearingLabel = bearing == null
        ? l10n.travelSetLocation
        : l10n.qiblaBearing(bearing.round().toString());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        centerTitle: true,
        title: UiText(
          l10n.qiblaTitle,
          type: UiTextType.titleLarge,
          fontWeight: AppWeight.bold,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.huge,
            AppSpacing.xs,
            AppSpacing.huge,
            AppSpacing.pageBottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LocationLine(
                locationName: locationName,
                hasLocation: hasLocation,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                radius: AppRadius.xxl,
                child: Column(
                  children: [
                    _QiblaDial(
                      bearingLabel: bearingLabel,
                      hasLocation: hasLocation,
                    ),
                    if (bearing != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const _KaabaLegend(),
                      const SizedBox(height: AppSpacing.lg),
                      _Readouts(
                        bearing: bearing,
                        distanceKm: distanceKm!,
                        locale: Localizations.localeOf(context).languageCode,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _QiblaStatus(status: status, hasLocation: hasLocation),
              const SizedBox(height: AppSpacing.mega),
              AppButton(
                label: l10n.travelTitle,
                icon: Icons.flight_takeoff_outlined,
                variant: AppButtonVariant.tonal,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const TravelScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// City line above the instrument. Kept quiet so the dial stays the hero.
class _LocationLine extends StatelessWidget {
  const _LocationLine({required this.locationName, required this.hasLocation});

  final String locationName;
  final bool hasLocation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.place_outlined, size: AppIconSize.lg, color: scheme.primary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: UiText(
            hasLocation
                ? l10n.qiblaSubtitle(locationName)
                : l10n.travelSetLocation,
            type: UiTextType.labelLarge,
            color: scheme.onSurfaceVariant,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// The instrument itself. The face, tick ring and gold beam are painted once;
/// only the needle layer subscribes to the 30 Hz heading stream.
class _QiblaDial extends ConsumerWidget {
  const _QiblaDial({required this.bearingLabel, required this.hasLocation});

  final String bearingLabel;
  final bool hasLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(qiblaControllerProvider.select((s) => s.status));
    final aligned = ref.watch(
      qiblaControllerProvider.select((s) => s.isAligned),
    );
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final statusLabel = switch (status) {
      CompassStatus.unavailable => l10n.qiblaSensorUnavailable,
      CompassStatus.calibrating => l10n.qiblaCalibrate,
      CompassStatus.available =>
        aligned ? l10n.qiblaFacing : l10n.qiblaCompassHint,
    };
    final semanticsLabel = hasLocation
        ? '$bearingLabel, $statusLabel'
        : l10n.travelSetLocation;

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dimension = constraints.maxWidth < AppSize.qiblaDialMax
              ? constraints.maxWidth
              : AppSize.qiblaDialMax;
          return Center(
            child: SizedBox(
              width: dimension,
              height: dimension,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DialFacePainter(
                        scheme: scheme,
                        aligned: aligned,
                      ),
                    ),
                  ),
                  const Positioned.fill(child: _NeedleLayer()),
                  _DialHub(scheme: scheme, aligned: aligned),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Isolates the per-sample rebuild to the needle.
class _NeedleLayer extends ConsumerWidget {
  const _NeedleLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final angle = ref.watch(
      qiblaControllerProvider.select((s) => s.needleAngle),
    );
    final status = ref.watch(qiblaControllerProvider.select((s) => s.status));
    final aligned = ref.watch(
      qiblaControllerProvider.select((s) => s.isAligned),
    );
    if (angle == null) return const SizedBox.shrink();

    return _CompassNeedle(
      angle: angle,
      scheme: Theme.of(context).colorScheme,
      dimmed: status == CompassStatus.calibrating,
      aligned: aligned,
    );
  }
}

/// Smoothly eases the needle between sensor samples without ever spinning the
/// long way round when the angle crosses ±180°. Honours both reduce-motion
/// sources through [AppSpring.isDisabled].
class _CompassNeedle extends StatefulWidget {
  const _CompassNeedle({
    required this.angle,
    required this.scheme,
    required this.dimmed,
    required this.aligned,
  });

  final double angle;
  final ColorScheme scheme;
  final bool dimmed;
  final bool aligned;

  @override
  State<_CompassNeedle> createState() => _CompassNeedleState();
}

class _CompassNeedleState extends State<_CompassNeedle> {
  late double _angle = widget.angle;
  late double _turns = widget.angle / 360;

  @override
  void didUpdateWidget(covariant _CompassNeedle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.angle == widget.angle) return;
    _turns += shortestAngleDelta(_angle, widget.angle) / 360;
    _angle = widget.angle;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppSpring.isDisabled(context);
    return ExcludeSemantics(
      child: AnimatedRotation(
        turns: _turns,
        duration: reduceMotion ? Duration.zero : AppMotion.short,
        curve: AppMotion.standard,
        child: CustomPaint(
          painter: _NeedlePainter(
            scheme: widget.scheme,
            dimmed: widget.dimmed,
            aligned: widget.aligned,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Static pivot cover. Sits above the needle so the needle appears to pass
/// under a metal pin rather than through the middle of the card.
class _DialHub extends StatelessWidget {
  const _DialHub({required this.scheme, required this.aligned});

  final ColorScheme scheme;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    final accent = aligned ? scheme.tertiary : scheme.primary;
    return Container(
      width: AppSize.qiblaHub,
      height: AppSize.qiblaHub,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surfaceContainerLowest,
        border: Border.all(
          color: accent.withValues(alpha: AppOpacity.hairline),
        ),
      ),
      child: Center(
        child: Container(
          width: AppSize.qiblaHubDot,
          height: AppSize.qiblaHubDot,
          decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
        ),
      ),
    );
  }
}

/// Face, tick ring and alignment gate. All geometry is derived from the painted
/// size, so the same painter works at 296dp and at the 320dp cap.
class _DialFacePainter extends CustomPainter {
  const _DialFacePainter({required this.scheme, required this.aligned});

  final ColorScheme scheme;
  final bool aligned;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final outer = radius - AppSpacing.xs;
    final outerRect = Rect.fromCircle(center: center, radius: outer);

    // A quiet centre wash gives the flat card a little depth without turning
    // the instrument into a glowing button.
    final wash = Paint()
      ..shader = RadialGradient(
        colors: [
          scheme.primary.withValues(alpha: AppOpacity.whisper),
          scheme.primary.withValues(alpha: AppOpacity.none),
        ],
      ).createShader(outerRect);
    canvas.drawCircle(center, outer, wash);

    // Alignment turns the whole frame gold: a blurred halo under a crisp ring,
    // readable from arm's length before any label is parsed.
    if (aligned) {
      canvas.drawCircle(
        center,
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppStroke.selected
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            AppElevation.qiblaArcBlur,
          )
          ..color = scheme.tertiary.withValues(alpha: AppOpacity.arcGlow),
      );
    }

    final structure = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppStroke.hairline
      ..color = aligned
          ? scheme.tertiary.withValues(alpha: AppOpacity.supportingInk)
          : scheme.outline.withValues(alpha: AppOpacity.hairline);
    canvas.drawCircle(center, outer, structure);
    canvas.drawCircle(center, outer * AppSize.qiblaInnerRing, structure);

    // A protractor ring: 5° marks, with every 30° standing up taller so the
    // graduations read as an instrument rather than a texture.
    final tickPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = AppStroke.hairline;
    final tickOuter = outer - AppSpacing.xs;
    for (var degrees = 0; degrees < 360; degrees += 5) {
      final major = degrees % 30 == 0;
      final length = major ? AppSize.qiblaTickMajor : AppSize.qiblaTickMinor;
      final direction = _polar(degrees - 90);
      tickPaint.color = major
          ? scheme.outline.withValues(alpha: AppOpacity.faintMark)
          : scheme.outlineVariant.withValues(alpha: AppOpacity.hairline);
      canvas.drawLine(
        center + direction * (tickOuter - length),
        center + direction * tickOuter,
        tickPaint,
      );
    }

    // The gold beam is the target, not decoration: the needle has to enter it
    // before the screen will confirm that the phone is facing the Qibla.
    final arcRadius = outer - AppSize.qiblaArcInset;
    final arcRect = Rect.fromCircle(center: center, radius: arcRadius);
    const sweep = qiblaAlignmentTolerance * 2 * math.pi / 180;
    const start = -math.pi / 2 - sweep / 2;
    final innerRadius = outer * AppSize.qiblaBeamInner;

    // At rest the beam is an open gate: two radial edges and the gold arc. Only
    // once the needle is inside it does gold light fill the slot, so the
    // confirmation is a change in the instrument, not just a label.
    if (aligned) {
      final beam = Path()
        ..moveTo(
          center.dx + math.cos(start) * innerRadius,
          center.dy + math.sin(start) * innerRadius,
        )
        ..lineTo(
          center.dx + math.cos(start) * arcRadius,
          center.dy + math.sin(start) * arcRadius,
        )
        ..arcTo(arcRect, start, sweep, false)
        ..lineTo(
          center.dx + math.cos(start + sweep) * innerRadius,
          center.dy + math.sin(start + sweep) * innerRadius,
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerRadius),
          start + sweep,
          -sweep,
          false,
        )
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..shader = RadialGradient(
            colors: [
              scheme.tertiary.withValues(alpha: AppOpacity.none),
              scheme.tertiary.withValues(alpha: AppOpacity.qiblaBeamAligned),
            ],
            stops: const [AppSize.qiblaBeamInner, AppOpacity.full],
          ).createShader(arcRect),
      );
    }

    final edgePaint = Paint()
      ..strokeWidth = AppStroke.hairline
      ..color = scheme.tertiary.withValues(
        alpha: aligned ? AppOpacity.supportingInk : AppOpacity.faintMark,
      );
    canvas.drawLine(
      center + _polar(-90 - _halfSweep) * innerRadius,
      center + _polar(-90 - _halfSweep) * arcRadius,
      edgePaint,
    );
    canvas.drawLine(
      center + _polar(-90 + _halfSweep) * innerRadius,
      center + _polar(-90 + _halfSweep) * arcRadius,
      edgePaint,
    );

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = aligned ? AppStroke.selected : AppStroke.arcTrack
      ..color = scheme.tertiary.withValues(
        alpha: aligned ? AppOpacity.full : AppOpacity.supportingInk,
      );
    if (aligned) {
      canvas.drawArc(
        arcRect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppStroke.selected
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            AppElevation.qiblaArcBlur,
          )
          ..color = scheme.tertiary.withValues(alpha: AppOpacity.pulseGlowDrop),
      );
    }
    canvas.drawArc(arcRect, start, sweep, false, arcPaint);
  }

  /// Degrees from the top of the dial, clockwise.
  static const double _halfSweep = qiblaAlignmentTolerance * math.pi / 180;

  static Offset _polar(double degrees, [double radius = 1]) {
    final radians = degrees * math.pi / 180;
    return Offset(math.cos(radians), math.sin(radians)) * radius;
  }

  @override
  bool shouldRepaint(covariant _DialFacePainter oldDelegate) =>
      oldDelegate.scheme != scheme || oldDelegate.aligned != aligned;
}

/// The Kaaba-tipped needle. Drawn pointing up; the widget above rotates it.
class _NeedlePainter extends CustomPainter {
  const _NeedlePainter({
    required this.scheme,
    required this.dimmed,
    required this.aligned,
  });

  final ColorScheme scheme;
  final bool dimmed;
  final bool aligned;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final opacity = dimmed ? AppOpacity.faintMark : AppOpacity.full;
    final ink = scheme.primary.withValues(alpha: opacity);
    final gold = scheme.tertiary.withValues(alpha: opacity);
    final tipY = -radius * AppSize.qiblaNeedleTip;
    final tailY = radius * AppSize.qiblaNeedleTail;
    final halfWidth = radius * AppSize.qiblaNeedleHalfWidth;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    final needleRect = Rect.fromLTRB(-halfWidth, tipY, halfWidth, tailY);
    final needle = Path()
      ..moveTo(0, tipY)
      ..lineTo(halfWidth, 0)
      ..lineTo(halfWidth * AppSize.qiblaNeedleWaist, tailY)
      ..lineTo(-halfWidth * AppSize.qiblaNeedleWaist, tailY)
      ..lineTo(-halfWidth, 0)
      ..close();
    canvas.drawPath(
      needle,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gold, ink],
          stops: const [AppOpacity.none, AppSize.qiblaNeedleGoldStop],
        ).createShader(needleRect),
    );

    // Counterweight: a small disc so the tail does not end in a needle point.
    canvas.drawCircle(
      Offset(0, tailY),
      halfWidth * AppSize.qiblaTailDot,
      Paint()..color = ink,
    );

    final cubeSize = radius * AppSize.qiblaCubeScale;
    final cube = Rect.fromCenter(
      center: Offset(0, tipY),
      width: cubeSize,
      height: cubeSize,
    );
    final cubeRRect = RRect.fromRectAndRadius(
      cube,
      Radius.circular(cubeSize * AppSize.qiblaCubeRadius),
    );

    if (aligned) {
      canvas.drawCircle(
        Offset(0, tipY),
        cubeSize * AppSize.qiblaCubeGlowOuter,
        Paint()..color = scheme.tertiary.withValues(alpha: AppOpacity.arcGlow),
      );
      canvas.drawCircle(
        Offset(0, tipY),
        cubeSize * AppSize.qiblaCubeGlowInner,
        Paint()..color = scheme.tertiary.withValues(alpha: AppOpacity.soft),
      );
    }

    canvas.drawRRect(cubeRRect, Paint()..color = gold);
    canvas.save();
    canvas.clipRRect(cubeRRect);
    canvas.drawRect(
      Rect.fromLTWH(
        cube.left,
        cube.top + cubeSize * AppSize.qiblaCubeBandTop,
        cubeSize,
        cubeSize * AppSize.qiblaCubeBand,
      ),
      Paint()..color = AppColors.deepInk.withValues(alpha: opacity),
    );
    canvas.restore();
    canvas.drawRRect(
      cubeRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.hairline
        ..color = AppColors.deepInk.withValues(
          alpha: AppOpacity.secondaryText * opacity,
        ),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter oldDelegate) =>
      oldDelegate.scheme != scheme ||
      oldDelegate.dimmed != dimmed ||
      oldDelegate.aligned != aligned;
}

/// Bearing and distance are the instrument's numeric readouts. At 200% text
/// they become two label/value rows instead of two cramped columns.
class _Readouts extends StatelessWidget {
  const _Readouts({
    required this.bearing,
    required this.distanceKm,
    required this.locale,
  });

  final double bearing;
  final double distanceKm;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat.decimalPattern(locale);
    final bearingDegrees = formatter.format(bearing.round());
    final distance = l10n.qiblaDistance(formatter.format(distanceKm.round()));
    final largeText =
        MediaQuery.textScalerOf(context).scale(AppFontSize.md) >
        AppFontSize.md * 1.3;

    final bearingReadout = _Readout(
      semanticsLabel: l10n.qiblaBearing(bearingDegrees),
      label: l10n.qiblaBearingLabel,
      value: '$bearingDegrees°',
      horizontal: largeText,
    );
    final distanceReadout = _Readout(
      semanticsLabel: distance,
      label: l10n.qiblaDistanceLabel,
      value: distance,
      horizontal: largeText,
    );

    if (largeText) {
      return Column(
        children: [
          bearingReadout,
          Divider(
            height: AppSpacing.lg,
            thickness: AppStroke.hairline,
            color: scheme.outlineVariant.withValues(alpha: AppOpacity.hairline),
          ),
          distanceReadout,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: bearingReadout),
        Container(
          width: AppStroke.hairline,
          height: AppSize.qiblaReadoutRule,
          color: scheme.outlineVariant.withValues(alpha: AppOpacity.hairline),
        ),
        Expanded(child: distanceReadout),
      ],
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({
    required this.semanticsLabel,
    required this.label,
    required this.value,
    required this.horizontal,
  });

  final String semanticsLabel;
  final String label;
  final String value;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valueStyle = Theme.of(context).textTheme.headlineSmall
        ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    final labelWidget = UiText(
      label.toUpperCase(),
      type: UiTextType.labelSmall,
      color: scheme.onSurfaceVariant,
      textAlign: horizontal ? TextAlign.start : TextAlign.center,
    );
    final valueWidget = FittedBox(
      fit: BoxFit.scaleDown,
      child: UiText(
        value,
        type: UiTextType.headlineSmall,
        style: valueStyle,
        fontWeight: AppWeight.semibold,
        textAlign: TextAlign.center,
      ),
    );

    final content = horizontal
        ? Row(
            children: [
              Expanded(child: labelWidget),
              const SizedBox(width: AppSpacing.md),
              Flexible(child: valueWidget),
            ],
          )
        : Column(
            children: [
              labelWidget,
              const SizedBox(height: AppSpacing.xxs),
              valueWidget,
            ],
          );

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: content,
        ),
      ),
    );
  }
}

/// Small gold cube that teaches the needle-tip marker.
class _KaabaLegend extends StatelessWidget {
  const _KaabaLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _KaabaMark(size: AppSpacing.md, color: scheme.tertiary),
        const SizedBox(width: AppSpacing.xs),
        UiText(
          l10n.qiblaKaaba,
          type: UiTextType.labelSmall,
          color: scheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _KaabaMark extends StatelessWidget {
  const _KaabaMark({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const bandColor = AppColors.deepInk;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * AppSize.qiblaCubeRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: color),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: size * AppSize.qiblaCubeBandTop),
                child: SizedBox(
                  width: size,
                  height: size * AppSize.qiblaCubeBand,
                  child: const ColoredBox(color: bandColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One status line for the live states, or a card when something needs an
/// explanation (no location, no sensor, calibration).
class _QiblaStatus extends ConsumerWidget {
  const _QiblaStatus({required this.status, required this.hasLocation});

  final CompassStatus status;
  final bool hasLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final guidance = ref.watch(qiblaControllerProvider.select(_readGuidance));

    if (!hasLocation) {
      return _StatusCard(
        icon: Icons.location_off_outlined,
        title: l10n.travelSetLocation,
        description: l10n.travelDesc,
        color: scheme.onSurfaceVariant,
      );
    }
    if (status == CompassStatus.unavailable) {
      return _StatusCard(
        icon: Icons.sensors_off_outlined,
        title: l10n.qiblaSensorUnavailable,
        description: l10n.qiblaSensorHint,
        color: scheme.onSurfaceVariant,
      );
    }
    if (status == CompassStatus.calibrating) {
      return _StatusCard(
        icon: Icons.all_inclusive,
        title: l10n.qiblaCalibrate,
        description: l10n.qiblaCompassHint,
        color: scheme.tertiary,
      );
    }
    if (guidance.aligned) {
      return _StatusLine(
        icon: Icons.check_circle_rounded,
        label: l10n.qiblaFacing,
        color: scheme.tertiary,
      );
    }
    return _StatusLine(
      icon: guidance.right ? Icons.turn_right_rounded : Icons.turn_left_rounded,
      label: guidance.right
          ? l10n.qiblaTurnRight('${guidance.degrees}')
          : l10n.qiblaTurnLeft('${guidance.degrees}'),
      caption: l10n.qiblaCompassHint,
      color: scheme.primary,
    );
  }
}

/// Quantised so the turn label does not rebuild on every compass sample.
typedef _QiblaGuidance = ({bool aligned, bool right, int degrees});

_QiblaGuidance _readGuidance(QiblaState state) {
  if (state.status != CompassStatus.available) {
    return (aligned: false, right: true, degrees: 0);
  }
  if (state.isAligned) {
    return (aligned: true, right: true, degrees: 0);
  }
  final angle = state.needleAngle;
  if (angle == null) {
    return (aligned: false, right: true, degrees: 0);
  }
  final degrees = ((angle.abs() / qiblaTurnStep).round() * qiblaTurnStep)
      .clamp(qiblaTurnStep, 180.0)
      .toInt();
  return (aligned: false, right: angle >= 0, degrees: degrees);
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.color,
    this.description,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIconSize.xl, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UiText(title, type: UiTextType.titleSmall),
                if (description != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  UiText(
                    description!,
                    type: UiTextType.labelMedium,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.label,
    required this.color,
    this.caption,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Icon(icon, size: AppIconSize.xl, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Column(
              children: [
                UiText(
                  label,
                  type: UiTextType.titleSmall,
                  color: color,
                  textAlign: TextAlign.center,
                ),
                if (caption != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  UiText(
                    caption!,
                    type: UiTextType.labelSmall,
                    color: scheme.onSurfaceVariant,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
