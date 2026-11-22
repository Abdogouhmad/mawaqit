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
import 'package:mawaqit/data/models/update_channel.dart';
import 'package:mawaqit/data/models/update_manifest.dart';
import 'package:ota_update/ota_update.dart';

/// Compile-time constant so the manifest URL can't drift between the code and
/// the CI workflow that writes it.
const String kGitHubRepo = 'Abdogouhmad/mawaqit';

/// Raw URL of the committed `update_manifest.json` on the default branch.
const String kUpdateManifestUrl =
    'https://raw.githubusercontent.com/$kGitHubRepo/main/update_manifest.json';

/// Raw URL of the committed beta manifest. Kept separate from stable so opting
/// into beta can never change what stable users receive.
const String kUpdateManifestBetaUrl =
    'https://raw.githubusercontent.com/$kGitHubRepo/main/update_manifest_beta.json';

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
  const UpdateService({this.httpClient, this.customManifestUrl});

  /// Injected mock client in tests; `null` uses a real `http.Client` per call.
  final http.Client? httpClient;

  /// Test/dev escape hatch that overrides both channel URLs.
  final String? customManifestUrl;

  /// URI of the selected channel's manifest. The `ts` parameter busts the CDN
  /// cache that can otherwise serve a stale copy for minutes after a release.
  Uri manifestUri({
    UpdateChannel channel = UpdateChannel.stable,
    DateTime? now,
  }) {
    final base =
        customManifestUrl ??
        (channel == UpdateChannel.beta
            ? kUpdateManifestBetaUrl
            : kUpdateManifestUrl);
    final uri = Uri.parse(base);
    final query = Map<String, String>.from(uri.queryParameters);
    query['ts'] = (now ?? DateTime.now()).millisecondsSinceEpoch.toString();
    return uri.replace(queryParameters: query);
  }

  /// Fetches the newest manifest for [channel]. Returns `null` on any failure
  /// so callers can treat a failed background check as "check again later".
  Future<UpdateManifest?> fetchManifest({
    UpdateChannel channel = UpdateChannel.stable,
    DateTime? now,
  }) async {
    final client = httpClient ?? http.Client();
    try {
      final response = await client
          .get(
            manifestUri(channel: channel, now: now),
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
  /// Stable never offers a pre-release, even if a manifest is misconfigured.
  UpdateCheckResult check({
    required UpdateManifest? manifest,
    required int currentVersionCode,
    String? currentVersionName,
    UpdateChannel channel = UpdateChannel.stable,
  }) {
    if (manifest == null) return UpdateCheckResult.checkFailed;
    // Beta trusts only a manifest that declares itself beta. Stable already
    // rejects prereleases below, but must keep accepting legacy manifests that
    // predate the `channel` field (they default to `stable`).
    if (channel == UpdateChannel.beta && !manifest.belongsTo(channel)) {
      return UpdateCheckResult.checkFailed;
    }
    // A freshly seeded beta manifest is not a failed release — there simply is
    // no prerelease to offer yet.
    if (channel == UpdateChannel.beta && manifest.isEmptySeed) {
      return UpdateCheckResult.upToDate;
    }
    if (manifest.latestVersionCode <= 0 ||
        manifest.apkUrl.isEmpty ||
        !manifest.isInstallable) {
      return UpdateCheckResult.checkFailed;
    }
    if (channel == UpdateChannel.stable && manifest.isPrerelease) {
      // Second gate: a beta build accidentally published to the stable file
      // is simply not a candidate for stable users.
      return UpdateCheckResult.upToDate;
    }

    // versionCode is authoritative, but beta builds share it with their
    // eventual stable release. Break that tie with semver precedence so a beta
    // user switching to stable can still see the final release.
    final newerByCode = manifest.isNewerThan(currentVersionCode);
    final newerByName =
        manifest.latestVersionCode == currentVersionCode &&
        currentVersionName != null &&
        compareUpdateVersions(manifest.latestVersionName, currentVersionName) >
            0;
    if (!newerByCode && !newerByName) {
      return UpdateCheckResult.upToDate;
    }

    final floor = manifest.minSupportedVersionCode;
    if (manifest.mandatory || (floor != null && currentVersionCode < floor)) {
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
