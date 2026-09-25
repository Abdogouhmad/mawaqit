import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Quiet astronomical summary: solar noon, day length and sunset.
class SolarCard extends StatelessWidget {
  const SolarCard({super.key, required this.day});

  final PrayerDay day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                UiText(
                  'Solar Noon',
                  type: UiTextType.labelLarge,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: AppSpacing.xxs),
                UiText(
                  '${TimeFormatter.clock(day.solarNoon)}  •  Day length '
                  '${TimeFormatter.dayLength(dayLength)}',
                  type: UiTextType.labelSmall,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              UiText(
                'Sunset',
                type: UiTextType.labelLarge,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: AppSpacing.xxs),
              UiText(
                TimeFormatter.clock(day.sunset),
                type: UiTextType.labelSmall,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
