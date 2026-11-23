import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/core/const/prayer_keys.dart';
import 'package:mawaqit/core/insights/prayer_insights.dart';
import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/l10n/enum_localization.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Local-only prayer insights, shown on the Times tab next to the monthly
/// shift card.
///
/// Every number comes from [PrayerInsights.forMonth], a pure function of the
/// marks in [prayerHistoryProvider]. There is deliberately no "sync" button,
/// no sign-in prompt and no device id: the privacy line at the bottom is a
/// statement of fact, not marketing copy.
class InsightsCard extends ConsumerWidget {
  const InsightsCard({super.key, required this.now, required this.today});

  /// One instant for the whole tab, so the streak and the mark states agree
  /// even across a midnight boundary.
  final DateTime now;

  /// Today's schedule, used only for the five toggle buttons. `null` before a
  /// location resolves, in which case the marking row is omitted rather than
  /// showing buttons that would have no prayer times to compare against.
  final PrayerDay? today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(prayerHistoryProvider).value ?? const [];
    final summary = PrayerInsights.forMonth(history, now);
    final controller = ref.read(prayerHistoryProvider.notifier);

    return AppCard(
      ambient: false,
      color: scheme.surfaceContainerLow,
      borderColor: scheme.outlineVariant,
      radius: AppRadius.xl,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiText(
            l10n.insightsTitle,
            type: UiTextType.labelSmall,
            fontWeight: AppWeight.bold,
            letterSpacing: AppTypeDetail.sectionLetterSpacing,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.xs),
          UiText(
            l10n.insightsSubtitle,
            type: UiTextType.labelSmall,
            color: scheme.onSurfaceVariant.withValues(
              alpha: AppOpacity.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (summary.isEmpty)
            UiText(
              l10n.insightsEmpty,
              type: UiTextType.bodySmall,
              color: scheme.onSurfaceVariant,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => _Metrics(
                summary: summary,
                availableWidth: constraints.maxWidth,
              ),
            ),
          if (today != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _MarkingRow(
              day: today!,
              isMarked: controller.isMarked,
              onToggle: (id, time) =>
                  controller.toggle(id, now: now, prayerTime: time),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outlined,
                size: AppIconSize.sm,
                color: scheme.onSurfaceVariant.withValues(
                  alpha: AppOpacity.secondaryText,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: UiText(
                  l10n.privacyLocalOnly,
                  type: UiTextType.labelSmall,
                  color: scheme.onSurfaceVariant.withValues(
                    alpha: AppOpacity.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The three figures laid out like the shift card's row: evenly sized cells,
/// wrapping only when the localized labels genuinely need more width.
class _Metrics extends StatelessWidget {
  const _Metrics({required this.summary, required this.availableWidth});

  final PrayerInsightSummary summary;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final values = <String, String>{
      l10n.insightsTotal: '${summary.total}',
      l10n.insightsOnTime: summary.onTimePercent == null
          ? '—'
          : l10n.insightsPercent(summary.onTimePercent!),
      l10n.insightsStreak: l10n.insightsDays(summary.streakDays),
    };
    final cellWidth = availableWidth / values.length;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final entry in values.entries)
          SizedBox(
            width: cellWidth - AppSpacing.md,
            child: Semantics(
              label: '${entry.key}: ${entry.value}',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  UiText(
                    entry.value,
                    type: UiTextType.titleMedium,
                    fontWeight: AppWeight.bold,
                    color: scheme.primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  UiText(
                    entry.key,
                    type: UiTextType.labelSmall,
                    color: scheme.onSurfaceVariant,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Five small toggles for today's prayers. Marking is manual and explicit —
/// the native "Prayed" notification action only dismisses a live update, and
/// inferring history from mutes or resolved markers would silently invent data.
class _MarkingRow extends StatelessWidget {
  const _MarkingRow({
    required this.day,
    required this.isMarked,
    required this.onToggle,
  });

  final PrayerDay day;
  final bool Function(String occurrenceId) isMarked;
  final Future<void> Function(String occurrenceId, DateTime time) onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final markedColor = scheme.primary;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final kind in PrayerKind.five)
          () {
            final time = day.prayer(kind)?.time;
            if (time == null) return const SizedBox.shrink();
            final id = PrayerKeys.occurrenceId(day.date, kind);
            final marked = isMarked(id);
            return Semantics(
              button: true,
              selected: marked,
              label: '${kind.localized(l10n)} — ${l10n.notifLiveActionPrayed}',
              child: InkWell(
                onTap: () => onToggle(id, time),
                borderRadius: BorderRadius.circular(AppRadius.chip),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    color: marked
                        ? markedColor.withValues(alpha: AppOpacity.accent)
                        : scheme.surfaceContainerHighest,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        marked ? Icons.check_circle : Icons.circle_outlined,
                        size: AppIconSize.sm,
                        color: marked ? markedColor : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      UiText(
                        kind.localized(l10n),
                        type: UiTextType.labelSmall,
                        color: marked ? markedColor : scheme.onSurfaceVariant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }(),
      ],
    );
  }
}
