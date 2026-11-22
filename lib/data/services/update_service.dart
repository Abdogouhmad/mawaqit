/// OTA update service: fetches `update_manifest.json` from this repo and
/// compares it against the installed version.
///
/// The manifest is a raw GitHub file, so the updater needs nothing but a plain
/// HTTPS GET. A failed or offline check is always silent — it never blocks
/// startup and never surfaces as an error for a routine background check.
///
/// The manifest is treated as untrusted input: a release without a valid
/// SHA-256, or with a non-HTTPS APK URL, is refused before it can be offered,
/// downloaded or installed (the same fail-closed rule Keyel uses).
library;

import 'package:http/http.dart' as http;
import 'package:mawaqit/data/models/update_manifest.dart';
import 'package:ota_update/ota_update.dart';

/// Compile-time constant so the manifest URL can't drift between the code and
/// the CI workflow that writes it.
const String kGitHubRepo = 'Abdogouhmad/mawaqit';

/// Raw URL of the committed `update_manifest.json` on the default branch.
const String kUpdateManifestUrl =
    'https://raw.githubusercontent.com/$kGitHubRepo/main/update_manifest.json';

/// Background checks must never hang the UI on a dead connection — fail fast
/// and treat it like "check again later".
const Duration kManifestFetchTimeout = Duration(seconds: 10);

/// Result of comparing the installed version against the latest manifest.
enum UpdateCheckResult {
  /// The app is already up to date.
  upToDate,

  /// An update is available but not mandatory.
  updateAvailable,

  /// An update is available and mandatory — the installed build is out of
  /// support and the app must be updated to keep working.
  updateMandatory,

  /// The check failed (offline, HTTP error, malformed or unverifiable manifest).
  checkFailed,
}

class UpdateService {
  /// Creates a service with an injectable HTTP client (for tests).
  const UpdateService({this.httpClient});

  /// Injected mock client in tests; `null` uses a real `http.Client` per call.
  final http.Client? httpClient;

  /// URI of the manifest. The `ts` parameter busts the CDN cache that can
  /// otherwise serve a stale copy for minutes after a release is committed.
  Uri manifestUri({DateTime? now}) {
    final uri = Uri.parse(kUpdateManifestUrl);
    final query = Map<String, String>.from(uri.queryParameters);
    query['ts'] = (now ?? DateTime.now()).millisecondsSinceEpoch.toString();
    return uri.replace(queryParameters: query);
  }

  /// Fetches the newest update manifest. Returns `null` on any failure so
  /// callers can treat a failed background check as "check again later".
  Future<UpdateManifest?> fetchManifest({DateTime? now}) async {
    final client = httpClient ?? http.Client();
    try {
      final response = await client
          .get(
            manifestUri(now: now),
            headers: const {
              'Accept': 'application/json',
              'Cache-Control': 'no-cache',
              'User-Agent': 'Mawaqit-Updater',
            },
          )
          .timeout(kManifestFetchTimeout);
      if (response.statusCode != 200) return null;
      return UpdateManifest.tryDecode(response.body);
    } on Object catch (_) {
      return null;
    }
  }

  /// Compares the installed [currentVersionCode] against [manifest] and
  /// reports whether an update is available and/or required.
  ///
  /// A manifest that cannot be verified fails closed: no prompt, no download.
  UpdateCheckResult check({
    required UpdateManifest? manifest,
    required int currentVersionCode,
  }) {
    if (manifest == null ||
        manifest.latestVersionCode <= 0 ||
        manifest.apkUrl.isEmpty ||
        !manifest.isInstallable) {
      return UpdateCheckResult.checkFailed;
    }
    if (!manifest.isNewerThan(currentVersionCode)) {
      return UpdateCheckResult.upToDate;
    }
    if (manifest.isMandatoryFor(currentVersionCode)) {
      return UpdateCheckResult.updateMandatory;
    }
    return UpdateCheckResult.updateAvailable;
  }

  /// Downloads and installs the manifest's APK.
  ///
  /// `ota_update` downloads the file with live progress, verifies the SHA-256
  /// from the manifest against the downloaded bytes **before** anything is
  /// installed (it surfaces `OtaStatus.CHECKSUM_ERROR` on a mismatch), and
  /// hands off to Android's system `PackageInstaller`.
  Stream<OtaEvent> downloadAndInstall({required UpdateManifest manifest}) {
    // Defence in depth: the check path already rejects these, but callers can
    // construct a manifest directly (a deep link, a test, a future UI).
    if (!manifest.isInstallable) {
      throw StateError('Refusing to install an unverified update');
    }
    return OtaUpdate().execute(
      manifest.apkUrl,
      destinationFilename: 'mawaqit-update.apk',
      // Verified natively before the install intent is fired.
      sha256checksum: manifest.sha256!.trim(),
    );
  }
}
