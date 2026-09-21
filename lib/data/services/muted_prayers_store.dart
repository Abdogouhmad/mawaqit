import 'package:shared_preferences/shared_preferences.dart';

/// Persists per-occurrence mute flags for prayer notifications.
///
/// A "prayer id" encodes date + prayer kind so that muting today's Maghrib
/// never silences tomorrow's, e.g. `"2026-09-21_maghrib"`.
///
/// On Android the native `MutePrayerReceiver` writes the same
/// `shared_preferences` file directly (keys `muted_prayer_<id>`), so mute
/// state set from the lockscreen card is visible here — and in-app toggles
/// are visible to the native side — without a method-channel round-trip.
class MutedPrayersStore {
  static const String _prefix = 'muted_prayer_';

  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = <String>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      if (prefs.getBool(key) ?? false) {
        ids.add(key.substring(_prefix.length));
      }
    }
    return ids;
  }

  Future<Set<String>> setMuted(String prayerId, bool muted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$prayerId', muted);
    return load();
  }
}