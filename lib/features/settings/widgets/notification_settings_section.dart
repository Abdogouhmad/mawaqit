import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/notification_kind.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/features/settings/widgets/tone_sheet.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:mawaqit/shared/widgets/segmented_control.dart';
import 'package:mawaqit/shared/widgets/settings_row.dart';

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

  static const List<(int, String)> _leadOptions = [
    (5, '5 min'),
    (10, '10 min'),
    (15, '15 min'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsProvider);
    final settings = asyncSettings.value;
    if (settings == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
              Container(
                width: AppSpacing.control,
                height: AppSpacing.control,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.secondaryContainer.withValues(alpha: 0.55),
                ),
                child: Icon(
                  icon,
                  size: AppIconSize.lg,
                  color: scheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kind.label,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      enabled ? _enabledHint : kind.offHint,
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
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
            title: '${kind.label} Tone',
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
            title: 'Test ${kind.label}',
            subtitle: kind == NotificationKind.adhan
                ? 'Fires the full-screen alarm in 3 seconds'
                : 'Fires the reminder in 3 seconds',
            onTap: () => _fireTest(context, ref, settings),
            trailing: const Icon(Icons.chevron_right, size: AppIconSize.xl),
          ),
        ],
      ],
    );
  }

  String get _enabledHint => kind == NotificationKind.prePrayer
      ? 'Reminds you before each prayer'
      : 'Rings the adhan at prayer entry';

  Widget _disabledNote(BuildContext context) {
    return Text(
      kind == NotificationKind.prePrayer
          ? 'Turn on to get countdown reminders before each prayer.'
          : 'Turn on to make the full adhan ring at every prayer time.',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  /// Lead-time picker — only meaningful for the pre-prayer countdown.
  Widget _prePrayerLead(
    BuildContext context,
    SettingsController controller,
    AppSettings settings,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Remind me before',
              style: textTheme.titleMedium?.copyWith(fontSize: AppFontSize.lg),
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
              child: Text(
                '${settings.leadMinutes} min before',
                key: ValueKey(settings.leadMinutes),
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
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
          options: _leadOptions,
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
    final service = ref.read(notificationServiceProvider);
    if (!settings.notifEnabled(kind)) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${kind.label} notifications are off — flip the switch above then '
            'tap again.',
          ),
        ),
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
          const SnackBar(
            content: Text(
              'Notification access is off — allow notifications for Mawaqit '
              'in system Settings, then tap again.',
            ),
          ),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            kind == NotificationKind.adhan
                ? service.canUseFullScreenIntents
                      ? 'Adhan alarm fires in 3 seconds — full-screen, over the lockscreen.'
                      : 'Adhan fires in 3 seconds (heads-up — full-screen '
                            'access is off in system Settings).'
                : 'Pre-prayer reminder fires in 3 seconds — ${settings.notifTone(kind)} will play.',
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('${kind.label} test failed: $e\n$st');
      messenger.showSnackBar(
        SnackBar(content: Text('${kind.label} test failed: $e')),
      );
    }
  }
}
