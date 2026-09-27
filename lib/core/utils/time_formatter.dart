import 'dart:ui' show Locale;

import 'package:intl/intl.dart';

import 'package:hijri/hijri_calendar.dart';

import 'package:mawaqit/l10n/ambient_l10n.dart';

/// Pure formatting helpers shared across the app.
///
/// Two process-wide inputs are synced from the widget tree on every build (see
/// `MawaqitApp`): [use24HourFormat] for the device's clock convention, and
/// [locale] for the active language. Both are read here rather than threaded
/// through call sites because this class is used from background isolates
/// (WorkManager, the home-screen widget) where no `BuildContext` exists.
abstract final class TimeFormatter {
  /// Locale the [DateFormat]s are built for. `null` means "whatever intl
  /// defaults to", which preserves the pre-localization behaviour.
  static String? _locale;

  /// Rebuilt whenever [_locale] changes — `DateFormat` binds its locale at
  /// construction, so they cannot be built once and reused across languages.
  static DateFormat _time12 = DateFormat('h:mm a');
  static DateFormat _time24 = DateFormat('HH:mm');
  static DateFormat _date = DateFormat('EEEE, MMMM d');

  /// Hijri month names. Arabic has its own set (محرم، صفر، …) and reusing the
  /// Latin transliterations left the Hijri line on the home screen reading like
  /// a typo, so these come from the catalog too.
  static List<String> _hijriMonths = _defaultHijriMonths;

  static const List<String> _defaultHijriMonths = [
    'Muharram',
    'Safar',
    "Rabi' al-Awwal",
    "Rabi' al-Thani",
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];

  /// Whether times render in 24-hour form.
  ///
  /// Every clock in the app used to be hardcoded to `h:mm a`, so a user whose
  /// device is set to 24-hour — very common across the countries this app
  /// serves — saw an 18:30 Isha as "6:30 PM" everywhere, including the
  /// notification bodies and the reminder cards.
  ///
  /// Defaults to 12-hour so anything formatted before the first frame keeps the
  /// previous behaviour rather than guessing; [use24HourFormat] then reports
  /// the real device setting. Flutter only exposes it through
  /// `MaterialLocalizations`, so this is a process-wide value the widget tree
  /// keeps in sync (see `MawaqitApp`) rather than something derived per call.
  static bool _use24Hour = false;

  static bool get use24Hour => _use24Hour;

  /// Reports the device's clock convention. Called on every app build so a
  /// change made in system settings while the app is open is picked up.
  static void use24HourFormat(bool value) {
    _use24Hour = value;
  }

  /// Points the formatters at [value]'s language.
  ///
  /// Called from the app builder with the locale actually resolved by
  /// `Localizations`, so an unsupported device language still formats in the
  /// nearest supported one instead of silently falling back to English.
  static void locale(String? value) {
    if (_locale == value) return;
    // Narrow to a shipped language first: intl is happy to format an unknown
    // locale, but our Hijri lookup (and the app's own delegate) is not, and a
    // half-localized clock is worse than a consistently English one.
    final resolved = value == null
        ? null
        : supportedLocaleFor(Locale(value)).languageCode;
    _locale = resolved;
    _time12 = DateFormat('h:mm a', resolved);
    _time24 = DateFormat('HH:mm', resolved);
    _date = DateFormat('EEEE, MMMM d', resolved);
    if (value == null) {
      _hijriMonths = _defaultHijriMonths;
    } else {
      // gen-l10n has no List<String> support, so the 12 month names are declared
      // individually in the catalog and stitched back into a list here.
      // `resolveLocalizations` rather than `lookupAppLocalizations`: this is
      // reachable with a raw device locale, and the generated lookup throws for
      // anything outside the supported set.
      final l = resolveLocalizations(Locale(resolved!));
      _hijriMonths = [
        l.hijriMonth1,
        l.hijriMonth2,
        l.hijriMonth3,
        l.hijriMonth4,
        l.hijriMonth5,
        l.hijriMonth6,
        l.hijriMonth7,
        l.hijriMonth8,
        l.hijriMonth9,
        l.hijriMonth10,
        l.hijriMonth11,
        l.hijriMonth12,
      ];
    }
  }

  static String clock(DateTime t) => (_use24Hour ? _time24 : _time12).format(t);

  /// Capitalised "Monday, September 22" — the alarm presenter's date line.
  static String dateTitle(DateTime d) => _date.format(d);

  static String gregorian(DateTime d) => _date.format(d).toLowerCase();

  static String hijri(DateTime d) {
    final h = HijriCalendar.fromDate(d);
    final month = h.hMonth.clamp(1, 12);
    return '${h.hDay} ${_hijriMonths[month - 1]} ${h.hYear}'.toLowerCase();
  }

  /// "1h 24m 13s" style countdown for the next-prayer hero/tile. Seconds are
  /// always shown (the home ticker runs every second); the largest unit omits
  /// its leading zero.
  ///
  /// The unit suffixes come from the catalog: Arabic writes them as separate
  /// letters (1س 24د 13ث) and the abbreviations do not compose by concatenation
  /// the way the Latin ones do.
  static String countdown(Duration d) {
    final l10n = AmbientL10n.instance;
    final totalSeconds = d.inSeconds;
    if (totalSeconds <= 0) return '0${l10n.unitSeconds}';
    final days = d.inDays;
    final hours = days > 0 ? d.inHours % 24 : d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = totalSeconds % 60;
    final s = '${seconds.toString().padLeft(2, '0')}${l10n.unitSeconds}';
    if (days > 0) {
      return '$days${l10n.unitDays} $hours${l10n.unitHours} '
          '$minutes${l10n.unitMinutes} $s';
    }
    if (hours > 0) {
      return '$hours${l10n.unitHours} $minutes${l10n.unitMinutes} $s';
    }
    if (minutes > 0) return '$minutes${l10n.unitMinutes} $s';
    return s;
  }

  /// Long human friendly countdown: "1 hour 24 minutes".
  static String longCountdown(Duration d) {
    final l10n = AmbientL10n.instance;
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '$hours${l10n.unitHours} $minutes${l10n.unitMinutes}';
    }
    if (hours > 0) return '$hours${l10n.unitHours}';
    if (minutes > 0) return '$minutes${l10n.unitMinutes}';
    return '${d.inSeconds}${l10n.unitSeconds}';
  }

  /// Full numeric duration e.g. "11h 14m".
  static String dayLength(Duration d) {
    final l10n = AmbientL10n.instance;
    return '${d.inHours}${l10n.unitHours} ${d.inMinutes % 60}${l10n.unitMinutes}'
        .trim();
  }
}
