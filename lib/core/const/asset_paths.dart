/// Asset paths, as registered in `pubspec.yaml`.
///
/// These are resolved from the asset manifest at runtime, so a typo fails at
/// load time rather than at build time. The `assets/adhan/` prefix is also the
/// contract with the native module: Kotlin opens the *same* files through
/// `context.assets.openFd("flutter_assets/assets/adhan/<name>")`, which is why
/// `androidResources.noCompress` must list the extensions (see feat.md §4.4).
library;

abstract final class AssetPaths {
  const AssetPaths._();

  /// Directory prefix for the adhan clips. Must match the `assets/adhan/`
  /// entry in `pubspec.yaml` exactly.
  static const String adhanDir = 'assets/adhan/';

  /// Directory prefix for the short pre-prayer chimes.
  static const String chimesDir = 'assets/audio/';

  /// Bundled offline city list for the manual location picker: an array of
  /// `{name, country, lat, lon, timezone}` objects. Bundled rather than fetched
  /// so city search keeps working in airplane mode (feat.md §1, privacy).
  static const String cities = 'assets/data/cities.json';
}
