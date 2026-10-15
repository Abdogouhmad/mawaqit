/// Asset paths, as registered in `pubspec.yaml`.
///
/// These are resolved from the asset manifest at runtime, so a typo fails at
/// load time rather than at build time.
library;

abstract final class AssetPaths {
  const AssetPaths._();

  /// The app's launcher art — the emerald mihrab mark. Bundled via
  /// `assets/icons/` in `pubspec.yaml` so the About dialog and the Settings
  /// footer can draw the real logo instead of a stand-in [Icon] glyph.
  static const String appIcon = 'assets/icons/icon_e_mihrab_512.png';
}
