import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/colors.dart';
import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/services/notification_service.dart';
import 'package:mawaqit/shared/widgets/app_button.dart';
import 'package:mawaqit/shared/widgets/app_text.dart';

/// Full-screen adhan presenter (Rakiz-style): raised when the adhan fires while
/// the app is open, giving the call a room-consuming surface instead of a tray
/// toast. The tone itself is started by [`NotificationService`] (audioplayers,
/// looping on the alarm stream) — this screen only owns dismissal, which stops
/// playback and clears the mirroring tray notification. The route cannot be
/// swiped away; it exits via the on-screen Stop control or the device
/// volume/side buttons (native → service → [alarmDismissed]).
class AdhanOverlayScreen extends StatefulWidget {
  const AdhanOverlayScreen({
    super.key,
    required this.title,
    this.notificationId,
  });

  /// Headline text — just the occurrence ("Maghrib", "Test"); the "ADHAN"
  /// eyebrow above it carries the context, matching the native lockscreen UI.
  final String title;

  /// Tray notification (if any) to dismiss together with the alarm.
  final int? notificationId;

  @override
  State<AdhanOverlayScreen> createState() => _AdhanOverlayScreenState();
}

class _AdhanOverlayScreenState extends State<AdhanOverlayScreen> {
  StreamSubscription<void>? _dismissSub;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    // Close when the alarm is stopped externally — the volume/side buttons
    // route through NotificationService and emit on [alarmDismissed].
    _dismissSub = NotificationService.instance.alarmDismissed.listen((_) {
      if (mounted) _stop();
    });
  }

  @override
  void dispose() {
    _dismissSub?.cancel();
    super.dispose();
  }

  Future<void> _stop() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    try {
      await NotificationService.instance.stopAlarm(
        notificationId: widget.notificationId,
      );
      // Small delay so the loading state is perceived and the native service
      // fully tears down before the route pops.
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // Fallback: if stopping fails, still allow the user to exit.
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _stop();
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.darkForest, AppColors.deepInk],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  // Soft halo behind the bell — mirrors the native lockscreen
                  // activity so both presenters read as the same screen.
                  Center(
                    child: Container(
                      width: AppSpacing.offsetLg + AppSpacing.huge,
                      height: AppSpacing.offsetLg + AppSpacing.huge,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryDark.withValues(alpha: 0.18),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        size: AppIconSize.display,
                        color: AppColors.radiantSage,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppText.eyebrow(
                    context,
                    'ADHAN',
                    color: AppColors.radiantSage,
                    tracking: 6,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppFontSize.displaySm,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const Spacer(flex: 1),
                  const _AlarmClock(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Tap Stop or press either volume key\nto silence the call',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: AppFontSize.sm,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: AppButton(
                      label: 'Stop Adhan',
                      icon: Icons.stop_rounded,
                      loading: _stopping,
                      loadingLabel: 'Silencing…',
                      onPressed: _stop,
                      minHeight: 64,
                      radius: AppRadius.xxl,
                      backgroundColor: AppColors.radiantSage,
                      foregroundColor: AppColors.deepInk,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Live clock + date for the alarm presenter — the only widgets that rebuild
/// on the per-second ticker.
class _AlarmClock extends StatefulWidget {
  const _AlarmClock();

  @override
  State<_AlarmClock> createState() => _AlarmClockState();
}

class _AlarmClockState extends State<_AlarmClock> {
  DateTime _now = DateTime.now();
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          TimeFormatter.clock(_now),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppFontSize.displayLg,
            fontWeight: FontWeight.w200,
            letterSpacing: -1.5,
            height: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          TimeFormatter.dateTitle(_now),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: AppFontSize.md,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}