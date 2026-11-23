import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/core/const/prayer_keys.dart';
import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_schedule.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/l10n/enum_localization.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/components/section_header.dart';
import 'package:mawaqit/shared/components/settings_row.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/app_pill.dart';
import 'package:mawaqit/shared/ui/option_sheet.dart';
import 'package:mawaqit/shared/ui/segmented_control.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Settings → Notifications → Prayer schedule.
///
/// Adhan 2.0 moves the "when and how" of each call from one global rule to five
/// independent, persisted choices. The editor deliberately writes through the
/// same [SettingsController] as every other preference: its reschedule gate
/// already watches [AppSettings.prayerSchedules], so a change here re-arms the
/// very occurrence the user just edited instead of waiting for tomorrow.
class PrayerScheduleScreen extends ConsumerWidget {
  const PrayerScheduleScreen({super.key});

  static const int offsetStepMinutes = 5;
  static const int summaryLabelFlex = 2;
  static const int summaryValueFlex = 3;

  /// Reminder leads offered per prayer. `null` means "follow the global lead";
  /// zero is a distinct choice that switches this prayer's card off.
  static const List<int?> reminderChoices = [null, 0, 5, 10, 15, 20, 30];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        centerTitle: true,
        title: UiText(
          l10n.scheduleTitle,
          type: UiTextType.titleLarge,
          fontWeight: AppWeight.bold,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.huge,
            AppSpacing.sm,
            AppSpacing.huge,
            AppSpacing.pageBottom,
          ),
          child: settings == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      label: l10n.scheduleTitle,
                      description: l10n.scheduleSectionDesc,
                      icon: Icons.event_repeat_outlined,
                    ),
                    _WeeklySummary(settings: settings),
                    const SizedBox(height: AppSpacing.mega),
                    for (final kind in PrayerKind.five) ...[
                      _PrayerCard(kind: kind, settings: settings),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _WeeklySummary extends StatelessWidget {
  const _WeeklySummary({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: AppIconSize.lg,
                color: scheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: UiText(
                  l10n.scheduleWeeklyTitle,
                  type: UiTextType.titleMedium,
                  fontWeight: AppWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          UiText(
            l10n.scheduleWeeklyNote,
            type: UiTextType.labelMedium,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final (index, kind) in PrayerKind.five.indexed) ...[
            if (index > 0)
              Divider(
                height: AppStroke.hairline,
                color: scheme.outlineVariant.withValues(
                  alpha: AppOpacity.hairline,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: PrayerScheduleScreen.summaryLabelFlex,
                    child: UiText(
                      kind.localized(l10n),
                      type: UiTextType.bodyLarge,
                      fontWeight: AppWeight.semibold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: PrayerScheduleScreen.summaryValueFlex,
                    child: UiText(
                      _summaryLine(context, settings, kind),
                      type: UiTextType.labelMedium,
                      color: scheme.onSurfaceVariant,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _summaryLine(
    BuildContext context,
    AppSettings settings,
    PrayerKind kind,
  ) {
    final l10n = AppLocalizations.of(context);
    final schedule = settings.scheduleFor(kind);
    if (!schedule.enabled) {
      return l10n.scheduleSummaryOff(kind.localized(l10n));
    }
    final mode = schedule.mode == AdhanMode.full
        ? l10n.scheduleModeFull
        : l10n.scheduleModeSilent;
    final offset = l10n.notifLeadShort(schedule.adhanOffsetMinutes);
    final reminder = schedule.reminderLeadMinutes == null
        ? l10n.scheduleReminderGlobal(settings.leadMinutes)
        : schedule.reminderLeadMinutes == 0
        ? l10n.scheduleReminderOff
        : l10n.scheduleReminderCustom(schedule.reminderLeadMinutes!);
    return l10n.scheduleSummaryEnabled(
      kind.localized(l10n),
      mode,
      offset,
      reminder,
    );
  }
}

class _PrayerCard extends ConsumerWidget {
  const _PrayerCard({required this.kind, required this.settings});

  final PrayerKind kind;
  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final schedule = settings.scheduleFor(kind);
    final id = PrayerKeys.id(kind);

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UiText(
                        kind.localized(l10n),
                        type: UiTextType.titleMedium,
                        fontWeight: AppWeight.bold,
                      ),
                      UiText(
                        l10n.scheduleEnabledLabel,
                        type: UiTextType.labelMedium,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('schedule_${id}_reset'),
                  tooltip: l10n.scheduleResetTooltip,
                  icon: const Icon(Icons.restart_alt_outlined),
                  color: scheme.onSurfaceVariant,
                  iconSize: AppIconSize.xl,
                  onPressed: () => _save(
                    ref,
                    settings.withPrayerSchedule(kind, const PrayerSchedule()),
                  ),
                ),
                Switch(
                  key: Key('schedule_${id}_enabled'),
                  value: schedule.enabled,
                  onChanged: (value) => _save(
                    ref,
                    settings.withPrayerSchedule(
                      kind,
                      schedule.copyWith(enabled: value),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Opacity(
            opacity: schedule.enabled ? AppOpacity.full : AppOpacity.disabled,
            child: IgnorePointer(
              ignoring: !schedule.enabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Divider(
                    height: AppStroke.hairline,
                    color: scheme.outlineVariant.withValues(
                      alpha: AppOpacity.hairline,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: UiText(
                                l10n.scheduleOffsetLabel,
                                type: UiTextType.titleSmall,
                              ),
                            ),
                            AppPill(
                              label: l10n.notifLeadShort(
                                schedule.adhanOffsetMinutes,
                              ),
                              dense: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            IconButton(
                              key: Key('schedule_${id}_earlier'),
                              tooltip: l10n.scheduleOffsetEarlier,
                              icon: const Icon(Icons.remove_circle_outline),
                              color: scheme.primary,
                              iconSize: AppIconSize.xl,
                              onPressed: () => _changeOffset(ref, -1),
                            ),
                            Expanded(
                              child: UiText(
                                l10n.scheduleOffsetLabel,
                                type: UiTextType.labelMedium,
                                color: scheme.onSurfaceVariant,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              key: Key('schedule_${id}_later'),
                              tooltip: l10n.scheduleOffsetLater,
                              icon: const Icon(Icons.add_circle_outline),
                              color: scheme.primary,
                              iconSize: AppIconSize.xl,
                              onPressed: () => _changeOffset(ref, 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        UiText(
                          l10n.scheduleModeLabel,
                          type: UiTextType.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SegmentedControl<AdhanMode>(
                          key: Key('schedule_${id}_mode'),
                          value: schedule.mode,
                          onChanged: (mode) => _save(
                            ref,
                            settings.withPrayerSchedule(
                              kind,
                              schedule.copyWith(mode: mode),
                            ),
                          ),
                          options: [
                            (AdhanMode.full, l10n.scheduleModeFull),
                            (AdhanMode.silent, l10n.scheduleModeSilent),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SettingsRow(
                    key: Key('schedule_${id}_reminder'),
                    icon: Icons.alarm_add_outlined,
                    title: l10n.scheduleReminderLabel,
                    subtitle: _reminderLabel(l10n, schedule),
                    onTap: () => _pickReminder(context, ref, schedule),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: AppIconSize.xl,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _reminderLabel(AppLocalizations l10n, PrayerSchedule schedule) {
    final lead = schedule.reminderLeadMinutes;
    if (lead == null) {
      return l10n.scheduleReminderGlobal(settings.leadMinutes);
    }
    if (lead == 0) return l10n.scheduleReminderOff;
    return l10n.scheduleReminderCustom(lead);
  }

  void _changeOffset(WidgetRef ref, int direction) {
    final schedule = settings.scheduleFor(kind);
    _save(
      ref,
      settings.withPrayerSchedule(
        kind,
        schedule.copyWith(
          adhanOffsetMinutes: PrayerSchedule.clampOffset(
            schedule.adhanOffsetMinutes +
                direction * PrayerScheduleScreen.offsetStepMinutes,
          ),
        ),
      ),
    );
  }

  Future<void> _pickReminder(
    BuildContext context,
    WidgetRef ref,
    PrayerSchedule schedule,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showOptionSheet<int?>(
      context: context,
      title: l10n.scheduleReminderLabel,
      current: schedule.reminderLeadMinutes,
      options: PrayerScheduleScreen.reminderChoices,
      label: (minutes) => switch (minutes) {
        null => l10n.scheduleReminderGlobal(settings.leadMinutes),
        0 => l10n.scheduleReminderOff,
        final value => l10n.scheduleReminderCustom(value),
      },
    );
    if (!context.mounted || selected == schedule.reminderLeadMinutes) return;
    _save(
      ref,
      settings.withPrayerSchedule(
        kind,
        schedule.copyWith(
          reminderLeadMinutes: selected,
          clearReminderLead: selected == null,
        ),
      ),
    );
  }

  void _save(WidgetRef ref, AppSettings next) {
    ref.read(settingsProvider.notifier).save(next);
  }
}
