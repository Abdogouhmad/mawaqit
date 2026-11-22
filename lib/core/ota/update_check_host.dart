import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/features/settings/update_controller.dart';

/// Runs quiet update checks while Mawaqit is in the foreground.
///
/// Checks happen on mount, on every resume and every [checkInterval] while the
/// app is visible. There is deliberately no background service: an update is
/// discovered the next time the user opens the app, and a failed check stays
/// silent. Checks are throttled by the persisted last-check timestamp so a
/// quick app switch cannot turn into a stream of HTTP requests.
///
/// The host sits above the router so the launch check happens even on a deep
/// link or a pushed full-screen route.
class UpdateCheckHost extends ConsumerStatefulWidget {
  /// Creates the host around the root app.
  const UpdateCheckHost({
    required this.child,
    this.checkInterval = const Duration(minutes: 30),
    super.key,
  });

  /// Widget below the host, normally `MawaqitApp`.
  final Widget child;

  /// Minimum time between two automatic checks.
  final Duration checkInterval;

  @override
  ConsumerState<UpdateCheckHost> createState() => _UpdateCheckHostState();
}

class _UpdateCheckHostState extends ConsumerState<UpdateCheckHost>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Never mutate Riverpod state during the first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resumed();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _resumed();
        });
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _timer?.cancel();
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _resumed() {
    _timer?.cancel();
    _timer = Timer.periodic(
      widget.checkInterval,
      (_) => unawaited(_maybeCheck()),
    );
    if (!_hydrated) {
      _hydrated = true;
      unawaited(_firstCheck());
      return;
    }
    unawaited(_maybeCheck());
  }

  /// Restores persisted preferences before the first silent check so a
  /// dismissed version or a disabled auto-check is respected from frame one.
  Future<void> _firstCheck() async {
    final notifier = ref.read(updateProvider.notifier);
    await notifier.hydrate();
    if (!mounted) return;
    await _maybeCheck();
  }

  Future<void> _maybeCheck() async {
    final notifier = ref.read(updateProvider.notifier);
    final state = ref.read(updateProvider);
    if (!state.autoCheck || state.isChecking || state.isDownloading) return;

    final lastCheck = ref.read(lastUpdateCheckProvider);
    if (lastCheck != null &&
        DateTime.now().difference(lastCheck) < widget.checkInterval) {
      return;
    }

    // Never let the permission dialog delay the network check: the banner is
    // shown even when notifications are declined.
    unawaited(notifier.maybePromptForNotifications());
    await notifier.checkForUpdates(userInitiated: false);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
