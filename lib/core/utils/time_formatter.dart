import 'package:intl/intl.dart';

import 'package:hijri/hijri_calendar.dart';

/// Pure formatting helpers shared across the app.
abstract final class TimeFormatter {
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _date = DateFormat('EEEE, MMMM d');

  static String clock(DateTime t) => _time.format(t);

  static String gregorian(DateTime d) => _date.format(d).toLowerCase();

  static String hijri(DateTime d) {
    final h = HijriCalendar.fromDate(d);
    final names = const [
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
    final month = h.hMonth.clamp(1, 12);
    return '${h.hDay} ${names[month - 1]} ${h.hYear}'.toLowerCase();
  }

  /// "1h 24m" style countdown, omits leading zeros.
  static String countdown(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (d.inDays > 0) {
      return '${d.inDays}d ${hours % 24}h ${minutes}m';
    }
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    return '${seconds}s';
  }

  /// Long human friendly countdown: "1 hour 24 minutes".
  static String longCountdown(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    if (minutes > 0) return '${minutes}m';
    return '${d.inSeconds}s';
  }

  /// Full numeric duration e.g. "11h 14m".
  static String dayLength(Duration d) =>
      '${d.inHours}h ${d.inMinutes % 60}m'.trim();

  static String methodLabelWithAngle(String methodName, String? angle) =>
      angle == null ? methodName : '$methodName ($angle)';
}