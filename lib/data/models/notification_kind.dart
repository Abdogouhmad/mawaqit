/// Which audible notification the settings UI and service layer are operating
/// on. Both kinds share one service and one settings component — the adhan
/// additionally layers full-screen + alarm-stop behaviour on top of the base.
enum NotificationKind {
  /// Short countdown reminder shown a few minutes before each prayer.
  prePrayer,

  /// The full adhan call at prayer entry (full-screen alarm behaviour).
  adhan,

  // No `label` / `offHint` here on purpose: both are locale-dependent display
  // copy and now live in `NotificationKindL10n`
  // (lib/l10n/enum_localization.dart). See [PrayerKind] for the same reasoning.
}
