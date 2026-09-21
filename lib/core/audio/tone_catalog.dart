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
      name: 'Traditional Adhan',
      assetPath: 'audio/tone_traditional_adhan.wav',
      androidRawResource: 'tone_traditional_adhan',
    ),
    AdhanTone(
      name: 'Mellow Bell',
      assetPath: 'audio/tone_mellow_bell.wav',
      androidRawResource: 'tone_mellow_bell',
    ),
    AdhanTone(
      name: 'Minimal Chime',
      assetPath: 'audio/tone_minimal_chime.wav',
      androidRawResource: 'tone_minimal_chime',
    ),
    AdhanTone(
      name: 'Desert Wind',
      assetPath: 'audio/tone_desert_wind.wav',
      androidRawResource: 'tone_desert_wind',
    ),
    AdhanTone(
      name: 'Nabawi Melody',
      assetPath: 'audio/tone_nabawi_melody.wav',
      androidRawResource: 'tone_nabawi_melody',
    ),
    AdhanTone(
      name: 'Zen Bow',
      assetPath: 'audio/tone_zen_bow.wav',
      androidRawResource: 'tone_zen_bow',
    ),
    AdhanTone(
      name: 'Dawn Call',
      assetPath: 'audio/tone_dawn_call.wav',
      androidRawResource: 'tone_dawn_call',
    ),
    AdhanTone(
      name: 'Amber Bell',
      assetPath: 'audio/tone_amber_bell.wav',
      androidRawResource: 'tone_amber_bell',
    ),
    AdhanTone(
      name: 'Soft Harp',
      assetPath: 'audio/tone_soft_harp.wav',
      androidRawResource: 'tone_soft_harp',
    ),
    AdhanTone(
      name: 'Medina Breeze',
      assetPath: 'audio/tone_medina_breeze.wav',
      androidRawResource: 'tone_medina_breeze',
    ),
    AdhanTone(
      name: 'Night Calm',
      assetPath: 'audio/tone_night_calm.wav',
      androidRawResource: 'tone_night_calm',
    ),
    AdhanTone(
      name: 'Tranquil Gong',
      assetPath: 'audio/tone_tranquil_gong.wav',
      androidRawResource: 'tone_tranquil_gong',
    ),
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
    name: 'Traditional Adhan',
    assetPath: 'audio/tone_traditional_adhan.wav',
    androidRawResource: 'tone_traditional_adhan',
  );

  /// Resolves a persisted tone name to its definition (never null).
  static AdhanTone byName(String name) {
    for (final tone in tones) {
      if (tone.name == name) return tone;
    }
    return fallback;
  }
}