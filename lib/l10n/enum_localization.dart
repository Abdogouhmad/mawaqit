import 'package:mawaqit/data/models/alarm_access.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/notification_kind.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';

/// Localized display names for the domain enums.
///
/// These labels used to live on the enums themselves (`PrayerKind.displayName`,
/// `LocationMode.label`), which pinned them to English forever — a model cannot
/// reach a `BuildContext`, and threading one into the calculation engine would
/// be worse. Keeping the lookup here means the widget layer asks for a name
/// *in the active locale* while the models stay plain data.
///
/// Anything persisted (`adhanTone`, `prayerId`, …) must keep using the raw
/// enum/name, never these — only display goes through here.
///
/// Calculation methods and madhabs are deliberately absent: they are proper
/// nouns in this domain and `adhan_dart` already ships their display names, so
/// they read the same in every locale.
extension PrayerKindL10n on PrayerKind {
  String localized(AppLocalizations l10n) => switch (this) {
    PrayerKind.fajr => l10n.prayerFajr,
    PrayerKind.dhuhr => l10n.prayerDhuhr,
    PrayerKind.asr => l10n.prayerAsr,
    PrayerKind.maghrib => l10n.prayerMaghrib,
    PrayerKind.isha => l10n.prayerIsha,
  };
}

extension NotificationKindL10n on NotificationKind {
  String localized(AppLocalizations l10n) => switch (this) {
    NotificationKind.prePrayer => l10n.notifKindPrePrayer,
    NotificationKind.adhan => l10n.notifKindAdhan,
  };

  /// Subtitle shown on the settings row while the kill switch is off.
  String localizedOffHint(AppLocalizations l10n) => switch (this) {
    NotificationKind.prePrayer => l10n.notifOffPrePrayer,
    NotificationKind.adhan => l10n.notifOffAdhan,
  };
}

extension LocationModeL10n on LocationMode {
  String localized(AppLocalizations l10n) => switch (this) {
    LocationMode.autoGps => l10n.settingsLocationModeAuto,
    LocationMode.city => l10n.settingsLocationModeCity,
  };
}

/// `AlarmPermission` carries a `label`/`blurb` pair for the settings rows. Same
/// story as the other enums: these are display copy and must be able to change
/// with the locale, so the lookup moves here and the model keeps only the enum
/// values that the platform APIs are keyed on.
extension AlarmPermissionL10n on AlarmPermission {
  String localized(AppLocalizations l10n) => switch (this) {
    AlarmPermission.notifications => l10n.accessNotifications,
    AlarmPermission.exactAlarms => l10n.accessAlarmsAndReminders,
    AlarmPermission.fullScreenIntent => l10n.accessFullScreen,
    AlarmPermission.overlay => l10n.accessDisplayOverOtherApps,
    AlarmPermission.policyAccess => l10n.accessDndAccess,
    AlarmPermission.battery => l10n.accessUnrestrictedBattery,
  };

  String localizedBlurb(AppLocalizations l10n) => switch (this) {
    AlarmPermission.notifications => l10n.accessBlurbNotifications,
    AlarmPermission.exactAlarms => l10n.accessBlurbAlarmsAndReminders,
    AlarmPermission.fullScreenIntent => l10n.accessBlurbFullScreen,
    AlarmPermission.overlay => l10n.accessBlurbOverApps,
    AlarmPermission.policyAccess => l10n.accessBlurbDnd,
    AlarmPermission.battery => l10n.accessBlurbBattery,
  };
}

extension AppLanguageL10n on AppLanguage {
  String localized(AppLocalizations l10n) => switch (this) {
    AppLanguage.system => l10n.settingsLanguageSystem,
    AppLanguage.english => l10n.settingsLanguageEnglish,
    AppLanguage.arabic => l10n.settingsLanguageArabic,
    AppLanguage.french => l10n.settingsLanguageFrench,
  };
}

extension AppThemeModeL10n on AppThemeMode {
  String localized(AppLocalizations l10n) => switch (this) {
    AppThemeMode.system => l10n.settingsThemeSystem,
    AppThemeMode.light => l10n.settingsThemeLight,
    AppThemeMode.dark => l10n.settingsThemeDark,
  };
}
