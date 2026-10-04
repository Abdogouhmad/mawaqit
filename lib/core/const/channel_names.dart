/// Android notification channel ids and display names.
///
/// These strings are written into the *same* `SharedPreferences` file the
/// Kotlin side reads, and into `NotificationManager` itself, so they are part of
/// the app's on-disk contract rather than display copy. Two rules follow:
///
///  * the ids are frozen — Android ignores attempts to change a channel's
///    importance or sound after creation, so a changed setting needs a **new**
///    id (and an explicit delete of the old one);
///  * the ids mirror the Kotlin `Channels` object byte for byte.
///
/// Display names come from `AppLocalizations.channel*` instead; only the stable
/// machine ids live here.
library;

abstract final class ChannelNames {
  const ChannelNames._();

  /// The adhan itself: silent, because the foreground service owns the audio
  /// and a channel sound would double up with it.
  static const String adhan = 'adhan';

  /// Fallback path for when the foreground service cannot start
  /// (`ForegroundServiceStartNotAllowedException`). This one *does* carry the
  /// adhan sound, so it is the only channel that must survive on its own.
  static const String adhanFallback = 'adhan_fallback';

  /// Soft pre-prayer countdown.
  static const String reminder = 'reminder';

  /// In-app "test adhan" so the Reliability screen can prove the path works
  /// without waiting for a real prayer time.
  static const String adhanTest = 'adhan_test';
}
