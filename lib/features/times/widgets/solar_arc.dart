import 'package:flutter/material.dart';
import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Today's solar cycle as one hairline arc: dawn at the reading-start edge,
/// nightfall at the other, and a sun marker where the day currently stands.
class SolarArc extends StatelessWidget {
  const SolarArc({
    super.key,
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.dotColor,
    required this.rtl,
    this.height = AppSize.solarArcHeight,
  });

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
    const inset = AppSpacing.lg;
    const apexInset = AppSpacing.lg;
    final baseY = h - AppSpacing.md;

    double x(double v) => rtl ? w - v : v;

    final p0 = Offset(x(inset), baseY);
    final p1 = Offset(x(w - inset), baseY);
    // Control at the apex x, pulled up so the quadratic midpoint lands on it.
    final control = Offset(x(w / 2), 2 * apexInset - baseY);

    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..quadraticBezierTo(control.dx, control.dy, p1.dx, p1.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.arcTrack
        ..strokeCap = StrokeCap.round,
    );

    final horizon = Paint()..color = trackColor;
    canvas.drawCircle(p0, AppSize.arcHorizonDot, horizon);
    canvas.drawCircle(p1, AppSize.arcHorizonDot, horizon);

    final metric = path.computeMetrics().first;
    final total = metric.length;

    if (progress > 0) {
      canvas.drawPath(
        metric.extractPath(0, total * progress),
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppStroke.spinner
          ..strokeCap = StrokeCap.round,
      );
    }

    final tangent = metric.getTangentForOffset(total * progress);
    if (tangent != null) {
      final centre = tangent.position;
      canvas.drawCircle(
        centre,
        AppSpacing.md,
        Paint()..color = dotColor.withValues(alpha: AppOpacity.arcGlow),
      );
      canvas.drawCircle(centre, AppSize.arcSunCore, Paint()..color = dotColor);
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

/// The current day told through its solar cycle: date, arc, sunrise/sunset and
/// solar noon. Rendered only for the current month — a lapsed or future month
/// has no meaningful "now".
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
      child: AppCard(
        ambient: false,
        color: scheme.surfaceContainerLow,
        borderColor: scheme.outlineVariant,
        radius: AppRadius.xl,
        padding: const EdgeInsets.all(AppSpacing.jumbo),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: AppSpacing.sm,
                  height: AppSpacing.sm,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.tertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                UiText(
                  l10n.timesHighlightedToday.toUpperCase(),
                  type: UiTextType.labelSmall,
                  fontWeight: AppWeight.bold,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: AppTypeDetail.sectionLetterSpacing,
                ),
                const Spacer(),
                Flexible(
                  child: UiText(
                    TimeFormatter.hijri(now),
                    type: UiTextType.labelSmall,
                    color: scheme.onSurfaceVariant.withValues(
                      alpha: AppOpacity.secondaryText,
                    ),
                    letterSpacing: AppTypeDetail.fineTracking,
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
              fontWeight: AppWeight.semibold,
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
              color: scheme.onSurfaceVariant.withValues(
                alpha: AppOpacity.supportingInk,
              ),
              letterSpacing: AppTypeDetail.fineTracking,
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
          fontWeight: AppWeight.semibold,
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        ),
        const SizedBox(height: AppSpacing.xxs),
        UiText(
          label,
          type: UiTextType.labelSmall,
          color: scheme.onSurfaceVariant,
          letterSpacing: AppTypeDetail.labelTracking,
        ),
      ],
    );
  }
}
