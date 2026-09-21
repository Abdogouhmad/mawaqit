import 'package:shared_preferences/shared_preferences.dart';

import 'package:mawaqit/data/services/update_service.dart';

/// Persists the OTA updater's bookkeeping across launches
/// (SharedPreferences, matching [SettingsRepository]).
class UpdateStore {
  static const String kLastUpdateCheckKey = 'last_update_check_ms';
  static const String kLastUpdateCheckResultKey = 'last_update_check_result';

  Future<DateTime?> lastUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(kLastUpdateCheckKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveLastUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      kLastUpdateCheckKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<UpdateCheckResult?> lastUpdateCheckResult() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(kLastUpdateCheckResultKey);
    if (name == null) return null;
    return UpdateCheckResult.values.asNameMap()[name];
  }

  Future<void> saveLastUpdateCheckResult(UpdateCheckResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kLastUpdateCheckResultKey, result.name);
  }
}