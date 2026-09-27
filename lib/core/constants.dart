abstract final class AppConstants {
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
}
