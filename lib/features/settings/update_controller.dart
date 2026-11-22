import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/data/models/update_channel.dart';
import 'package:mawaqit/data/models/update_manifest.dart';
import 'package:mawaqit/data/services/notification_service.dart';
import 'package:mawaqit/data/services/update_service.dart';
import 'package:mawaqit/features/settings/services/app_info.dart';
import 'package:mawaqit/features/settings/update_store.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:ota_update/ota_update.dart';

final updateServiceProvider = Provider<UpdateService>(
  (ref) => const UpdateService(),
);

final updateStoreProvider = Provider<UpdateStore>((ref) => UpdateStore());

enum UpdateStatus {
  idle,
  checking,
  available,
  downloading,
  readyToInstall,
  error,
}

/// Failure kinds surfaced while [UpdateStatus.error]. The provider stores a
/// code (never a user-facing string — the UI maps it to copy).
enum UpdateErrorCode {
  /// The manifest points at an empty/invalid APK URL.
  noBuild,

  /// The download itself failed (network / transport).
  downloadFailed,

  /// The downloaded APK failed SHA-256 verification against the manifest.
  integrity,

  /// The system package installer rejected the APK.
  install,

  /// Another install/update was already running when this one started.
  alreadyRunning,

  /// The user declined the "install unknown apps" system prompt.
  permissionDenied,
}

/// The update state surfaced to the UI.
class UpdateState {
  final UpdateStatus status;
  final UpdateManifest? manifest;
  final UpdateCheckResult? checkResult;
  final double? progress;
  final UpdateErrorCode? error;
  final String? errorDetail;

  /// Version whose global announcement banner was dismissed.
  final String? dismissedVersion;

  /// Whether silent checks (launch / resume / timer) are enabled.
  final bool autoCheck;

  /// Cached POST_NOTIFICATIONS state, refreshed whenever the app resumes.
  final bool notificationsEnabled;

  /// Release channel being checked. Stable by default, persisted in [UpdateStore].
  final UpdateChannel channel;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.manifest,
    this.checkResult,
    this.progress,
    this.error,
    this.errorDetail,
    this.dismissedVersion,
    this.autoCheck = true,
    this.notificationsEnabled = false,
    this.channel = UpdateChannel.stable,
  });

  bool get hasUpdate =>
      checkResult == UpdateCheckResult.updateAvailable ||
      checkResult == UpdateCheckResult.updateMandatory;

  bool get isMandatory => checkResult == UpdateCheckResult.updateMandatory;

  bool get isChecking => status == UpdateStatus.checking;

  bool get isDownloading => status == UpdateStatus.downloading;

  UpdateState copyWith({
    UpdateStatus? status,
    UpdateManifest? manifest,
    UpdateCheckResult? checkResult,
    double? progress,
    UpdateErrorCode? error,
    String? errorDetail,
    String? dismissedVersion,
    bool? autoCheck,
    bool? notificationsEnabled,
    UpdateChannel? channel,
    bool clearError = false,
    bool clearManifest = false,
    bool clearCheckResult = false,
    bool clearErrorDetail = false,
    bool clearDismissedVersion = false,
  }) {
    return UpdateState(
      status: status ?? this.status,
      manifest: clearManifest ? null : manifest ?? this.manifest,
      checkResult: clearCheckResult ? null : checkResult ?? this.checkResult,
      progress: progress ?? this.progress,
      error: clearError ? null : error ?? this.error,
      // A `null` argument means "leave it alone", so switching to an error code
      // that renders its own sentence has to drop a detail left over from a
      // previous failure — otherwise a stale native exception string rides along.
      errorDetail: (clearError || clearErrorDetail)
          ? null
          : errorDetail ?? this.errorDetail,
      dismissedVersion: clearDismissedVersion
          ? null
          : dismissedVersion ?? this.dismissedVersion,
      autoCheck: autoCheck ?? this.autoCheck,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      channel: channel ?? this.channel,
    );
  }
}

/// The single OTA update notifier driving the whole flow.
final updateProvider = NotifierProvider<UpdateNotifier, UpdateState>(
  UpdateNotifier.new,
);

/// The `DateTime` of the last update check — `null` when never checked.
final lastUpdateCheckProvider =
    NotifierProvider<LastUpdateCheckNotifier, DateTime?>(
      LastUpdateCheckNotifier.new,
    );

/// Outcome of the most recent update check across launches.
final lastUpdateCheckResultProvider =
    NotifierProvider<LastUpdateCheckResultNotifier, UpdateCheckResult?>(
      LastUpdateCheckResultNotifier.new,
    );

class LastUpdateCheckNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  Future<void> markChecked() async {
    state = DateTime.now();
    await ref.read(updateStoreProvider).saveLastUpdateCheck();
  }
}

class LastUpdateCheckResultNotifier extends Notifier<UpdateCheckResult?> {
  @override
  UpdateCheckResult? build() => null;

