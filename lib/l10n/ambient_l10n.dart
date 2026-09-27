import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';

/// Resolves [device] to the closest locale the app actually ships, falling back
/// to the template language.
///
/// This has to exist: the generated `lookupAppLocalizations` *throws* a
/// `FlutterError` for any locale outside `supportedLocales`, so passing a raw
/// `PlatformDispatcher.instance.locale` straight through would crash on a phone
/// set to, say, French. Every entry point that starts from a device locale goes
/// through here first.
AppLocalizations resolveLocalizations(Locale device) {
  for (final supported in AppLocalizations.supportedLocales) {
    if (supported.languageCode == device.languageCode) {
      return lookupAppLocalizations(supported);
    }
  }
  return lookupAppLocalizations(AppLocalizations.supportedLocales.first);
}

/// The locale the app will actually render in for a given device locale.
Locale supportedLocaleFor(Locale device) {
  for (final supported in AppLocalizations.supportedLocales) {
    if (supported.languageCode == device.languageCode) return supported;
  }
  return AppLocalizations.supportedLocales.first;
}

/// Resolves the user's [AppLanguage] preference against the [device] locale.
///
/// [AppLanguage.system] yields a narrowed device locale rather than the raw
/// one, so an unsupported device language does not reach code that cannot cope
/// with it. This is the single definition of "which language is the app in",
/// used by both the widget layer (`MaterialApp.locale`) and the service layer.
Locale resolveAppLocale(AppLanguage language, Locale device) =>
    Locale(language.languageCode ?? supportedLocaleFor(device).languageCode);

/// Ambient locale for code that cannot reach a `BuildContext`.
///
/// Notification channels, shade titles/bodies, `TimeFormatter` and
/// background-isolate callbacks are all built outside the widget tree, so
/// `AppLocalizations.of(context)` is simply not available there. Rather than
/// sprinkle `lookupAppLocalizations` calls — and risk the throw described above
/// — the current locale is recorded once in [MawaqitApp]'s builder and read back
/// through here.
///
/// The widget layer should still prefer `AppLocalizations.of(context)`; this is
/// only for the service/background side of the app.
class AmbientL10n {
  const AmbientL10n._();

  /// Starts at the device locale, already narrowed to a supported language so
  /// the very first notification (which can be scheduled before the first
  /// frame, e.g. by a background isolate) resolves instead of throwing.
  static Locale _locale = supportedLocaleFor(
    PlatformDispatcher.instance.locale,
  );

  static AppLocalizations get instance => lookupAppLocalizations(_locale);

  /// Records the locale the widget tree resolved. [value] is normalised through
  /// [supportedLocaleFor], so passing an unsupported locale is safe.
  static set locale(Locale value) => _locale = supportedLocaleFor(value);

  /// Test hook: restores the platform locale.
  static void reset() =>
      _locale = supportedLocaleFor(PlatformDispatcher.instance.locale);
}
