import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/data/models/alarm_access.dart';
import 'package:mawaqit/data/services/alarm_access_prompt.dart';
import 'package:mawaqit/data/services/background_scheduler.dart';
import 'package:mawaqit/data/services/notification_service.dart';
import 'package:mawaqit/features/settings/services/app_info.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Asks once per build (so: on first install and after every update) for the
/// battery-optimisation exemption, and nothing else.
///
/// This is the single most common reason the adhan "doesn't work" on a phone that
/// has every other permission granted: the OEM power manager freezes Mawaqit as
/// soon as the screen locks, and an exact alarm that fires into a frozen process
/// is deferred to the next wake-up — the notification can land minutes to hours
/// late, or never. Nothing in the app can fix that silently, because Android
/// only grants the exemption from a system screen the user has to confirm.
///
/// The rest of the alarm accesses (notifications, exact alarms, full-screen,
/// Do Not Disturb) are left to the "Alarm reliability" block in Settings: they are
/// each a *page*, and stacking four pages on first launch is how an app loses
/// the user on the very first run. A dismissed ask is remembered for the build,
/// so Settings is the place to fix it later — with a row that says "Fix".
class AlarmAccessGate extends ConsumerStatefulWidget {
  const AlarmAccessGate({super.key});

  @override
  ConsumerState<AlarmAccessGate> createState() => _AlarmAccessGateState();
}

class _AlarmAccessGateState extends ConsumerState<AlarmAccessGate> {
  @override
  void initState() {
    super.initState();
    unawaited(_askOnce());
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  Future<void> _askOnce() async {
    // Android-only: the exemption is an Android concept, and on desktop the
    // app is never frozen in the first place.
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final service = ref.read(notificationServiceProvider);
    try {
      final access = await service.refreshAlarmAccess();

      final currentBuild = _currentBuild();
      final lastPrompted = await _store().lastPromptedBuild();
      if (!shouldAskForBatteryExemption(
        access: access,
        currentBuild: currentBuild,
        lastPromptedBuild: lastPrompted,
      )) {
        return;
      }

      // Marked *before* the ask: the decision to show it is what must not repeat,
      // so an interrupted dialog (rotation, a call, a killed process) cannot
      // turn into a loop.
      await _store().markPromptedBuild(currentBuild!);
      if (!mounted) return;
      await _prompt(access: access, service: service);
    } catch (e) {
      debugPrint('Battery-optimisation ask skipped: $e');
    }
  }

  /// The build the ask belongs to; null when the version is not available yet.
  int? _currentBuild() {
    try {
      return AppInfo.buildNumber;
    } catch (_) {
      return null;
    }
  }

  AlarmAccessPromptStore _store() => AlarmAccessPromptStore();

  Future<void> _prompt({
    required AlarmAccess access,
    required NotificationService service,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final allow = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.battery_charging_full_outlined, color: scheme.primary),
        title: const UiText(
          'Keep the adhan on time',
          type: UiTextType.titleLarge,
        ),
        content: const UiText(
          'Your phone freezes apps while the screen is locked, and that is '
          'usually why the adhan rings late — or not at all. Allowing Mawaqit '
          'to ignore battery optimisation keeps the adhan playing at prayer '
          'time, even in your pocket.',
          type: UiTextType.bodyMedium,
        ),
        actions: [
          TextButton(
            key: const Key('battery-exemption-later'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const UiText('Not now', type: UiTextType.labelLarge),
          ),
          TextButton(
            key: const Key('battery-exemption-allow'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: UiText(
              'Allow',
              type: UiTextType.labelLarge,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );

    if (allow != true) {
      // "Not now" is not a refusal: the row in Settings → Alarm reliability
      // still says "Fix", so this is only a first-run heads-up.
      return;
    }

    // Hands the user the system's own exemption dialog. The state is re-read on
    // the way back, and a granted exemption re-arms the day so tonight is
    // already protected.
    await service.requestAlarmAccess(AlarmPermission.battery);

    final after = await service.refreshAlarmAccess();
    if (after.battery == access.battery) return;

    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;
    await BackgroundScheduler.rescheduleNow(settings);
  }
}
