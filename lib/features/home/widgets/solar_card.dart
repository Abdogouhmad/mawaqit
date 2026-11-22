import 'package:flutter/material.dart';
import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/app_list_row.dart';
import 'package:mawaqit/shared/ui/icon_badge.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Quiet astronomical summary: solar noon, day length and sunset.
///
/// Two [AppListRow]s in one card keep the solar figures aligned with the prayer
/// timeline above instead of inventing a second two-column layout.
class SolarCard extends StatelessWidget {
  const SolarCard({super.key, required this.day});

  final PrayerDay day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final dayLength = day.sunset.difference(day.sunrise);

    return AppCard(
      ambient: false,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          AppListRow(
            title: l10n.solarNoon,
            subtitle: l10n.solarNoonDetail(
              TimeFormatter.clock(day.solarNoon),
              TimeFormatter.dayLength(dayLength),
            ),
            leading: IconBadge(
              icon: Icons.wb_sunny_outlined,
              foregroundColor: scheme.primary,
            ),
            trailing: _Time(scheme.primary, TimeFormatter.clock(day.solarNoon)),
          ),
          Divider(
            height: AppStroke.hairline,
            indent: AppSpacing.xxxl + AppSpacing.control + AppSpacing.xxl,
            endIndent: AppSpacing.xxxl,
            color: scheme.outlineVariant.withValues(alpha: AppOpacity.hairline),
          ),
          AppListRow(
            title: l10n.sunset,
            subtitle: l10n.homeSunsetAt(TimeFormatter.clock(day.sunset)),
            leading: IconBadge(
              icon: Icons.wb_twilight,
              foregroundColor: scheme.primary,
            ),
            trailing: _Time(scheme.primary, TimeFormatter.clock(day.sunset)),
          ),
        ],
      ),
    );
  }
}

class _Time extends StatelessWidget {
  const _Time(this.color, this.time);

  final Color color;
  final String time;

  @override
  Widget build(BuildContext context) {
    return UiText(
      time,
      type: UiTextType.titleMedium,
      color: color,
      fontWeight: AppWeight.semibold,
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    );
  }
}
