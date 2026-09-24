/// Which audible notification the settings UI and service layer are operating
/// on. Both kinds share one service and one settings component — the adhan
/// additionally layers full-screen + alarm-stop behaviour on top of the base.
enum NotificationKind {
  /// Short countdown reminder shown a few minutes before each prayer.
  prePrayer,

  /// The full adhan call at prayer entry (full-screen alarm behaviour).
  adhan;

  /// Settings/tab label for this kind.
  String get label => switch (this) {
    NotificationKind.prePrayer => 'Pre-Prayer',
    NotificationKind.adhan => 'Adhan',
  };

  /// Settings row subtitle when this kind is switched off.
  String get offHint => switch (this) {
    NotificationKind.prePrayer => 'No countdown reminders before prayers.',
    NotificationKind.adhan => 'No adhan alarm at prayer entry.',
  };
}
