/// Every `SharedPreferences` key the app writes.
///
/// The Kotlin module reads some of these from the same preferences file, so
/// they are a cross-language contract: renaming one silently orphans the value
/// on the native side. Values are namespaced per concern so a future migration
/// can target one group without guessing.
library;

abstract final class PrefKeys {
  const PrefKeys._();

  // ── Settings ────────────────────────────────────────────────────────────
  /// Single JSON blob holding the whole `AppSettings`. Bumped when its shape
  /// changes incompatibly; `_fromJson` treats an unknown blob as defaults.
  static const String appSettings = 'app_settings_v1';

  // ── Resolved location cache ─────────────────────────────────────────────
  /// Read by the background isolate and by the native reschedule path, so it
  /// must land *before* any scheduling is attempted.
  static const String locationLatitude = 'resolved_latitude';
  static const String locationLongitude = 'resolved_longitude';
  static const String locationName = 'resolved_location_name';
  static const String locationIsManual = 'resolved_location_manual';

  // ── Onboarding ──────────────────────────────────────────────────────────
  /// Set once the user has been through (or skipped) the permissions flow, so
  /// the walkthrough is shown exactly once per install.
  static const String onboardingComplete = 'onboarding_complete';

  // ── Scheduled events ────────────────────────────────────────────────────
  /// Fingerprint of the event list last handed to native. Lets the Dart side
  /// skip a reschedule when nothing actually changed.
  static const String scheduledFingerprint = 'scheduled_fingerprint';

  /// Epoch ms of the last successful native hand-off, used by the Reliability
  /// screen's "days of events remaining" read.
  static const String scheduledAt = 'scheduled_at';

  // ── Onboarding / reliability ────────────────────────────────────────────
  /// Per-prayer mutes for a single occurrence, as `2026-09-21_maghrib`. Shared
  /// with the native lock-screen card through the same prefs file.
  static const String mutedPrayers = 'muted_prayers';
}
