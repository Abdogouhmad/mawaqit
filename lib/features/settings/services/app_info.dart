import 'package:package_info_plus/package_info_plus.dart';

/// App identity captured once at startup from `PackageInfo`.
///
/// The OTA updater compares the Android `versionCode` ([buildNumber]) against
/// `update_manifest.json`. Because Mawaqit derives versionCode deterministically
/// from the semver version, `version` and `buildNumber` can never drift apart.
///
/// Every getter here is fallible-by-design: [init] is awaited on the startup
/// path *before* `runApp`, so anything it throws leaves the process sitting on
/// the launch window's blank background with no Flutter frame ever drawn, and
/// the getters are read synchronously from six call sites including widgets
/// built during the first frame. A missing version string is a cosmetic
/// problem; a thrown one is an app that looks like it failed to launch.
class AppInfo {
  static String _version = fallbackVersion;
  static int _buildNumber = 0;

  static bool _initialized = false;

  /// Shown when the platform channel cannot be reached — for example on a
  /// desktop dev run or an install whose native side predates the plugin.
  static const String fallbackVersion = '0.0.0';

  /// Call this ONCE at app startup. Never throws.
  static Future<void> init() async {
    if (_initialized) return;

    try {
      final pkg = await PackageInfo.fromPlatform();
      _version = pkg.version.isEmpty ? fallbackVersion : pkg.version;
      _buildNumber = int.tryParse(pkg.buildNumber) ?? 0;
    } catch (_) {
      // Leave the fallbacks in place. The OTA updater treats versionCode 0 as
      // "older than anything in the manifest", so the worst case is an
      // update prompt that never clears — not a crash on launch.
      _version = fallbackVersion;
      _buildNumber = 0;
    }
    _initialized = true;
  }

  /// Synchronous getter. Safe to call before [init] has completed.
  static String get version => _version;

  /// Android `versionCode` as parsed from `PackageInfo.buildNumber`.
  static int get buildNumber => _buildNumber;
}
