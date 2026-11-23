import 'package:flutter/foundation.dart';
import 'package:mawaqit/core/utils/hijri_dates.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/l10n/enum_localization.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';

/// The complete set of values the Glance card renders, computed away from the
/// plugin so the widget's behaviour is testable without a native host.
///
/// Every field is a scalar: the generated `saveData` API stores only strings
/// and booleans, and a nullable field it does not receive is simply left at its
/// previous value. This type therefore writes *every* field on every snapshot —
/// the same class of silent stale-data bug the five prayer dots used to have.
@immutable
class PrayerWidgetSnapshot {
  const PrayerWidgetSnapshot({
    required this.locationShort,
    required this.nextPrayerName,
    required this.nextPrayerTime,
    required this.nextPrayerCountdown,
    required this.hijriDate,
    required this.amoled,
    required this.showHijri,
    required this.showQuickActions,
    required this.activeKind,
    required this.pastKinds,
  });

  final String locationShort;
  final String nextPrayerName;
  final String nextPrayerTime;
  final String nextPrayerCountdown;
  final String hijriDate;
  final bool amoled;
  final bool showHijri;
  final bool showQuickActions;
  final PrayerKind activeKind;
  final Set<PrayerKind> pastKinds;

  bool isActive(PrayerKind kind) => kind == activeKind;
  bool isPast(PrayerKind kind) => pastKinds.contains(kind);

  /// Builds a snapshot for [now].
  ///
  /// [timeFormatterLocale] is passed in rather than read from `TimeFormatter`'s
  /// static state so a test can build the same snapshot twice under different
  /// locales without leaking configuration between cases. The production
  /// caller passes the resolved app locale.
  static PrayerWidgetSnapshot build(
    PrayerDay day,
    AppSettings settings,
    DateTime now,
    AppLocalizations l10n, {
    required String? locationShort,
    required String timeFormatterLocale,
    required bool darkThemeEffective,
  }) {
    TimeFormatter.locale(timeFormatterLocale);

    final next =
        day.currentOrNextPrayer(now) ??
        PrayerTime(kind: PrayerKind.fajr, time: day.nextDayFajr);
    final remaining = next.time.difference(now);
    final countdown = remaining.isNegative ? Duration.zero : remaining;

    final pastKinds = <PrayerKind>{
      for (final kind in PrayerKind.values)
        if (day.prayer(kind)?.time.isBefore(now) ?? false) kind,
    };

    return PrayerWidgetSnapshot(
      locationShort: _shorten(
        locationShort ?? settings.effectiveLocationName ?? settings.cityName,
      ),
      nextPrayerName: next.kind.localized(l10n),
      nextPrayerTime: TimeFormatter.clock(next.time),
      nextPrayerCountdown: l10n.widgetIn(
        TimeFormatter.longCountdown(countdown),
      ),
      hijriDate: _hijri(now, l10n),
      // True black only makes sense in dark mode; a light-theme AMOLED flag is
      // remembered but deliberately not applied to the widget either.
      amoled: settings.amoled && darkThemeEffective,
      showHijri: settings.widgetShowHijri,
      showQuickActions: settings.widgetShowQuickActions,
      activeKind: next.kind,
      pastKinds: pastKinds,
    );
  }

  /// First comma-separated part of a place name ("Halifax, NS, Canada" →
  /// "Halifax"), dropped to the "—" placeholder when empty.
  static String _shorten(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final first = raw.split(',').first.trim();
    return first.isEmpty ? '—' : first;
  }

  /// Hijri date with month names from the app catalogue, not the `hijri`
  /// package's English/Arabic-only table.
  static String _hijri(DateTime date, AppLocalizations l10n) {
    final h = HijriDates.full(date);
    final months = [
      l10n.hijriMonth1,
      l10n.hijriMonth2,
      l10n.hijriMonth3,
      l10n.hijriMonth4,
      l10n.hijriMonth5,
      l10n.hijriMonth6,
      l10n.hijriMonth7,
      l10n.hijriMonth8,
      l10n.hijriMonth9,
      l10n.hijriMonth10,
      l10n.hijriMonth11,
      l10n.hijriMonth12,
    ];
    return '${h.day} ${months[(h.month - 1).clamp(0, 11)]} ${h.year}';
  }
}