  Future<void> markResult(UpdateCheckResult result) async {
    state = result;
    await ref.read(updateStoreProvider).saveLastUpdateCheckResult(result);
  }
}

class UpdateNotifier extends Notifier<UpdateState> {
  @override
  UpdateState build() => const UpdateState();

  UpdateStore get _store => ref.read(updateStoreProvider);

  NotificationService get _notifications =>
      ref.read(notificationServiceProvider);

  /// Hydrates the persisted bookkeeping (reads once, lazily).
  Future<void> hydrate() async {
    final last = await _store.lastUpdateCheck();
    final result = await _store.lastUpdateCheckResult();
    final dismissed = await _store.dismissedVersion();
    final autoCheck = await _store.autoCheckEnabled();
    final channel = await _store.channel();
    if (!ref.mounted) return;
    if (last != null) {
      ref.read(lastUpdateCheckProvider.notifier).state = last;
    }
    if (result != null) {
      ref.read(lastUpdateCheckResultProvider.notifier).state = result;
    }
    state = state.copyWith(
      dismissedVersion: dismissed,
      autoCheck: autoCheck,
      channel: channel,
    );
    await refreshNotificationPermission();
  }

  /// Triggers an update check.
  ///
  /// Silent checks ([userInitiated] `false`) are used by the launch/resume
  /// host: they never surface a transient network error and post an OS
  /// notification only for a newly discovered version.
  Future<void> checkForUpdates({bool userInitiated = true}) async {
    if (state.isChecking || state.isDownloading) return;

    final previousStatus = state.status;
    state = state.copyWith(status: UpdateStatus.checking, clearError: true);

    final service = ref.read(updateServiceProvider);
    final channel = state.channel;
    final manifest = await service.fetchManifest(channel: channel);
    if (!ref.mounted) return;

    final outcome = service.check(
      manifest: manifest,
      currentVersionCode: AppInfo.buildNumber,
      currentVersionName: AppInfo.version,
      channel: channel,
    );

    if (outcome == UpdateCheckResult.checkFailed) {
      // A failed check is still a check: persist the timestamp + "failed"
      // result so the user can tell "check failed" from "never checked".
      await ref.read(lastUpdateCheckProvider.notifier).markChecked();
      await ref
          .read(lastUpdateCheckResultProvider.notifier)
          .markResult(outcome);
      if (!ref.mounted) return;
      state = state.copyWith(
        // A silent failure must not replace a useful screen with an error.
        status: userInitiated ? UpdateStatus.idle : previousStatus,
        checkResult: userInitiated ? outcome : state.checkResult,
        clearManifest: userInitiated,
      );
      return;
    }

    state = state.copyWith(
      status: UpdateStatus.available,
      manifest: manifest,
      checkResult: outcome,
      clearError: true,
      dismissedVersion: await _store.dismissedVersion(),
    );

    await ref.read(lastUpdateCheckProvider.notifier).markChecked();
    await ref.read(lastUpdateCheckResultProvider.notifier).markResult(outcome);

    // Only a silent discovery announces itself; an explicit "Check now" is
    // already visible on screen and should not post a notification.
    if (!userInitiated) await _notifyIfNew(manifest);
  }

  /// Fires a "Mawaqit vX.Y.Z is available" notification the first time a given
  /// release is detected, then remembers it so re-checks stay silent.
  Future<void> _notifyIfNew(UpdateManifest? manifest) async {
    if (!state.autoCheck ||
        manifest == null ||
        !_hasRelease(state.checkResult)) {
      return;
    }
    try {
      if (await _store.lastUpdateNotifiedVersion() ==
          manifest.latestVersionName) {
        return;
      }
      await _notifications.init(allowPrompt: false);
      await _notifications.notifyUpdateAvailable(
        version: manifest.latestVersionName,
        releaseNotes: manifest.releaseNotes,
        isBeta: state.channel == UpdateChannel.beta,
      );
      await _store.saveLastUpdateNotifiedVersion(manifest.latestVersionName);
    } on Object catch (_) {
      // A failed notification must never surface as an update check error.
    }
  }

  static bool _hasRelease(UpdateCheckResult? outcome) =>
      outcome == UpdateCheckResult.updateAvailable ||
      outcome == UpdateCheckResult.updateMandatory;

  /// Cached notification permission, refreshed on every resume so a change
  /// made in Android settings is reflected in the update screen.
  Future<void> refreshNotificationPermission() async {
    try {
      await _notifications.refreshAlarmAccess();
      if (!ref.mounted) return;
      state = state.copyWith(
        notificationsEnabled: _notifications.alarmAccess.notifications,
      );
    } on Object catch (_) {
      // Permission state is cosmetic here; the banner always works.
    }
  }

