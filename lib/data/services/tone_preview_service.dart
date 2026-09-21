import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;

import 'package:mawaqit/core/audio/tone_catalog.dart';

/// Plays short tone previews inside the settings tone picker.
///
/// On Android/iOS the bundled `audioplayers` engine is used. On Linux desktop
/// `audioplayers` needs the GStreamer `wavparse`/`autoaudiosink` plugins, which
/// are frequently absent on dev machines, so we fall back to a system audio CLI
/// (`paplay`, `aplay` or `ffplay`) instead. All failures are swallowed and
/// reported via the returned bool so a missing backend never crashes the app.
class TonePreviewService {
  TonePreviewService() {
    if (_isLinux) {
      _linuxPlayer = _detectLinuxPlayer();
    } else {
      _player = AudioPlayer();
      _completeSub = _player!.onPlayerComplete.listen((_) {
        _playing = null;
        onComplete?.call();
      });
    }
  }

  static final bool _isLinux = !kIsWeb && Platform.isLinux;
  static final bool _isAndroid = !kIsWeb && Platform.isAndroid;

  static const MethodChannel _deviceChannel = MethodChannel('mawaqit/native');

  AudioPlayer? _player;
  StreamSubscription<void>? _completeSub;
  Process? _process;
  String? _linuxPlayer;

  String? _playing;

  /// Invoked when the current preview finishes on its own.
  VoidCallback? onComplete;

  /// The tone name currently previewing, or null when stopped.
  String? get playing => _playing;

  /// Whether a preview backend is available on this platform.
  bool get isSupported => _isLinux ? _linuxPlayer != null : true;

  /// Device ringtones/notifications are an Android-only concept.
  bool get supportsDeviceTones => _isAndroid;

  /// Lists the device's notification, alarm and ringtone sounds.
  Future<List<DeviceTone>> listDeviceTones() async {
    if (!_isAndroid) return const [];
    try {
      final rows = await _deviceChannel
          .invokeListMethod<Map<dynamic, dynamic>>('listDeviceTones');
      if (rows == null) return const [];
      return [
        for (final row in rows)
          if (row['uri'] is String && (row['uri'] as String).isNotEmpty)
            DeviceTone(
              name: (row['name'] as String?)?.trim().isNotEmpty == true
                  ? row['name'] as String
                  : 'Device sound',
              uri: row['uri'] as String,
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Previews a device sound through the native ringtone player.
  Future<bool> previewDeviceTone(DeviceTone tone) async {
    if (!_isAndroid) return false;
    await stop();
    try {
      await _deviceChannel.invokeMethod('previewDeviceTone', {
        'uri': tone.uri,
      });
      _playing = tone.name;
      return true;
    } catch (_) {
      _playing = null;
      return false;
    }
  }

  /// Plays [tone], or stops when it is already the one playing.
  Future<bool> toggle(AdhanTone tone) async {
    if (_playing == tone.name) {
      await stop();
      return true;
    }
    return play(tone);
  }

  Future<bool> play(AdhanTone tone) async {
    await stop();
    if (tone.silent || tone.assetPath.isEmpty) return true;
    if (_isLinux) return _playLinux(tone);
    return _playAudioPlayers(tone);
  }

  Future<void> stop() async {
    _playing = null;
    if (_isAndroid) {
      try {
        await _deviceChannel.invokeMethod('stopDeviceTonePreview');
      } catch (_) {}
    }
    if (_isLinux) {
      final process = _process;
      _process = null;
      try {
        process?.kill(ProcessSignal.sigterm);
      } catch (_) {}
      return;
    }
    try {
      await _player?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _completeSub?.cancel();
    await stop();
    try {
      await _player?.dispose();
    } catch (_) {}
  }

  Future<bool> _playAudioPlayers(AdhanTone tone) async {
    try {
      await _player!.play(AssetSource(tone.assetPath));
      _playing = tone.name;
      return true;
    } catch (_) {
      _playing = null;
      return false;
    }
  }

  Future<bool> _playLinux(AdhanTone tone) async {
    final command = _linuxPlayer;
    if (command == null) return false;
    try {
      final file = await _extractAsset(tone);
      final args = command == 'ffplay'
          ? ['-nodisp', '-autoexit', '-loglevel', 'quiet', file.path]
          : [file.path];
      final process = await Process.start(command, args);
      _process = process;
      _playing = tone.name;
      process.exitCode.then((_) {
        if (_process == process) _process = null;
        if (_playing == tone.name) {
          _playing = null;
          onComplete?.call();
        }
      });
      return true;
    } catch (_) {
      _playing = null;
      return false;
    }
  }

  /// Copies a bundled tone asset to a temp file for CLI playback.
  Future<File> _extractAsset(AdhanTone tone) async {
    final data = await rootBundle.load('assets/${tone.assetPath}');
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final file = File(
      '${Directory.systemTemp.path}/waqt_${tone.androidRawResource}.wav',
    );
    if (!file.existsSync() || file.lengthSync() != bytes.length) {
      await file.writeAsBytes(bytes, flush: true);
    }
    return file;
  }

  static String? _detectLinuxPlayer() {
    for (final candidate in const ['paplay', 'aplay', 'ffplay']) {
      try {
        final result = Process.runSync('which', [candidate]);
        if (result.exitCode == 0 && (result.stdout as String).trim().isNotEmpty) {
          return candidate;
        }
      } catch (_) {}
    }
    return null;
  }
}