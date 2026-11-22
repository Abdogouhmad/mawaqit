import 'package:mawaqit/data/models/update_channel.dart';
import 'package:mawaqit/data/services/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the OTA updater's bookkeeping across launches
/// (SharedPreferences, matching [SettingsRepository]).
///
/// Everything the check host needs to stay quiet is stored here so a restart
/// cannot re-offer a release the user already dismissed or re-post its
/// notification.
class UpdateStore {
  static const String kLastUpdateCheckKey = 'last_update_check_ms';
  static const String kLastUpdateCheckResultKey = 'last_update_check_result';

  /// Latest release the user was already alerted about, so the push-notify
  /// fires exactly once per version (brewline-style `kLastUpdateNotifiedKey`).
  static const String kLastUpdateNotifiedKey = 'last_update_notified_version';

  /// Version whose global banner was dismissed. A newer version brings it back.
  static const String kDismissedVersionKey = 'update_dismissed_version';

  /// Whether automatic (foreground) checks are enabled — on by default.
  static const String kAutoCheckKey = 'update_auto_check';

  /// Whether the one-time notification permission prompt was already shown.
  static const String kNotificationPromptShownKey =
      'update_notification_prompt_shown';

  /// Selected release channel (`stable` unless explicitly set to `beta`).
  static const String kUpdateChannelKey = 'update_channel';

  Future<DateTime?> lastUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(kLastUpdateCheckKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveLastUpdateCheck() async {
    await _write(
      (prefs) => prefs.setInt(
        kLastUpdateCheckKey,
        DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<UpdateCheckResult?> lastUpdateCheckResult() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(kLastUpdateCheckResultKey);
    if (name == null) return null;
    return UpdateCheckResult.values.asNameMap()[name];
  }

  Future<void> saveLastUpdateCheckResult(UpdateCheckResult result) async {
    await _write(
      (prefs) => prefs.setString(kLastUpdateCheckResultKey, result.name),
    );
  }

  Future<String?> lastUpdateNotifiedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kLastUpdateNotifiedKey);
  }

  Future<void> saveLastUpdateNotifiedVersion(String version) async {
    await _write((prefs) => prefs.setString(kLastUpdateNotifiedKey, version));
  }

  Future<String?> dismissedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kDismissedVersionKey);
  }

  Future<void> saveDismissedVersion(String version) async {
    await _write((prefs) => prefs.setString(kDismissedVersionKey, version));
  }

  /// Forgets the dismissed version, used when switching channels so a banner
  /// dismissed on one channel cannot hide a release on the other.
  Future<void> clearDismissedVersion() async {
    await _write((prefs) => prefs.remove(kDismissedVersionKey));
  }

  Future<bool> autoCheckEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kAutoCheckKey) ?? true;
  }

  Future<void> saveAutoCheck(bool enabled) async {
    await _write((prefs) => prefs.setBool(kAutoCheckKey, enabled));
  }

  /// The persisted channel. A missing or unknown value stays on stable.
  Future<UpdateChannel> channel() async {
    final prefs = await SharedPreferences.getInstance();
    return UpdateChannel.fromStorage(prefs.getString(kUpdateChannelKey));
  }

  Future<void> saveChannel(UpdateChannel channel) async {
    await _write(
      (prefs) => prefs.setString(kUpdateChannelKey, channel.storageKey),
    );
  }

  Future<bool> notificationPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kNotificationPromptShownKey) ?? false;
  }

  Future<void> markNotificationPromptShown() async {
    await _write((prefs) => prefs.setBool(kNotificationPromptShownKey, true));
  }

  /// One `SharedPreferences.getInstance()` per write, with no error escaping:
  /// a failed bookkeeping write must never break an update check.
  static Future<void> _write(
    Future<bool> Function(SharedPreferences prefs) write,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await write(prefs);
    } on Object catch (_) {
      // Best effort: the in-memory state still drives this session.
    }
  }
}
