import 'package:flutter/material.dart';

import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Today's solar cycle as a single drawn arc — dawn on one edge, nightfall on
/// the other, and a sun marker where the day currently stands.
///
/// This is the Times tab's signature. A monthly table is a grid of numbers and
/// says nothing about *where in the day* the reader is; the arc restores that in
/// the one place the tab opens — the current month — and does it in the app's own
/// astronomical vocabulary rather than with another progress bar.
///
/// The painter is deliberately hairline and undecorated (feat.md's "Warm
/// Precision Minimalism"): a 2dp stroke, a solid sun, and nothing else. The
/// travelled portion is gold (the app's colour for solar facts, shared with the
/// month-shift card) over a neutral track.
class SolarArc extends StatelessWidget {
  const SolarArc({
    super.key,
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.dotColor,
    required this.rtl,
    this.height = 64,
  });

  /// Fraction of daylight elapsed, 0 (dawn) to 1 (dusk).
  final double progress;

  final Color trackColor;
  final Color progressColor;
  final Color dotColor;

  /// Mirrors the arc so dawn sits on the reading-start edge in both directions.
  final bool rtl;

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SolarArcPainter(
          progress: progress.clamp(0.0, 1.0),
          trackColor: trackColor,
          progressColor: progressColor,
          dotColor: dotColor,
          rtl: rtl,
        ),
      ),
    );
  }
}

class _SolarArcPainter extends CustomPainter {
  _SolarArcPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.dotColor,
    required this.rtl,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final Color dotColor;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Inset so the endpoint dots and the sun are never clipped by the box edge.
    const inset = 10.0;
    const apexInset = 10.0;
    final baseY = h - 8;
    final apexY = apexInset;

    double x(double v) => rtl ? w - v : v;

    final p0 = Offset(x(inset), baseY);
    final p1 = Offset(x(w - inset), baseY);
    // Control at the same x as the apex, pulled up so the quadratic's midpoint
    // (0.25*p0 + 0.5*control + 0.25*p1) lands exactly on the apex.
    final control = Offset(x(w / 2), 2 * apexY - baseY);

    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..quadraticBezierTo(control.dx, control.dy, p1.dx, p1.dy);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, track);

    // Endpoint ticks: the two horizons the arc is measured between.
    final horizon = Paint()..color = trackColor;
    canvas.drawCircle(p0, 2.5, horizon);
    canvas.drawCircle(p1, 2.5, horizon);

    final metric = path.computeMetrics().first;
    final total = metric.length;

    if (progress > 0) {
      final travelled = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(metric.extractPath(0, total * progress), travelled);
    }

    final tangent = metric.getTangentForOffset(total * progress);
    if (tangent != null) {
      final centre = tangent.position;
      canvas.drawCircle(
        centre,
        8,
        Paint()..color = dotColor.withValues(alpha: 0.18),
      );
      canvas.drawCircle(centre, 4.5, Paint()..color = dotColor);
    }
  }

  @override
  bool shouldRepaint(covariant _SolarArcPainter old) =>
      old.progress != progress ||
      old.rtl != rtl ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor ||
      old.dotColor != dotColor;
}

/// The current day, told through its solar cycle: today's Gregorian and Hijri
/// dates, the drawn arc, sunrise and sunset at the ends, and solar noon beneath.
///
/// Rendered only for the current month — see [TimesScreen] — because the arc is
/// about "now", and a lapsed or future month has no meaningful now.
class DaySolarCard extends StatelessWidget {
  const DaySolarCard({super.key, required this.day, required this.now});

  final PrayerDay day;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    final sunrise = day.sunrise;
    final sunset = day.sunset;
    final dayLength = sunset.difference(sunrise);
    final dayMs = dayLength.inMilliseconds;
    final elapsed = now.difference(sunrise).inMilliseconds;
    final progress = dayMs <= 0 ? 0.0 : (elapsed / dayMs).clamp(0.0, 1.0);

    final info = l10n.solarNoonDetail(
      TimeFormatter.clock(day.solarNoon),
      TimeFormatter.dayLength(dayLength),
    );

    return Semantics(
      label:
          '${l10n.timesHighlightedToday}, ${TimeFormatter.dateTitle(now)}, '
          '${l10n.timesSunrise} ${TimeFormatter.clock(sunrise)}, '
          '${l10n.sunset} ${TimeFormatter.clock(sunset)}, '
          '$info',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.jumbo,
          vertical: AppSpacing.jumbo,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.tertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                UiText(
                  l10n.timesHighlightedToday.toUpperCase(),
                  type: UiTextType.labelSmall,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1.4,
                ),
                const Spacer(),
                Flexible(
                  child: UiText(
                    TimeFormatter.hijri(now),
                    type: UiTextType.labelSmall,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                    letterSpacing: 0.1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            UiText(
              TimeFormatter.dateTitle(now),
              type: UiTextType.titleSmall,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: AppSpacing.md),
            SolarArc(
              progress: progress,
              trackColor: scheme.outlineVariant,
              progressColor: scheme.tertiary,
              dotColor: scheme.tertiary,
              rtl: rtl,
            ),
            Row(
              children: [
                // Each anchor gets half the row rather than its intrinsic width:
                // "Lever/Coucher du soleil" is wider than half a narrow phone at
                // large text scales, and a `Spacer` gave them unbounded width, so
                // the Row overflowed instead of the labels wrapping.
                Expanded(
                  child: _ArcAnchor(
                    time: TimeFormatter.clock(sunrise),
                    label: l10n.timesSunrise,
                    alignment: CrossAxisAlignment.start,
                  ),
                ),
                Expanded(
                  child: _ArcAnchor(
                    time: TimeFormatter.clock(sunset),
                    label: l10n.sunset,
                    alignment: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            UiText(
              info,
              type: UiTextType.labelSmall,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
              letterSpacing: 0.1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcAnchor extends StatelessWidget {
  const _ArcAnchor({
    required this.time,
    required this.label,
    required this.alignment,
  });

  final String time;
  final String label;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        UiText(
          time,
          type: UiTextType.titleSmall,
          fontWeight: FontWeight.w600,
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        ),
        const SizedBox(height: AppSpacing.xxs),
        UiText(
          label,
          type: UiTextType.labelSmall,
          color: scheme.onSurfaceVariant,
          letterSpacing: 0.3,
        ),
      ],
    );
  }
}
