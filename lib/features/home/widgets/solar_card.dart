import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/shared/widgets/app_card.dart';

/// Quiet astronomical summary: solar noon, day length and sunset.
class SolarCard extends StatelessWidget {
  const SolarCard({super.key, required this.day});

  final PrayerDay day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dayLength = day.sunset.difference(day.sunrise);

    return AppCard(
      ambient: false,
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.jumbo,
        vertical: AppSpacing.xxxl,
      ),
      child: Row(
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            size: AppIconSize.xl,
            color: scheme.primary,
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solar Noon',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${TimeFormatter.clock(day.solarNoon)}  •  Day length '
                  '${TimeFormatter.dayLength(dayLength)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Sunset',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                TimeFormatter.clock(day.sunset),
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
