import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/colors.dart';
import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/services/notification_service.dart';

/// Full-screen adhan presenter (Rakiz-style): raised when the adhan fires while
/// the app is open, giving the call a room-consuming surface instead of a tray
/// toast. The tone itself is started by [`NotificationService`] (audioplayers,
/// alarm stream) — this screen only owns dismissal, which stops playback and
/// clears the mirroring tray notification. The route cannot be swiped away;
/// only the Stop control exits it.
class AdhanOverlayScreen extends StatefulWidget {
  const AdhanOverlayScreen({
    super.key,
    required this.title,
    this.notificationId,
  });

  /// Heads-up text, e.g. "Adhan — Maghrib" or "Test — Adhan".
  final String title;

  /// Tray notification (if any) to dismiss together with the alarm.
  final int? notificationId;

  @override
  State<AdhanOverlayScreen> createState() => _AdhanOverlayScreenState();
}

class _AdhanOverlayScreenState extends State<AdhanOverlayScreen> {
  DateTime _now = DateTime.now();
  Timer? _clock;
  bool _stopping = false;

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

  Future<void> _stop() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    await NotificationService.instance.stopAlarm(
      notificationId: widget.notificationId,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepInk,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _stop();
        },
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              const Icon(
                Icons.notifications_active_rounded,
                size: 88,
                color: AppColors.radiantSage,
              ),
              const SizedBox(height: AppSpacing.blockLg),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.headline,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: AppSpacing.giga),
              Text(
                TimeFormatter.clock(_now),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.displayLg,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: AppSpacing.mega),
              Text(
                'Adhan — prayer time',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: AppFontSize.lg,
                ),
              ),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.block,
                  vertical: AppSpacing.block,
                ),
                child: FilledButton.icon(
                  onPressed: _stopping ? null : _stop,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(
                      AppSpacing.control + AppSpacing.xl,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sheet),
                    ),
                    textStyle: const TextStyle(
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: _stopping
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        )
                      : const Icon(Icons.stop_rounded, size: 22),
                  label: Text(_stopping ? 'Stopping…' : 'Stop alarm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}