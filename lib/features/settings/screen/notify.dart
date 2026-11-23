import 'package:flutter/material.dart';

import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/data/models/notification_kind.dart';
import 'package:mawaqit/features/settings/screen/prayer_schedule.dart';
import 'package:mawaqit/features/settings/widgets/notification_settings_section.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/components/section_header.dart';
import 'package:mawaqit/shared/components/settings_group.dart';
import 'package:mawaqit/shared/components/settings_row.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Settings → Notifications.
///
/// The pre-prayer reminder and the adhan each get their own block — kill switch,
/// tone picker, lead time and a 3-second test — so the two alert types stay
/// independent and the pattern is learned once.
///
/// Pushed from the main settings list, so it renders its own [Scaffold] and
/// [AppBar] with a back button.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        centerTitle: true,
        title: UiText(
          l10n.settingsSectionNotifications,
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
                label: l10n.settingsSectionNotifications,
                description: l10n.settingsNotificationsDesc,
                icon: Icons.notifications_none,
              ),
              const SettingsGroup(
                children: [
                  NotificationSettingsSection(kind: NotificationKind.prePrayer),
                  NotificationSettingsSection(kind: NotificationKind.adhan),
                ],
              ),
              const SizedBox(height: AppSpacing.mega),
              SectionHeader(
                label: l10n.scheduleTitle,
                description: l10n.scheduleSectionDesc,
                icon: Icons.event_repeat_outlined,
              ),
              SettingsGroup(
                children: [
                  SettingsRow(
                    icon: Icons.event_note_outlined,
                    title: l10n.scheduleRowTitle,
                    subtitle: l10n.scheduleRowSubtitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PrayerScheduleScreen(),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: AppIconSize.xl,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
