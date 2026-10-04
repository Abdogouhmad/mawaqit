/// App-wide literals that are not user-facing copy.
///
/// Anything a user can read lives in `AppLocalizations` instead — see feat.md
/// §6. What belongs here is identity (the app's own name), typography plumbing,
/// and the numbers the design spec fixes as geometry.
library;

abstract final class AppConstants {
  const AppConstants._();

  static const String appName = 'Mawaqit';

  /// Latin/numerals face. Covers ASCII only.
  static const String fontFamily = 'Manrope';

  /// Consulted per glyph run for anything [fontFamily] cannot draw — in
  /// practice the whole Arabic UI, plus the few symbols Manrope lacks.
  ///
  /// A fallback rather than a per-locale `fontFamily` swap on purpose: it keeps
  /// mixed-script strings (an Arabic prayer name followed by a Latin "5:30 PM",
  /// or a Hijri month) correct without every call site having to know which
  /// language it is currently rendering.
  static const List<String> fontFamilyFallback = ['Cairo'];

  /// Android `MethodChannel` that owns alarm scheduling and adhan playback.
  ///
  /// Mirrored on the Kotlin side in `bridge/NativeChannel.kt`; both halves must
  /// agree or every call fails with `MissingPluginException`.
  static const String nativeChannel = 'mawaqit/native';
}
