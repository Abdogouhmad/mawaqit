abstract final class AppConstants {
  static const String appName = 'Waqt';

  /// Mirrors `version:` in pubspec.yaml (Android versionName / GitHub tag).
  static const String appVersion = '0.2.0';

  static const String notificationChannelId = 'mawaqit_prayer_reminders';
  static const String notificationChannelName = 'Prayer reminders';
  static const String notificationChannelDesc =
      'Pre-prayer countdown reminders and adhan alerts';

  static const int defaultLeadMinutes = 10;

  static const String fontFamily = 'Manrope';
}