  /// Requests POST_NOTIFICATIONS once, on the first automatic check.
  ///
  /// The flag is persisted *before* the await so a second resume cannot show
  /// the dialog twice. Declining never blocks the banner or a manual check.
  Future<void> maybePromptForNotifications() async {
    if (!state.autoCheck) return;
    if (await _store.notificationPromptShown()) {
      await refreshNotificationPermission();
      return;
    }
    await _store.markNotificationPromptShown();
    try {
      await _notifications.init();
      if (!ref.mounted) return;
      state = state.copyWith(
        notificationsEnabled: _notifications.alarmAccess.notifications,
      );
    } on Object catch (_) {
      // Ignored: the next launch can try again via Settings.
    }
  }

  /// Persists the automatic-check preference.
  Future<void> setAutoCheck({required bool enabled}) async {
    await _store.saveAutoCheck(enabled);
    if (!ref.mounted) return;
    state = state.copyWith(autoCheck: enabled);
    if (enabled) unawaited(maybePromptForNotifications());
  }

  /// Switches the release channel, persists the choice and re-checks at once.
  ///
  /// Clearing the dismissed version and stale release prevents a banner
  /// dismissed on one channel from hiding a release on the other. A switch is
  /// never a downgrade: Android refuses an older versionCode anyway, and the
  /// check reports "up to date" when the new channel has nothing newer.
  Future<void> setChannel(UpdateChannel channel) async {
    if (state.channel == channel) return;
    await _store.saveChannel(channel);
    await _store.clearDismissedVersion();
    if (!ref.mounted) return;
    state = state.copyWith(
      channel: channel,
      status: UpdateStatus.idle,
      clearManifest: true,
      clearCheckResult: true,
      clearDismissedVersion: true,
      clearError: true,
    );
    await checkForUpdates(userInitiated: false);
  }

  /// Hides the global banner for the currently offered version only.
  Future<void> dismissUpdateBanner() async {
    final version = state.manifest?.latestVersionName;
    if (version == null) return;
    await _store.saveDismissedVersion(version);
    if (!ref.mounted) return;
    state = state.copyWith(dismissedVersion: version);
  }

  /// Dismisses an active error and returns to idle or available.
  void dismissError() {
    state = state.copyWith(
      status: state.manifest != null
          ? UpdateStatus.available
          : UpdateStatus.idle,
      clearError: true,
    );
  }

  /// Downloads and installs the update. `ota_update` verifies the manifest's
  /// SHA-256 before anything is installed and hands off to Android's
  /// `PackageInstaller`, which takes over the screen mid-flow.
  Future<void> downloadAndInstall() async {
    final manifest = state.manifest;
    if (manifest == null) return;

    if (!manifest.isInstallable) {
      state = state.copyWith(
        status: UpdateStatus.error,
        error: manifest.apkUrl.isEmpty
            ? UpdateErrorCode.noBuild
            : UpdateErrorCode.integrity,
      );
      return;
    }

    Stream<OtaEvent> stream;
    try {
      stream = ref
          .read(updateServiceProvider)
          .downloadAndInstall(manifest: manifest);
    } catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        error: UpdateErrorCode.downloadFailed,
        errorDetail: e.toString(),
      );
      return;
    }

    state = state.copyWith(status: UpdateStatus.downloading, progress: 0);

    await for (final event in stream) {
      if (!ref.mounted) return;
      switch (event.status) {
        case OtaStatus.DOWNLOADING:
          final progress = double.tryParse(event.value ?? '') ?? 0;
          state = state.copyWith(progress: (progress / 100).clamp(0, 1));
        case OtaStatus.INSTALLING:
          state = state.copyWith(
            status: UpdateStatus.readyToInstall,
            progress: 1,
          );
        case OtaStatus.INSTALLATION_DONE:
          state = state.copyWith(
            status: UpdateStatus.idle,
            clearManifest: true,
            clearCheckResult: true,
          );
        // Both of these get their own error code rather than an English
        // `errorDetail`: the screen renders `errorDetail` straight into a
        // localized sentence, so prose here would leak into the Arabic UI.
        case OtaStatus.ALREADY_RUNNING_ERROR:
          state = state.copyWith(
            status: UpdateStatus.error,
            error: UpdateErrorCode.alreadyRunning,
            clearErrorDetail: true,
          );
        case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
          state = state.copyWith(
            status: UpdateStatus.error,
            error: UpdateErrorCode.permissionDenied,
            clearErrorDetail: true,
          );
        case OtaStatus.CHECKSUM_ERROR:
          state = state.copyWith(
            status: UpdateStatus.error,
            error: UpdateErrorCode.integrity,
            errorDetail: event.value,
          );
        case OtaStatus.INSTALLATION_ERROR:
          state = state.copyWith(
            status: UpdateStatus.error,
            error: UpdateErrorCode.install,
            errorDetail: event.value,
          );
        case OtaStatus.DOWNLOAD_ERROR:
        case OtaStatus.INTERNAL_ERROR:
          state = state.copyWith(
            status: UpdateStatus.error,
            error: UpdateErrorCode.downloadFailed,
            errorDetail: event.value,
          );
        case OtaStatus.CANCELED:
          state = state.copyWith(status: UpdateStatus.available);
      }
    }
  }
}
