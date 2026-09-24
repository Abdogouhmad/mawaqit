import 'package:package_info_plus/package_info_plus.dart';

/// App identity captured once at startup from `PackageInfo`.
///
/// The OTA updater compares the Android `versionCode` ([buildNumber]) against
/// `update_manifest.json`. Because Mawaqit derives versionCode deterministically
/// from the semver version, `version` and `buildNumber` can never drift apart.
class AppInfo {
  static late String _version;
  static late int _buildNumber;

  static bool _initialized = false;

  /// Call this ONCE at app startup.
  static Future<void> init() async {
    if (_initialized) return;

    final pkg = await PackageInfo.fromPlatform();
    _version = pkg.version;
    _buildNumber = int.tryParse(pkg.buildNumber) ?? 0;
    _initialized = true;
  }

  /// Synchronous getter.
  static String get version {
    _ensureInitialized();
    return _version;
  }

  /// Android `versionCode` as parsed from `PackageInfo.buildNumber`.
  static int get buildNumber {
    _ensureInitialized();
    return _buildNumber;
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw Exception(
        'AppInfo not initialized. Call AppInfo.init() before accessing.',
      );
    }
  }
}
