/// Domain model for the OTA update manifest.
///
/// The manifest is a small JSON file hosted in this repo (raw GitHub URL),
/// rewritten by the release CI. Both the in-app OTA updater and the GitHub
/// Release share the same changelog text, so the manifest's [releaseNotes]
/// is *verbatim* the matching `CHANGELOG.md` section.
///
/// The in-app updater always downloads the **universal** APK, which is why
/// [apkUrl] points at the fat archive, not a per-ABI one.
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

  final DateTime? publishedAt;

  const UpdateManifest({
    required this.latestVersionCode,
    required this.latestVersionName,
    this.minSupportedVersionCode,
    this.mandatory = false,
    this.releaseNotes = '',
    required this.apkUrl,
    this.sha256,
    this.publishedAt,
  });

  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    return UpdateManifest(
      latestVersionCode: json['latestVersionCode'] as int? ?? 0,
      latestVersionName: json['latestVersionName'] as String? ?? '',
      minSupportedVersionCode: json['minSupportedVersionCode'] as int?,
      mandatory: json['mandatory'] as bool? ?? false,
      releaseNotes: json['releaseNotes'] as String? ?? '',
      apkUrl: json['apkUrl'] as String? ?? '',
      sha256: json['sha256'] as String?,
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
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
}