import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/data/models/alarm_access.dart';
import 'package:mawaqit/data/services/background_scheduler.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:mawaqit/shared/components/section_header.dart';
import 'package:mawaqit/shared/components/settings_group.dart';
import 'package:mawaqit/shared/components/settings_row.dart';
import 'package:mawaqit/shared/ui/app_pill.dart';
import 'package:mawaqit/shared/ui/icon_badge.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// "Alarm reliability" — the system accesses the adhan and the pre-prayer card
/// depend on, each with its own grant screen.
///
/// Android hands these out in stages, behind different screens, and revokes them
/// silently: notifications off means no card at all, a missing exact-alarm grant
/// means the adhan is batched into a maintenance window, a missing full-screen
/// grant means the alarm never wakes the display, and a silenced phone with no
/// Do Not Disturb access simply swallows the call. Every row here is therefore
/// also an action — tap it and the matching system screen opens — and the state
/// is re-read on every return to the app, because that is the only moment it can
/// have changed.
///
/// Rendering is Android-only: the access list is a property of the Android
/// platform, so on desktop the block is simply absent.
class AlarmAccessSection extends ConsumerStatefulWidget {
  const AlarmAccessSection({super.key});

  @override
  ConsumerState<AlarmAccessSection> createState() => _AlarmAccessSectionState();
}

class _AlarmAccessSectionState extends ConsumerState<AlarmAccessSection>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Granting happens on a system screen, so the state can only change while
    // the app was away.
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
    }
  }

  AlarmAccess get _access => ref.read(notificationServiceProvider).alarmAccess;

  Future<void> _refresh() async {
    if (!mounted) return;
    final before = _access;
    final after = await ref
        .read(notificationServiceProvider)
        .refreshAlarmAccess();
    if (!mounted) return;
    setState(() {});
    // A newly granted access is only worth anything once the day is re-armed
    // with it — this is what turns a fix into a working reminder tonight.
    if (after != before && after.missing.length < before.missing.length) {
      final settings = ref.read(settingsProvider).value;
      if (settings == null) return;
      await BackgroundScheduler.rescheduleNow(settings);
      if (!mounted) return;
      _toast(
        after.canRingOnTime
            ? 'Done — today’s adhan and reminders are re-armed.'
            : 'Applied — today’s reminders are re-armed.',
      );
    }
  }

  Future<void> _request(AlarmPermission permission) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await ref
        .read(notificationServiceProvider)
        .requestAlarmAccess(permission);
    if (!opened) {
      // Nothing to grant on this Android release (e.g. full-screen intents
      // below 14) — no nagging, just leave the row as it is.
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${permission.label} is granted automatically on this Android '
            'version — nothing to do.',
          ),
        ),
      );
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final access = _access;
    final missing = access.missing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          label: 'Alarm reliability',
          description: access.canRingOnTime
              ? 'The adhan can ring on time and wake your screen'
              : 'The adhan can be late or silent without these',
          icon: Icons.shield_moon_outlined,
        ),
        SettingsGroup(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxxl,
                AppSpacing.xxl,
                AppSpacing.xxxl,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  IconBadge(
                    icon: missing.isEmpty
                        ? Icons.verified_outlined
                        : Icons.warning_amber_rounded,
                    color: missing.isEmpty
                        ? scheme.primary.withValues(alpha: 0.1)
                        : scheme.error.withValues(alpha: 0.1),
                    foregroundColor: missing.isEmpty
                        ? scheme.primary
                        : scheme.error,
                  ),
                  const SizedBox(width: AppSpacing.xxl),
                  Expanded(
                    child: UiText(
                      missing.isEmpty
                          ? 'All alarm accesses granted'
                          : '${missing.length} of ${AlarmPermission.values.length} '
                                'accesses are off — the adhan can ring late, '
                                'stay silent, or not show at all. Tap a row to '
                                'fix it.',
                      type: UiTextType.labelMedium,
                      color: missing.isEmpty
                          ? scheme.onSurfaceVariant
                          : scheme.error,
                    ),
                  ),
                ],
              ),
            ),
            for (final permission in AlarmPermission.values)
              SettingsRow(
                icon: permission.icon,
                title: permission.label,
                subtitle: permission.blurb,
                subtitleColor: access.granted(permission)
                    ? scheme.primary
                    : scheme.error,
                onTap: () => _request(permission),
                trailing: _status(permission, access),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.mega),
      ],
    );
  }

  Widget _status(AlarmPermission permission, AlarmAccess access) {
    final scheme = Theme.of(context).colorScheme;
    final granted = access.granted(permission);
    return AppPill(
      label: granted ? 'Allowed' : 'Fix',
      icon: granted ? Icons.check_circle_outline : Icons.open_in_new,
      dense: true,
      color: granted ? scheme.primary : scheme.error,
    );
  }
}
