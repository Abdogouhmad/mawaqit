/// Domain model for the OTA update manifest.
///
/// The manifest is a small JSON file hosted in this repo (raw GitHub URL),
/// rewritten by the release CI. Both the in-app OTA updater and the GitHub
/// Release share the same changelog text, so the manifest's [releaseNotes]
/// is *verbatim* the matching `CHANGELOG.md` section.
///
/// The in-app updater always downloads the **universal** APK, which is why
/// [apkUrl] points at the fat archive, not a per-ABI one.
library;

import 'dart:convert';

/// Strict 64-hex SHA-256 — the only checksum an update may be installed with.
final RegExp _checksumPattern = RegExp(r'^[a-fA-F0-9]{64}$');

/// Whether [value] is a checksum we are willing to install against.
///
/// Following Keyel's OTA policy, a missing or malformed hash fails closed:
/// such a release is never offered, downloaded or handed to the installer.
bool isValidUpdateChecksum(String? value) =>
    value != null && _checksumPattern.hasMatch(value.trim());

/// Whether [url] points at an absolute HTTPS resource.
///
/// APK downloads are restricted to HTTPS so a manifest edited by anyone with
/// repo access cannot redirect the updater to plaintext HTTP.
bool isSecureUpdateUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  return uri != null && uri.isAbsolute && uri.scheme.toLowerCase() == 'https';
}

class UpdateManifest {
  /// Android `versionCode` of the newest release (derived from semver).
  final int latestVersionCode;

  /// Human-facing semver string of the newest release, e.g. `0.4.0`.
  final String latestVersionName;

  /// Oldest `versionCode` the current build supports. Releases older than this
  /// are considered breaking and become a mandatory update.
  final int? minSupportedVersionCode;

  /// When true the update cannot be declined — see [minSupportedVersionCode].
  final bool mandatory;

  /// The matching `CHANGELOG.md` section, injected by CI — shown in-app.
  final String releaseNotes;

  /// Direct download URL of the universal APK.
  final String apkUrl;

  /// SHA-256 of that exact APK, verified before anything is installed.
  final String? sha256;

  /// Size of the APK in bytes, when the manifest publishes it.
  final int? size;

  /// Release channel published in the manifest (`stable` by default).
  final String channel;

  /// Whether the manifest describes a pre-release build.
  final bool isPrerelease;

  /// When the release was published, when the manifest carries it.
  final DateTime? publishedAt;

  const UpdateManifest({
    required this.latestVersionCode,
    required this.latestVersionName,
    this.minSupportedVersionCode,
    this.mandatory = false,
    this.releaseNotes = '',
    required this.apkUrl,
    this.sha256,
    this.size,
    this.channel = 'stable',
    this.isPrerelease = false,
    this.publishedAt,
  });

  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    final published = json['publishedAt'] as String?;
    return UpdateManifest(
      latestVersionCode: json['latestVersionCode'] as int? ?? 0,
      latestVersionName: json['latestVersionName'] as String? ?? '',
      minSupportedVersionCode: json['minSupportedVersionCode'] as int?,
      mandatory: json['mandatory'] as bool? ?? false,
      releaseNotes: json['releaseNotes'] as String? ?? '',
      apkUrl: json['apkUrl'] as String? ?? '',
      sha256: json['sha256'] as String?,
      size: json['size'] as int?,
      channel: json['channel'] as String? ?? 'stable',
      isPrerelease: json['isPrerelease'] == true || json['channel'] == 'beta',
      publishedAt: published == null ? null : DateTime.tryParse(published),
    );
  }

  /// Whether the given installed [currentVersionCode] is older than this
  /// manifest's newest build.
  bool isNewerThan(int currentVersionCode) =>
      latestVersionCode > currentVersionCode;

  /// Whether an installed [currentVersionCode] is forced to update: either
  /// the newest release is explicitly [mandatory], or the installed build has
  /// dropped below [minSupportedVersionCode].
  bool isMandatoryFor(int currentVersionCode) {
    if (!isNewerThan(currentVersionCode)) return false;
    if (mandatory) return true;
    final floor = minSupportedVersionCode;
    return floor != null && currentVersionCode < floor;
  }

  /// Whether this release may be offered to the updater at all.
  ///
  /// A broken publish (no 64-hex hash, non-HTTPS APK or empty version) is not
  /// a candidate: it is a failed release, not something to install unverified.
  bool get isInstallable =>
      latestVersionName.trim().isNotEmpty &&
      isSecureUpdateUrl(apkUrl) &&
      isValidUpdateChecksum(sha256);

  /// Human-readable APK size, or an empty string when the manifest omits it.
  String get formattedSize {
    final bytes = size ?? 0;
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Decodes a manifest from [body], returning `null` when it is malformed.
  static UpdateManifest? tryDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      return UpdateManifest.fromJson(decoded);
    } on Object catch (_) {
      return null;
    }
  }
}
