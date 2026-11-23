import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mawaqit/core/const/prayer_keys.dart';
import 'package:mawaqit/core/navigation/app_shell.dart';
import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/features/home/home_controller.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:mawaqit/shared/components/section_header.dart';
import 'package:mawaqit/shared/components/settings_group.dart';
import 'package:mawaqit/shared/components/settings_row.dart';
import 'package:mawaqit/shared/ui/app_button.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';
import 'package:mawaqit/src/home_widget/prayer_widget.home_widget.dart';

/// Settings → Home-screen widget.
///
/// The launcher owns widget size, so this screen explains how to choose it
/// rather than offering a control that would do nothing. What it *can* own is
/// the snapshot content (Hijri line, quick-action hint) and the two quick
/// actions: opening Times and silencing the next adhan. Glance generates a
/// single root tap target, so per-button widget actions would need hand-written
/// native code; keeping them here makes them work on every Android version.
class WidgetSettingsScreen extends ConsumerWidget {
  const WidgetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncSettings = ref.watch(settingsProvider);
    final settings = asyncSettings.value;

    Future<void> refresh() async {
      await PrayerWidgetHomeWidget.updatePreview();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.widgetUpdateHint)));
    }

    Future<void> silenceNext() async {
      // A ringing alarm is stopped first: muting the *next* occurrence would
      // otherwise leave the current one playing and look like a broken button.
      await ref.read(notificationServiceProvider).stopAlarm();
      final home = ref.read(homeControllerProvider).value;
      final next = home?.nextPrayer;
      if (next == null) return;
      final id = PrayerKeys.occurrenceId(home!.now, next.kind);
      await ref.read(mutedPrayersProvider.notifier).toggle(id);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        centerTitle: true,
        title: UiText(
          l10n.widgetTitle,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                label: l10n.widgetTitle,
                description: l10n.widgetDesc,
                icon: Icons.widgets_outlined,
              ),
              SettingsGroup(
                children: [
                  SettingsRow(
                    icon: Icons.calendar_month_outlined,
                    title: l10n.widgetHijriDate,
                    subtitle: l10n.widgetHijriDate,
                    trailing: Switch(
                      value: settings?.widgetShowHijri ?? true,
                      onChanged: settings == null
                          ? null
                          : (value) => ref
                                .read(settingsProvider.notifier)
                                .save(
                                  settings.copyWith(widgetShowHijri: value),
                                ),
                    ),
                  ),
                  SettingsRow(
                    icon: Icons.bolt_outlined,
                    title: l10n.widgetQuickActions,
                    subtitle: l10n.widgetQuickActions,
                    trailing: Switch(
                      value: settings?.widgetShowQuickActions ?? true,
                      onChanged: settings == null
                          ? null
                          : (value) => ref
                                .read(settingsProvider.notifier)
                                .save(
                                  settings.copyWith(
                                    widgetShowQuickActions: value,
                                  ),
                                ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.mega),
              SectionHeader(
                label: l10n.widgetQuickActions,
                description: l10n.widgetSizeHint,
                icon: Icons.bolt_outlined,
              ),
              SettingsGroup(
                children: [
                  SettingsRow(
                    icon: Icons.calendar_month_outlined,
                    title: l10n.widgetOpenTimes,
                    onTap: () => context.go(AppRoutes.times),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: AppIconSize.xl,
                    ),
                  ),
                  SettingsRow(
                    icon: Icons.volume_off_outlined,
                    title: l10n.widgetSilenceAdhan,
                    onTap: silenceNext,
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: AppIconSize.xl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.mega),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiText(l10n.widgetSizeSmall, type: UiTextType.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    UiText(
                      l10n.widgetSizeHint,
                      type: UiTextType.labelMedium,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: l10n.widgetPreview,
                      icon: Icons.refresh_rounded,
                      variant: AppButtonVariant.tonal,
                      onPressed: refresh,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    UiText(
                      l10n.widgetPinHint,
                      type: UiTextType.labelMedium,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
