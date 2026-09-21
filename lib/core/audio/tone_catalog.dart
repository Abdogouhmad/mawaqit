/// Built-in adhan / alert tones.
///
/// Each tone is an original, synthesised WAV (see `tool/gen_tones.py`) bundled
/// both as a Flutter asset (for in-app preview) and as an Android `res/raw`
/// resource (for the notification channel sound). The names here are the
/// values persisted in [AppSettings.adhanTone]; never rename them without a
/// migration.
class AdhanTone {
  const AdhanTone({
    required this.name,
    required this.assetPath,
    required this.androidRawResource,
    this.silent = false,
  });

  final String name;
  final String assetPath;

  /// `res/raw` name passed to the Android notification sound (no extension).
  final String androidRawResource;
  final bool silent;
}

/// A ringtone / notification sound that already exists on the device.
class DeviceTone {
  const DeviceTone({required this.name, required this.uri});

  final String name;

  /// Platform URI (Android `content://…`) usable as a notification sound.
  final String uri;

  /// Stable, resource-safe channel suffix derived from the URI.
  String get slug {
    final parts = uri.split('/').where((part) => part.isNotEmpty).toList();
    final cleaned = parts.isEmpty
        ? ''
        : parts.last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return cleaned.isEmpty ? 'sound' : cleaned.toLowerCase();
  }
}

abstract final class ToneCatalog {
  static const String silentName = 'Silent';

  static const List<AdhanTone> tones = [
    AdhanTone(
      name: 'Adham Al Sharqawe',
      assetPath: 'audio/Adham Al Sharqawe.mp3',
      androidRawResource: 'adhan_adham_al_sharqawe',
    ),
    AdhanTone(
      name: silentName,
      assetPath: '',
      androidRawResource: '',
      silent: true,
    ),
  ];

  static const AdhanTone fallback = AdhanTone(
    name: 'Adham Al Sharqawe',
    assetPath: 'audio/Adham Al Sharqawe.mp3',
    androidRawResource: 'adhan_adham_al_sharqawe',
  );

  /// Resolves a persisted tone name to its definition (never null).
  static AdhanTone byName(String name) {
    for (final tone in tones) {
      if (tone.name == name) return tone;
    }
    return fallback;
  }
}