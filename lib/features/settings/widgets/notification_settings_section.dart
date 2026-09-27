import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/notification_kind.dart';
import 'package:mawaqit/data/services/notification_service.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/features/settings/widgets/tone_sheet.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:mawaqit/shared/ui/icon_badge.dart';
import 'package:mawaqit/shared/ui/segmented_control.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';
import 'package:mawaqit/shared/components/settings_row.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/l10n/enum_localization.dart';

/// One reusable section for a notification type — **Pre-Prayer** and **Adhan**
/// both render this exact component parameterized by [kind], so the kill
/// switch, tone picker and 3-second test trigger share one implementation.
///
/// Composed inside a single Notifications card in the settings screen (no
/// `AppCard` of its own — the parent adds the surface and the hairline divider
/// between the two sections). The Adhan section additionally explains its
/// full-screen + volume-button alarm behaviour in the test row's subtitle.
class NotificationSettingsSection extends ConsumerWidget {
  const NotificationSettingsSection({super.key, required this.kind});

  final NotificationKind kind;

  /// The minute counts are fixed, but their labels are built per-build so they
  /// can follow the locale.
  static const List<int> _leadMinutes = [5, 10, 15];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsProvider);
    final settings = asyncSettings.value;
    if (settings == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(settingsProvider.notifier);
    final enabled = settings.notifEnabled(kind);
    final icon = kind == NotificationKind.prePrayer
        ? Icons.alarm_add_outlined
        : Icons.call_made_outlined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxxl,
            AppSpacing.xxxl,
            AppSpacing.xxxl,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              IconBadge(icon: icon),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiText(
                      kind.localized(AppLocalizations.of(context)),
                      type: UiTextType.titleMedium,
                      fontWeight: FontWeight.w700,
                    ),
                    UiText(
                      enabled
                          ? _enabledHint(context)
                          : kind.localizedOffHint(AppLocalizations.of(context)),
                      type: UiTextType.labelMedium,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  controller.save(settings.withNotifEnabled(kind, value));
                },
              ),
            ],
          ),
        ),
        if (!enabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxxl,
              0,
              AppSpacing.xxxl,
              AppSpacing.xxxl,
            ),
            child: _disabledNote(context),
          )
        else ...[
          if (kind == NotificationKind.prePrayer)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxxl,
                AppSpacing.sm,
                AppSpacing.xxxl,
                AppSpacing.xl,
              ),
              child: _prePrayerLead(context, controller, settings),
            ),
          SettingsRow(
            icon: Icons.music_note_outlined,
            title: AppLocalizations.of(context)
                .notifToneTitle(kind.localized(AppLocalizations.of(context))),
            subtitle: settings.notifTone(kind),
            onTap: () => _openToneSheet(context, controller, settings),
            trailing: const Icon(Icons.chevron_right, size: AppIconSize.xl),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
            child: Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          SettingsRow(
            icon: Icons.campaign_outlined,
            title: AppLocalizations.of(context)
                .notifTestAction(kind.localized(AppLocalizations.of(context))),
            subtitle: kind == NotificationKind.adhan
                ? AppLocalizations.of(context).notifTestAdhanSubtitle
                : AppLocalizations.of(context).notifTestPrePrayerSubtitle,
            onTap: () => _fireTest(context, ref, settings),
            trailing: const Icon(Icons.chevron_right, size: AppIconSize.xl),
          ),
        ],
      ],
    );
  }

  String _enabledHint(BuildContext context) =>
      kind == NotificationKind.prePrayer
      ? AppLocalizations.of(context).notifEnabledPrePrayerHint
      : AppLocalizations.of(context).notifEnabledAdhanHint;

  Widget _disabledNote(BuildContext context) {
    return UiText(
      kind == NotificationKind.prePrayer
          ? AppLocalizations.of(context).notifDisabledPrePrayerNote
          : AppLocalizations.of(context).notifDisabledAdhanNote,
      type: UiTextType.labelMedium,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      style: const TextStyle(fontStyle: FontStyle.italic),
    );
  }

  /// Lead-time picker — only meaningful for the pre-prayer countdown.
  Widget _prePrayerLead(
    BuildContext context,
    SettingsController controller,
    AppSettings settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            UiText(
              AppLocalizations.of(context).notifRemindMeBefore,
              type: UiTextType.titleMedium,
              fontSize: AppFontSize.lg,
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                ),
              ),
              child: UiText(
                '${settings.leadMinutes} min before',
                key: ValueKey(settings.leadMinutes),
                type: UiTextType.labelMedium,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SegmentedControl<int>(
          value: settings.leadMinutes,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            controller.save(settings.copyWith(leadMinutes: value));
          },
          options: [
            for (final m in _leadMinutes)
              (m, AppLocalizations.of(context).notifLeadShort(m)),
          ],
        ),
      ],
    );
  }

  void _openToneSheet(
    BuildContext context,
    SettingsController controller,
    AppSettings settings,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ToneSheet(
        controller: controller,
        initialSettings: settings,
        kind: kind,
      ),
    );
  }

  Future<void> _fireTest(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    // Resolved before the first await: the callbacks below run after the
    // scheduler round trip, where `context` may no longer be valid.
    final l10n = AppLocalizations.of(context);
    final kindLabel = kind.localized(l10n);
    final service = ref.read(notificationServiceProvider);
    if (!settings.notifEnabled(kind)) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.notifKindDisabledWarning(kindLabel))),
      );
      return;
    }
    try {
      await service.init();
      final armed = await service.scheduleTestNotification(
        kind: kind,
        settings: settings,
      );
      if (!armed) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.notifAccessWarning)),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(_testConfirmation(l10n, service, settings))),
      );
    } catch (e, st) {
      debugPrint('$kindLabel test failed: $e\n$st');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.notifTestFailed(kindLabel, '$e'))),
      );
    }
  }

  /// Which visual treatment the user is about to get, spelled out up front so a
  /// card-when-in-use result is not mistaken for the test having failed.
  String _testConfirmation(
    AppLocalizations l10n,
    NotificationService service,
    AppSettings settings,
  ) {
    if (kind == NotificationKind.prePrayer) {
      return l10n.notifTestPrePrayerTone(settings.notifTone(kind));
    }
    if (!service.canUseFullScreenIntents) return l10n.notifTestAdhanHeadsUp;
    if (!service.canShowOverOtherApps) return l10n.notifTestAdhanOverApps;
    return l10n.notifTestAdhanFull;
  }
}
