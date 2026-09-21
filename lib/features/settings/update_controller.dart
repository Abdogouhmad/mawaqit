import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ota_update/ota_update.dart';

import 'package:mawaqit/data/models/update_manifest.dart';
import 'package:mawaqit/data/services/update_service.dart';
import 'package:mawaqit/features/settings/services/app_info.dart';
import 'package:mawaqit/features/settings/update_store.dart';

final updateServiceProvider =
    Provider<UpdateService>((ref) => const UpdateService());

final updateStoreProvider = Provider<UpdateStore>((ref) => UpdateStore());

enum UpdateStatus { idle, checking, available, downloading, readyToInstall, error }

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
}

/// The update state surfaced to the UI.
class UpdateState {
  final UpdateStatus status;
  final UpdateManifest? manifest;
  final UpdateCheckResult? checkResult;
  final double? progress;
  final UpdateErrorCode? error;
  final String? errorDetail;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.manifest,
    this.checkResult,
    this.progress,
    this.error,
    this.errorDetail,
  });

  bool get hasUpdate =>
      checkResult == UpdateCheckResult.updateAvailable ||
      checkResult == UpdateCheckResult.updateMandatory;

  bool get isMandatory => checkResult == UpdateCheckResult.updateMandatory;

  UpdateState copyWith({
    UpdateStatus? status,
    UpdateManifest? manifest,
    UpdateCheckResult? checkResult,
    double? progress,
    UpdateErrorCode? error,
    String? errorDetail,
    bool clearError = false,
    bool clearManifest = false,
    bool clearCheckResult = false,
  }) {
    return UpdateState(
      status: status ?? this.status,
      manifest: clearManifest ? null : manifest ?? this.manifest,
      checkResult: clearCheckResult ? null : checkResult ?? this.checkResult,
      progress: progress ?? this.progress,
      error: clearError ? null : error ?? this.error,
      errorDetail: clearError ? null : errorDetail ?? this.errorDetail,
    );
  }
}

/// The single OTA update notifier driving the whole flow.
final updateProvider =
    NotifierProvider<UpdateNotifier, UpdateState>(UpdateNotifier.new);

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

  /// Hydrates the persisted "last checked" info (reads once, lazily).
  Future<void> hydrate() async {
    final store = ref.read(updateStoreProvider);
    final last = await store.lastUpdateCheck();
    final result = await store.lastUpdateCheckResult();
    if (last != null) {
      ref.read(lastUpdateCheckProvider.notifier).state = last;
    }
    if (result != null) {
      ref.read(lastUpdateCheckResultProvider.notifier).state = result;
    }
  }

  /// Triggers an update check. Silent on failure (never blocks startup).
  Future<void> checkForUpdates() async {
    state = state.copyWith(status: UpdateStatus.checking, clearError: true);

    final manifest = await ref.read(updateServiceProvider).fetchManifest();

    final outcome = ref.read(updateServiceProvider).check(
      manifest: manifest,
      currentVersionCode: AppInfo.buildNumber,
    );

    if (outcome == UpdateCheckResult.checkFailed) {
      // A failed check is still a check: persist the timestamp + "failed"
      // result so the user can tell "check failed" from "never checked".
      await ref.read(lastUpdateCheckProvider.notifier).markChecked();
      await ref.read(lastUpdateCheckResultProvider.notifier).markResult(outcome);
      state = state.copyWith(
        status: UpdateStatus.idle,
        checkResult: outcome,
        clearManifest: true,
      );
      return;
    }

    state = state.copyWith(
      status: UpdateStatus.available,
      manifest: manifest,
      checkResult: outcome,
      progress: null,
      clearError: true,
    );

    await ref.read(lastUpdateCheckProvider.notifier).markChecked();
    await ref.read(lastUpdateCheckResultProvider.notifier).markResult(outcome);
  }

  /// Downloads and installs the update. `ota_update` verifies the manifest's
  /// SHA-256 before anything is installed and hands off to Android's
  /// `PackageInstaller`, which takes over the screen mid-flow.
  Future<void> downloadAndInstall() async {
    final manifest = state.manifest;
    if (manifest == null) return;

    if (manifest.apkUrl.isEmpty) {
      state = state.copyWith(
        status: UpdateStatus.error,
        error: UpdateErrorCode.noBuild,
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
      switch (event.status) {
        case OtaStatus.DOWNLOADING:
          final progress = double.tryParse(event.value ?? '') ?? 0;
          state = state.copyWith(progress: (progress / 100).clamp(0, 1));
        case OtaStatus.INSTALLING:
          state = state.copyWith(status: UpdateStatus.readyToInstall, progress: 1);
        case OtaStatus.INSTALLATION_DONE:
          state = state.copyWith(
            status: UpdateStatus.idle,
            clearManifest: true,
            clearCheckResult: true,
          );
        case OtaStatus.ALREADY_RUNNING_ERROR:
          state = state.copyWith(
            status: UpdateStatus.error,
            error: UpdateErrorCode.downloadFailed,
            errorDetail: 'An update is already in progress.',
          );
        case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
          state = state.copyWith(
            status: UpdateStatus.error,
            error: UpdateErrorCode.install,
            errorDetail: 'Permission to install apps was denied.',
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