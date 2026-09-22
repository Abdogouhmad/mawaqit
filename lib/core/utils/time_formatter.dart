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

  /// "1h 24m 13s" style countdown for the next-prayer hero/tile. Seconds are
  /// always shown (the home ticker runs every second); the largest unit omits
  /// its leading zero.
  static String countdown(Duration d) {
    final totalSeconds = d.inSeconds;
    if (totalSeconds <= 0) return '0s';
    final days = d.inDays;
    final hours = days > 0 ? d.inHours % 24 : d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = totalSeconds % 60;
    final s = '${seconds.toString().padLeft(2, '0')}s';
    if (days > 0) return '${days}d ${hours}h ${minutes}m $s';
    if (hours > 0) return '${hours}h ${minutes}m $s';
    if (minutes > 0) return '${minutes}m $s';
    return s;
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