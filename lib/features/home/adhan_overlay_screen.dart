import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/services/notification_service.dart';
import 'package:mawaqit/shared/ui/app_button.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

class AdhanOverlayScreen extends StatefulWidget {
  const AdhanOverlayScreen({
    super.key,
    required this.title,
    this.notificationId,
  });

  final String title;
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

    _dismissSub = NotificationService.instance.alarmDismissed.listen((_) {
      if (mounted) {
        _stop();
      }
    });
  }

  @override
  void dispose() {
    _dismissSub?.cancel();
    super.dispose();
  }

  Future<void> _stop() async {
    if (_stopping) return;

    setState(() {
      _stopping = true;
    });

    try {
      await NotificationService.instance.stopAlarm(
        notificationId: widget.notificationId,
      );

      await Future.delayed(const Duration(milliseconds: 180));

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);

    final compact = size.height < 700;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _stop();
          }
        },
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                _Header(),

                Expanded(
                  child: _Content(title: widget.title, compact: compact),
                ),

                _BottomAction(
                  stopping: _stopping,
                  onStop: _stop,
                  compact: compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.graphic_eq_rounded,
                size: 18,
                color: scheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              UiText(
                'ADHAN',
                type: UiTextType.labelLarge,
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.title, required this.compact});

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AdhanIcon(compact: compact),

          SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),

          UiText(
            'IT IS TIME FOR',
            type: UiTextType.labelMedium,
            color: scheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),

          const SizedBox(height: 6),

          UiText(
            title,
            type: UiTextType.displaySmall,
            textAlign: TextAlign.center,
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            style: const TextStyle(height: 1, letterSpacing: -1),
          ),

          const SizedBox(height: 8),

          UiText(
            'The call to prayer is playing',
            type: UiTextType.bodyMedium,
            textAlign: TextAlign.center,
            color: scheme.onSurfaceVariant,
          ),

          SizedBox(height: compact ? AppSpacing.xl : AppSpacing.huge),

          const _ClockCard(),
        ],
      ),
    );
  }
}

class _AdhanIcon extends StatelessWidget {
  const _AdhanIcon({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final size = compact ? 112.0 : 132.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size * .42),
          topRight: Radius.circular(size * .25),
          bottomLeft: Radius.circular(size * .25),
          bottomRight: Radius.circular(size * .42),
        ),
      ),
      child: Center(
        child: Container(
          width: size * .62,
          height: size * .62,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications_active_rounded,
            color: scheme.onPrimary,
            size: size * .30,
          ),
        ),
      ),
    );
  }
}

class _ClockCard extends StatelessWidget {
  const _ClockCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const _LiveClock(),
    );
  }
}

class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        UiText(
          TimeFormatter.clock(_now),
          type: UiTextType.displayMedium,
          color: scheme.onSurface,
          fontWeight: FontWeight.w400,
          style: const TextStyle(height: 1, letterSpacing: -1.5),
        ),

        const SizedBox(height: 4),

        UiText(
          TimeFormatter.dateTitle(_now),
          type: UiTextType.bodySmall,
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.stopping,
    required this.onStop,
    required this.compact,
  });

  final bool stopping;
  final VoidCallback onStop;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        AppButton(
          label: 'Stop Adhan',
          icon: Icons.stop_rounded,
          loading: stopping,
          loadingLabel: 'Silencing…',
          onPressed: onStop,
          expanded: false,
          minHeight: compact ? 56 : 60,
          radius: AppRadius.lg,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volume_up_outlined,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            UiText(
              'Press a volume key to silence',
              type: UiTextType.bodySmall,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }
}
