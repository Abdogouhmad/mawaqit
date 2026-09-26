import 'package:shared_preferences/shared_preferences.dart';

import 'package:mawaqit/data/models/alarm_access.dart';

/// One-time bookkeeping for the "let Mawaqit ignore battery optimisation" ask.
///
/// Android's Doze is what makes the adhan "not work" on a lot of phones: once
/// the screen is off for a while the app is frozen, and the exact alarm the adhan
/// was armed with is deferred (or dropped outright) until the phone next wakes up
/// — which is why the failure looks like a bug in the app rather than a setting.
/// The exemption is granted on a system screen, so it has to be *asked for*.
///
/// It is asked once per build, which is also once per install and once per
/// update: [lastPromptedBuild] remembers the build the user last saw the ask for
/// (whether they allowed or dismissed it), so a new release — where the app may
/// have new alarm behaviour to protect — gets one more chance, and no version
/// ever nags twice.
class AlarmAccessPromptStore {
  static const String kLastPromptedBuildKey = 'alarm_access_prompted_build';

  /// Build (Android `versionCode`) the ask was last shown for, if ever.
  Future<int?> lastPromptedBuild() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(kLastPromptedBuildKey);
  }

  Future<void> markPromptedBuild(int build) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kLastPromptedBuildKey, build);
  }
}

/// Whether the battery-optimisation ask should be shown right now.
///
/// Kept pure and separate from the widget so the rule is unit-testable: ask only
/// on Android, only while the exemption is genuinely missing, and only when the
/// running build has not asked yet. A [currentBuild] of null means the version
/// is unknown (very early startup, or a host without package info) — staying
/// silent is the safe answer, because an ask that cannot be attributed to a
/// build would repeat forever.
bool shouldAskForBatteryExemption({
  required AlarmAccess access,
  required int? currentBuild,
  required int? lastPromptedBuild,
}) {
  if (access.battery) return false;
  if (currentBuild == null) return false;
  return lastPromptedBuild != currentBuild;
}
